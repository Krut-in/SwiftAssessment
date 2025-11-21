"""
Luna venue discovery backend API.

This module implements all 5 API endpoints for the venue discovery application:
- GET /venues - List all venues
- GET /venues/{venue_id} - Get venue details with interested users
- POST /interests - Express interest in a venue
- GET /users/{user_id} - Get user profile with interested venues
- GET /recommendations - Get personalized venue recommendations
"""

from datetime import datetime
from typing import List, Dict, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Import data from data.py
from data import users_dict, venues_dict, interests_list
from agent import booking_agent


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


class InterestResponse(BaseModel):
    """Response model after expressing interest."""
    success: bool
    agent_triggered: bool
    message: str
    reservation_code: Optional[str] = None


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
    
    return [
        {
            "id": venue.id,
            "name": venue.name,
            "category": venue.category,
            "description": venue.description,
            "image": venue.image,
            "address": venue.address,
            "interested_count": get_interested_count(venue.id)
        }
        for venue_id in interested_venue_ids
        if (venue := venues_dict.get(venue_id))
    ]


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


def calculate_recommendation_score(user_id: str, venue_id: str) -> tuple[float, str]:
    """
    Calculate recommendation score for a venue based on three factors.
    
    Scoring algorithm:
    - Factor 1: Popularity (0-3 points) = min(interested_count / 3, 3)
    - Factor 2: Category match (0-4 points) = 4 if venue category matches user interests
    - Factor 3: Friend interest (0-3 points) = min(friends_interested, 3)
    
    Args:
        user_id: The ID of the user
        venue_id: The ID of the venue
        
    Returns:
        Tuple of (score, reason string)
    """
    if user_id not in users_dict or venue_id not in venues_dict:
        return 0.0, "Invalid user or venue"
    
    user = users_dict[user_id]
    venue = venues_dict[venue_id]
    score = 0.0
    reasons = []
    
    # Factor 1: Popularity (0-3 points)
    interested_count = get_interested_count(venue_id)
    popularity_score = min(interested_count / 3, 3)
    score += popularity_score
    if interested_count > 0:
        reasons.append(f"Popular venue ({interested_count} interested)")
    
    # Factor 2: Category match (0-4 points)
    # Check if venue category matches any user interest
    venue_category_lower = venue.category.lower()
    for interest in user.interests:
        if interest.lower() in venue_category_lower or venue_category_lower in interest.lower():
            score += 4
            reasons.append("Matches your interests")
            break
    
    # Factor 3: Friend interest (0-3 points)
    friends_interested = count_friends_interested(user_id, venue_id)
    friend_score = min(friends_interested, 3)
    score += friend_score
    if friends_interested > 0:
        reasons.append(f"{friends_interested} friend{'s' if friends_interested > 1 else ''} interested")
    
    # Generate reason string
    reason = ", ".join(reasons) if reasons else "New venue to explore"
    
    return score, reason


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
    if venue_id not in venues_dict:
        raise HTTPException(status_code=404, detail=f"Venue with id '{venue_id}' not found")
    
    venue = venues_dict[venue_id]
    interested_users = get_interested_users(venue_id)
    
    return {
        "venue": {
            "id": venue.id,
            "name": venue.name,
            "category": venue.category,
            "description": venue.description,
            "image": venue.image,
            "address": venue.address,
            "interested_count": get_interested_count(venue_id)
        },
        "interested_users": interested_users
    }


@app.post("/interests")
def express_interest(request: InterestRequest) -> InterestResponse:
    """
    Express or toggle interest in a venue.
    
    If the user is already interested, removes the interest.
    If not interested, adds the interest.
    
    Args:
        request: InterestRequest containing user_id and venue_id
        
    Returns:
        InterestResponse with success status and message
        
    Raises:
        HTTPException: 404 if user or venue not found
        HTTPException: 400 for invalid requests
    """
    # Validate user and venue exist
    if request.user_id not in users_dict:
        raise HTTPException(status_code=404, detail=f"User with id '{request.user_id}' not found")
    
    if request.venue_id not in venues_dict:
        raise HTTPException(status_code=404, detail=f"Venue with id '{request.venue_id}' not found")
    
    # Check if interest already exists
    existing_interest = None
    for i, interest in enumerate(interests_list):
        if interest.user_id == request.user_id and interest.venue_id == request.venue_id:
            existing_interest = i
            break
    
    if existing_interest is not None:
        # Remove interest (toggle off)
        interests_list.pop(existing_interest)
        return InterestResponse(
            success=True,
            agent_triggered=False,
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
        
        # Check if booking agent should be triggered
        interested_count = get_interested_count(request.venue_id)
        venue_name = venues_dict[request.venue_id].name
        agent_response = booking_agent(request.venue_id, venue_name, interested_count)
        
        # Build response based on agent result
        if agent_response["agent_triggered"]:
            return InterestResponse(
                success=True,
                agent_triggered=True,
                message=agent_response["message"],
                reservation_code=agent_response["reservation_code"]
            )
        else:
            return InterestResponse(
                success=True,
                agent_triggered=False,
                message="Interest recorded successfully"
            )


@app.get("/users/{user_id}")
def get_user_profile(user_id: str):
    """
    Get user profile with their interested venues.
    
    Args:
        user_id: The ID of the user to retrieve
        
    Returns:
        JSON object with user details and list of interested venues
        
    Raises:
        HTTPException: 404 if user not found
    """
    if user_id not in users_dict:
        raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
    
    user = users_dict[user_id]
    interested_venues = get_user_interested_venues(user_id)
    
    return {
        "user": {
            "id": user.id,
            "name": user.name,
            "avatar": user.avatar,
            "bio": user.bio,
            "interests": user.interests
        },
        "interested_venues": interested_venues
    }


@app.get("/recommendations")
def get_recommendations(user_id: str):
    """
    Get personalized venue recommendations for a user.
    
    Recommendations are scored based on:
    - Popularity (0-3 points)
    - Category match with user interests (0-4 points)
    - Friend interest (0-3 points)
    
    Args:
        user_id: The ID of the user to get recommendations for
        
    Returns:
        JSON object with sorted list of recommendations
        
    Raises:
        HTTPException: 404 if user not found
    """
    if user_id not in users_dict:
        raise HTTPException(status_code=404, detail=f"User with id '{user_id}' not found")
    
    # Get venues user is already interested in
    user_interested_venue_ids = {
        interest.venue_id for interest in interests_list 
        if interest.user_id == user_id
    }
    
    # Calculate scores for all venues user hasn't expressed interest in
    recommendations = []
    for venue_id, venue in venues_dict.items():
        if venue_id not in user_interested_venue_ids:
            score, reason = calculate_recommendation_score(user_id, venue_id)
            recommendations.append({
                "venue": {
                    "id": venue.id,
                    "name": venue.name,
                    "category": venue.category,
                    "description": venue.description,
                    "image": venue.image,
                    "address": venue.address,
                    "interested_count": get_interested_count(venue_id)
                },
                "score": round(score, 1),
                "reason": reason
            })
    
    # Sort by score descending
    recommendations.sort(key=lambda x: x["score"], reverse=True)
    
    return {"recommendations": recommendations}
