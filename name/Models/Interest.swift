//
//  Interest.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Domain model representing a user's interest in a specific venue.
//  Implements many-to-many relationship between users and venues.
//  Includes custom date decoding for backend timestamp format compatibility.
//  
//  FIELDS:
//  - user_id: ID of the user expressing interest
//  - venue_id: ID of the venue of interest
//  - timestamp: When the interest was expressed
//  
//  PROTOCOL CONFORMANCE:
//  - Codable: JSON serialization with custom date handling
//  - Hashable: Enables Set operations for deduplication
//  
//  CUSTOM DECODING:
//  The init(from:) decoder handles two timestamp formats:
//  1. ISO8601 string (from backend API)
//  2. Native Date object (for local operations)
//  
//  This flexibility ensures compatibility with various backend
//  date serialization strategies without breaking the client.
//  
//  BACKEND INTEGRATION:
//  - Matches backend Interest model structure
//  - Snake_case naming follows Python conventions
//  - CodingKeys provide explicit JSON mapping
//  
//  USAGE:
//  - Tracking user-venue relationships
//  - Temporal analysis (when interests were expressed)
//  - Sorting interests by recency
//  - Calculating interested user counts
//  
//  ERROR HANDLING:
//  Custom decoder throws descriptive DecodingError if:
//  - Timestamp string is malformed
//  - Timestamp cannot be parsed as Date or String
//  - Required fields are missing
//  
//  NOTES:
//  While this model exists, the iOS app primarily uses
//  AppState.interestedVenueIds (Set<String>) for performance.
//  This model is mainly used for API responses that include timestamps.
//

import Foundation

/// Represents a user's interest in a venue
struct Interest: Codable, Hashable {
    let user_id: String
    let venue_id: String
    let timestamp: Date
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case user_id
        case venue_id
        case timestamp
    }
    
    /// Custom date decoding to handle ISO8601 format from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user_id = try container.decode(String.self, forKey: .user_id)
        venue_id = try container.decode(String.self, forKey: .venue_id)
        
        // Try to decode timestamp as string first, then convert to Date
        if let timestampString = try? container.decode(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .timestamp, in: container, debugDescription: "Date string does not match expected format")
            }
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    /// Initialize with direct values (for testing or manual creation)
    init(user_id: String, venue_id: String, timestamp: Date) {
        self.user_id = user_id
        self.venue_id = venue_id
        self.timestamp = timestamp
    }
}
