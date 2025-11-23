"""
Distance calculation utilities for geographic coordinates.

This module provides functions to calculate distances between two points
on Earth using the Haversine formula, which accounts for the spherical
nature of the planet.

FUNCTIONS:
    haversine_distance: Calculate distance between two lat/lon points
    calculate_proximity_score: Convert distance to recommendation score

USAGE:
    from utils.distance import haversine_distance, calculate_proximity_score
    
    distance = haversine_distance(40.7589, -73.9851, 40.7406, -74.0014)
    score = calculate_proximity_score(distance)
"""

import math


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points on Earth.
    
    Uses the Haversine formula to compute the distance between two geographic
    coordinates. The formula accounts for the spherical nature of Earth.
    
    Formula:
        a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
        c = 2 * atan2(√a, √(1−a))
        d = R * c
    
    Args:
        lat1: Latitude of first point in decimal degrees (-90 to 90)
        lon1: Longitude of first point in decimal degrees (-180 to 180)
        lat2: Latitude of second point in decimal degrees (-90 to 90)
        lon2: Longitude of second point in decimal degrees (-180 to 180)
    
    Returns:
        Distance in kilometers, rounded to 1 decimal place.
        Returns 0.0 if the points are the same location.
    
    Examples:
        >>> haversine_distance(40.7589, -73.9851, 40.7406, -74.0014)
        2.3
        >>> haversine_distance(40.7589, -73.9851, 40.7589, -73.9851)
        0.0
    """
    # Earth's radius in kilometers
    R = 6371.0
    
    # Convert latitude and longitude from degrees to radians
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    # Calculate differences
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    # Haversine formula
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    # Calculate distance
    distance = R * c
    
    # Round to 1 decimal place
    return round(distance, 1)


def calculate_proximity_score(distance_km: float) -> float:
    """
    Convert distance in kilometers to a proximity score for recommendations.
    
    Uses a tiered scoring system that heavily favors nearby venues:
    - 0-1 km: 1.0 (perfect score)
    - 1-3 km: 0.8 (very close)
    - 3-5 km: 0.6 (moderate)
    - 5-8 km: 0.4 (far)
    - 8+ km:  0.2 (very far)
    
    Args:
        distance_km: Distance in kilometers (must be >= 0)
    
    Returns:
        Proximity score between 0.2 and 1.0
    
    Examples:
        >>> calculate_proximity_score(0.5)
        1.0
        >>> calculate_proximity_score(2.0)
        0.8
        >>> calculate_proximity_score(10.0)
        0.2
    """
    if distance_km <= 1:
        return 1.0
    elif distance_km <= 3:
        return 0.8
    elif distance_km <= 5:
        return 0.6
    elif distance_km <= 8:
        return 0.4
    else:
        return 0.2
