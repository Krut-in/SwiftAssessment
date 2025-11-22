"""  
Synthetic data generator for Luna venue discovery application.

This module provides test data including users, venues, and interest relationships.
In production, this would be replaced with a database layer (PostgreSQL, MongoDB, etc.).

DATA STRUCTURE:
    - 8 users with diverse interests (coffee, food, bars, culture)
    - 12 venues across 4 categories (Coffee, Restaurant, Bar, Cultural)
    - 25+ interest relationships creating realistic social graph

KEY SCENARIOS:
    - Blue Bottle Coffee (venue_1) has 4+ users interested (triggers booking agent)
    - Users have overlapping interests to demonstrate social features
    - Mix of popular and less popular venues for recommendation testing

DATA INITIALIZATION:
    - Data is initialized on module import
    - Returns dictionaries for O(1) lookup by ID
    - Interest list maintains temporal ordering

PRODUCTION MIGRATION:
    To migrate to a database:
    1. Replace dictionaries with database queries
    2. Add proper ORM models (SQLAlchemy, Django ORM, etc.)
    3. Implement database transactions for interest toggling
    4. Add indexes on user_id and venue_id for performance
    5. Consider caching layer (Redis) for frequently accessed data

DATA CONSISTENCY:
    - All user IDs follow pattern: user_{n}
    - All venue IDs follow pattern: venue_{n}
    - Timestamps use datetime objects for proper sorting
    - Avatar URLs use pravatar.cc for consistent avatars
    - Venue images use picsum.photos with unique seeds

TESTING DATA:
    - user_1 (Alex Chen): Coffee enthusiast - use for coffee venue tests
    - venue_1 (Blue Bottle): Has 4 interests - use for booking agent tests
    - Overlapping interests enable friend recommendation testing
"""

