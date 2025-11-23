"""
Seed data migration for Luna venue discovery application.

This module provides initial data population for the SQLite database.
Migrates users, venues, interests, user interests, friendships, and action items.

DATA:
    - 8 users with diverse interests
    - 12 venues across NYC with geographic coordinates
    - 25+ interest relationships
    - User category interests (coffee, food, bars, culture)
    - All user pairs as friends (28 bidirectional friendships)

COORDINATES:
    - Approximate NYC coordinates based on venue addresses
    - Latitude/longitude for map display

USAGE:
    from seed_data import seed_database
    from database import get_db
    
    async with get_db() as session:
        await seed_database(session)

RESET:
    - Delete luna.db file to reset database
    - Restart server to re-seed
"""

from datetime import datetime
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.db_models import (
    UserDB, VenueDB, InterestDB, UserInterestDB, 
    FriendshipDB, ActionItemDB
)

logger = logging.getLogger(__name__)


async def seed_database(session: AsyncSession) -> None:
    """
    Seed database with initial data.
    
    Creates users, venues, interests, user interests, and friendships.
    Safe to call multiple times - checks if data already exists.
    
    Args:
        session: Database session for operations
    """
    # Check if data already exists
    result = await session.execute(select(UserDB))
    existing_users = result.scalars().all()
    
    if existing_users:
        logger.info("Database already seeded, skipping...")
        return
    
    logger.info("Seeding database with initial data...")
    
    # Create users
    users_data = [
        {
            "id": "user_1",
            "name": "Alex Chen",
            "avatar": "https://i.pravatar.cc/150?img=1",
            "bio": "Coffee enthusiast",
            "latitude": 40.7589,  # Times Square
            "longitude": -73.9851,
            "interests": ["coffee", "food"]
        },
        {
            "id": "user_2",
            "name": "Jordan Kim",
            "avatar": "https://i.pravatar.cc/150?img=2",
            "bio": "Foodie",
            "latitude": 40.7282,  # East Village
            "longitude": -73.9942,
            "interests": ["food", "restaurants"]
        },
        {
            "id": "user_3",
            "name": "Sam Rivera",
            "avatar": "https://i.pravatar.cc/150?img=3",
            "bio": "Social butterfly",
            "latitude": 40.7489,  # Midtown
            "longitude": -73.9680,
            "interests": ["bars", "social"]
        },
        {
            "id": "user_4",
            "name": "Taylor Lee",
            "avatar": "https://i.pravatar.cc/150?img=4",
            "bio": "Culture seeker",
            "latitude": 40.7614,  # MoMA area
            "longitude": -73.9776,
            "interests": ["culture", "museums"]
        },
        {
            "id": "user_5",
            "name": "Morgan Park",
            "avatar": "https://i.pravatar.cc/150?img=5",
            "bio": "Bar enthusiast",
            "latitude": 40.7267,  # Lower East Side
            "longitude": -73.9834,
            "interests": ["bars", "nightlife"]
        },
        {
            "id": "user_6",
            "name": "Casey Wu",
            "avatar": "https://i.pravatar.cc/150?img=6",
            "bio": "Brunch fan",
            "latitude": 40.7431,  # Flatiron
            "longitude": -73.9897,
            "interests": ["food", "brunch"]
        },
        {
            "id": "user_7",
            "name": "Riley Brooks",
            "avatar": "https://i.pravatar.cc/150?img=7",
            "bio": "Museum goer",
            "latitude": 40.7794,  # Upper West Side
            "longitude": -73.9632,
            "interests": ["culture", "art"]
        },
        {
            "id": "user_8",
            "name": "Quinn Davis",
            "avatar": "https://i.pravatar.cc/150?img=8",
            "bio": "Casual diner",
            "latitude": 40.7060,  # Financial District
            "longitude": -74.0088,
            "interests": ["food", "casual"]
        }
    ]
    
    # Create user records
    for user_data in users_data:
        interests = user_data.pop("interests")
        user = UserDB(**user_data)
        session.add(user)
        
        # Create user interests
        for idx, interest_category in enumerate(interests):
            user_interest = UserInterestDB(
                id=f"{user_data['id']}_interest_{idx}",
                user_id=user_data["id"],
                interest_category=interest_category
            )
            session.add(user_interest)
    
    logger.info(f"Created {len(users_data)} users with interests")
    
    # Create venues with coordinates
    venues_data = [
        # Coffee Shops
        {
            "id": "venue_1",
            "name": "Blue Bottle Coffee",
            "category": "Coffee Shop",
            "description": "Artisan coffee in minimalist space",
            "image": "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&h=300&fit=crop",
            "address": "450 W 15th St, NYC",
            "latitude": 40.7406,
            "longitude": -74.0014
        },
        {
            "id": "venue_2",
            "name": "Stumptown Coffee",
            "category": "Coffee Shop",
            "description": "Portland-style coffee roasters",
            "image": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&h=300&fit=crop",
            "address": "18 W 29th St, NYC",
            "latitude": 40.7456,
            "longitude": -73.9882
        },
        {
            "id": "venue_3",
            "name": "La Colombe Coffee",
            "category": "Coffee Shop",
            "description": "Draft latte specialists",
            "image": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=300&fit=crop",
            "address": "270 Lafayette St, NYC",
            "latitude": 40.7247,
            "longitude": -73.9963
        },
        # Restaurants
        {
            "id": "venue_4",
            "name": "The Smith",
            "category": "Restaurant",
            "description": "American brasserie with lively atmosphere",
            "image": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop",
            "address": "956 Broadway, NYC",
            "latitude": 40.7420,
            "longitude": -73.9897
        },
        {
            "id": "venue_5",
            "name": "Joe's Pizza",
            "category": "Restaurant",
            "description": "Classic New York slice",
            "image": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop",
            "address": "7 Carmine St, NYC",
            "latitude": 40.7304,
            "longitude": -74.0028
        },
        {
            "id": "venue_6",
            "name": "Sushi Place",
            "category": "Restaurant",
            "description": "Fresh sushi and Japanese cuisine",
            "image": "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop",
            "address": "123 E 12th St, NYC",
            "latitude": 40.7330,
            "longitude": -73.9891
        },
        # Bars
        {
            "id": "venue_7",
            "name": "Dead Rabbit",
            "category": "Bar",
            "description": "Award-winning Irish pub",
            "image": "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop",
            "address": "30 Water St, NYC",
            "latitude": 40.7033,
            "longitude": -74.0110
        },
        {
            "id": "venue_8",
            "name": "Employees Only",
            "category": "Bar",
            "description": "Prohibition-style cocktail bar",
            "image": "https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=400&h=300&fit=crop",
            "address": "510 Hudson St, NYC",
            "latitude": 40.7341,
            "longitude": -74.0067
        },
        {
            "id": "venue_9",
            "name": "Rooftop Bar",
            "category": "Bar",
            "description": "Skyline views and craft cocktails",
            "image": "https://images.unsplash.com/photo-1533769329083-7f2e6e82d73b?w=400&h=300&fit=crop",
            "address": "230 Fifth Ave, NYC",
            "latitude": 40.7442,
            "longitude": -73.9880
        },
        # Cultural
        {
            "id": "venue_10",
            "name": "MoMA",
            "category": "Cultural",
            "description": "Museum of Modern Art",
            "image": "https://images.unsplash.com/photo-1564399579883-451a5d44ec08?w=400&h=300&fit=crop",
            "address": "11 W 53rd St, NYC",
            "latitude": 40.7614,
            "longitude": -73.9776
        },
        {
            "id": "venue_11",
            "name": "Whitney Museum",
            "category": "Cultural",
            "description": "American art museum",
            "image": "https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=400&h=300&fit=crop",
            "address": "99 Gansevoort St, NYC",
            "latitude": 40.7396,
            "longitude": -74.0089
        },
        {
            "id": "venue_12",
            "name": "Comedy Cellar",
            "category": "Cultural",
            "description": "Legendary comedy club",
            "image": "https://images.unsplash.com/photo-1585699324551-f6c309eedeca?w=400&h=300&fit=crop",
            "address": "117 MacDougal St, NYC",
            "latitude": 40.7300,
            "longitude": -74.0010
        }
    ]
    
    for venue_data in venues_data:
        venue = VenueDB(**venue_data)
        session.add(venue)
    
    logger.info(f"Created {len(venues_data)} venues with coordinates")
    
    # Create interests
    interests_data = [
        # Blue Bottle Coffee (venue_1) - 4 users (triggers action item)
        {"user_id": "user_1", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 20, 10, 30, 0)},
        {"user_id": "user_2", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 20, 11, 15, 0)},
        {"user_id": "user_3", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 20, 14, 20, 0)},
        {"user_id": "user_6", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 19, 10, 0, 0)},
        
        # Alex Chen (user_1) - coffee lover
        {"user_id": "user_1", "venue_id": "venue_2", "timestamp": datetime(2024, 11, 19, 9, 0, 0)},
        {"user_id": "user_1", "venue_id": "venue_3", "timestamp": datetime(2024, 11, 18, 15, 30, 0)},
        
        # Jordan Kim (user_2) - foodie
        {"user_id": "user_2", "venue_id": "venue_4", "timestamp": datetime(2024, 11, 19, 12, 0, 0)},
        {"user_id": "user_2", "venue_id": "venue_5", "timestamp": datetime(2024, 11, 18, 19, 30, 0)},
        {"user_id": "user_2", "venue_id": "venue_6", "timestamp": datetime(2024, 11, 17, 20, 0, 0)},
        
        # Sam Rivera (user_3) - social butterfly
        {"user_id": "user_3", "venue_id": "venue_7", "timestamp": datetime(2024, 11, 20, 18, 0, 0)},
        {"user_id": "user_3", "venue_id": "venue_8", "timestamp": datetime(2024, 11, 19, 21, 0, 0)},
        {"user_id": "user_3", "venue_id": "venue_9", "timestamp": datetime(2024, 11, 17, 22, 0, 0)},
        
        # Taylor Lee (user_4) - culture seeker
        {"user_id": "user_4", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 20, 13, 0, 0)},
        {"user_id": "user_4", "venue_id": "venue_11", "timestamp": datetime(2024, 11, 19, 14, 30, 0)},
        {"user_id": "user_4", "venue_id": "venue_12", "timestamp": datetime(2024, 11, 18, 20, 0, 0)},
        
        # Morgan Park (user_5) - bar enthusiast
        {"user_id": "user_5", "venue_id": "venue_7", "timestamp": datetime(2024, 11, 20, 19, 0, 0)},
        {"user_id": "user_5", "venue_id": "venue_8", "timestamp": datetime(2024, 11, 19, 22, 0, 0)},
        {"user_id": "user_5", "venue_id": "venue_9", "timestamp": datetime(2024, 11, 18, 21, 30, 0)},
        
        # Casey Wu (user_6) - brunch fan
        {"user_id": "user_6", "venue_id": "venue_4", "timestamp": datetime(2024, 11, 20, 11, 0, 0)},
        
        # Riley Brooks (user_7) - museum goer
        {"user_id": "user_7", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 20, 14, 0, 0)},
        {"user_id": "user_7", "venue_id": "venue_11", "timestamp": datetime(2024, 11, 19, 15, 0, 0)},
        {"user_id": "user_7", "venue_id": "venue_12", "timestamp": datetime(2024, 11, 18, 19, 30, 0)},
        
        # Quinn Davis (user_8) - casual diner
        {"user_id": "user_8", "venue_id": "venue_5", "timestamp": datetime(2024, 11, 20, 18, 30, 0)},
        {"user_id": "user_8", "venue_id": "venue_6", "timestamp": datetime(2024, 11, 19, 19, 0, 0)},
        {"user_id": "user_8", "venue_id": "venue_4", "timestamp": datetime(2024, 11, 18, 12, 30, 0)},
    ]
    
    for interest_data in interests_data:
        interest = InterestDB(
            user_id=interest_data["user_id"],
            venue_id=interest_data["venue_id"],
            created_at=interest_data["timestamp"]
        )
        session.add(interest)
    
    logger.info(f"Created {len(interests_data)} interest relationships")
    
    # Create friendships (all user pairs)
    # Store each friendship once with user_id < friend_id
    user_ids = [f"user_{i}" for i in range(1, 9)]
    friendships_created = 0
    
    for i, user_id in enumerate(user_ids):
        for friend_id in user_ids[i+1:]:
            friendship = FriendshipDB(
                user_id=user_id,
                friend_id=friend_id
            )
            session.add(friendship)
            friendships_created += 1
    
    logger.info(f"Created {friendships_created} friendships (all user pairs)")
    
    # Commit all changes
    await session.commit()
    logger.info("Database seeding completed successfully")


async def check_and_seed(session: AsyncSession) -> None:
    """
    Check if database needs seeding and seed if necessary.
    
    Args:
        session: Database session for operations
    """
    result = await session.execute(select(UserDB))
    users = result.scalars().all()
    
    if not users:
        await seed_database(session)
    else:
        logger.info(f"Database already contains {len(users)} users")
