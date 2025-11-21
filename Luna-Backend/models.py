"""
Data models for Luna venue discovery application.

This module defines the core Pydantic models for users, venues, and interests.
"""

from datetime import datetime
from typing import List
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
        image: URL to venue's image
        address: Physical address of the venue
    """
    id: str
    name: str
    category: str
    description: str
    image: str
    address: str


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