from datetime import datetime
from typing import Dict, List
from models import User, Venue, Interest
def initialize_data() -> tuple[Dict[str, User], Dict[str, Venue], List[Interest]]:
    """
    Initialize and return synthetic test data for the application.
    
    Returns:
        Tuple containing:
        - users_dict: Dictionary mapping user IDs to User objects
        - venues_dict: Dictionary mapping venue IDs to Venue objects
        - interests_list: List of Interest objects
    """
    
    # Create 8 users
    users = [
        User(
            id="user_1",
            name="Alex Chen",
            avatar="https://i.pravatar.cc/150?img=1",
            bio="Coffee enthusiast",
            interests=["coffee", "food"]
        ),
        User(
            id="user_2",
            name="Jordan Kim",
            avatar="https://i.pravatar.cc/150?img=2",
            bio="Foodie",
            interests=["food", "restaurants"]
        ),
        User(
            id="user_3",
            name="Sam Rivera",
            avatar="https://i.pravatar.cc/150?img=3",
            bio="Social butterfly",
            interests=["bars", "social"]
        ),
        User(
            id="user_4",
            name="Taylor Lee",
            avatar="https://i.pravatar.cc/150?img=4",
            bio="Culture seeker",
            interests=["culture", "museums"]
        ),
        User(
            id="user_5",
            name="Morgan Park",
            avatar="https://i.pravatar.cc/150?img=5",
            bio="Bar enthusiast",
            interests=["bars", "nightlife"]
        ),
        User(
            id="user_6",
            name="Casey Wu",
            avatar="https://i.pravatar.cc/150?img=6",
            bio="Brunch fan",
            interests=["food", "brunch"]
        ),
        User(
            id="user_7",
            name="Riley Brooks",
            avatar="https://i.pravatar.cc/150?img=7",
            bio="Museum goer",
            interests=["culture", "art"]
        ),
        User(
            id="user_8",
            name="Quinn Davis",
            avatar="https://i.pravatar.cc/150?img=8",
            bio="Casual diner",
            interests=["food", "casual"]
        )
    ]
    
    # Create 12 venues (3 Coffee, 3 Restaurants, 3 Bars, 3 Cultural)
    venues = [
        # Coffee Shops
        Venue(
            id="venue_1",
            name="Blue Bottle Coffee",
            category="Coffee Shop",
            description="Artisan coffee in minimalist space",
            image="https://picsum.photos/400/300?random=1",
            address="450 W 15th St, NYC"
        ),
        Venue(
            id="venue_2",
            name="Stumptown Coffee",
            category="Coffee Shop",
            description="Portland-style coffee roasters",
            image="https://picsum.photos/400/300?random=2",
            address="18 W 29th St, NYC"
        ),
        Venue(
            id="venue_3",
            name="La Colombe Coffee",
            category="Coffee Shop",
            description="Draft latte specialists",
            image="https://picsum.photos/400/300?random=3",
            address="270 Lafayette St, NYC"
        ),
        # Restaurants
        Venue(
            id="venue_4",
            name="The Smith",
            category="Restaurant",
            description="American brasserie with lively atmosphere",
            image="https://picsum.photos/400/300?random=4",
            address="956 Broadway, NYC"
        ),
        Venue(
            id="venue_5",
            name="Joe's Pizza",
            category="Restaurant",
            description="Classic New York slice",
            image="https://picsum.photos/400/300?random=5",
            address="7 Carmine St, NYC"
        ),
        Venue(
            id="venue_6",
            name="Sushi Place",
            category="Restaurant",
            description="Fresh sushi and Japanese cuisine",
            image="https://picsum.photos/400/300?random=6",
            address="123 E 12th St, NYC"
        ),
        # Bars
        Venue(
            id="venue_7",
            name="Dead Rabbit",
            category="Bar",
            description="Award-winning Irish pub",
            image="https://picsum.photos/400/300?random=7",
            address="30 Water St, NYC"
        ),
        Venue(
            id="venue_8",
            name="Employees Only",
            category="Bar",
            description="Prohibition-style cocktail bar",
            image="https://picsum.photos/400/300?random=8",
            address="510 Hudson St, NYC"
        ),
        Venue(
            id="venue_9",
            name="Rooftop Bar",
            category="Bar",
            description="Skyline views and craft cocktails",
            image="https://picsum.photos/400/300?random=9",
            address="230 Fifth Ave, NYC"
        ),
        # Cultural
        Venue(
            id="venue_10",
            name="MoMA",
            category="Cultural",
            description="Museum of Modern Art",
            image="https://picsum.photos/400/300?random=10",
            address="11 W 53rd St, NYC"
        ),
        Venue(
            id="venue_11",
            name="Whitney Museum",
            category="Cultural",
            description="American art museum",
            image="https://picsum.photos/400/300?random=11",
            address="99 Gansevoort St, NYC"
        ),
        Venue(
            id="venue_12",
            name="Comedy Cellar",
            category="Cultural",
            description="Legendary comedy club",
            image="https://picsum.photos/400/300?random=12",
            address="117 MacDougal St, NYC"
        )
    ]
    
    # Create 25 interest relationships
    # Ensure Alex, Jordan, and Sam are all interested in Blue Bottle Coffee
    interests = [
        # Blue Bottle Coffee (venue_1) - Alex, Jordan, Sam
        Interest(user_id="user_1", venue_id="venue_1", timestamp=datetime(2024, 11, 20, 10, 30, 0)),
        Interest(user_id="user_2", venue_id="venue_1", timestamp=datetime(2024, 11, 20, 11, 15, 0)),
        Interest(user_id="user_3", venue_id="venue_1", timestamp=datetime(2024, 11, 20, 14, 20, 0)),
        
        # Alex Chen (user_1) - coffee lover
        Interest(user_id="user_1", venue_id="venue_2", timestamp=datetime(2024, 11, 19, 9, 0, 0)),
        Interest(user_id="user_1", venue_id="venue_3", timestamp=datetime(2024, 11, 18, 15, 30, 0)),
        
        # Jordan Kim (user_2) - foodie
        Interest(user_id="user_2", venue_id="venue_4", timestamp=datetime(2024, 11, 19, 12, 0, 0)),
        Interest(user_id="user_2", venue_id="venue_5", timestamp=datetime(2024, 11, 18, 19, 30, 0)),
        Interest(user_id="user_2", venue_id="venue_6", timestamp=datetime(2024, 11, 17, 20, 0, 0)),
        
        # Sam Rivera (user_3) - social butterfly
        Interest(user_id="user_3", venue_id="venue_7", timestamp=datetime(2024, 11, 20, 18, 0, 0)),
        Interest(user_id="user_3", venue_id="venue_8", timestamp=datetime(2024, 11, 19, 21, 0, 0)),
        
        # Taylor Lee (user_4) - culture seeker
        Interest(user_id="user_4", venue_id="venue_10", timestamp=datetime(2024, 11, 20, 13, 0, 0)),
        Interest(user_id="user_4", venue_id="venue_11", timestamp=datetime(2024, 11, 19, 14, 30, 0)),
        Interest(user_id="user_4", venue_id="venue_12", timestamp=datetime(2024, 11, 18, 20, 0, 0)),
        
        # Morgan Park (user_5) - bar enthusiast
        Interest(user_id="user_5", venue_id="venue_7", timestamp=datetime(2024, 11, 20, 19, 0, 0)),
        Interest(user_id="user_5", venue_id="venue_8", timestamp=datetime(2024, 11, 19, 22, 0, 0)),
        Interest(user_id="user_5", venue_id="venue_9", timestamp=datetime(2024, 11, 18, 21, 30, 0)),
        
        # Casey Wu (user_6) - brunch fan
        Interest(user_id="user_6", venue_id="venue_4", timestamp=datetime(2024, 11, 20, 11, 0, 0)),
        Interest(user_id="user_6", venue_id="venue_1", timestamp=datetime(2024, 11, 19, 10, 0, 0)),
        
        # Riley Brooks (user_7) - museum goer
        Interest(user_id="user_7", venue_id="venue_10", timestamp=datetime(2024, 11, 20, 14, 0, 0)),
        Interest(user_id="user_7", venue_id="venue_11", timestamp=datetime(2024, 11, 19, 15, 0, 0)),
        Interest(user_id="user_7", venue_id="venue_12", timestamp=datetime(2024, 11, 18, 19, 30, 0)),
        
        # Quinn Davis (user_8) - casual diner
        Interest(user_id="user_8", venue_id="venue_5", timestamp=datetime(2024, 11, 20, 18, 30, 0)),
        Interest(user_id="user_8", venue_id="venue_6", timestamp=datetime(2024, 11, 19, 19, 0, 0)),
        Interest(user_id="user_8", venue_id="venue_4", timestamp=datetime(2024, 11, 18, 12, 30, 0)),
        
        # Additional overlap
        Interest(user_id="user_3", venue_id="venue_9", timestamp=datetime(2024, 11, 17, 22, 0, 0))
    ]
    
    # Convert to dictionaries for easy lookup
    users_dict = {user.id: user for user in users}
    venues_dict = {venue.id: venue for venue in venues}
    
    return users_dict, venues_dict, interests


# Initialize data on module load
users_dict, venues_dict, interests_list = initialize_data()
