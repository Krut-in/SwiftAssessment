//
//  SocialModels.swift
//  name
//
//  Created by Krutin Rathod on 02/12/25.
//
//  DESCRIPTION:
//  Data models for the Social Feed feature, representing friend interest activities
//  and highlighted venues that have reached critical mass for group meetups.
//
//  MODELS:
//  - InterestActivity: Represents a single friend's interest action on a venue
//  - HighlightedVenue: Venues that have reached the interest threshold
//  - FriendSummary: Lightweight friend representation for avatar stacks
//
//  USAGE:
//  These models power the SocialFeedView, showing friend activities and
//  highlighting venues when multiple friends express interest.
//

import Foundation

// MARK: - Interest Activity Model

/// Represents a friend's interest activity for display in the social feed
struct InterestActivity: Codable, Identifiable, Hashable {
    let id: String
    let user: ActivityUser
    let venue: ActivityVenue
    let action: InterestAction
    let timestamp: Date
    let isActive: Bool
    
    /// Human-readable action description
    var actionDescription: String {
        switch action {
        case .interested:
            return "is interested in"
        case .notInterested:
            return "is no longer interested in"
        }
    }
    
    /// Check if this activity is from the current user
    func isCurrentUser(_ currentUserId: String) -> Bool {
        return user.id == currentUserId
    }
    
    /// Get display name - returns "You" if activity is from current user
    func displayName(currentUserId: String) -> String {
        if user.id == currentUserId {
            return "You"
        }
        return user.name
    }
    
    /// Get action description adjusted for current user
    func displayActionDescription(currentUserId: String) -> String {
        if user.id == currentUserId {
            switch action {
            case .interested:
                return "are interested in"
            case .notInterested:
                return "are no longer interested in"
            }
        }
        return actionDescription
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
        
        enum CodingKeys: String, CodingKey {
            case id
            case user
            case venue
            case action
            case timestamp
            case isActive = "is_active"
        }
    }
    
    // MARK: - Interest Action Enum
    
    /// Types of interest actions a user can perform
    enum InterestAction: String, Codable, Hashable {
        case interested = "interested"
        case notInterested = "not_interested"
    }
    
    // MARK: - Highlighted Venue Model
    
    /// Represents a venue that has reached the interest threshold among friends
    struct HighlightedVenue: Codable, Identifiable, Hashable {
        let id: String
        let venueId: String
        let venueName: String
        let venueImageURL: String
        let venueCategory: String
        let venueAddress: String
        let interestedFriends: [FriendSummary]
        let totalInterestedCount: Int
        let threshold: Int
        let lastActivityTimestamp: Date
        
        /// Whether this venue has met the highlight threshold
        var isHighlighted: Bool {
            totalInterestedCount >= threshold
        }
        
        /// Relative timestamp for the most recent activity
        var relativeTimestamp: String {
            let now = Date()
            let interval = now.timeIntervalSince(lastActivityTimestamp)
            
            let hours = Int(interval / 3600)
            let days = Int(interval / 86400)
            
            if hours < 1 {
                return "Active now"
            } else if hours < 24 {
                return "\(hours)h ago"
            } else if days == 1 {
                return "Yesterday"
            } else {
                return "\(days)d ago"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case venueId = "venue_id"
            case venueName = "venue_name"
            case venueImageURL = "venue_image_url"
            case venueCategory = "venue_category"
            case venueAddress = "venue_address"
            case interestedFriends = "interested_friends"
            case totalInterestedCount = "total_interested_count"
            case threshold
            case lastActivityTimestamp = "last_activity_timestamp"
        }
    }
    
    // MARK: - Friend Summary Model
    
    /// Lightweight friend representation for avatar stacks and lists
    struct FriendSummary: Codable, Identifiable, Hashable {
        let id: String
        let name: String
        let avatarURL: String
        let interestedTimestamp: Date
        
        /// First name for compact display
        var firstName: String {
            name.components(separatedBy: " ").first ?? name
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case avatarURL = "avatar_url"
            case interestedTimestamp = "interested_timestamp"
        }
    }
    
    // MARK: - Social Feed Response Models
    
    /// Response from GET /social/feed endpoint
    struct SocialFeedResponse: Codable {
        let activities: [InterestActivity]
        let highlightedVenues: [HighlightedVenue]
        let hasMore: Bool
        let page: Int
        let limit: Int
        let totalCount: Int
        
        enum CodingKeys: String, CodingKey {
            case activities = "interest_activities"
            case highlightedVenues = "highlighted_venues"
            case hasMore = "has_more"
            case page
            case limit
            case totalCount = "total_count"
        }
    }
    
    /// Request for broadcasting interest to friends
    struct BroadcastInterestRequest: Codable {
        let userId: String
        let venueId: String
        let action: InterestAction
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case venueId = "venue_id"
            case action
        }
    }
    
    /// Response from interest broadcast
    struct BroadcastInterestResponse: Codable {
        let success: Bool
        let activityId: String?
        let broadcastedTo: Int
        let message: String?
        
        enum CodingKeys: String, CodingKey {
            case success
            case activityId = "activity_id"
            case broadcastedTo = "broadcasted_to"
            case message
        }
    }

