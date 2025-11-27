//
//  Activity.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Domain model for user activities in the social feed.
//  Represents actions like interests, bookings, and check-ins performed by friends.
//  
//  USAGE:
//  Activities are fetched from the /activities endpoint and displayed in SocialFeedView.
//  Each activity shows who did what at which venue.
//  
//  FIELDS:
//  - id: Unique identifier for the activity
//  - user: ActivityUser with name and avatar
//  - venue: ActivityVenue with basic info
//  - action: Type of action ("interested", "booked", "checked_in")
//  - timestamp: When the activity occurred
//

import Foundation

/// Represents a user in an activity
struct ActivityUser: Codable, Hashable {
    let id: String
    let name: String
    let avatar: String
}

/// Represents a venue in an activity
struct ActivityVenue: Codable, Hashable {
    let id: String
    let name: String
    let category: String
    let image: String
}

/// Represents a social activity performed by a user
struct Activity: Codable, Identifiable, Hashable {
    let id: String
    let user: ActivityUser
    let venue: ActivityVenue
    let action: String  // "interested", "booked", "checked_in"
    let timestamp: Date
    
    /// Custom coding keys forJSON serialization
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case venue
        case action
        case timestamp
    }
    
    /// Human-readable action description
    var actionDescription: String {
        switch action {
        case "interested":
            return "marked as interested"
        case "booked":
            return "booked"
        case "checked_in":
            return "checked in at"
        default:
            return action
        }
    }
    
    /// Relative timestamp (e.g., "2h ago", "yesterday")
    var relativeTimestamp: String {
        let now = Date()
        let interval = now.timeIntervalSince(timestamp)
        
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else if days == 1 {
            return "yesterday"
        } else if days < 7 {
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: timestamp)
        }
    }
}

/// Response model for activities endpoint
struct ActivitiesResponse: Codable {
    let activities: [Activity]
    let page: Int
    let limit: Int
    let total_count: Int
    
    enum CodingKeys: String, CodingKey {
        case activities
        case page
        case limit
        case total_count
    }
}
