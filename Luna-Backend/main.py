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
from datetime import datetime
from typing import List, Dict, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import selectinload

# Database imports
from database import init_db, close_db, get_db
from models.db_models import UserDB, VenueDB, InterestDB, UserInterestDB, FriendshipDB, ActionItemDB
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
    result = await session.execute(
        select(func.count(InterestDB.user_id))
        .where(InterestDB.venue_id == venue_id)
    )
    return result.scalar() or 0


async def get_interested_users(session, venue_id: str) -> List[Dict]:
    """
    Get list of users interested in a specific venue.
    
    Args:
        session: Database session
        venue_id: The ID of the venue
        
    Returns:
        List of simplified user objects (id, name, avatar only)
    """
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


async def get_user_interested_venues(session, user_id: str) -> List[Dict]:
    """
    Get list of venues a user is interested in.
    
    Args:
        session: Database session
        user_id: The ID of the user
        
    Returns:
        List of full venue objects with interested counts
    """
    result = await session.execute(
        select(VenueDB)
        .join(InterestDB, InterestDB.venue_id == VenueDB.id)
        .where(InterestDB.user_id == user_id)
    )
    venues = result.scalars().all()
    
    venues_list = []
    for venue in venues:
        interested_count = await get_interested_count(session, venue.id)
        venues_list.append({
            "id": venue.id,
            "name": venue.name,
            "category": venue.category,
            "description": venue.description,
            "image": venue.image,
            "address": venue.address,
            "interested_count": interested_count
        })
    
    return venues_list


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


async def calculate_recommendation_score(session, user_id: str, venue_id: str) -> tuple[float, str, int, int, Optional[float]]:
    """
    Calculate recommendation score for a venue based on four factors.
    
    CRITICAL: Score is calculated based on OTHER users' interests only.
    This ensures the score remains stable when the current user toggles their interest.
    
    Scoring algorithm (out of 10 points total):
    - Factor 1: Popularity (30% weight) - min(other_users_interested / 3, 1.0) * 3
    - Factor 2: Category match (25% weight) - 1.0 if match, else 0.0, * 2.5
    - Factor 3: Friend interest (25% weight) - min(friends_interested / 3, 1.0) * 2.5
    - Factor 4: Proximity (20% weight) - distance-based score (1.0 to 0.2) * 2
    
    Args:
        session: Database session
        user_id: The ID of the user
        venue_id: The ID of the venue
        
    Returns:
        Tuple of (score, reason string, friends_interested_count, total_interested_count, distance_km)
    """
    # Get user and venue
    user = await session.get(UserDB, user_id)
    venue = await session.get(VenueDB, venue_id)
    
    if not user or not venue:
        return 0.0, "Invalid user or venue", 0, 0, None
    
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
    
    return score, reason, friends_interested, total_interested_count, distance_km


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
async def get_venues(user_id: Optional[str] = None):
    """
    Get list of all venues with basic information.
    
    If user_id is provided, calculates distance from user to each venue.
    
    Args:
        user_id: Optional user ID to calculate distances
    
    Returns:
        JSON object with venues array containing id, name, category, image, interested_count,
        and optionally distance_km (if user_id provided)
    """
    logger.info(f"Fetching all venues (user_id: {user_id})")
    
    async with get_db() as session:
        # Get user if user_id provided
        user = None
        if user_id:
            user = await session.get(UserDB, user_id)
            if not user:
                logger.warning(f"User not found: {user_id}")
        
        # Get all venues
        result = await session.execute(select(VenueDB))
        venues_db = result.scalars().all()
        
        venues = []
        for venue in venues_db:
            interested_count = await get_interested_count(session, venue.id)
            venue_data = {
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "image": venue.image,
                "interested_count": interested_count
            }
            
            # Calculate distance if user provided
            if user:
                distance_km = haversine_distance(user.latitude, user.longitude, venue.latitude, venue.longitude)
                venue_data["distance_km"] = distance_km
            
            venues.append(venue_data)
        
        logger.info(f"Returning {len(venues)} venues")
        return {"venues": venues}


