"""  
Luna venue discovery backend API.

This module implements all 5 API endpoints for the venue discovery application:
- GET /venues - List all venues
- GET /venues/{venue_id} - Get venue details with interested users
- POST /interests - Express interest in a venue
- GET /users/{user_id} - Get user profile with interested venues
- GET /recommendations - Get personalized venue recommendations
"""

import logging
from datetime import datetime
from typing import List, Dict, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
import threading

# Import data from data.py
from data import users_dict, venues_dict, interests_list
from agent import action_item_agent
from models import ActionItem

# Global storage for action items and race condition protection
action_items_list: List[Dict] = []
venue_locks: Dict[str, threading.Lock] = {}

def get_venue_lock(venue_id: str) -> threading.Lock:
    """Get or create a lock for a specific venue."""
    if venue_id not in venue_locks:
        venue_locks[venue_id] = threading.Lock()
    return venue_locks[venue_id]

# Configure logging for production
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)
# Initialize FastAPI app
app = FastAPI(
    title="Luna Venue Discovery API",
    description="Backend API for venue discovery and social interest tracking",
    version="1.0.0"
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


# Helper Functions
def get_interested_count(venue_id: str) -> int:
    """
    Calculate the number of users interested in a venue.
    
    Args:
        venue_id: The ID of the venue
        
    Returns:
        Count of users interested in this venue
    """
    return sum(1 for interest in interests_list if interest.venue_id == venue_id)


def get_interested_users(venue_id: str) -> List[Dict]:
    """
    Get list of users interested in a specific venue.
    
    Args:
        venue_id: The ID of the venue
        
    Returns:
        List of simplified user objects (id, name, avatar only)
    """
    interested_user_ids = [
        interest.user_id for interest in interests_list 
        if interest.venue_id == venue_id
    ]
    
    return [
        {
            "id": user_id,
            "name": users_dict[user_id].name,
            "avatar": users_dict[user_id].avatar
        }
        for user_id in interested_user_ids
        if user_id in users_dict
    ]


def get_user_interested_venues(user_id: str) -> List[Dict]:
    """
    Get list of venues a user is interested in.
    
    Args:
        user_id: The ID of the user
        
    Returns:
        List of full venue objects
    """
    interested_venue_ids = [
        interest.venue_id for interest in interests_list 
        if interest.user_id == user_id
    ]
    
    result = []
    for venue_id in interested_venue_ids:
        venue = venues_dict.get(venue_id)
        if venue:
            result.append({
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "description": venue.description,
                "image": venue.image,
                "address": venue.address,
                "interested_count": get_interested_count(venue.id)
            })
    
    return result


def count_friends_interested(user_id: str, venue_id: str) -> int:
    """
    Count how many other users (friends) are interested in a venue.
    
    For this prototype, all other users are considered friends.
    
    Args:
        user_id: The ID of the current user
        venue_id: The ID of the venue
        
    Returns:
        Count of other users interested in this venue
    """
    return sum(
        1 for interest in interests_list 
        if interest.venue_id == venue_id and interest.user_id != user_id
    )


def calculate_recommendation_score(user_id: str, venue_id: str) -> tuple[float, str, int, int]:
    """
    Calculate recommendation score for a venue based on three factors.
    
    CRITICAL: Score is calculated based on OTHER users' interests only.
    This ensures the score remains stable when the current user toggles their interest.
    
    Scoring algorithm:
    - Factor 1: Popularity (0-3 points) = min(other_users_interested / 3, 3)
    - Factor 2: Category match (0-4 points) = 4 if venue category matches user interests
    - Factor 3: Friend interest (0-3 points) = min(friends_interested, 3)
    
    Args:
        user_id: The ID of the user
        venue_id: The ID of the venue
        
    Returns:
        Tuple of (score, reason string, friends_interested_count, total_interested_count)
    """
    if user_id not in users_dict or venue_id not in venues_dict:
        return 0.0, "Invalid user or venue", 0, 0
    
    user = users_dict[user_id]
    venue = venues_dict[venue_id]
    score = 0.0
    reasons = []
    
    # Get total interested count (all users)
    total_interested_count = get_interested_count(venue_id)
    
    # Get count of OTHER users interested (excluding current user)
    # This ensures score doesn't change when user toggles their own interest
    other_users_interested = sum(
        1 for interest in interests_list 
        if interest.venue_id == venue_id and interest.user_id != user_id
    )
    
    # Get friends interested count
    friends_interested = count_friends_interested(user_id, venue_id)
    
    # Factor 1: Popularity (0-3 points) - based on OTHER users only
    popularity_score = min(other_users_interested / 3, 3)
    score += popularity_score
    if other_users_interested > 0:
        reasons.append(f"Popular venue")
    
    # Factor 2: Category match (0-4 points)
    # Check if venue category matches any user interest
    venue_category_lower = venue.category.lower()
    for interest in user.interests:
        if interest.lower() in venue_category_lower or venue_category_lower in interest.lower():
            score += 4
            reasons.append("Matches your interests")
            break
    
    # Factor 3: Friend interest (0-3 points)
    friend_score = min(friends_interested, 3)
    score += friend_score
    
    # Generate reason string
    reason = ", ".join(reasons) if reasons else "New venue to explore"
    
    return score, reason, friends_interested, total_interested_count


# API Endpoints

@app.get("/")
def root():
    """Health check endpoint."""
    return {
        "message": "Luna Venue Discovery API",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/venues")
def get_venues():
    """
    Get list of all venues with basic information.
    
    Returns:
        JSON object with venues array containing id, name, category, image, and interested_count
    """
    logger.info("Fetching all venues")
    
    venues = [
        {
            "id": venue.id,
            "name": venue.name,
            "category": venue.category,
            "image": venue.image,
            "interested_count": get_interested_count(venue.id)
        }
        for venue in venues_dict.values()
    ]
    
    logger.info(f"Returning {len(venues)} venues")
    return {"venues": venues}


@app.get("/venues/{venue_id}")
def get_venue_detail(venue_id: str):
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
    
    if venue_id not in venues_dict:
        logger.warning(f"Venue not found: {venue_id}")
        raise HTTPException(status_code=404, detail=f"Venue with id '{venue_id}' not found")
    
    venue = venues_dict[venue_id]
    interested_users = get_interested_users(venue_id)
    interested_count = get_interested_count(venue_id)
    
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
def express_interest(request: InterestRequest) -> InterestResponse:
    """
    Express or toggle interest in a venue.
    
    If the user is already interested, removes the interest.
    If not interested, adds the interest.
    
    Handles booking creation when threshold is met and booking cancellation
    when interest count drops below threshold.
    
    Uses per-venue locks to prevent race conditions during booking creation.
    
    Args:
        request: InterestRequest containing user_id and venue_id
        
    Returns:
        InterestResponse with success status and message
        
    Raises:
        HTTPException: 404 if user or venue not found
        HTTPException: 400 for invalid requests
    """
    logger.info(f"Express interest request: user={request.user_id}, venue={request.venue_id}")
    
    # Validate user and venue exist
    if request.user_id not in users_dict:
        logger.warning(f"User not found: {request.user_id}")
        raise HTTPException(status_code=404, detail=f"User with id '{request.user_id}' not found")
    
    if request.venue_id not in venues_dict:
        logger.warning(f"Venue not found: {request.venue_id}")
        raise HTTPException(status_code=404, detail=f"Venue with id '{request.venue_id}' not found")
    
    # Get venue lock to prevent race conditions
    venue_lock = get_venue_lock(request.venue_id)
    
    with venue_lock:
        # Check if interest already exists
        existing_interest = None
        for i, interest in enumerate(interests_list):
            if interest.user_id == request.user_id and interest.venue_id == request.venue_id:
                existing_interest = i
                break
        
        if existing_interest is not None:
            # Remove interest (toggle off)
            interests_list.pop(existing_interest)
            logger.info(f"Interest removed: user={request.user_id}, venue={request.venue_id}")
            
            return InterestResponse(
                success=True,
                message=f"Interest removed for {venues_dict[request.venue_id].name}"
            )
        else:
            # Add interest (toggle on)
            from models import Interest
            new_interest = Interest(
                user_id=request.user_id,
                venue_id=request.venue_id,
                timestamp=datetime.now()
            )
            interests_list.append(new_interest)
            logger.info(f"Interest added: user={request.user_id}, venue={request.venue_id}")
            
            # Get all interested user IDs for this venue
            interested_user_ids = [
                interest.user_id for interest in interests_list
                if interest.venue_id == request.venue_id
            ]
            interested_count = len(interested_user_ids)
            venue = venues_dict[request.venue_id]
            
            # Check if action item already exists for this venue
            existing_action_item = None
            for item in action_items_list:
                if item["venue_id"] == request.venue_id and item["status"] == "pending":
                    existing_action_item = item
                    break
            
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
                    # Create new action item record
                    action_item = {
                        "id": agent_response["action_item_id"],
                        "venue_id": request.venue_id,
                        "interested_user_ids": agent_response["interested_user_ids"],
                        "action_type": agent_response["action_type"],
                        "action_code": agent_response["action_code"],
                        "description": agent_response["description"],
                        "threshold_met": True,
                        "status": "pending",
                        "created_at": agent_response["created_at"]
                    }
                    action_items_list.append(action_item)
                    
                    logger.info(f"Action item created: {action_item['id']} for venue={request.venue_id}, count={interested_count}")
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
                else:
                    return InterestResponse(
                        success=True,
                        message="Interest recorded successfully"
                    )
            except Exception as e:
                logger.error(f"Action item agent error: {str(e)}")
                # Still return success since interest was recorded
                return InterestResponse(
                    success=True,
                    message="Interest recorded successfully"
                )


@app.get("/users/{user_id}")
def get_user_profile(user_id: str):
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
    
    if user_id not in users_dict:
        logger.warning(f"User not found: {user_id}")
        raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
    
    user = users_dict[user_id]
    interested_venues = get_user_interested_venues(user_id)
    
    # Get action items where user is interested and status is pending
    user_action_items = []
    for item in action_items_list:
        if user_id in item["interested_user_ids"] and item["status"] == "pending":
            venue = venues_dict.get(item["venue_id"])
            if venue:
                user_action_items.append({
                    "id": item["id"],
                    "venue_id": item["venue_id"],
                    "interested_user_ids": item["interested_user_ids"],
                    "action_type": item["action_type"],
                    "action_code": item["action_code"],
                    "description": item["description"],
                    "threshold_met": item["threshold_met"],
                    "status": item["status"],
                    "created_at": item["created_at"],
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
            "interests": user.interests
        },
        "interested_venues": interested_venues,
        "action_items": user_action_items
    }


@app.get("/recommendations")
def get_recommendations(user_id: str):
    """
    Get personalized venue recommendations for a user.
    
    CRITICAL BEHAVIOR:
    - Scores are calculated based on OTHER users' interests only (not including current user)
    - This ensures venue positions DON'T change when user toggles their own interest
    - Venues are sorted by score only, NOT by already_interested flag
    - This keeps venues in consistent positions regardless of user's interest state
    
    Recommendations are scored based on:
    - Popularity (0-3 points) - based on OTHER users interested
    - Category match with user interests (0-4 points)
    - Friend interest (0-3 points)
    
    Includes venues user is already interested in with already_interested flag.
    
    Args:
        user_id: The ID of the user to get recommendations for
        
    Returns:
        JSON object with sorted list of recommendations
        
    Raises:
        HTTPException: 404 if user not found
    """
    logger.info(f"Fetching recommendations for user_id: {user_id}")
    
    if user_id not in users_dict:
        logger.warning(f"User not found: {user_id}")
        raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
    
    # Get venues user is already interested in
    user_interested_venue_ids = {
        interest.venue_id for interest in interests_list 
        if interest.user_id == user_id
    }
    
    # Calculate scores for ALL venues
    recommendations = []
    for venue_id, venue in venues_dict.items():
        score, reason, friends_interested, total_interested = calculate_recommendation_score(user_id, venue_id)
        
        # Check if user is already interested
        already_interested = venue_id in user_interested_venue_ids
        
        recommendations.append({
            "venue": {
                "id": venue.id,
                "name": venue.name,
                "category": venue.category,
                "description": venue.description,
                "image": venue.image,
                "address": venue.address,
                "interested_count": total_interested
            },
            "score": round(score, 1),
            "reason": reason,
            "already_interested": already_interested,
            "friends_interested": friends_interested,
            "total_interested": total_interested
        })
    
    # Sort by score descending only
    # Do NOT sort by already_interested - that was pushing liked venues to bottom
    # Scores are now stable regardless of user's own interest (calculated from other users only)
    recommendations.sort(key=lambda x: -x["score"])
    
    logger.info(f"Returning {len(recommendations)} recommendations ({len(user_interested_venue_ids)} already interested)")
    return {"recommendations": recommendations}


class CompleteActionItemRequest(BaseModel):
    """Request model for completing an action item."""
    user_id: str


class SuccessResponse(BaseModel):
    """Generic success response."""
    success: bool
    message: str


@app.post("/action-items/{item_id}/complete")
def complete_action_item(item_id: str, request: CompleteActionItemRequest) -> SuccessResponse:
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
    
    # Find the action item
    action_item = None
    for item in action_items_list:
        if item["id"] == item_id:
            action_item = item
            break
    
    if not action_item:
        logger.warning(f"Action item not found: {item_id}")
        raise HTTPException(status_code=404, detail=f"Action item with id '{item_id}' not found")
    
    # Verify user is part of this action item
    if request.user_id not in action_item["interested_user_ids"]:
        logger.warning(f"User {request.user_id} not authorized for action item {item_id}")
        raise HTTPException(status_code=403, detail="User not authorized for this action item")
    
    # Update status
    action_item["status"] = "completed"
    logger.info(f"Action item {item_id} marked as completed")
    
    return SuccessResponse(
        success=True,
        message="Action item marked as completed"
    )


@app.delete("/action-items/{item_id}")
def dismiss_action_item(item_id: str, user_id: str) -> SuccessResponse:
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
    
    # Find the action item
    action_item = None
    action_item_index = None
    for i, item in enumerate(action_items_list):
        if item["id"] == item_id:
            action_item = item
            action_item_index = i
            break
    
    if not action_item:
        logger.warning(f"Action item not found: {item_id}")
        raise HTTPException(status_code=404, detail=f"Action item with id '{item_id}' not found")
    
    # Verify user is part of this action item
    if user_id not in action_item["interested_user_ids"]:
        logger.warning(f"User {user_id} not authorized for action item {item_id}")
        raise HTTPException(status_code=403, detail="User not authorized for this action item")
    
    # Update status to dismissed
    action_item["status"] = "dismissed"
    logger.info(f"Action item {item_id} dismissed")
    
    return SuccessResponse(
        success=True,
        message="Action item dismissed"
    )


@app.get("/bookings/{user_id}")
def get_user_bookings(user_id: str):
    """
    Get all active bookings for a specific user.
    
    Returns bookings where the user is included in the user_ids list
    and the booking status is "active".
    
    Args:
        user_id: The ID of the user to get bookings for
        
    Returns:
        JSON object with list of active bookings including venue details
        
    Raises:
        HTTPException: 404 if user not found
    """
    logger.info(f"Fetching bookings for user_id: {user_id}")
    
    if user_id not in users_dict:
        logger.warning(f"User not found: {user_id}")
        raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
    
    # Find all active bookings for this user
    user_bookings = []
    for booking in bookings_list:
        if booking["status"] == "active" and user_id in booking["user_ids"]:
            venue = venues_dict.get(booking["venue_id"])
            if venue:
                user_bookings.append({
                    "id": booking["id"],
                    "venue": {
                        "id": venue.id,
                        "name": venue.name,
                        "category": venue.category,
                        "image": venue.image,
                        "address": venue.address
                    },
                    "reservation_code": booking["reservation_code"],
                    "created_at": booking["created_at"],
                    "party_size": len(booking["user_ids"])
                })
    
    logger.info(f"Returning {len(user_bookings)} bookings for user {user_id}")
    return {"bookings": user_bookings}


@app.get("/venues/{venue_id}/booking")
def get_venue_booking(venue_id: str):
    """
    Check if a venue has an active booking.
    
    Args:
        venue_id: The ID of the venue to check
        
    Returns:
        JSON object with booking details if active booking exists, or None
        
    Raises:
        HTTPException: 404 if venue not found
    """
    logger.info(f"Checking booking status for venue_id: {venue_id}")
    
    if venue_id not in venues_dict:
        logger.warning(f"Venue not found: {venue_id}")
        raise HTTPException(status_code=404, detail=f"Venue with id '{venue_id}' not found")
    
    # Find active booking for this venue
    for booking in bookings_list:
        if booking["venue_id"] == venue_id and booking["status"] == "active":
            logger.info(f"Active booking found for venue {venue_id}")
            return {
                "has_booking": True,
                "booking": {
                    "id": booking["id"],
                    "reservation_code": booking["reservation_code"],
                    "created_at": booking["created_at"],
                    "party_size": len(booking["user_ids"])
                }
            }
    
    logger.info(f"No active booking for venue {venue_id}")
    return {"has_booking": False, "booking": None}
