//
//  AnalyticsService.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Protocol-based analytics service for tracking user actions and events.
//  Provides structured event logging with consistent schema for easy integration
//  with analytics platforms like Firebase, Mixpanel, or Amplitude.
//  
//  FEATURES:
//  - Protocol-first design for testability
//  - Strongly-typed event parameters
//  - Console logging for demo/development
//  - Ready for production analytics integration
//  
//  TRACKED EVENTS:
//  - venue_viewed: User views venue detail
//  - venue_interested: User toggles interest
//  - recommendation_clicked: User taps recommendation
//  - filter_applied: User applies filters
//  - map_pin_tapped: User taps map pin
//  
//  USAGE:
//  let analytics = AnalyticsService.shared
//  analytics.track(event: "venue_viewed", properties: ["venue_id": "venue_1"])
//

import Foundation

/// Protocol defining analytics tracking interface
protocol AnalyticsServiceProtocol {
    func track(event: String, properties: [String: Any]?)
    func setUserProperty(key: String, value: Any)
}

/// Mock analytics service that logs events to console
/// In production, replace with Firebase Analytics, Mixpanel, etc.
class AnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Event Tracking
    
    /// Track an analytics event with optional properties
    /// - Parameters:
    ///   - event: Event name (e.g., "venue_viewed")
    ///   - properties: Dictionary of event properties
    func track(event: String, properties: [String: Any]? = nil) {
        var eventData: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let properties = properties {
            eventData["properties"] = properties
        }
        
        // Log as JSON for demo purposes
        if let jsonData = try? JSONSerialization.data(withJSONObject: eventData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📊 Analytics Event:\n\(jsonString)")
        }
    }
    
    /// Set a user property for analytics
    /// - Parameters:
    ///   - key: Property key (e.g., "user_id")
    ///   - value: Property value
    func setUserProperty(key: String, value: Any) {
        print("📊 Analytics User Property: \(key) = \(value)")
    }
}

// MARK: - Event Constants

extension AnalyticsService {
    
    /// Standard event names
    enum Event {
        static let venueViewed = "venue_viewed"
        static let venueInterested = "venue_interested"
        static let recommendationClicked = "recommendation_clicked"
        static let filterApplied = "filter_applied"
        static let mapPinTapped = "map_pin_tapped"
        static let socialActivityTapped = "social_activity_tapped"
    }
    
    /// Standard property keys
    enum PropertyKey {
        static let venueId = "venue_id"
        static let venueName = "venue_name"
        static let category = "category"
        static let distanceKm = "distance_km"
        static let isInterested = "is_interested"
        static let filterType = "filter_type"
        static let filterValue = "filter_value"
        static let reason = "reason"
        static let score = "score"
        static let action = "action"
    }
}