@app.get("/venues/{venue_id}")
async def get_venue_detail(venue_id: str):
    """
    Get detailed information about a specific venue.
    
    Args:
        venue_id: The ID of the venue to retrieve
        
    Returns:
        JSON object with venue details and list of interested users
        
    Raises:
        HTTPException: 404 if venue not found
    """
    logger.info(f"Fetching venue detail for venue_id: {venue_id}")
    
    async with get_db() as session:
        venue = await session.get(VenueDB, venue_id)
        
        if not venue:
            logger.warning(f"Venue not found: {venue_id}")
            raise HTTPException(status_code=404, detail=f"Venue with id '{venue_id}' not found")
        
        interested_users = await get_interested_users(session, venue_id)
        
        return {
            "venue": {
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "description": venue.description,
                "image": venue.image,
                "address": venue.address
            },
            "interested_users": interested_users
        }


@app.post("/interests")
async def express_interest(request: InterestRequest) -> InterestResponse:
    """
    Express or toggle interest in a venue.
    
    If the user is already interested, removes the interest.
    If not interested, adds the interest.
    
    Handles action item creation when threshold is met (4+ users).
    
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
            # Remove interest (toggle off)
            await session.delete(existing_interest)
            await session.commit()
            
            logger.info(f"Interest removed: user={request.user_id}, venue={request.venue_id}")
            
            return InterestResponse(
                success=True,
                message=f"Interest removed for {venue.name}"
            )
        else:
            # Add interest (toggle on)
            new_interest = InterestDB(
                user_id=request.user_id,
                venue_id=request.venue_id,
                created_at=datetime.now()
            )
            session.add(new_interest)
            
            # IMPORTANT: Flush to database but don't commit yet
            # This makes the interest visible to subsequent queries in this transaction
            await session.flush()
            
            logger.info(f"Interest added: user={request.user_id}, venue={request.venue_id}")
            
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
            
            try:
                # Try to create action item if threshold met
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
                        status="pending",
                        created_at=agent_response["created_at"]
                    )
                    session.add(action_item)
                    
                    # Commit both the interest and action item together
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
                        # Handle potential unique constraint violation on action_code
                        logger.error(f"Failed to commit action item: {str(commit_error)}", exc_info=True)
                        await session.rollback()
                        
                        # Re-add just the interest and commit it
                        new_interest = InterestDB(
                            user_id=request.user_id,
                            venue_id=request.venue_id,
                            created_at=datetime.now()
                        )
                        session.add(new_interest)
                        await session.commit()
                        
                        return InterestResponse(
                            success=True,
                            message="Interest recorded successfully"
                        )
                else:
                    # No action item needed, just commit the interest
                    await session.commit()
                    return InterestResponse(
                        success=True,
                        message="Interest recorded successfully"
                    )
            except Exception as e:
                logger.error(f"Action item agent error: {str(e)}", exc_info=True)
                # Rollback any pending action item changes
                await session.rollback()
                # Still return success since interest was recorded
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
            score, reason, friends_interested, total_interested, distance_km = await calculate_recommendation_score(
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
                    "address": venue.address,
                    "interested_count": total_interested,
                    "distance_km": distance_km
                },
                "score": round(score, 1),
                "reason": reason,
                "already_interested": already_interested,
                "friends_interested": friends_interested,
                "total_interested": total_interested
            })
        
        # Sort by score descending only
        recommendations.sort(key=lambda x: -x["score"])
        
        logger.info(f"Returning {len(recommendations)} recommendations ({len(user_interested_venue_ids)} already interested)")
        return {"recommendations": recommendations}


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


# Note: Bookings endpoints not implemented as bookings_list was not defined in original code
# These would follow the same pattern as action items if needed
