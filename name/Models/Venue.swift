//
//  Venue.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Domain models for venue data used throughout the iOS application.
//  Provides two representations: full detail and list item summary.
//  
//  MODELS:
//  - Venue: Complete venue information for detail views
//  - VenueListItem: Lightweight summary for list/grid views
//  
//  DESIGN RATIONALE:
//  Two separate models optimize for different use cases:
//  - VenueListItem: Minimal data for feed performance
//  - Venue: Full details loaded on demand
//  
//  PROTOCOL CONFORMANCE:
//  - Codable: JSON serialization for API communication
//  - Identifiable: Required for SwiftUI ForEach loops
//  - Hashable: Enables Set operations and Equatable checks
//  
//  FIELD DETAILS:
//  - id: Unique identifier (e.g., "venue_1")
//  - name: Display name of the venue
//  - category: Type classification (Coffee Shop, Restaurant, etc.)
//  - description: Full text description (Venue only)
//  - image: URL string for venue photo
//  - address: Physical location (Venue only)
//  - interested_count: Number of users interested (VenueListItem only)
//  
//  USAGE:
//  - VenueListItem: Feed, search results, profile grids
//  - Venue: Detail view, booking confirmations
//  
//  SNAKE_CASE PROPERTIES:
//  Properties use snake_case to match backend API format.
//  CodingKeys explicitly map Swift names to JSON keys.
//

import Foundation

/// Represents a venue with full details
struct Venue: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let description: String
    let image: String
    let images: [String]?  // Optional array of image URLs for multi-image galleries
    let address: String
    let latitude: Double?
    let longitude: Double?
    let distance_km: Double?
    let interested_count: Int?  // For recommendation responses
    
    /// Returns all available images for the venue
    /// Falls back to single image if images array is not available
    var allImages: [String] {
        if let images = images, !images.isEmpty {
            return images
        }
        return [image]  // Backward compatibility: single image as array
    }
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case image
        case images  // New field for multi-image support
        case address
        case latitude
        case longitude
        case distance_km
        case interested_count  // For recommendation responses
    }
}

/// Represents a venue in list view with interested count
struct VenueListItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let image: String
    let interested_count: Int
    let distance_km: Double?
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case image
        case interested_count
        case distance_km
    }
}
