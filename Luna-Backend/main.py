"""  
Luna venue discovery backend API - Database version.

This module implements all API endpoints for the venue discovery application
using SQLite persistence via SQLAlchemy async ORM.

ENDPOINTS:
- GET /venues - List all venues
- GET /venues/{venue_id} - Get venue details with interested users
- POST /interests - Express interest in a venue
- GET /users/{user_id} - Get user profile with interested venues
- GET /recommendations - Get personalized venue recommendations
- POST /action-items/{item_id}/complete - Complete action item
- DELETE /action-items/{item_id} - Dismiss action item
- GET /bookings/{user_id} - Get user bookings
- GET /venues/{venue_id}/booking - Check venue booking status

DATABASE:
- SQLite with async support (aiosqlite)
- SQLAlchemy 2.0 async ORM
- Automatic initialization and seeding on first run
"""

import logging
import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

# Database imports
from database import init_db, close_db, get_db
from models.db_models import (
    UserDB, VenueDB, InterestDB, UserInterestDB, FriendshipDB, 
    ActionItemDB, ActivityDB, ActionItemConfirmationDB,
    ChatDB, ChatParticipantDB, ChatMessageDB
)
from models.api_models import ActionItem
from seed_data import check_and_seed
from agent import action_item_agent
from utils.distance import haversine_distance, calculate_proximity_score

