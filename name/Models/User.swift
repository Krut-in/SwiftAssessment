//
//  User.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  User domain model representing app users and their profile information.
//  Includes helper computed properties for safe optional value access.
//  
//  FIELDS:
//  - id: Unique user identifier (e.g., "user_1")
//  - name: User's display name
//  - avatar: URL string for profile picture
//  - bio: Optional user biography/description
//  - interests: Optional array of interest categories
//  
//  PROTOCOL CONFORMANCE:
//  - Codable: Automatic JSON serialization/deserialization
//  - Identifiable: Required for SwiftUI ForEach and List views
//  - Hashable: Enables Set operations and equality comparisons
//  
//  COMPUTED PROPERTIES:
//  - displayBio: Returns bio or empty string (never nil)
//  - displayInterests: Returns interests or empty array (never nil)
//  
//  These computed properties simplify UI code by eliminating optional unwrapping:
//    // Instead of: if let bio = user.bio { Text(bio) }
//    // You can use: Text(user.displayBio)
//  
//  BACKEND INTEGRATION:
//  - CodingKeys map to backend's snake_case format
//  - Optional fields handle missing backend data gracefully
//  - All fields match API response structure exactly
//  
//  USAGE CONTEXTS:
//  - Profile view: Full user display with bio and interests
//  - Venue detail: Interested users list (avatar and name only)
//  - Recommendations: User interest matching
//

import Foundation

/// Represents a user in the Luna venue discovery system
struct User: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let avatar: String
    let bio: String?
    let interests: [String]?
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatar
        case bio
        case interests
    }
    
    /// Helper computed properties with default values
    var displayBio: String {
        bio ?? ""
    }
    
    var displayInterests: [String] {
        interests ?? []
    }
}
