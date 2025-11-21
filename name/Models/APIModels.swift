//
//  APIModels.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
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
