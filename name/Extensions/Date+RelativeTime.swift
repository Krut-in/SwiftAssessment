//
//  Date+RelativeTime.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Extension providing relative time formatting for Date objects.
//  Consolidates duplicate time formatting logic used across multiple ViewModels.
//  
//  PURPOSE:
//  - Single source of truth for relative time display
//  - Eliminates 63 lines of duplicate code across 3 ViewModels
//  - Provides consistent time formatting throughout the app
//  
//  USAGE:
//  let date = Date()
//  let relativeString = date.relativeTimeString()
//  // Returns: "Just now", "5 minutes ago", "2 hours ago", "3 days ago"
//  
//  TIME RANGES:
//  - < 60 seconds: "Just now"
//  - < 60 minutes: "X minute(s) ago"
//  - < 24 hours: "X hour(s) ago"
//  - >= 24 hours: "X day(s) ago"
//  
//  THREAD SAFETY:
//  - Pure function with no side effects
//  - Safe to call from any thread
//  - No shared mutable state
//

import Foundation

extension Date {
    
    /// Returns a human-readable relative time string from this date to now.
    ///
    /// Calculates the time difference between this date and the current time,
    /// then formats it as a user-friendly string.
    ///
    /// - Returns: Formatted relative time string
    ///
    /// - Examples:
    ///   - 30 seconds ago: "Just now"
    ///   - 5 minutes ago: "5 minutes ago"
    ///   - 1 minute ago: "1 minute ago"
    ///   - 2 hours ago: "2 hours ago"
    ///   - 1 hour ago: "1 hour ago"
    ///   - 3 days ago: "3 days ago"
    ///   - 1 day ago: "1 day ago"
    func relativeTimeString() -> String {
        let now = Date()
        let seconds = Int(now.timeIntervalSince(self))
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
