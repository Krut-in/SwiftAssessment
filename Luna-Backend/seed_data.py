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
    FriendshipDB, ActionItemDB, ActivityDB
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
    
    # Create users (15 diverse NYC personas)
    users_data = [
        {
            "id": "user_1",
            "name": "Alex Chen",
            "avatar": "https://i.pravatar.cc/150?img=1",
            "bio": "Third-wave coffee connoisseur who can tell you the origin story of every bean. Works in tech by day, explores Brooklyn's hidden café gems by weekend. Always hunting for the perfect pour-over.",
            "latitude": 40.7589,  # Times Square
            "longitude": -73.9851,
            "interests": ["coffee", "food", "culture"]
        },
        {
            "id": "user_2",
            "name": "Jordan Kim",
            "avatar": "https://i.pravatar.cc/150?img=2",
            "bio": "Food blogger with 50k followers and an appetite for adventure. From Michelin stars to hole-in-the-wall dumplings, I eat it all. Life's too short for boring meals!",
            "latitude": 40.7282,  # East Village
            "longitude": -73.9942,
            "interests": ["food", "restaurants", "bars"]
        },
        {
            "id": "user_3",
            "name": "Sam Rivera",
            "avatar": "https://i.pravatar.cc/150?img=3",
            "bio": "Social butterfly and nightlife enthusiast. You'll find me at the hottest rooftop bars or underground speakeasies. New in town? I'll show you where the locals really go.",
            "latitude": 40.7489,  # Midtown
            "longitude": -73.9680,
            "interests": ["bars", "nightlife", "entertainment"]
        },
        {
            "id": "user_4",
            "name": "Taylor Lee",
            "avatar": "https://i.pravatar.cc/150?img=4",
            "bio": "Art history PhD student living my best museum life. I spend weekends gallery hopping and hunting for hidden artistic treasures across the city. Culture is my cardio!",
            "latitude": 40.7614,  # MoMA area
            "longitude": -73.9776,
            "interests": ["culture", "museums", "entertainment"]
        },
        {
            "id": "user_5",
            "name": "Morgan Park",
            "avatar": "https://i.pravatar.cc/150?img=5",
            "bio": "Craft cocktail enthusiast and amateur mixologist. I've tried every speakeasy in Manhattan and can recommend the perfect drink for any mood. Cheers to new adventures!",
            "latitude": 40.7267,  # Lower East Side
            "longitude": -73.9834,
            "interests": ["bars", "nightlife", "food"]
        },
        {
            "id": "user_6",
            "name": "Casey Wu",
            "avatar": "https://i.pravatar.cc/150?img=6",
            "bio": "Brunch is not a meal, it's a lifestyle. Marketing professional who plans weekend outings around bottomless mimosas and Instagram-worthy avocado toast.",
            "latitude": 40.7431,  # Flatiron
            "longitude": -73.9897,
            "interests": ["food", "coffee", "parks"]
        },
        {
            "id": "user_7",
            "name": "Riley Brooks",
            "avatar": "https://i.pravatar.cc/150?img=7",
            "bio": "Museum member at five institutions and proud of it. Architecture nerd who geeks out over Brutalism and can spend hours in a single gallery. Art is life!",
            "latitude": 40.7794,  # Upper West Side
            "longitude": -73.9632,
            "interests": ["culture", "museums", "parks"]
        },
        {
            "id": "user_8",
            "name": "Quinn Davis",
            "avatar": "https://i.pravatar.cc/150?img=8",
            "bio": "Finance bro with a surprising appreciation for good food. From pizza slices on lunch breaks to fancy dinners, I know where to eat in every neighborhood.",
            "latitude": 40.7060,  # Financial District
            "longitude": -74.0088,
            "interests": ["food", "bars", "entertainment"]
        },
        {
            "id": "user_9",
            "name": "Blake Martinez",
            "avatar": "https://i.pravatar.cc/150?img=9",
            "bio": "Broadway fanatic and theater insider. I've seen Hamilton 12 times and regret nothing. Living for standing ovations and stage door meetups!",
            "latitude": 40.7580,  # Theater District
            "longitude": -73.9855,
            "interests": ["entertainment", "culture", "food"]
        },
        {
            "id": "user_10",
            "name": "Devon Patel",
            "avatar": "https://i.pravatar.cc/150?img=10",
            "bio": "Outdoor enthusiast who escapes to Central Park every morning before work. Runner, yogi, and advocate for more green spaces. Fresh air is my therapy.",
            "latitude": 40.7829,  # Central Park
            "longitude": -73.9654,
            "interests": ["parks", "coffee", "food"]
        },
        {
            "id": "user_11",
            "name": "Skylar Thompson",
            "avatar": "https://i.pravatar.cc/150?img=11",
            "bio": "Brooklyn-based photographer who documents the city's hidden corners. Jazz clubs, street performers, and late-night diners are my favorite subjects.",
            "latitude": 40.6782,  # Brooklyn
            "longitude": -73.9442,
            "interests": ["entertainment", "bars", "culture"]
        },
        {
            "id": "user_12",
            "name": "Harper Chen",
            "avatar": "https://i.pravatar.cc/150?img=12",
            "bio": "Urban planner passionate about walkable neighborhoods and public spaces. I rate cities by their parks and pedestrian infrastructure. Concrete jungle done right!",
            "latitude": 40.7489,  # Midtown East
            "longitude": -73.9680,
            "interests": ["parks", "culture", "coffee"]
        },
        {
            "id": "user_13",
            "name": "River Jordan",
            "avatar": "https://i.pravatar.cc/150?img=13",
            "bio": "Stand-up comedian who finds material in everyday NYC chaos. You'll catch me at open mics or comedy cellars. Life's funnier when you're laughing.",
            "latitude": 40.7308,  # Greenwich Village
            "longitude": -74.0020,
            "interests": ["entertainment", "bars", "food"]
        },
        {
            "id": "user_14",
            "name": "Sage Rodriguez",
            "avatar": "https://i.pravatar.cc/150?img=14",
            "bio": "Wellness coach who believes in balance: green juice in the morning, craft beer in the evening. Parks for meditation, bars for celebration!",
            "latitude": 40.7411,  # Chelsea
            "longitude": -74.0006,
            "interests": ["parks", "bars", "food"]
        },
        {
            "id": "user_15",
            "name": "Phoenix Lee",
            "avatar": "https://i.pravatar.cc/150?img=15",
            "bio": "Jazz aficionado and vinyl collector. Nothing beats live music in an intimate venue. I chase good vibes and even better acoustics across the city.",
            "latitude": 40.7282,  # East Village
            "longitude": -73.9942,
            "interests": ["entertainment", "culture", "coffee"]
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
    
    # Create venues with coordinates (20 venues across all categories)
    venues_data = [
        # Coffee Shops (4 venues)
        {
            "id": "venue_1",
            "name": "Blue Bottle Coffee",
            "category": "Coffee Shop",
            "description": "Minimalist coffee temple where third-wave brewing meets Japanese aesthetics. Known for their meticulously sourced beans and precise pour-over technique that transforms each cup into a ritual. The Chelsea flagship features floor-to-ceiling windows perfect for people-watching while savoring single-origin espresso.",
            "image": "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=300&fit=crop"
            ],
            "address": "450 W 15th St, NYC",
            "latitude": 40.7406,
            "longitude": -74.0014
        },
        {
            "id": "venue_2",
            "name": "Stumptown Coffee",
            "category": "Coffee Shop",
            "description": "Portland's legendary roaster brings their bold, direct-trade philosophy to the Ace Hotel. This industrial-chic café buzzes with freelancers and creatives fueling up on perfectly pulled shots. Don't miss their signature cold brew on nitro – it's like beer for coffee lovers.",
            "image": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=300&fit=crop"
            ],
            "address": "18 W 29th St, NYC",
            "latitude": 40.7456,
            "longitude": -73.9882
        },
        {
            "id": "venue_3",
            "name": "La Colombe Coffee",
            "category": "Coffee Shop",
            "description": "The birthplace of the draft latte revolution, serving velvety smooth coffee on tap like craft beer. This Nolita hotspot combines old-world roasting traditions with innovative brewing methods. Their signature draft latte has a cult following that rivals any trendy cocktail bar.",
            "image": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1587049352846-4a222e784112?w=400&h=300&fit=crop"
            ],
            "address": "270 Lafayette St, NYC",
            "latitude": 40.7247,
            "longitude": -73.9963
        },
        {
            "id": "venue_4",
            "name": "Ground Central Coffee",
            "category": "Coffee Shop",
            "description": "Cozy neighborhood gem tucked in the West Village with exposed brick and vintage furniture. Their baristas know regulars by name and drink order, creating that rare 'Cheers' vibe in Manhattan. Perfect spot for laptop work sessions or catching up with friends over cortados.",
            "image": "https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1521017432531-fbd92d768814?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1497515114629-f71d768fd07c?w=400&h=300&fit=crop"
            ],
            "address": "155 W 10th St, NYC",
            "latitude": 40.7353,
            "longitude": -74.0012
        },
        
        # Restaurants (5 venues)
        {
            "id": "venue_5",
            "name": "The Smith",
            "category": "Restaurant",
            "description": "Bustling American brasserie that's equally perfect for power lunches or late-night hangs. Their extensive menu satisfies every craving from steak frites to mac and cheese, all prepared with surprising finesse. Weekend brunch here is a contact sport – arrive early or prepare to wait with a Bloody Mary in hand.",
            "image": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop"
            ],
            "address": "956 Broadway, NYC",
            "latitude": 40.7420,
            "longitude": -73.9897
        },
        {
            "id": "venue_6",
            "name": "Joe's Pizza",
            "category": "Restaurant",
            "description": "Greenwich Village institution slinging perfect New York slices since 1975. The crust achieves that magical balance of crispy and chewy, sauce is sweet and tangy, and cheese stretches for days. This is the pizza New Yorkers send tourists to – it's that legit.",
            "image": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=400&h=300&fit=crop"
            ],
            "address": "7 Carmine St, NYC",
            "latitude": 40.7304,
            "longitude": -74.0028
        },
        {
            "id": "venue_7",
            "name": "Sushi Nakazawa",
            "category": "Restaurant",
            "description": "Omakase destination where Chef Nakazawa's Jiro-trained precision meets New York energy. Each piece of nigiri is a work of art, from the rice temperature to the fish sourcing. Reservations are brutally competitive, but scoring a seat at the counter is worth every effort.",
            "image": "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1564489563601-c53cfc451e93?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1582450871972-ab5ca641643d?w=400&h=300&fit=crop"
            ],
            "address": "23 Commerce St, NYC",
            "latitude": 40.7350,
            "longitude": -74.0065
        },
        {
            "id": "venue_8",
            "name": "Russ & Daughters Café",
            "category": "Restaurant",
            "description": "Lower East Side legend bringing four generations of smoked fish expertise to a charming sit-down space. Their bagels with lox are transcendent, but don't sleep on the latkes or matzo ball soup. A taste of authentic NYC Jewish food culture that hasn't been homogenized.",
            "image": "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1568051243851-f55fe13db2d7?w=400&h=300&fit=crop"
            ],
            "address": "127 Orchard St, NYC",
            "latitude": 40.7184,
            "longitude": -73.9885
        },
        {
            "id": "venue_9",
            "name": "Carbone",
            "category": "Restaurant",
            "description": "Theatrical Italian-American feast where every detail channels mid-century glamour. The spicy rigatoni vodka is legendary, but the real show is the tableside Caesar salad and flawless service choreography. Expensive and worth it for special occasions that demand drama.",
            "image": "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1608093326681-0a84267cbb3a?w=400&h=300&fit=crop"
            ],
            "address": "181 Thompson St, NYC",
            "latitude": 40.7277,
            "longitude": -74.0021
        },
        
        # Bars (4 venues)
        {
            "id": "venue_10",
            "name": "Dead Rabbit",
            "category": "Bar",
            "description": "World's Best Bar (multiple times over) serving historically accurate Irish-American punches downstairs and craft cocktails upstairs. The three-story FiDi location feels like stepping into 1850s New York, complete with period-appropriate drinks and sawdust floors. Their menu is a history lesson you can drink.",
            "image": "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1436076863939-06870fe779c2?w=400&h=300&fit=crop"
            ],
            "address": "30 Water St, NYC",
            "latitude": 40.7033,
            "longitude": -74.0110
        },
        {
            "id": "venue_11",
            "name": "Employees Only",
            "category": "Bar",
            "description": "Hidden speakeasy where master mixologists craft some of the city's finest cocktails with theatrical flair. The fortune teller in the entrance sets the mysterious tone, while the late-night kitchen feeds hungry drinkers till 3:30 AM. Their bartenders have won more awards than most restaurants.",
            "image": "https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1509669803555-fd5ec55d7e5e?w=400&h=300&fit=crop"
            ],
            "address": "510 Hudson St, NYC",
            "latitude": 40.7341,
            "longitude": -74.0067
        },
        {
            "id": "venue_12",
            "name": "230 Fifth Rooftop",
            "category": "Bar",
            "description": "Sprawling rooftop bar with unobstructed views of the Empire State Building that never get old. The heated igloos in winter and al fresco seating in summer make it year-round essential. Perfect for celebrating anything from birthdays to Tuesday.",
            "image": "https://images.unsplash.com/photo-1533769329083-7f2e6e82d73b?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1533769329083-7f2e6e82d73b?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1518176258769-f227c798150e?w=400&h=300&fit=crop"
            ],
            "address": "230 Fifth Ave, NYC",
            "latitude": 40.7442,
            "longitude": -73.9880
        },
        {
            "id": "venue_13",
            "name": "Death & Co",
            "category": "Bar",
            "description": "The bar that launched a thousand craft cocktail programs, still setting the standard in the East Village. Reservations recommended for their intimate candlelit space where bartenders take your drink order as seriously as a sommelier studies wine. Every cocktail tells a story.",
            "image": "https://images.unsplash.com/photo-1545315630-fcf7d447d4eb?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1545315630-fcf7d447d4eb?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1597290282695-edc43d0e7129?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1619173548764-5de00fdeb879?w=400&h=300&fit=crop"
            ],
            "address": "433 E 6th St, NYC",
            "latitude": 40.7254,
            "longitude": -73.9814
        },
        
        # Cultural (3 venues)
        {
            "id": "venue_14",
            "name": "MoMA",
            "category": "Cultural",
            "description": "The Museum of Modern Art houses humanity's greatest modern masterpieces from Van Gogh's Starry Night to Warhol's soup cans. Recent expansion doubled the galleries while maintaining an intimate viewing experience. Friday evenings with live music and cocktails transform art appreciation into a social event.",
            "image": "https://images.unsplash.com/photo-1564399579883-451a5d44ec08?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1564399579883-451a5d44ec08?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1513807016779-d51c0c026263?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=400&h=300&fit=crop"
            ],
            "address": "11 W 53rd St, NYC",
            "latitude": 40.7614,
            "longitude": -73.9776
        },
        {
            "id": "venue_15",
            "name": "Whitney Museum",
            "category": "Cultural",
            "description": "Renzo Piano's architectural marvel in the Meatpacking District celebrates American art with stadium-style outdoor galleries. The terraces offer stunning Hudson River views between modern art installations. Their biennial exhibition sets the pulse of contemporary American art.",
            "image": "https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1521103935904-b89a8bfce1a1?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1580913428706-c311e67898b3?w=400&h=300&fit=crop"
            ],
            "address": "99 Gansevoort St, NYC",
            "latitude": 40.7396,
            "longitude": -74.0089
        },
        {
            "id": "venue_16",
            "name": "The Met Cloisters",
            "category": "Cultural",
            "description": "Medieval European art and architecture transported to a peaceful Fort Tryon Park hilltop. This hidden gem features actual monastery cloisters, unicorn tapestries, and some of the most serene gardens in Manhattan. It's a time machine to another era without leaving the city.",
            "image": "https://images.unsplash.com/photo-1567975862653-5fe8a9200271?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1567975862653-5fe8a9200271?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1558120924-3a4ee0c6d42f?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1566127444979-b3d2b64d4de6?w=400&h=300&fit=crop"
            ],
            "address": "99 Margaret Corbin Dr, NYC",
            "latitude": 40.8648,
            "longitude": -73.9318
        },
        
        # Entertainment (2 venues)
        {
            "id": "venue_17",
            "name": "Comedy Cellar",
            "category": "Entertainment",
            "description": "Legendary underground comedy club where every major comedian has tested material since 1982. The intimate brick-walled basement puts you close enough to make eye contact with performers. Drop-in surprise sets from household names happen weekly – you never know who'll show up.",
            "image": "https://images.unsplash.com/photo-1585699324551-f6c309eedeca?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1585699324551-f6c309eedeca?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400&h=300&fit=crop"
            ],
            "address": "117 MacDougal St, NYC",
            "latitude": 40.7300,
            "longitude": -74.0010
        },
        {
            "id": "venue_18",
            "name": "Blue Note Jazz Club",
            "category": "Entertainment",
            "description": "The world's most famous jazz club has hosted every legend from Dizzy Gillespie to Prince. Two sets nightly in an intimate Greenwich Village venue where the music quality is consistently stellar. The $5 late-night jam sessions are NYC's best musical bargain.",
            "image": "https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1525201548942-d8732f6617a0?w=400&h=300&fit=crop"
            ],
            "address": "131 W 3rd St, NYC",
            "latitude": 40.7307,
            "longitude": -74.0011
        },
        
        # Parks (2 venues)
        {
            "id": "venue_19",
            "name": "Central Park - Sheep Meadow",
            "category": "Park",
            "description": "The 15-acre lawn that defines NYC summer, where thousands gather for picnics, sunbathing, and people-watching. From frisbee games to impromptu concerts, this is democracy in action. Pack a blanket, grab food from nearby vendors, and soak in the most diverse crowd you'll see anywhere.",
            "image": "https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1568515387631-8b650bbcdb90?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1564231629473-45ca3b67cb24?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1577213488789-e1e7a58ee7f1?w=400&h=300&fit=crop"
            ],
            "address": "Central Park West & 69th St, NYC",
            "latitude": 40.7749,
            "longitude": -73.9730
        },
        {
            "id": "venue_20",
            "name": "Brooklyn Bridge Park",
            "category": "Park",
            "description": "Waterfront wonderland stretching 1.3 miles along the East River with the most iconic Manhattan skyline views. From kayaking to beach volleyball, rock climbing to carousel rides, there's something for everyone. Sunset here turns Instagram into your job.",
            "image": "https://images.unsplash.com/photo-1518391846015-55a9cc003b25?w=400&h=300&fit=crop",
            "images": [
                "https://images.unsplash.com/photo-1518391846015-55a9cc003b25?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1600717186825-895ed6a94ad0?w=400&h=300&fit=crop",
                "https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=400&h=300&fit=crop"
            ],
            "address": "334 Furman St, Brooklyn, NYC",
            "latitude": 40.6962,
            "longitude": -73.9969
        }
    ]
    
    for venue_data in venues_data:
        venue = VenueDB(**venue_data)
        session.add(venue)
    
    
    logger.info(f"Created {len(venues_data)} venues with coordinates")
    
    # Create interests (55+ relationships with realistic patterns)
    interests_data = [
        # Blue Bottle Coffee (venue_1) - 5 users (triggers action item)
        {"user_id": "user_1", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 20, 10, 30, 0)},
        {"user_id": "user_6", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 19, 10, 0, 0)},
        {"user_id": "user_10", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 21, 8, 15, 0)},
        {"user_id": "user_12", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 21, 14, 0, 0)},
        {"user_id": "user_15", "venue_id": "venue_1", "timestamp": datetime(2024, 11, 20, 16, 0, 0)},
        
        # Coffee Shop interests
        {"user_id": "user_1", "venue_id": "venue_2", "timestamp": datetime(2024, 11, 19, 9, 0, 0)},
        {"user_id": "user_1", "venue_id": "venue_3", "timestamp": datetime(2024, 11, 18, 15, 30, 0)},
        {"user_id": "user_6", "venue_id": "venue_4", "timestamp": datetime(2024, 11, 20, 11, 0, 0)},
        {"user_id": "user_10", "venue_id": "venue_2", "timestamp": datetime(2024, 11, 21, 7, 30, 0)},
        {"user_id": "user_12", "venue_id": "venue_3", "timestamp": datetime(2024, 11, 18, 12, 0, 0)},
        {"user_id": "user_15", "venue_id": "venue_4", "timestamp": datetime(2024, 11, 20, 15, 0, 0)},
        
        # Restaurant interests - The Smith (venue_5) has 4+ users
        {"user_id": "user_2", "venue_id": "venue_5", "timestamp": datetime(2024, 11, 19, 12, 0, 0)},
        {"user_id": "user_6", "venue_id": "venue_5", "timestamp": datetime(2024, 11, 20, 11, 30, 0)},
        {"user_id": "user_8", "venue_id": "venue_5", "timestamp": datetime(2024, 11, 18, 12, 30, 0)},
        {"user_id": "user_14", "venue_id": "venue_5", "timestamp": datetime(2024, 11, 21, 13, 0, 0)},
        
        # Pizza and other restaurants
        {"user_id": "user_2", "venue_id": "venue_6", "timestamp": datetime(2024, 11, 18, 19, 30, 0)},
        {"user_id": "user_8", "venue_id": "venue_6", "timestamp": datetime(2024, 11, 19, 19, 0, 0)},
        {"user_id": "user_13", "venue_id": "venue_6", "timestamp": datetime(2024, 11, 20, 20, 0, 0)},
        
        {"user_id": "user_2", "venue_id": "venue_7", "timestamp": datetime(2024, 11, 17, 20, 0, 0)},
        {"user_id": "user_9", "venue_id": "venue_7", "timestamp": datetime(2024, 11, 21, 19, 0, 0)},
        
        {"user_id": "user_2", "venue_id": "venue_8", "timestamp": datetime(2024, 11, 20, 10, 0, 0)},
        {"user_id": "user_8", "venue_id": "venue_9", "timestamp": datetime(2024, 11, 19, 21, 0, 0)},
        {"user_id": "user_9", "venue_id": "venue_9", "timestamp": datetime(2024, 11, 20, 20, 30, 0)},
        
        # Bar interests - Dead Rabbit (venue_10) with 5+ users
        {"user_id": "user_3", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 20, 18, 0, 0)},
        {"user_id": "user_5", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 20, 19, 0, 0)},
        {"user_id": "user_11", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 21, 21, 0, 0)},
        {"user_id": "user_13", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 19, 22, 0, 0)},
        {"user_id": "user_14", "venue_id": "venue_10", "timestamp": datetime(2024, 11, 21, 20, 0, 0)},
       
        # Other bars
        {"user_id": "user_3", "venue_id": "venue_11", "timestamp": datetime(2024, 11, 19, 21, 0, 0)},
        {"user_id": "user_5", "venue_id": "venue_11", "timestamp": datetime(2024, 11, 19, 22, 0, 0)},
        {"user_id": "user_11", "venue_id": "venue_11", "timestamp": datetime(2024, 11, 20, 23, 0, 0)},
        
        {"user_id": "user_3", "venue_id": "venue_12", "timestamp": datetime(2024, 11, 17, 22, 0, 0)},
        {"user_id": "user_5", "venue_id": "venue_12", "timestamp": datetime(2024, 11, 18, 21, 30, 0)},
        
        {"user_id": "user_3", "venue_id": "venue_13", "timestamp": datetime(2024, 11, 20, 22, 30, 0)},
        {"user_id": "user_5", "venue_id": "venue_13", "timestamp": datetime(2024, 11, 19, 23, 0, 0)},
        {"user_id": "user_14", "venue_id": "venue_13", "timestamp": datetime(2024, 11, 21, 21, 30, 0)},
        
        # Cultural interests - MOoMA (venue_14) with 4+ users
        {"user_id": "user_4", "venue_id": "venue_14", "timestamp": datetime(2024, 11, 20, 13, 0, 0)},
        {"user_id": "user_7", "venue_id": "venue_14", "timestamp": datetime(2024, 11, 20, 14, 0, 0)},
        {"user_id": "user_9", "venue_id": "venue_14", "timestamp": datetime(2024, 11, 19, 11, 0, 0)},
        {"user_id": "user_12", "venue_id": "venue_14", "timestamp": datetime(2024, 11, 21, 15, 0, 0)},
        
        {"user_id": "user_4", "venue_id": "venue_15", "timestamp": datetime(2024, 11, 19, 14, 30, 0)},
        {"user_id": "user_7", "venue_id": "venue_15", "timestamp": datetime(2024, 11, 19, 15, 0, 0)},
        {"user_id": "user_11", "venue_id": "venue_15", "timestamp": datetime(2024, 11, 20, 13, 0, 0)},
        
        {"user_id": "user_4", "venue_id": "venue_16", "timestamp": datetime(2024, 11, 21, 12, 0, 0)},
        {"user_id": "user_7", "venue_id": "venue_16", "timestamp": datetime(2024, 11, 20, 16, 0, 0)},
        
        # Entertainment interests
        {"user_id": "user_3", "venue_id": "venue_17", "timestamp": datetime(2024, 11, 20, 20, 0, 0)},
        {"user_id": "user_9", "venue_id": "venue_17", "timestamp": datetime(2024, 11, 19, 19, 30, 0)},
        {"user_id": "user_13", "venue_id": "venue_17", "timestamp": datetime(2024, 11, 18, 21, 0, 0)},
        {"user_id": "user_15", "venue_id": "venue_17", "timestamp": datetime(2024, 11, 21, 22, 0, 0)},
        
        {"user_id": "user_11", "venue_id": "venue_18", "timestamp": datetime(2024, 11, 20, 21, 0, 0)},
        {"user_id": "user_15", "venue_id": "venue_18", "timestamp": datetime(2024, 11, 19, 20, 0, 0)},
       
        # Parks interests
        {"user_id": "user_6", "venue_id": "venue_19", "timestamp": datetime(2024, 11, 20, 9, 0, 0)},
        {"user_id": "user_7", "venue_id": "venue_19", "timestamp": datetime(2024, 11, 21, 10, 0, 0)},
        {"user_id": "user_10", "venue_id": "venue_19", "timestamp": datetime(2024, 11, 20, 8, 0, 0)},
        {"user_id": "user_12", "venue_id": "venue_19", "timestamp": datetime(2024, 11, 19, 17, 0, 0)},
        {"user_id": "user_14", "venue_id": "venue_19", "timestamp": datetime(2024, 11, 21, 7, 0, 0)},
        
        {"user_id": "user_10", "venue_id": "venue_20", "timestamp": datetime(2024, 11, 19, 16, 0, 0)},
        {"user_id": "user_12", "venue_id": "venue_20", "timestamp": datetime(2024, 11, 20, 18, 0, 0)},
        {"user_id": "user_14", "venue_id": "venue_20", "timestamp": datetime(2024, 11, 21, 17, 30, 0)},
    ]
    
    for interest_data in interests_data:
        interest = InterestDB(
            user_id=interest_data["user_id"],
            venue_id=interest_data["venue_id"],
            created_at=interest_data["timestamp"]
        )
        session.add(interest)
    
    
    logger.info(f"Created {len(interests_data)} interest relationships")
    
    # Create activities for social feed (one activity per interest)
    # This populates friends' social feeds with historical activity data
    activities_created = 0
    for interest_data in interests_data:
        activity_id = f"activity_{interest_data['user_id']}_{interest_data['venue_id']}_{int(interest_data['timestamp'].timestamp())}"
        activity = ActivityDB(
            id=activity_id,
            user_id=interest_data["user_id"],
            venue_id=interest_data["venue_id"],
            action="interested",
            created_at=interest_data["timestamp"]
        )
        session.add(activity)
        activities_created += 1
    
    logger.info(f"Created {activities_created} activity records for social feed")
    
    # Create friendships (all user pairs for 15 users)
    # Store each friendship once with user_id < friend_id
    user_ids = [f"user_{i}" for i in range(1, 16)]  # Updated to 15 users
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
