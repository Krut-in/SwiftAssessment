"""  
Data models for Luna venue discovery application.

This module defines the core Pydantic models for users, venues, and interests.
All models use Pydantic for automatic validation and serialization.

MODELS:
    User: Represents a user with profile information and interests
    Venue: Represents a physical location/venue users can discover
    Interest: Represents a many-to-many relationship between users and venues
    ActionItem: Represents trackable actions when interest threshold is met

VALIDATION:
    - All models use Pydantic's BaseModel for automatic validation
    - String fields are automatically validated for type
    - Datetime fields ensure proper timestamp handling
    - List fields validate element types
    - Optional fields allow backward compatibility

SERIALIZATION:
    - Models automatically serialize to JSON for API responses
    - Snake_case naming matches Python conventions
    - DateTime fields serialize to ISO8601 format

USAGE:
    from models import User, Venue, Interest
    
    user = User(
        id="user_1",
        name="John Doe",
        avatar="https://example.com/avatar.jpg",
        bio="Coffee lover",
        interests=["coffee", "food"]
    )
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel
class User(BaseModel):
    """
    User model representing a person using the venue discovery app.
    
    Attributes:
        id: Unique identifier for the user
        name: Full name of the user
        avatar: URL to user's avatar image
        bio: Short biography or description
        interests: List of interest categories (e.g., "coffee", "food")
    """
    id: str
    name: str
    avatar: str
    bio: str
    interests: List[str]


class Venue(BaseModel):
    """
    Venue model representing a place users can discover and visit.
    
    Attributes:
        id: Unique identifier for the venue
        name: Name of the venue
        category: Category type (e.g., "Coffee Shop", "Restaurant")
        description: Detailed description of the venue
        image: URL to venue's primary image (for backward compatibility)
        images: List of image URLs for multi-image galleries (optional)
        address: Physical address of the venue
        latitude: Geographic latitude coordinate (optional)
        longitude: Geographic longitude coordinate (optional)
        distance_km: Distance from user in kilometers (optional, only when user_id provided)
    """
    id: str
    name: str
    category: str
    description: str
    image: str
    images: Optional[List[str]] = None
    address: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    distance_km: Optional[float] = None


class Interest(BaseModel):
    """
    Interest model representing a user's interest in a specific venue.
    
    Attributes:
        user_id: ID of the user expressing interest
        venue_id: ID of the venue the user is interested in
        timestamp: When the interest was expressed
    """
    user_id: str
    venue_id: str
    timestamp: datetime


class ActionItem(BaseModel):
    """
    ActionItem model representing a trackable action when venue interest threshold is met.
    
    Created when interest threshold is met (4+ users interested).
    Users can track these items and take manual action (booking, visiting, etc).
    
    Attributes:
        id: Unique identifier for the action item
        venue_id: ID of the venue this action item is for
        interested_user_ids: List of user IDs who expressed interest
        action_type: Type of action ("book_venue" or "visit_venue")
        action_code: Unique code for reference (e.g., "LUNA-venue_1-1234")
        description: Human-readable description (e.g., "3 friends interested - coordinate plans!")
        threshold_met: Whether the interest threshold was met
        status: Current status ("pending", "completed", "dismissed")
        created_at: Timestamp when action item was created
    """
    id: str
    venue_id: str
    interested_user_ids: List[str]
    action_type: str  # "book_venue" or "visit_venue"
    action_code: str
    description: str
    threshold_met: bool
    status: str  # "pending", "completed", "dismissed"
    created_at: datetime
