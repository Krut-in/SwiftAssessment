"""
SQLAlchemy database models for Luna venue discovery application.

This module defines the ORM models for persistent storage using SQLite.
All models inherit from Base and use SQLAlchemy 2.0 async syntax.

MODELS:
    UserDB: User profile information
    VenueDB: Venue details with geographic coordinates
    InterestDB: Many-to-many relationship between users and venues
    UserInterestDB: User's category interests (coffee, food, etc.)
    FriendshipDB: Bidirectional friendships between users
    ActionItemDB: Trackable action items when venue interest threshold met

INDEXES:
    - Foreign keys indexed for query performance
    - Composite primary keys for junction tables

RELATIONSHIPS:
    - Cascade deletes configured where appropriate
    - Bidirectional relationships for easy navigation

USAGE:
    from models.db_models import UserDB, VenueDB, InterestDB
    from database import get_db
    from sqlalchemy import select
    
    async with get_db() as session:
        result = await session.execute(select(UserDB))
        users = result.scalars().all()
"""

from datetime import datetime
from typing import List
import json

from sqlalchemy import (
    Column, String, Float, DateTime, JSON, Text,
    ForeignKey, Index, UniqueConstraint, Boolean
)
from sqlalchemy.orm import relationship
from database import Base


class UserDB(Base):
    """
    User model for storing user profile information.
    
    Attributes:
        id: Unique identifier (e.g., "user_1")
        name: Full name of the user
        avatar: URL to user's avatar image
        bio: Short biography or description
        latitude: Geographic latitude coordinate (-90 to 90)
        longitude: Geographic longitude coordinate (-180 to 180)
        created_at: Timestamp when user was created
    """
    __tablename__ = "users"
    
    id = Column(String(100), primary_key=True)
    name = Column(String(255), nullable=False)
    avatar = Column(String(500), nullable=False)
    bio = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)  # Valid range: -90 to 90
    longitude = Column(Float, nullable=False)  # Valid range: -180 to 180
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    interests = relationship("InterestDB", back_populates="user", cascade="all, delete-orphan")
    user_interests = relationship("UserInterestDB", back_populates="user", cascade="all, delete-orphan")
    friendships = relationship(
        "FriendshipDB",
        foreign_keys="FriendshipDB.user_id",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<UserDB(id={self.id}, name={self.name})>"


class VenueDB(Base):
    """
    Venue model for storing venue information with geographic coordinates.
    
    Attributes:
        id: Unique identifier (e.g., "venue_1")
        name: Name of the venue
        category: Category type (e.g., "Coffee Shop", "Restaurant")
        description: Detailed description of the venue
        image: URL to venue's primary image (for backward compatibility)
        images: JSON array of image URLs for multi-image galleries (optional)
        address: Physical address of the venue
        latitude: Geographic latitude coordinate
        longitude: Geographic longitude coordinate
        created_at: Timestamp when venue was created
    """
    __tablename__ = "venues"
    
    id = Column(String(100), primary_key=True)
    name = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    image = Column(String(500), nullable=False)
    images = Column(JSON, nullable=True)  # Store array of image URLs as JSON
    address = Column(String(500), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    interests = relationship("InterestDB", back_populates="venue", cascade="all, delete-orphan")
    action_items = relationship("ActionItemDB", back_populates="venue", cascade="all, delete-orphan")
    
    # Index on category for filtering
    __table_args__ = (
        Index('idx_venue_category', 'category'),
    )
    
    def __repr__(self):
        return f"<VenueDB(id={self.id}, name={self.name}, category={self.category})>"


class InterestDB(Base):
    """
    Interest model representing a user's interest in a specific venue.
    
    Junction table for many-to-many relationship between users and venues.
    
    Attributes:
        user_id: ID of the user expressing interest
        venue_id: ID of the venue the user is interested in
        created_at: When the interest was expressed
    """
    __tablename__ = "interests"
    
    user_id = Column(String(100), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    venue_id = Column(String(100), ForeignKey("venues.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    user = relationship("UserDB", back_populates="interests")
    venue = relationship("VenueDB", back_populates="interests")
    
    # Indexes for query performance
    # Single column indexes for filtering
    # Compound index for checking if user is interested in specific venue
    __table_args__ = (
        Index('idx_interest_user', 'user_id'),
        Index('idx_interest_venue', 'venue_id'),
        Index('idx_interest_user_venue', 'user_id', 'venue_id'),  # Compound index for lookup
    )
    
    def __repr__(self):
        return f"<InterestDB(user_id={self.user_id}, venue_id={self.venue_id})>"


class UserInterestDB(Base):
    """
    User interest categories (converted from User.interests list).
    
    Stores user's general interests like "coffee", "food", "bars", etc.
    
    Attributes:
        id: Auto-incrementing primary key
        user_id: ID of the user
        interest_category: Category name (e.g., "coffee", "food")
        created_at: When the interest was added
    """
    __tablename__ = "user_interests"
    
    id = Column(String(100), primary_key=True)
    user_id = Column(String(100), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    interest_category = Column(String(100), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    user = relationship("UserDB", back_populates="user_interests")
    
    # Indexes
    __table_args__ = (
        Index('idx_user_interest_user', 'user_id'),
        UniqueConstraint('user_id', 'interest_category', name='uq_user_interest'),
    )
    
    def __repr__(self):
        return f"<UserInterestDB(user_id={self.user_id}, category={self.interest_category})>"


class FriendshipDB(Base):
    """
    Friendship model for bidirectional friendships between users.
    
    Each friendship is stored once (user_id < friend_id) to avoid duplicates.
    Both users are considered friends of each other.
    
    Attributes:
        user_id: ID of first user (lower ID)
        friend_id: ID of second user (higher ID)
        created_at: When the friendship was created
    """
    __tablename__ = "friendships"
    
    user_id = Column(String(100), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    friend_id = Column(String(100), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    user = relationship("UserDB", foreign_keys=[user_id], back_populates="friendships")
    
    # Indexes
    __table_args__ = (
        Index('idx_friendship_user', 'user_id'),
        Index('idx_friendship_friend', 'friend_id'),
    )
    
    def __repr__(self):
        return f"<FriendshipDB(user_id={self.user_id}, friend_id={self.friend_id})>"


class ActionItemDB(Base):
    """
    Action item model for trackable actions when venue interest threshold met.
    
    Created when 4+ users express interest in a venue.
    Users can track these items and take manual action (booking, visiting, etc).
    
    Attributes:
        id: Unique identifier
        venue_id: ID of the venue this action item is for
        interested_user_ids: JSON array of user IDs who expressed interest
        action_type: Type of action ("book_venue" or "visit_venue")
        action_code: Unique code for reference (e.g., "LUNA-venue_1-1234")
        description: Human-readable description
        status: Current status ("pending", "completed", "dismissed")
        threshold_met: Whether the interest threshold was met
        created_at: Timestamp when action item was created
    """
    __tablename__ = "action_items"
    
    id = Column(String(100), primary_key=True)
    venue_id = Column(String(100), ForeignKey("venues.id", ondelete="CASCADE"), nullable=False)
    interested_user_ids = Column(JSON, nullable=False)  # Store as JSON array
    action_type = Column(String(50), nullable=False)  # "book_venue" or "visit_venue"
    action_code = Column(String(100), nullable=False, unique=True)
    description = Column(Text, nullable=False)
    status = Column(String(50), nullable=False, default="pending")  # "pending", "completed", "dismissed"
    threshold_met = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    venue = relationship("VenueDB", back_populates="action_items")
    
    # Indexes
    __table_args__ = (
        Index('idx_action_item_venue', 'venue_id'),
        Index('idx_action_item_status', 'status'),
    )
    
    def __repr__(self):
        return f"<ActionItemDB(id={self.id}, venue_id={self.venue_id}, status={self.status})>"


class ActivityDB(Base):
    """
    Activity model for tracking user actions in venues (social feed).
    
    Tracks activities like expressing interest, booking, and check-ins.
    Used to populate friend activity feeds.
    
    Attributes:
        id: Unique identifier for the activity
        user_id: ID of the user who performed the action
        venue_id: ID of the venue the action relates to
        action: Type of action ("interested", "booked", "checked_in")
        created_at: Timestamp when the activity occurred
    """
    __tablename__ = "activities"
    
    id = Column(String(100), primary_key=True)
    user_id = Column(String(100), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    venue_id = Column(String(100), ForeignKey("venues.id", ondelete="CASCADE"), nullable=False)
    action = Column(String(50), nullable=False)  # "interested", "booked", "checked_in"
    created_at = Column(DateTime, default=lambda: datetime.now(), nullable=False)
    
    # Relationships
    user = relationship("UserDB", backref="activities")
    venue = relationship("VenueDB", backref="activities")
    
    # Indexes for efficient feed queries
    __table_args__ = (
        Index('idx_activity_user', 'user_id'),
        Index('idx_activity_venue', 'venue_id'),
        Index('idx_activity_created', 'created_at'),
    )
    
    def __repr__(self):
        return f"<ActivityDB(id={self.id}, user_id={self.user_id}, action={self.action})>"