# Configure logging for production
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for application startup and shutdown.
    
    Initializes database and seeds data on startup.
    Closes database connections on shutdown.
    """
    logger.info("Starting Luna Backend API...")
    
    # Initialize database
    await init_db()
    
    # Check and seed database if needed
    async with get_db() as session:
        await check_and_seed(session)
    
    logger.info("Luna Backend API ready")
    
    yield
    
    # Cleanup on shutdown
    logger.info("Shutting down Luna Backend API...")
    await close_db()


# Initialize FastAPI app with lifespan
app = FastAPI(
    title="Luna Venue Discovery API",
    description="Backend API for venue discovery and social interest tracking",
    version="2.0.0",
    lifespan=lifespan
)

# Add CORS middleware for iOS app integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request/Response Models
class InterestRequest(BaseModel):
    """Request model for expressing interest in a venue."""
    user_id: str
    venue_id: str
    
    @validator('user_id', 'venue_id')
    def validate_ids(cls, v):
        """Validate that IDs are not empty and contain only valid characters."""
        if not v or not v.strip():
            raise ValueError('ID cannot be empty')
        if len(v) > 100:
            raise ValueError('ID too long (max 100 characters)')
        # Basic sanitization - alphanumeric and underscore only
        if not all(c.isalnum() or c == '_' for c in v):
            raise ValueError('ID contains invalid characters')
        return v.strip()


class ActionItemResponse(BaseModel):
    """Response model for action item creation."""
    action_item_created: bool
    action_item_id: Optional[str] = None
    description: Optional[str] = None
    action_code: Optional[str] = None
    interested_user_ids: Optional[List[str]] = None


class InterestResponse(BaseModel):
    """Response model after expressing interest."""
    success: bool
    message: str
    action_item: Optional[ActionItemResponse] = None


class CompleteActionItemRequest(BaseModel):
    """Request model for completing an action item."""
    user_id: str


class SuccessResponse(BaseModel):
    """Generic success response."""
    success: bool
    message: str


# Helper Functions (Database-backed)

async def get_interested_count(session, venue_id: str) -> int:
    """
    Calculate the number of users interested in a venue.
    
    Args:
        session: Database session
        venue_id: The ID of the venue
        
    Returns:
        Count of users interested in this venue
    """
    try:
        result = await session.execute(
            select(func.count(InterestDB.user_id))
            .where(InterestDB.venue_id == venue_id)
        )
        return result.scalar() or 0
    except Exception as e:
        logger.error(f"Failed to get interested count for venue {venue_id}: {e}")
        return 0  # Fail gracefully with 0 count



async def get_interested_users(session, venue_id: str) -> List[Dict]:
    """
    Get list of users interested in a specific venue.
    
    Args:
        session: Database session
        venue_id: The ID of the venue
        
    Returns:
        List of simplified user objects (id, name, avatar only)
    """
    try:
        result = await session.execute(
            select(UserDB)
            .join(InterestDB, InterestDB.user_id == UserDB.id)
            .where(InterestDB.venue_id == venue_id)
        )
        users = result.scalars().all()
        
        return [
            {
                "id": user.id,
                "name": user.name,
                "avatar": user.avatar
            }
            for user in users
        ]
    except Exception as e:
        logger.error(f"Failed to get interested users for venue {venue_id}: {e}")
        return []  # Fail gracefully with empty list


async def get_user_interested_venues(session, user_id: str) -> List[Dict]:
    """
    Get list of venues a user is interested in.
    
    Args:
        session: Database session
        user_id: The ID of the user
        
    Returns:
        List of full venue objects with interested counts
    """
    try:
        result = await session.execute(
            select(VenueDB)
            .join(InterestDB, InterestDB.venue_id == VenueDB.id)
            .where(InterestDB.user_id == user_id)
        )
        venues = result.scalars().all()
        
        venues_list = []
        for venue in venues:
            interested_count = await get_interested_count(session, venue.id)
            
            # Get user to calculate distance
            user = await session.get(UserDB, user_id)
            distance_km = None
            if user:
                distance_km = haversine_distance(
                    user.latitude, user.longitude,
                    venue.latitude, venue.longitude
                )
            
            venues_list.append({
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "description": venue.description,
                "image": venue.image,
                "images": venue.images,  # Array for multi-image galleries
                "address": venue.address,
                "latitude": venue.latitude,  # For "Get Directions" feature
                "longitude": venue.longitude,  # For "Get Directions" feature
                "interested_count": interested_count,
                "distance_km": distance_km
            })
        
        return venues_list
    except Exception as e:
        logger.error(f"Failed to get interested venues for user {user_id}: {e}")
        return []  # Fail gracefully with empty list


async def count_friends_interested(session, user_id: str, venue_id: str) -> int:
    """
    Count how many friends are interested in a venue.
    
    Checks bidirectional friendships and counts interests.
    
    Args:
        session: Database session
        user_id: The ID of the current user
        venue_id: The ID of the venue
        
    Returns:
        Count of friends interested in this venue
    """
    try:
        # Get all friend IDs (bidirectional)
        result = await session.execute(
            select(FriendshipDB)
            .where(
                or_(
                    FriendshipDB.user_id == user_id,
                    FriendshipDB.friend_id == user_id
                )
            )
        )
        friendships = result.scalars().all()
        
        friend_ids = set()
        for friendship in friendships:
            if friendship.user_id == user_id:
                friend_ids.add(friendship.friend_id)
            else:
                friend_ids.add(friendship.user_id)
        
        # Count how many friends are interested in this venue
        if not friend_ids:
            return 0
        
        result = await session.execute(
            select(func.count(InterestDB.user_id))
            .where(
                and_(
                    InterestDB.venue_id == venue_id,
                    InterestDB.user_id.in_(friend_ids)
                )
            )
        )
        return result.scalar() or 0
    except Exception as e:
        logger.error(f"Failed to count friends interested for user {user_id}, venue {venue_id}: {e}")
        return 0  # Fail gracefully with 0 count


async def batch_get_interested_counts(session, venue_ids: List[str]) -> Dict[str, int]:
    """
    Batch load interested counts for multiple venues in a single query.
    
    Optimizes N+1 query problem by loading all counts at once.
    
    Args:
        session: Database session
        venue_ids: List of venue IDs to get counts for
        
    Returns:
        Dictionary mapping venue_id to interested count
    """
    try:
        if not venue_ids:
            return {}
        
        result = await session.execute(
            select(
                InterestDB.venue_id,
                func.count(InterestDB.user_id).label('count')
            )
            .where(InterestDB.venue_id.in_(venue_ids))
            .group_by(InterestDB.venue_id)
        )
        
        # Convert to dictionary
        counts = {venue_id: count for venue_id, count in result.all()}
        
        # Ensure all requested venue_ids are in result (with 0 if no interests)
        return {venue_id: counts.get(venue_id, 0) for venue_id in venue_ids}
    except Exception as e:
        logger.error(f"Failed to batch get interested counts: {e}")
        # Return 0 for all venues on error
        return {venue_id: 0 for venue_id in venue_ids}


async def batch_count_friends_interested(session, user_id: str, venue_ids: List[str]) -> Dict[str, int]:
    """
    Batch load friend-interested counts for multiple venues in a single set of queries.
    
    Optimizes N+1 query problem for friend interest calculations.
    
    Args:
        session: Database session
        user_id: The ID of the current user
        venue_ids: List of venue IDs to check
        
    Returns:
        Dictionary mapping venue_id to friends interested count
    """
    try:
        if not venue_ids:
            return {}
        
        # Get all friend IDs (bidirectional) - single query
        result = await session.execute(
            select(FriendshipDB)
            .where(
                or_(
                    FriendshipDB.user_id == user_id,
                    FriendshipDB.friend_id == user_id
                )
            )
        )
        friendships = result.scalars().all()
        
        friend_ids = set()
        for friendship in friendships:
            if friendship.user_id == user_id:
                friend_ids.add(friendship.friend_id)
            else:
                friend_ids.add(friendship.user_id)
        
        if not friend_ids:
            return {venue_id: 0 for venue_id in venue_ids}
        
        # Count friends interested for all venues - single query
        result = await session.execute(
            select(
                InterestDB.venue_id,
                func.count(InterestDB.user_id).label('count')
            )
            .where(
                and_(
                    InterestDB.venue_id.in_(venue_ids),
                    InterestDB.user_id.in_(friend_ids)
                )
            )
            .group_by(InterestDB.venue_id)
        )
        
        counts = {venue_id: count for venue_id, count in result.all()}
        
        # Ensure all requested venue_ids are in result
        return {venue_id: counts.get(venue_id, 0) for venue_id in venue_ids}
    except Exception as e:
        logger.error(f"Failed to batch count friends interested: {e}")
        return {venue_id: 0 for venue_id in venue_ids}


async def batch_check_user_interests(session, user_id: str, venue_ids: List[str]) -> Dict[str, bool]:
    """
    Batch check if user is interested in multiple venues.
    
    Optimizes N+1 query problem for user interest checks.
    
    Args:
        session: Database session
        user_id: The ID of the user
        venue_ids: List of venue IDs to check
        
    Returns:
        Dictionary mapping venue_id to boolean (True if interested)
    """
    try:
        if not venue_ids:
            return {}
        
        result = await session.execute(
            select(InterestDB.venue_id)
            .where(
                and_(
                    InterestDB.user_id == user_id,
                    InterestDB.venue_id.in_(venue_ids)
                )
            )
        )
        
        interested_venue_ids = {row[0] for row in result.all()}
        
        return {venue_id: venue_id in interested_venue_ids for venue_id in venue_ids}
    except Exception as e:
        logger.error(f"Failed to batch check user interests: {e}")
        return {venue_id: False for venue_id in venue_ids}




async def calculate_recommendation_score(session, user_id: str, venue_id: str):
    """
    Calculate recommendation score for a venue based on user preferences.
    
    CRITICAL: Score is based on OTHER users' interests, excluding the current user.
    This ensures scores don't change when user toggles their own interest.
    
    Scoring factors (out of 10 points):
    - Popularity (30% = 3.0 points) based on OTHER users interested
    - Category match (25% = 2.5 points) based on user interests
    - Friend interest (25% = 2.5 points) based on friends interested
    - Proximity (20% = 2.0 points) based on distance from user
    
    Returns:
        Tuple of (score, reason, friends_interested, total_interested, distance_km, score_breakdown)
    """
    # Get user and venue
    user = await session.get(UserDB, user_id)
    venue = await session.get(VenueDB, venue_id)
    
    if not user or not venue:
        return 0.0, "Invalid user or venue", 0, 0, None, {}
    
    score = 0.0
    reasons = []
    
    # Calculate distance
    distance_km = haversine_distance(user.latitude, user.longitude, venue.latitude, venue.longitude)
    
    # Get total interested count (all users)
    total_interested_count = await get_interested_count(session, venue_id)
    
    # Get count of OTHER users interested (excluding current user)
    result = await session.execute(
        select(func.count(InterestDB.user_id))
        .where(
            and_(
                InterestDB.venue_id == venue_id,
                InterestDB.user_id != user_id
            )
        )
    )
    other_users_interested = result.scalar() or 0
    
    # Get friends interested count
    friends_interested = await count_friends_interested(session, user_id, venue_id)
    
    # Factor 1: Popularity (30% weight = 3.0 points max)
    popularity_normalized = min(other_users_interested / 3, 1.0)
    popularity_score = popularity_normalized * 3.0
    score += popularity_score
    if other_users_interested > 0:
        reasons.append(f"Popular venue")
    
    # Factor 2: Category match (25% weight = 2.5 points max)
    # Get user interests
    result = await session.execute(
        select(UserInterestDB.interest_category)
        .where(UserInterestDB.user_id == user_id)
    )
    user_interests = [row[0] for row in result.all()]
    
    venue_category_lower = venue.category.lower()
    category_match = 0.0
    for interest in user_interests:
        if interest.lower() in venue_category_lower or venue_category_lower in interest.lower():
            category_match = 1.0
            reasons.append("Matches your interests")
            break
    category_score = category_match * 2.5
    score += category_score
    
    # Factor 3: Friend interest (25% weight = 2.5 points max)
    friend_normalized = min(friends_interested / 3, 1.0)
    friend_score = friend_normalized * 2.5
    score += friend_score
    
    # Factor 4: Proximity (20% weight = 2.0 points max)
    proximity_score_value = calculate_proximity_score(distance_km)
    proximity_score = proximity_score_value * 2.0
    score += proximity_score
    
    # Add distance to reason if it's nearby
    if distance_km <= 2:
        reasons.append(f"{distance_km} km away")
    
    # Generate reason string
    reason = ", ".join(reasons) if reasons else "New venue to explore"
    
    # Calculate score breakdown percentages (out of 100)
    # Convert scores to percentages based on maximum possible score (10)
    score_breakdown = {
        "popularity": round((popularity_score / 3.0) * 30, 1),  # Max 30%
        "category_match": round((category_score / 2.5) * 25, 1),  # Max 25%
        "friend_signal": round((friend_score / 2.5) * 25, 1),  # Max 25%
        "proximity": round((proximity_score / 2.0) * 20, 1)  # Max 20%
    }
    
    return score, reason, friends_interested, total_interested_count, distance_km, score_breakdown


# API Endpoints

@app.get("/")
def root():
    """Health check endpoint."""
    return {
        "message": "Luna Venue Discovery API",
        "status": "running",
        "version": "2.0.0",
        "database": "SQLite"
    }


@app.get("/venues")
async def get_venues(
    user_id: Optional[str] = None,
    categories: Optional[str] = None,
    max_distance: Optional[float] = None,
    min_friend_interest: Optional[int] = None,
    only_interested: Optional[bool] = None,
    exclude_interested: Optional[bool] = None,
    sort_by: Optional[str] = None
):
    """
    Get list of all venues with optional filtering and sorting.
    
    Args:
        user_id: Optional user ID to calculate distances and friend interests
        categories: Comma-separated list of categories to filter by
        max_distance: Maximum distance in km (requires user_id)
        min_friend_interest: Minimum number of friends interested (requires user_id)
        only_interested: Show only venues user is interested in (requires user_id)
        exclude_interested: Show only venues user is NOT interested in (requires user_id)
        sort_by: Sort criterion (distance, popularity, friends, name)
    
    Returns:
        JSON object with venues array, applied filters, and result counts
    """
    logger.info(f"Fetching venues with filters: user_id={user_id}, categories={categories}, "
                f"max_distance={max_distance}, min_friend_interest={min_friend_interest}, "
                f"only_interested={only_interested}, exclude_interested={exclude_interested}, sort_by={sort_by}")
    
    async with get_db() as session:
        # Get user if user_id provided
        user = None
        if user_id:
            user = await session.get(UserDB, user_id)
            if not user:
                logger.warning(f"User not found: {user_id}")
        
        # Build base query with category filter
        query = select(VenueDB)
        
        # Apply category filter at SQL level
        if categories and categories.lower() != "all":
            category_list = [cat.strip() for cat in categories.split(",") if cat.strip()]
            if category_list:
                query = query.where(VenueDB.category.in_(category_list))
        
        # Get total venues count before filtering
        total_result = await session.execute(select(func.count()).select_from(VenueDB))
        total_venues = total_result.scalar() or 0
        
        # Execute query
        result = await session.execute(query)
        venues_db = result.scalars().all()
        
        # PERFORMANCE OPTIMIZATION: Batch load all data to avoid N+1 queries
        # Old approach: 3 queries per venue (interested_count, friends_interested, user_interested)
        # New approach: 3 queries total regardless of venue count
        
        venue_ids = [venue.id for venue in venues_db]
        
        # Batch load interested counts for all venues (1 query)
        interested_counts = await batch_get_interested_counts(session, venue_ids)
        
        # Batch load friend-interested counts if user provided (2 queries max)
        friends_interested_counts = {}
        user_interests = {}
        if user and user_id:
            friends_interested_counts = await batch_count_friends_interested(session, user_id, venue_ids)
            user_interests = await batch_check_user_interests(session, user_id, venue_ids)
        
        # Build venue list with all data (no queries in loop!)
        venues = []
        for venue in venues_db:
            venue_data = {
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "image": venue.image,
                "interested_count": interested_counts.get(venue.id, 0),
                "created_at": venue.created_at.isoformat() if venue.created_at else None
            }
            
            # Calculate distance if user provided (pure calculation, no query)
            if user:
                distance_km = haversine_distance(user.latitude, user.longitude, venue.latitude, venue.longitude)
                venue_data["distance_km"] = distance_km
                venue_data["friends_interested"] = friends_interested_counts.get(venue.id, 0)
                venue_data["user_interested"] = user_interests.get(venue.id, False)
            
            venues.append(venue_data)
        
        # Apply distance filter
        if max_distance is not None and user:
            venues = [v for v in venues if v.get("distance_km", float("inf")) <= max_distance]
        
        # Apply friend interest filter
        if min_friend_interest is not None and user:
            venues = [v for v in venues if v.get("friends_interested", 0) >= min_friend_interest]
        
        # Apply personal interest filters
        if only_interested and user:
            venues = [v for v in venues if v.get("user_interested", False)]
        elif exclude_interested and user:
            venues = [v for v in venues if not v.get("user_interested", False)]
        
        # Apply sorting
        sort_criterion = sort_by or "popularity"
        if sort_criterion == "distance" and user:
            venues.sort(key=lambda v: (v.get("distance_km", float("inf")), v["name"].lower()))
        elif sort_criterion == "popularity":
            venues.sort(key=lambda v: (-v["interested_count"], v["name"].lower()))
        elif sort_criterion == "friends" and user:
            venues.sort(key=lambda v: (-v.get("friends_interested", 0), v["name"].lower()))

        elif sort_criterion == "name":
            venues.sort(key=lambda v: v["name"].lower())
        else:
            # Default: popularity
            venues.sort(key=lambda v: (-v["interested_count"], v["name"].lower()))
        
        # Build response with metadata
        applied_filters = {}
        if categories:
            applied_filters["categories"] = categories
        if max_distance is not None:
            applied_filters["max_distance"] = max_distance
        if min_friend_interest is not None:
            applied_filters["min_friend_interest"] = min_friend_interest
        if only_interested:
            applied_filters["only_interested"] = only_interested
        if exclude_interested:
            applied_filters["exclude_interested"] = exclude_interested
        if sort_by:
            applied_filters["sort_by"] = sort_by
        
        logger.info(f"Returning {len(venues)} venues (total: {total_venues})")
        return {
            "venues": venues,
            "applied_filters": applied_filters,
            "result_count": len(venues),
            "total_venues": total_venues
        }


@app.get("/venues/{venue_id}")
async def get_venue_detail(venue_id: str, user_id: Optional[str] = None):
    """
    Get detailed information about a specific venue.
    
    Args:
        venue_id: The ID of the venue to retrieve
        user_id: Optional user ID to calculate distance from user location
        
    Returns:
        JSON object with complete venue details and list of interested users
        
    Raises:
        HTTPException: 404 if venue not found
    """
    logger.info(f"Fetching venue detail for venue_id: {venue_id}, user_id: {user_id}")
    
    async with get_db() as session:
        venue = await session.get(VenueDB, venue_id)
        
        if not venue:
            logger.warning(f"Venue not found: {venue_id}")
            raise HTTPException(status_code=404, detail=f"Venue with id '{venue_id}' not found")
        
        interested_users = await get_interested_users(session, venue_id)
        
        # Build venue response with complete data
        venue_data = {
            "id": venue.id,
            "name": venue.name,
            "category": venue.category,
            "description": venue.description,
            "image": venue.image,
            "images": venue.images,  # Array of image URLs for galleries
            "address": venue.address,
            "latitude": venue.latitude,
            "longitude": venue.longitude
        }
        
        # Calculate distance if user_id provided
        if user_id:
            user = await session.get(UserDB, user_id)
            if user:
                distance_km = haversine_distance(
                    user.latitude, user.longitude,
                    venue.latitude, venue.longitude
                )
                venue_data["distance_km"] = distance_km
        
        return {
            "venue": venue_data,
            "interested_users": interested_users
        }


@app.post("/interests")
async def express_interest(request: InterestRequest) -> InterestResponse:
    """
    Express or toggle interest in a venue.
    
    If the user is already interested, removes the interest and associated activity.
    If not interested, adds the interest and creates an activity for friends' social feeds.
    
    Activities are committed separately from action items to ensure they always persist.
    This maintains consistency across Profile, Discover, Recommended, and Social tabs.
    
    Handles action item creation when threshold is met (5+ users).
    
    Args:
        request: InterestRequest containing user_id and venue_id
        
    Returns:
        InterestResponse with success status and message
        
    Raises:
        HTTPException: 404 if user or venue not found
        HTTPException: 400 for invalid requests
    """
    logger.info(f"Express interest request: user={request.user_id}, venue={request.venue_id}")
    
    async with get_db() as session:
        # Validate user and venue exist
        user = await session.get(UserDB, request.user_id)
        venue = await session.get(VenueDB, request.venue_id)
        
        if not user:
            logger.warning(f"User not found: {request.user_id}")
            raise HTTPException(status_code=404, detail=f"User with id '{request.user_id}' not found")
        
        if not venue:
            logger.warning(f"Venue not found: {request.venue_id}")
            raise HTTPException(status_code=404, detail=f"Venue with id '{request.venue_id}' not found")
        
        # Check if interest already exists
        result = await session.execute(
            select(InterestDB)
            .where(
                and_(
                    InterestDB.user_id == request.user_id,
                    InterestDB.venue_id == request.venue_id
                )
            )
        )
        existing_interest = result.scalar_one_or_none()
        
        if existing_interest:
            # ============================================================
            # REMOVE INTEREST (toggle off)
            # ============================================================
            
            # Delete the interest record
            await session.delete(existing_interest)
            
            # Delete associated activity for consistency across all tabs
            # This ensures Social tab, Profile tab, etc. stay in sync
            result = await session.execute(
                select(ActivityDB)
                .where(
                    and_(
                        ActivityDB.user_id == request.user_id,
                        ActivityDB.venue_id == request.venue_id,
                        ActivityDB.action == "interested"
                    )
                )
            )
            activities = result.scalars().all()
            
            for activity in activities:
                await session.delete(activity)
            
            # Commit the deletions
            await session.commit()
            
            logger.info(f"Interest and {len(activities)} activity record(s) removed: user={request.user_id}, venue={request.venue_id}")
            
            return InterestResponse(
                success=True,
                message=f"Interest removed for {venue.name}"
            )
        else:
            # ============================================================
            # ADD INTEREST (toggle on)
            # ============================================================
            
            # Create interest record
            new_interest = InterestDB(
                user_id=request.user_id,
                venue_id=request.venue_id,
                created_at=datetime.now()
            )
            session.add(new_interest)
            
            # Create activity for social feed
            # Friends will see this in their Social tab
            activity_id = f"activity_{request.user_id}_{request.venue_id}_{int(datetime.now().timestamp())}"
            new_activity = ActivityDB(
                id=activity_id,
                user_id=request.user_id,
                venue_id=request.venue_id,
                action="interested",
                created_at=datetime.now()
            )
            session.add(new_activity)
            
            # CRITICAL: Commit interest + activity FIRST before action item logic
            # This prevents rollbacks from orphaning activities
            await session.commit()
            
            logger.info(f"Interest and activity created: user={request.user_id}, venue={request.venue_id}, activity_id={activity_id}")
            
            # ============================================================
            # ACTION ITEM LOGIC (separate transaction)
            # ============================================================
            
            # Get all interested user IDs for this venue (includes newly added interest)
            result = await session.execute(
                select(InterestDB.user_id)
                .where(InterestDB.venue_id == request.venue_id)
            )
            interested_user_ids = [row[0] for row in result.all()]
            interested_count = len(interested_user_ids)
            
            # Check if action item already exists for this venue
            result = await session.execute(
                select(ActionItemDB)
                .where(
                    and_(
                        ActionItemDB.venue_id == request.venue_id,
                        ActionItemDB.status == "pending"
                    )
                )
            )
            existing_action_item = result.scalar_one_or_none()
            
            # Try to create action item if threshold met (5+ users)
            try:
                agent_response = action_item_agent(
                    request.venue_id,
                    interested_user_ids,
                    venue.name,
                    venue.category
                )
                
                # Build response based on agent result
                if agent_response["action_item_created"] and not existing_action_item:
                    # Create new action item record in database
                    action_item = ActionItemDB(
                        id=agent_response["action_item_id"],
                        venue_id=request.venue_id,
                        interested_user_ids=agent_response["interested_user_ids"],
                        action_type=agent_response["action_type"],
                        action_code=agent_response["action_code"],
                        description=agent_response["description"],
                        threshold_met=True,
                        status="active",  # Changed from 'pending' to 'active'
                        created_at=agent_response["created_at"],
                        expires_at=agent_response["expires_at"]  # 90 days from creation
                    )
                    session.add(action_item)
                    
                    try:
                        await session.commit()
                        logger.info(f"Action item created: {action_item.id} for venue={request.venue_id}, count={interested_count}")
                        
                        return InterestResponse(
                            success=True,
                            message="Interest recorded successfully",
                            action_item=ActionItemResponse(
                                action_item_created=True,
                                action_item_id=agent_response["action_item_id"],
                                description=agent_response["description"],
                                action_code=agent_response["action_code"],
                                interested_user_ids=agent_response["interested_user_ids"]
                            )
                        )
                    except Exception as commit_error:
                        # Action item failed, but interest + activity are already saved!
                        logger.error(f"Failed to commit action item (interest already saved): {str(commit_error)}", exc_info=True)
                        await session.rollback()
                        
                        return InterestResponse(
                            success=True,
                            message="Interest recorded successfully"
                        )
                else:
                    # No action item needed
                    return InterestResponse(
                        success=True,
                        message="Interest recorded successfully"
                    )
            except Exception as e:
                # Action item logic failed, but interest + activity are already saved!
                logger.error(f"Action item agent error (interest already saved): {str(e)}", exc_info=True)
                
                return InterestResponse(
                    success=True,
                    message="Interest recorded successfully"
                )


@app.get("/users/{user_id}")
async def get_user_profile(user_id: str):
    """
    Get user profile with their interested venues and action items.
    
    Args:
        user_id: The ID of the user to retrieve
        
    Returns:
        JSON object with user details, interested venues, and pending action items
        
    Raises:
        HTTPException: 404 if user not found
    """
    logger.info(f"Fetching user profile for user_id: {user_id}")
    
    async with get_db() as session:
        user = await session.get(UserDB, user_id)
        
        if not user:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
        
        # Get user interests (categories)
        result = await session.execute(
            select(UserInterestDB.interest_category)
            .where(UserInterestDB.user_id == user_id)
        )
        user_interests = [row[0] for row in result.all()]
        
        # Get interested venues
        interested_venues = await get_user_interested_venues(session, user_id)
        
        # Get action items where user is interested and status is pending
        result = await session.execute(
            select(ActionItemDB)
            .options(selectinload(ActionItemDB.venue))
            .where(ActionItemDB.status == "pending")
        )
        all_action_items = result.scalars().all()
        
        user_action_items = []
        for item in all_action_items:
            if user_id in item.interested_user_ids:
                venue = item.venue
                user_action_items.append({
                    "id": item.id,
                    "venue_id": item.venue_id,
                    "interested_user_ids": item.interested_user_ids,
                    "action_type": item.action_type,
                    "action_code": item.action_code,
                    "description": item.description,
                    "threshold_met": item.threshold_met,
                    "status": item.status,
                    "created_at": item.created_at.isoformat(),
                    "venue": {
                        "id": venue.id,
                        "name": venue.name,
                        "category": venue.category,
                        "description": venue.description,
                        "image": venue.image,
                        "address": venue.address
                    }
                })
        
        return {
            "user": {
                "id": user.id,
                "name": user.name,
                "avatar": user.avatar,
                "bio": user.bio,
                "interests": user_interests
            },
            "interested_venues": interested_venues,
            "action_items": user_action_items
        }


@app.get("/recommendations")
async def get_recommendations(user_id: str):
    """
    Get personalized venue recommendations for a user.
    
    CRITICAL BEHAVIOR:
    - Scores are calculated based on OTHER users' interests only (not including current user)
    - This ensures venue positions DON'T change when user toggles their own interest
    - Venues are sorted by score only, NOT by already_interested flag
    - This keeps venues in consistent positions regardless of user's interest state
    
    Recommendations are scored based on (out of 10 points):
    - Popularity (30% weight) - based on OTHER users interested
    - Category match with user interests (25% weight)
    - Friend interest (25% weight)
    - Proximity to user location (20% weight)
    
    Includes venues user is already interested in with already_interested flag.
    
    Args:
        user_id: The ID of the user to get recommendations for (REQUIRED)
        
    Returns:
        JSON object with sorted list of recommendations including distance_km
        
    Raises:
        HTTPException: 404 if user not found
    """
    logger.info(f"Fetching recommendations for user_id: {user_id}")
    
    async with get_db() as session:
        user = await session.get(UserDB, user_id)
        
        if not user:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
        
        # Get venues user is already interested in
        result = await session.execute(
            select(InterestDB.venue_id)
            .where(InterestDB.user_id == user_id)
        )
        user_interested_venue_ids = {row[0] for row in result.all()}
        
        # Get all venues
        result = await session.execute(select(VenueDB))
        venues = result.scalars().all()
        
        # Calculate scores for ALL venues
        recommendations = []
        for venue in venues:
            score, reason, friends_interested, total_interested, distance_km, score_breakdown = await calculate_recommendation_score(
                session, user_id, venue.id
            )
            
            # Check if user is already interested
            already_interested = venue.id in user_interested_venue_ids
            
            recommendations.append({
                "venue": {
                    "id": venue.id,
                    "name": venue.name,
                    "category": venue.category,
                    "description": venue.description,
                    "image": venue.image,
                    "images": venue.images,  # Array for multi-image galleries
                    "address": venue.address,
                    "latitude": venue.latitude,  # For "Get Directions" feature
                    "longitude": venue.longitude,  # For "Get Directions" feature
                    "interested_count": total_interested,
                    "distance_km": distance_km
                },
                "score": round(score, 1),
                "reason": reason,
                "already_interested": already_interested,
                "friends_interested": friends_interested,
                "total_interested": total_interested,
                "score_breakdown": score_breakdown
            })
        
        # Sort by score descending only
        recommendations.sort(key=lambda x: -x["score"])
        
        logger.info(f"Returning {len(recommendations)} recommendations ({len(user_interested_venue_ids)} already interested)")
        return {"recommendations": recommendations}


@app.get("/activities")
async def get_activities(
    user_id: Optional[str] = None,
    page: int = 1,
    limit: int = 20
):
    """
    Get activity feed showing friend activities (interests, bookings, check-ins).
    
    Returns activities from the user's friends in chronological order.
    
    Args:
        user_id: Optional user ID to filter friend activities
        page: Page number for pagination (default: 1)
        limit: Number of activities per page (default: 20, max: 100)
        
    Returns:
        JSON object with activities array and pagination metadata
    """
    logger.info(f"Fetching activities for user_id={user_id}, page={page}, limit={limit}")
    
    # Validate pagination parameters
    if page < 1:
        page = 1
    if limit < 1 or limit > 100:
        limit = 20
    
    async with get_db() as session:
        # Get friend IDs if user_id provided
        friend_ids = set()
        if user_id:
            # Get bidirectional friendships
            result = await session.execute(
                select(FriendshipDB)
                .where(
                    or_(
                        FriendshipDB.user_id == user_id,
                        FriendshipDB.friend_id == user_id
                    )
                )
            )
            friendships = result.scalars().all()
            
            for friendship in friendships:
                if friendship.user_id == user_id:
                    friend_ids.add(friendship.friend_id)
                else:
                    friend_ids.add(friendship.user_id)
        
        # Build query for activities
        query = select(ActivityDB).options(
            selectinload(ActivityDB.user),
            selectinload(ActivityDB.venue)
        )
        
        # Filter by friend IDs if provided
        if user_id and friend_ids:
            query = query.where(ActivityDB.user_id.in_(friend_ids))
        elif user_id:
            # User has no friends, return empty list
            return {
                "activities": [],
                "page": page,
                "limit": limit,
                "total_count": 0
            }
        
        # Order by most recent first
        query = query.order_by(ActivityDB.created_at.desc())
        
        # Get total count
        count_result = await session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total_count = count_result.scalar() or 0
        
        # Apply pagination
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)
        
        # Execute query
        result = await session.execute(query)
        activities_db = result.scalars().all()
        
        # Build response
        activities = []
        for activity in activities_db:
            activities.append({
                "id": activity.id,
                "user": {
                    "id": activity.user.id,
                    "name": activity.user.name,
                    "avatar": activity.user.avatar
                },
                "venue": {
                    "id": activity.venue.id,
                    "name": activity.venue.name,
                    "category": activity.venue.category,
                    "image": activity.venue.image
                },
                "action": activity.action,
                "timestamp": activity.created_at.isoformat()
            })
        
        logger.info(f"Returning {len(activities)} activities (total: {total_count})")
        
        return {
            "activities": activities,
            "page": page,
            "limit": limit,
            "total_count": total_count
        }


@app.get("/social/feed")
async def get_social_feed(
    user_id: str,
    page: int = 1,
    limit: int = 20,
    since: Optional[str] = None
):
    """
    Get comprehensive social feed with friend interest activities and highlighted venues.
    
    Returns friend activities in InterestActivity format plus venues where 5+ friends are interested.
    Supports incremental updates via 'since' timestamp for real-time polling.
    
    Args:
        user_id: User ID to get social feed for (REQUIRED)
        page: Page number for pagination (default: 1)
        limit: Number of activities per page (default: 20, max: 100)
        since: ISO timestamp for incremental updates (optional)
        
    Returns:
        JSON object with:
        - interest_activities: Friend interest actions with full metadata
        - highlighted_venues: Venues with 5+ interested friends
        - has_more: Pagination flag
        - page, limit, total_count: Pagination metadata
        - new_count: Number of activities since 'since' timestamp
    """
    logger.info(f"Fetching social feed for user_id={user_id}, page={page}, limit={limit}, since={since}")
    
    # Validate pagination parameters
    if page < 1:
        page = 1
    if limit < 1 or limit > 100:
        limit = 20
    
    # Parse since timestamp if provided
    since_dt = None
    if since:
        try:
            since_dt = datetime.fromisoformat(since.replace('Z', '+00:00'))
        except ValueError:
            logger.warning(f"Invalid since timestamp: {since}")
    
    async with get_db() as session:
        # Get friend IDs
        result = await session.execute(
            select(FriendshipDB)
            .where(
                or_(
                    FriendshipDB.user_id == user_id,
                    FriendshipDB.friend_id == user_id
                )
            )
        )
        friendships = result.scalars().all()
        
        friend_ids = set()
        for friendship in friendships:
            if friendship.user_id == user_id:
                friend_ids.add(friendship.friend_id)
            else:
                friend_ids.add(friendship.user_id)
        
        if not friend_ids:
            # User has no friends
            return {
                "interest_activities": [],
                "highlighted_venues": [],
                "has_more": False,
                "page": page,
                "limit": limit,
                "total_count": 0,
                "new_count": 0
            }
        
        # Build query for friend activities (interested actions only)
        query = select(ActivityDB).options(
            selectinload(ActivityDB.user),
            selectinload(ActivityDB.venue)
        ).where(
            and_(
                ActivityDB.user_id.in_(friend_ids),
                ActivityDB.action == "interested"
            )
        )
        
        # Filter by since timestamp if provided
        if since_dt:
            query = query.where(ActivityDB.created_at > since_dt)
        
        # Order by most recent first
        query = query.order_by(ActivityDB.created_at.desc())
        
        # Get total count
        count_result = await session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total_count = count_result.scalar() or 0
        
        # Count new activities since 'since' for real-time updates
        new_count = 0
        if since_dt:
            new_count = total_count
        
        # Apply pagination
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)
        
        # Execute query
        result = await session.execute(query)
        activities_db = result.scalars().all()
        
        # Build interest activities in InterestActivity format
        interest_activities = []
        for activity in activities_db:
            interest_activities.append({
                "id": activity.id,
                "user": {
                    "id": activity.user.id,
                    "name": activity.user.name,
                    "avatar": activity.user.avatar
                },
                "venue": {
                    "id": activity.venue.id,
                    "name": activity.venue.name,
                    "category": activity.venue.category,
                    "image": activity.venue.image
                },
                "action": activity.action,
                "timestamp": activity.created_at.isoformat(),
                "is_active": True
            })
        
        # Calculate highlighted venues (5+ friends interested)
        highlighted_venues = await calculate_highlighted_venues(session, user_id, friend_ids)
        
        has_more = (offset + len(activities_db)) < total_count
        
        logger.info(f"Returning {len(interest_activities)} activities, {len(highlighted_venues)} highlighted venues (new: {new_count})")
        
        return {
            "interest_activities": interest_activities,
            "highlighted_venues": highlighted_venues,
            "has_more": has_more,
            "page": page,
            "limit": limit,
            "total_count": total_count,
            "new_count": new_count
        }


async def calculate_highlighted_venues(
    session: AsyncSession,
    user_id: str,
    friend_ids: set,
    threshold: int = 5
) -> list:
    """
    Calculate highlighted venues where 5+ friends are interested.
    
    Args:
        session: Database session
        user_id: Current user ID
        friend_ids: Set of friend IDs
        threshold: Minimum friend count (default: 5)
        
    Returns:
        List of highlighted venue dictionaries
    """
    # Get all interests from friends
    result = await session.execute(
        select(InterestDB)
        .options(selectinload(InterestDB.venue))
        .where(InterestDB.user_id.in_(friend_ids))
    )
    friend_interests = result.scalars().all()
    
    # Group by venue
    venue_friends = {}
    for interest in friend_interests:
        venue_id = interest.venue_id
        if venue_id not in venue_friends:
            venue_friends[venue_id] = {
                "venue": interest.venue,
                "friends": [],
                "timestamps": []
            }
        
        # Get user info
        user_result = await session.execute(
            select(UserDB).where(UserDB.id == interest.user_id)
        )
        user = user_result.scalar_one_or_none()
        
        if user:
            venue_friends[venue_id]["friends"].append({
                "id": user.id,
                "name": user.name,
                "avatar_url": user.avatar,
                "interested_timestamp": interest.created_at.isoformat()
            })
            venue_friends[venue_id]["timestamps"].append(interest.created_at)
    
    # Filter venues with threshold+ friends
    highlighted_venues = []
    for venue_id, data in venue_friends.items():
        friend_count = len(data["friends"])
        if friend_count >= threshold:
            venue = data["venue"]
            last_activity = max(data["timestamps"])
            
            # Also check total interested count (all users, not just friends)
            total_result = await session.execute(
                select(func.count())
                .select_from(InterestDB)
                .where(InterestDB.venue_id == venue_id)
            )
            total_interested = total_result.scalar() or 0
            
            highlighted_venues.append({
                "id": f"highlight_{venue_id}",
                "venue_id": venue_id,
                "venue_name": venue.name,
                "venue_image_url": venue.image,
                "venue_category": venue.category,
                "venue_address": venue.address,
                "interested_friends": data["friends"][:10],  # Limit to 10 for display
                "total_interested_count": total_interested,
                "threshold": threshold,
                "last_activity_timestamp": last_activity.isoformat()
            })
    
    # Sort by last activity (most recent first)
    highlighted_venues.sort(key=lambda x: x["last_activity_timestamp"], reverse=True)
    
    return highlighted_venues


@app.post("/action-items/{item_id}/complete")
async def complete_action_item(item_id: str, request: CompleteActionItemRequest) -> SuccessResponse:
    """
    Mark an action item as completed.
    
    Args:
        item_id: The ID of the action item to complete
        request: CompleteActionItemRequest containing user_id
        
    Returns:
        SuccessResponse indicating result
        
    Raises:
        HTTPException: 404 if action item not found
        HTTPException: 403 if user not in interested users
    """
    logger.info(f"Completing action item: {item_id} by user={request.user_id}")
    
    async with get_db() as session:
        action_item = await session.get(ActionItemDB, item_id)
        
        if not action_item:
            logger.warning(f"Action item not found: {item_id}")
            raise HTTPException(status_code=404, detail=f"Action item with id '{item_id}' not found")
        
        # Verify user is part of this action item
        if request.user_id not in action_item.interested_user_ids:
            logger.warning(f"User {request.user_id} not authorized for action item {item_id}")
            raise HTTPException(status_code=403, detail="User not authorized for this action item")
        
        # Update status
        action_item.status = "completed"
        await session.commit()
        
        logger.info(f"Action item {item_id} marked as completed")
        
        return SuccessResponse(
            success=True,
            message="Action item marked as completed"
        )


@app.delete("/action-items/{item_id}")
async def dismiss_action_item(item_id: str, user_id: str) -> SuccessResponse:
    """
    Dismiss/delete an action item.
    
    Args:
        item_id: The ID of the action item to dismiss
        user_id: The user dismissing the action item (query parameter)
        
    Returns:
        SuccessResponse indicating result
        
    Raises:
        HTTPException: 404 if action item not found
        HTTPException: 403 if user not in interested users
    """
    logger.info(f"Dismissing action item: {item_id} by user={user_id}")
    
    async with get_db() as session:
        action_item = await session.get(ActionItemDB, item_id)
        
        if not action_item:
            logger.warning(f"Action item not found: {item_id}")
            raise HTTPException(status_code=404, detail=f"Action item with id '{item_id}' not found")
        
        # Verify user is part of this action item
        if user_id not in action_item.interested_user_ids:
            logger.warning(f"User {user_id} not authorized for action item {item_id}")
            raise HTTPException(status_code=403, detail="User not authorized for this action item")
        
        # Update status to dismissed
        action_item.status = "dismissed"
        await session.commit()
        
        logger.info(f"Action item {item_id} dismissed")
        
        return SuccessResponse(
            success=True,
            message="Action item dismissed"
        )


# ============================================================
# NEW ACTION ITEM ENDPOINTS
# ============================================================

class InitiateRequest(BaseModel):
    """Request model for initiating Go Ahead flow."""
    user_id: str


class ConfirmDeclineRequest(BaseModel):
    """Request model for confirming or declining action item."""
    user_id: str


class CreateChatRequest(BaseModel):
    """Request model for creating a group chat."""
    action_item_id: Optional[str] = None
    venue_id: str
    created_by: str
    participant_user_ids: List[str]


class SendMessageRequest(BaseModel):
    """Request model for sending a chat message."""
    sender_id: str
    content: str


@app.post("/action-items/{item_id}/initiate")
async def initiate_action_item(item_id: str, request: InitiateRequest):
    """
    Initiate the "Go Ahead" flow for an action item.
    
    Creates confirmation records for all interested users except the initiator.
    
    Args:
        item_id: The ID of the action item
        request: InitiateRequest containing initiator user_id
        
    Returns:
        JSON object with confirmation statuses for all users
    """
    logger.info(f"Initiating Go Ahead flow for action item: {item_id} by user: {request.user_id}")
    
    async with get_db() as session:
        action_item = await session.get(ActionItemDB, item_id)
        
        if not action_item:
            raise HTTPException(status_code=404, detail=f"Action item '{item_id}' not found")
        
        if action_item.status != "active":
            raise HTTPException(status_code=400, detail=f"Action item is not active (status: {action_item.status})")
        
        if request.user_id not in action_item.interested_user_ids:
            raise HTTPException(status_code=403, detail="User not authorized for this action item")
        
        # Check if confirmations already exist
        result = await session.execute(
            select(ActionItemConfirmationDB)
            .where(ActionItemConfirmationDB.action_item_id == item_id)
        )
        existing_confirmations = result.scalars().all()
        
        if existing_confirmations:
            # Return existing confirmations
            confirmations = []
            for conf in existing_confirmations:
                user = await session.get(UserDB, conf.user_id)
                confirmations.append({
                    "user_id": conf.user_id,
                    "name": user.name if user else "Unknown",
                    "avatar": user.avatar if user else "",
                    "status": conf.status,
                    "responded_at": conf.responded_at.isoformat() if conf.responded_at else None
                })
            
            # Add initiator as auto-confirmed
            initiator = await session.get(UserDB, request.user_id)
            return {
                "action_item_id": item_id,
                "initiator": {
                    "user_id": request.user_id,
                    "name": initiator.name if initiator else "Unknown",
                    "avatar": initiator.avatar if initiator else "",
                    "status": "confirmed"
                },
                "confirmations": confirmations
            }
        
        # Create confirmation records for all users except initiator
        confirmations = []
        for user_id in action_item.interested_user_ids:
            if user_id == request.user_id:
                continue  # Skip initiator
            
            confirmation = ActionItemConfirmationDB(
                id=str(uuid.uuid4()),
                action_item_id=item_id,
                user_id=user_id,
                initiator_id=request.user_id,
                status="pending",
                created_at=datetime.now()
            )
            session.add(confirmation)
            
            user = await session.get(UserDB, user_id)
            confirmations.append({
                "user_id": user_id,
                "name": user.name if user else "Unknown",
                "avatar": user.avatar if user else "",
                "status": "pending",
                "responded_at": None
            })
        
        await session.commit()
        
        initiator = await session.get(UserDB, request.user_id)
        
        logger.info(f"Created {len(confirmations)} confirmation requests for action item {item_id}")
        
        return {
            "action_item_id": item_id,
            "initiator": {
                "user_id": request.user_id,
                "name": initiator.name if initiator else "Unknown",
                "avatar": initiator.avatar if initiator else "",
                "status": "confirmed"
            },
            "confirmations": confirmations
        }


@app.get("/action-items/{item_id}/status")
async def get_action_item_status(item_id: str):
    """
    Get confirmation statuses for all users in an action item.
    
    Args:
        item_id: The ID of the action item
        
    Returns:
        JSON object with list of confirmation statuses
    """
    logger.info(f"Getting status for action item: {item_id}")
    
    async with get_db() as session:
        action_item = await session.get(ActionItemDB, item_id)
        
        if not action_item:
            raise HTTPException(status_code=404, detail=f"Action item '{item_id}' not found")
        
        # Get venue info
        venue = await session.get(VenueDB, action_item.venue_id)
        
        # Get confirmations
        result = await session.execute(
            select(ActionItemConfirmationDB)
            .where(ActionItemConfirmationDB.action_item_id == item_id)
        )
        confirmations = result.scalars().all()
        
        # Get initiator if confirmations exist
        initiator_id = confirmations[0].initiator_id if confirmations else None
        
        statuses = []
        for conf in confirmations:
            user = await session.get(UserDB, conf.user_id)
            statuses.append({
                "user_id": conf.user_id,
                "name": user.name if user else "Unknown",
                "avatar": user.avatar if user else "",
                "status": conf.status,
                "responded_at": conf.responded_at.isoformat() if conf.responded_at else None
            })
        
        # Add initiator as confirmed
        if initiator_id:
            initiator = await session.get(UserDB, initiator_id)
            initiator_status = {
                "user_id": initiator_id,
                "name": initiator.name if initiator else "Unknown",
                "avatar": initiator.avatar if initiator else "",
                "status": "confirmed",
                "responded_at": None,
                "is_initiator": True
            }
        else:
            initiator_status = None
        
        # Check if chat was created
        result = await session.execute(
            select(ChatDB)
            .where(ChatDB.action_item_id == item_id)
        )
        chat = result.scalar_one_or_none()
        
        return {
            "action_item_id": item_id,
            "venue": {
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "image": venue.image
            } if venue else None,
            "status": action_item.status,
            "initiator": initiator_status,
            "confirmations": statuses,
            "chat_created": chat is not None,
            "chat_id": chat.id if chat else None
        }


@app.post("/action-items/{item_id}/confirm")
async def confirm_action_item(item_id: str, request: ConfirmDeclineRequest):
    """
    User confirms their interest in the action item.
    
    If 2+ users are confirmed (including initiator), auto-creates a group chat.
    
    Args:
        item_id: The ID of the action item
        request: ConfirmDeclineRequest containing user_id
        
    Returns:
        JSON object with updated status and chat info if created
    """
    logger.info(f"User {request.user_id} confirming action item: {item_id}")
    
    async with get_db() as session:
        # Find the confirmation record
        result = await session.execute(
            select(ActionItemConfirmationDB)
            .where(
                and_(
                    ActionItemConfirmationDB.action_item_id == item_id,
                    ActionItemConfirmationDB.user_id == request.user_id
                )
            )
        )
        confirmation = result.scalar_one_or_none()
        
        if not confirmation:
            raise HTTPException(status_code=404, detail="Confirmation not found for this user")
        
        if confirmation.status != "pending":
            raise HTTPException(status_code=400, detail=f"Already responded with status: {confirmation.status}")
        
        # Update confirmation
        confirmation.status = "confirmed"
        confirmation.responded_at = datetime.now()
        
        # Check total confirmed count (including initiator)
        result = await session.execute(
            select(func.count())
            .select_from(ActionItemConfirmationDB)
            .where(
                and_(
                    ActionItemConfirmationDB.action_item_id == item_id,
                    ActionItemConfirmationDB.status == "confirmed"
                )
            )
        )
        confirmed_count = result.scalar() or 0
        confirmed_count += 1  # Add this confirmation
        confirmed_count += 1  # Add initiator (always confirmed)
        
        chat_created = False
        chat_id = None
        
        # Auto-create chat if 2+ confirmed
        if confirmed_count >= 2:
            # Check if chat already exists
            result = await session.execute(
                select(ChatDB)
                .where(ChatDB.action_item_id == item_id)
            )
            existing_chat = result.scalar_one_or_none()
            
            if not existing_chat:
                action_item = await session.get(ActionItemDB, item_id)
                
                if action_item:
                    # Create chat
                    chat_id = str(uuid.uuid4())
                    chat = ChatDB(
                        id=chat_id,
                        action_item_id=item_id,
                        venue_id=action_item.venue_id,
                        created_by=confirmation.initiator_id,
                        created_at=datetime.now()
                    )
                    session.add(chat)
                    
                    # Add initiator as participant
                    session.add(ChatParticipantDB(
                        chat_id=chat_id,
                        user_id=confirmation.initiator_id,
                        joined_at=datetime.now()
                    ))
                    
                    # Add all confirmed users as participants
                    result = await session.execute(
                        select(ActionItemConfirmationDB)
                        .where(
                            and_(
                                ActionItemConfirmationDB.action_item_id == item_id,
                                ActionItemConfirmationDB.status == "confirmed"
                            )
                        )
                    )
                    confirmed_users = result.scalars().all()
                    
                    for conf in confirmed_users:
                        if conf.user_id != confirmation.initiator_id:
                            session.add(ChatParticipantDB(
                                chat_id=chat_id,
                                user_id=conf.user_id,
                                joined_at=datetime.now()
                            ))
                    
                    # Add current user
                    session.add(ChatParticipantDB(
                        chat_id=chat_id,
                        user_id=request.user_id,
                        joined_at=datetime.now()
                    ))
                    
                    chat_created = True
                    logger.info(f"Auto-created chat {chat_id} for action item {item_id}")
            else:
                # Add user to existing chat
                session.add(ChatParticipantDB(
                    chat_id=existing_chat.id,
                    user_id=request.user_id,
                    joined_at=datetime.now()
                ))
                chat_id = existing_chat.id
        
        await session.commit()
        
        return {
            "success": True,
            "message": "Confirmation recorded",
            "status": "confirmed",
            "confirmed_count": confirmed_count,
            "chat_created": chat_created,
            "chat_id": chat_id
        }


@app.post("/action-items/{item_id}/decline")
async def decline_action_item(item_id: str, request: ConfirmDeclineRequest):
    """
    User declines their interest in the action item.
    
    Args:
        item_id: The ID of the action item
        request: ConfirmDeclineRequest containing user_id
        
    Returns:
        JSON object with updated status
    """
    logger.info(f"User {request.user_id} declining action item: {item_id}")
    
    async with get_db() as session:
        result = await session.execute(
            select(ActionItemConfirmationDB)
            .where(
                and_(
                    ActionItemConfirmationDB.action_item_id == item_id,
                    ActionItemConfirmationDB.user_id == request.user_id
                )
            )
        )
        confirmation = result.scalar_one_or_none()
        
        if not confirmation:
            raise HTTPException(status_code=404, detail="Confirmation not found for this user")
        
        if confirmation.status != "pending":
            raise HTTPException(status_code=400, detail=f"Already responded with status: {confirmation.status}")
        
        confirmation.status = "declined"
        confirmation.responded_at = datetime.now()
        
        await session.commit()
        
        return {
            "success": True,
            "message": "Interest declined",
            "status": "declined"
        }


@app.put("/action-items/{item_id}/dismiss")
async def dismiss_action_item_put(item_id: str, request: ConfirmDeclineRequest):
    """
    Dismiss an action item for the calling user.
    
    Sets status to 'dismissed' and archived_at to now.
    
    Args:
        item_id: The ID of the action item
        request: Request containing user_id
        
    Returns:
        SuccessResponse indicating result
    """
    logger.info(f"Dismissing action item: {item_id} by user={request.user_id}")
    
    async with get_db() as session:
        action_item = await session.get(ActionItemDB, item_id)
        
        if not action_item:
            raise HTTPException(status_code=404, detail=f"Action item '{item_id}' not found")
        
        if request.user_id not in action_item.interested_user_ids:
            raise HTTPException(status_code=403, detail="User not authorized for this action item")
        
        action_item.status = "dismissed"
        action_item.archived_at = datetime.now()
        
        await session.commit()
        
        return SuccessResponse(
            success=True,
            message="Action item dismissed"
        )


@app.get("/users/{user_id}/action-items")
async def get_user_action_items(user_id: str):
    """
    Get active action items for a user.
    
    Returns action items where status='active' and user is in interested_user_ids.
    Includes venue details, distance calculation, and friend data.
    
    Args:
        user_id: The ID of the user
        
    Returns:
        JSON object with list of active action items
    """
    logger.info(f"Fetching active action items for user: {user_id}")
    
    async with get_db() as session:
        user = await session.get(UserDB, user_id)
        
        if not user:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        
        # Get active action items
        result = await session.execute(
            select(ActionItemDB)
            .options(selectinload(ActionItemDB.venue))
            .where(ActionItemDB.status == "active")
        )
        all_action_items = result.scalars().all()
        
        # Filter to items where user is interested
        action_items = []
        for item in all_action_items:
            if user_id not in item.interested_user_ids:
                continue
            
            venue = item.venue
            
            # Calculate distance
            distance_km = None
            if venue:
                distance_km = haversine_distance(
                    user.latitude, user.longitude,
                    venue.latitude, venue.longitude
                )
            
            # Get interested users info
            interested_users = []
            for uid in item.interested_user_ids:
                u = await session.get(UserDB, uid)
                if u:
                    interested_users.append({
                        "id": u.id,
                        "name": u.name,
                        "avatar": u.avatar
                    })
            
            # Check if Go Ahead flow was initiated
            result = await session.execute(
                select(ActionItemConfirmationDB)
                .where(ActionItemConfirmationDB.action_item_id == item.id)
            )
            confirmations = result.scalars().all()
            go_ahead_initiated = len(confirmations) > 0
            
            action_items.append({
                "id": item.id,
                "venue_id": item.venue_id,
                "action_type": item.action_type,
                "action_code": item.action_code,
                "description": item.description,
                "status": item.status,
                "created_at": item.created_at.isoformat() if item.created_at else None,
                "expires_at": item.expires_at.isoformat() if item.expires_at else None,
                "venue": {
                    "id": venue.id,
                    "name": venue.name,
                    "category": venue.category,
                    "image": venue.image,
                    "address": venue.address,
                    "distance_km": distance_km
                } if venue else None,
                "interested_users": interested_users,
                "interested_count": len(item.interested_user_ids),
                "go_ahead_initiated": go_ahead_initiated
            })
        
        return {
            "action_items": action_items,
            "count": len(action_items)
        }


@app.get("/users/{user_id}/action-items/archive")
async def get_user_archived_action_items(user_id: str):
    """
    Get archived action items for a user (dismissed, expired, completed).
    
    Args:
        user_id: The ID of the user
        
    Returns:
        JSON object with list of archived action items with status badges
    """
    logger.info(f"Fetching archived action items for user: {user_id}")
    
    async with get_db() as session:
        user = await session.get(UserDB, user_id)
        
        if not user:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        
        # Get non-active action items
        result = await session.execute(
            select(ActionItemDB)
            .options(selectinload(ActionItemDB.venue))
            .where(ActionItemDB.status.in_(["dismissed", "expired", "completed"]))
        )
        all_action_items = result.scalars().all()
        
        action_items = []
        for item in all_action_items:
            if user_id not in item.interested_user_ids:
                continue
            
            venue = item.venue
            
            action_items.append({
                "id": item.id,
                "venue_id": item.venue_id,
                "action_code": item.action_code,
                "description": item.description,
                "status": item.status,
                "status_badge": item.status.upper(),
                "created_at": item.created_at.isoformat() if item.created_at else None,
                "archived_at": item.archived_at.isoformat() if item.archived_at else None,
                "venue": {
                    "id": venue.id,
                    "name": venue.name,
                    "category": venue.category,
                    "image": venue.image
                } if venue else None
            })
        
        return {
            "archived_items": action_items,
            "count": len(action_items)
        }


@app.get("/action-items/expire")
async def expire_action_items():
    """
    Check and expire action items older than 90 days.
    
    Can be called on app launch or as a scheduled task.
    
    Returns:
        JSON object with count of expired items
    """
    logger.info("Running action item expiration check")
    
    async with get_db() as session:
        now = datetime.now()
        
        result = await session.execute(
            select(ActionItemDB)
            .where(
                and_(
                    ActionItemDB.status == "active",
                    ActionItemDB.expires_at <= now
                )
            )
        )
        expired_items = result.scalars().all()
        
        expired_count = 0
        for item in expired_items:
            item.status = "expired"
            item.archived_at = now
            expired_count += 1
        
        if expired_count > 0:
            await session.commit()
        
        logger.info(f"Expired {expired_count} action items")
        
        return {
            "success": True,
            "expired_count": expired_count,
            "checked_at": now.isoformat()
        }


# ============================================================
# CHAT ENDPOINTS
# ============================================================

@app.post("/chats")
async def create_chat(request: CreateChatRequest):
    """
    Create a group chat.
    
    Args:
        request: CreateChatRequest with venue_id, created_by, participant_user_ids
        
    Returns:
        JSON object with created chat info
    """
    logger.info(f"Creating chat for venue: {request.venue_id} by user: {request.created_by}")
    
    async with get_db() as session:
        # Validate venue
        venue = await session.get(VenueDB, request.venue_id)
        if not venue:
            raise HTTPException(status_code=404, detail=f"Venue '{request.venue_id}' not found")
        
        # Validate creator
        creator = await session.get(UserDB, request.created_by)
        if not creator:
            raise HTTPException(status_code=404, detail=f"User '{request.created_by}' not found")
        
        # Create chat
        chat_id = str(uuid.uuid4())
        chat = ChatDB(
            id=chat_id,
            action_item_id=request.action_item_id,
            venue_id=request.venue_id,
            created_by=request.created_by,
            created_at=datetime.now()
        )
        session.add(chat)
        
        # Add participants
        for user_id in request.participant_user_ids:
            session.add(ChatParticipantDB(
                chat_id=chat_id,
                user_id=user_id,
                joined_at=datetime.now()
            ))
        
        await session.commit()
        
        return {
            "success": True,
            "chat": {
                "id": chat_id,
                "venue_id": request.venue_id,
                "venue_name": venue.name,
                "created_by": request.created_by,
                "participant_count": len(request.participant_user_ids),
                "created_at": chat.created_at.isoformat()
            }
        }


@app.get("/chats/{chat_id}/messages")
async def get_chat_messages(chat_id: str, page: int = 1, limit: int = 50):
    """
    Get messages from a chat.
    
    Args:
        chat_id: The ID of the chat
        page: Page number (default 1)
        limit: Messages per page (default 50)
        
    Returns:
        JSON object with messages and sender info
    """
    logger.info(f"Fetching messages for chat: {chat_id}")
    
    async with get_db() as session:
        chat = await session.get(ChatDB, chat_id)
        if not chat:
            raise HTTPException(status_code=404, detail=f"Chat '{chat_id}' not found")
        
        # Get messages with pagination
        offset = (page - 1) * limit
        result = await session.execute(
            select(ChatMessageDB)
            .where(ChatMessageDB.chat_id == chat_id)
            .order_by(ChatMessageDB.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        messages_db = result.scalars().all()
        
        messages = []
        for msg in messages_db:
            sender = await session.get(UserDB, msg.sender_id)
            messages.append({
                "id": msg.id,
                "sender": {
                    "id": sender.id,
                    "name": sender.name,
                    "avatar": sender.avatar
                } if sender else None,
                "content": msg.content,
                "created_at": msg.created_at.isoformat()
            })
        
        # Get total count
        count_result = await session.execute(
            select(func.count())
            .select_from(ChatMessageDB)
            .where(ChatMessageDB.chat_id == chat_id)
        )
        total_count = count_result.scalar() or 0
        
        return {
            "chat_id": chat_id,
            "messages": messages,
            "page": page,
            "limit": limit,
            "total_count": total_count,
            "has_more": offset + len(messages) < total_count
        }


@app.post("/chats/{chat_id}/messages")
async def send_chat_message(chat_id: str, request: SendMessageRequest):
    """
    Send a message in a chat.
    
    Validates that sender is a participant.
    
    Args:
        chat_id: The ID of the chat
        request: SendMessageRequest with sender_id and content
        
    Returns:
        JSON object with created message
    """
    logger.info(f"User {request.sender_id} sending message to chat: {chat_id}")
    
    async with get_db() as session:
        chat = await session.get(ChatDB, chat_id)
        if not chat:
            raise HTTPException(status_code=404, detail=f"Chat '{chat_id}' not found")
        
        # Validate sender is participant
        result = await session.execute(
            select(ChatParticipantDB)
            .where(
                and_(
                    ChatParticipantDB.chat_id == chat_id,
                    ChatParticipantDB.user_id == request.sender_id
                )
            )
        )
        participant = result.scalar_one_or_none()
        
        if not participant:
            raise HTTPException(status_code=403, detail="User is not a participant in this chat")
        
        # Create message
        message_id = str(uuid.uuid4())
        message = ChatMessageDB(
            id=message_id,
            chat_id=chat_id,
            sender_id=request.sender_id,
            content=request.content,
            created_at=datetime.now()
        )
        session.add(message)
        
        await session.commit()
        
        sender = await session.get(UserDB, request.sender_id)
        
        return {
            "success": True,
            "message": {
                "id": message_id,
                "chat_id": chat_id,
                "sender": {
                    "id": sender.id,
                    "name": sender.name,
                    "avatar": sender.avatar
                } if sender else None,
                "content": request.content,
                "created_at": message.created_at.isoformat()
            }
        }


@app.get("/users/{user_id}/chats")
async def get_user_chats(user_id: str):
    """
    Get all chats for a user.
    
    Includes venue info, participant avatars, and last message.
    
    Args:
        user_id: The ID of the user
        
    Returns:
        JSON object with list of chats
    """
    logger.info(f"Fetching chats for user: {user_id}")
    
    async with get_db() as session:
        user = await session.get(UserDB, user_id)
        if not user:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        
        # Get chat IDs where user is participant
        result = await session.execute(
            select(ChatParticipantDB.chat_id)
            .where(ChatParticipantDB.user_id == user_id)
        )
        chat_ids = [row[0] for row in result.all()]
        
        if not chat_ids:
            return {"chats": [], "count": 0}
        
        # Get chats
        result = await session.execute(
            select(ChatDB)
            .where(ChatDB.id.in_(chat_ids))
            .order_by(ChatDB.created_at.desc())
        )
        chats_db = result.scalars().all()
        
        chats = []
        for chat in chats_db:
            venue = await session.get(VenueDB, chat.venue_id)
            
            # Get participants
            result = await session.execute(
                select(ChatParticipantDB)
                .where(ChatParticipantDB.chat_id == chat.id)
            )
            participants = result.scalars().all()
            
            participant_avatars = []
            for p in participants[:5]:  # Limit to 5 avatars
                u = await session.get(UserDB, p.user_id)
                if u:
                    participant_avatars.append(u.avatar)
            
            # Get last message
            result = await session.execute(
                select(ChatMessageDB)
                .where(ChatMessageDB.chat_id == chat.id)
                .order_by(ChatMessageDB.created_at.desc())
                .limit(1)
            )
            last_message = result.scalar_one_or_none()
            
            last_message_info = None
            if last_message:
                sender = await session.get(UserDB, last_message.sender_id)
                last_message_info = {
                    "sender_name": sender.name if sender else "Unknown",
                    "content": last_message.content[:50] + "..." if len(last_message.content) > 50 else last_message.content,
                    "created_at": last_message.created_at.isoformat()
                }
            
            chats.append({
                "id": chat.id,
                "venue": {
                    "id": venue.id,
                    "name": venue.name,
                    "category": venue.category,
                    "image": venue.image
                } if venue else None,
                "participant_count": len(participants),
                "participant_avatars": participant_avatars,
                "last_message": last_message_info,
                "created_at": chat.created_at.isoformat()
            })
        
        return {
            "chats": chats,
            "count": len(chats)
        }
