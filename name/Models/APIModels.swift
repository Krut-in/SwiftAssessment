//
//  APIModels.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Data transfer objects (DTOs) for API communication with the Luna backend.
//  Defines request and response models for all API endpoints.
//  
//  MODEL ORGANIZATION:
//  - Response Wrappers: Top-level API response structures
//  - Request Models: Payload structures for POST requests
//  - Nested Models: Referenced from other model files (User, Venue)
//  
//  API ENDPOINT MAPPING:
//  - VenuesResponse: GET /venues
//  - VenueDetailResponse: GET /venues/{id}
//  - UserProfileResponse: GET /users/{id}
//  - RecommendationsResponse: GET /recommendations
//  - InterestRequest: POST /interests (request)
//  - InterestResponse: POST /interests (response)
//  
//  CODABLE CONFORMANCE:
//  - All models conform to Codable for JSON serialization
//  - Snake_case property names match backend convention
//  - Optional fields handle missing backend data gracefully
//  
//  SPECIAL HANDLING:
//  - RecommendationItem conforms to Identifiable for ForEach loops
//  - Hashable conformance enables Set operations
//  - Computed id property derived from nested venue.id
//  
//  VALIDATION:
//  - Models validate automatically via Codable
//  - Decoding errors propagate to APIError.decodingError
//  - Type safety enforced at compile time
//

import Foundation

// MARK: - API Response Wrappers

/// Response from GET /venues endpoint
struct VenuesResponse: Codable {
    let venues: [VenueListItem]
}

/// Response from GET /venues/{venue_id} endpoint
struct VenueDetailResponse: Codable {
    let venue: Venue
    let interested_users: [User]
}

/// Response from GET /users/{user_id} endpoint
struct UserProfileResponse: Codable {
    let user: User
    let interested_venues: [Venue]
}

/// Response from GET /recommendations endpoint
struct RecommendationsResponse: Codable {
    let recommendations: [RecommendationItem]
}

/// Individual recommendation item with score and reason
struct RecommendationItem: Codable, Identifiable, Hashable {
    let venue: Venue
    let score: Double
    let reason: String
    
    // Computed property for Identifiable conformance
    var id: String {
        venue.id
    }
}

/// Response from POST /interests endpoint
struct InterestResponse: Codable {
    let success: Bool
    let agent_triggered: Bool?
    let message: String?
    let reservation_code: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case agent_triggered
        case message
        case reservation_code
    }
}

// MARK: - Request Models

/// Request body for POST /interests endpoint
struct InterestRequest: Codable {
    let user_id: String
    let venue_id: String
}
