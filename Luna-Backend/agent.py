"""  
Action item agent for Luna venue discovery application.

This module creates action items when interest threshold is met.
Action items are persistent, trackable items that users can manage from their profile.

ARCHITECTURE:
    - Triggered automatically when >= 5 users express interest in a venue
    - Creates persistent action items instead of mock bookings
    - Returns action item data for display in toast notifications
    - Designed for manual user action (no automatic booking)

THRESHOLD CONFIGURATION:
    - Current: 5 users (configurable)
    - Consider making this venue-specific in production
    - Could vary based on venue capacity or day/time

ACTION TYPES:
    - "book_venue": For restaurants, bars, clubs (requires reservation)
    - "visit_venue": For museums, parks, shops (no reservation needed)

EXAMPLE USAGE:
    result = action_item_agent("venue_1", ["user_1", "user_2", "user_3", "user_4"])
    if result["action_item_created"]:
        print(f"Action code: {result['action_code']}")
"""

import random
from typing import Dict, List
from datetime import datetime


def action_item_agent(
    venue_id: str,
    interested_user_ids: List[str],
    venue_name: str = "",
    venue_category: str = ""
) -> Dict:
    """
    Creates an action item when interest threshold is reached.
    
    Action items are persistent records that users can track and manage.
    When 5+ users are interested, creates an action item with a unique code
    and description encouraging coordination.
    
    Args:
        venue_id: The ID of the venue
        interested_user_ids: List of all user IDs interested in the venue
        venue_name: The name of the venue (for description generation)
        venue_category: The category of the venue (determines action_type)
        
    Returns:
        Dictionary containing:
        - action_item_created (bool): Whether an action item was created
        - action_item_id (str): Unique ID for the action item (if created)
        - description (str): Human-readable description (if created)
        - action_code (str): Unique reference code (if created)
        - action_type (str): Type of action - "book_venue" or "visit_venue"
        - interested_user_ids (List[str]): List of interested users
        - threshold_met (bool): Whether threshold was met
        - notification_payload (dict): Push notification data (if created)
    """
    threshold = 5  # Trigger when 5+ users interested
    user_count = len(interested_user_ids)
    
    # Check if threshold is met
    if user_count < threshold:
        return {
            "action_item_created": False,
            "threshold_met": False
        }
    
    # Generate unique action item ID and code
    action_item_id = f"action_{venue_id}_{random.randint(1000, 9999)}"
    action_code = f"LUNA-{venue_id}-{random.randint(1000, 9999)}"
    
    # Determine action type based on venue category
    booking_categories = ["restaurant", "bar", "club", "lounge", "bistro", "cafe"]
    action_type = "book_venue" if any(cat in venue_category.lower() for cat in booking_categories) else "visit_venue"
    
    # Generate description
    friend_word = "friends" if user_count > 1 else "friend"
    descriptions = [
        f"{user_count} {friend_word} interested - coordinate plans!",
        f"{user_count} {friend_word} ready to go!",
        f"Goal reached! {user_count} people want to visit",
        f"Perfect group size - {user_count} interested!"
    ]
    description = random.choice(descriptions)
    
    # Create notification payload for push notifications
    notification_title = f"Booking Opportunity at {venue_name}" if venue_name else "Booking Opportunity"
    notification_body = f"{user_count} of your friends are interested! Time to book."
    
    notification_payload = {
        "title": notification_title,
        "body": notification_body,
        "venue_id": venue_id,
        "venue_name": venue_name,
        "action_code": action_code,
        "interested_count": user_count,
        "deep_link": f"luna://venues/{venue_id}"
    }
    
    # Log notification payload (APNs integration would happen here in production)
    print(f"🔔 Notification Trigger: {notification_title}")
    print(f"   Body: {notification_body}")
    print(f"   Recipients: {interested_user_ids}")
    print(f"   Deep Link: luna://venues/{venue_id}")
    
    return {
        "action_item_created": True,
        "action_item_id": action_item_id,
        "description": description,
        "action_code": action_code,
        "action_type": action_type,
        "interested_user_ids": interested_user_ids,
        "threshold_met": True,
        "created_at": datetime.now(),  # Return datetime object, not ISO string
        "notification_payload": notification_payload
    }
