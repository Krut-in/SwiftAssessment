//
//  Interest.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
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
