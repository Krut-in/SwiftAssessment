"""  
Mock booking agent for Luna venue discovery application.

This module simulates automated reservation booking when interest threshold is met.
In production, this would integrate with OpenTable/Resy APIs.

ARCHITECTURE:
    - Triggered automatically when >= 3 users express interest in a venue
    - Returns mock reservation codes for demonstration
    - Designed to be replaced with real booking API integration

PRODUCTION INTEGRATION:
    To integrate with real booking services:
    1. Replace booking_agent function with API calls
    2. Add authentication for booking service APIs
    3. Implement retry logic for failed bookings
    4. Add webhook handlers for booking confirmations
    5. Store reservation details in database

RECOMMENDED APIS:
    - OpenTable: https://www.opentable.com/developers
    - Resy: https://resy.com/api
    - Yelp Reservations: https://www.yelp.com/developers

THRESHOLD CONFIGURATION:
    - Current: 3 users (configurable)
    - Consider making this venue-specific in production
    - Could vary based on venue capacity or day/time

ERROR HANDLING:
    - Currently fails silently (returns agent_triggered=False)
    - Production should log failures and notify admins
    - Consider queuing failed bookings for retry

EXAMPLE USAGE:
    result = booking_agent("venue_1", "Blue Bottle Coffee", 3)
    if result["agent_triggered"]:
        print(f"Reservation code: {result['reservation_code']}")
"""

import random
from typing import Dict
def booking_agent(venue_id: str, venue_name: str, user_count: int) -> Dict:
    """
    Simulates automated booking when interest threshold is reached.
    
    This is a mock implementation demonstrating the booking agent concept.
    In production, this would integrate with external booking APIs like:
    - OpenTable API (https://www.opentable.com/developers)
    - Resy API (https://resy.com/api)
    
    The agent triggers when 3 or more users express interest in a venue,
    simulating a group reservation request.
    
    Args:
        venue_id: The ID of the venue to book
        venue_name: The name of the venue (for message generation)
        user_count: The number of users interested in the venue
        
    Returns:
        Dictionary containing:
        - agent_triggered (bool): Whether the agent was activated
        - action (str): Type of action ("reservation_simulated" or None)
        - venue_id (str): ID of the venue (if triggered)
        - message (str): Human-readable message about the action
        - reservation_code (str): Mock reservation code (if triggered)
    """
    threshold = 3  # Trigger when 3+ users interested
    
    if user_count >= threshold:
        # Generate mock reservation code in format: LUNA-{venue_id}-{4_digits}
        reservation_code = f"LUNA-{venue_id}-{random.randint(1000, 9999)}"
        
        return {
            "agent_triggered": True,
            "action": "reservation_simulated",
            "venue_id": venue_id,
            "message": f"Mock booking agent: Reserved table for {user_count} at {venue_name}",
            "reservation_code": reservation_code
        }
    
    return {
        "agent_triggered": False
    }
