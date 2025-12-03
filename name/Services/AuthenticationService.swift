//
//  AuthenticationService.swift
//  name
//
//  Created by Krutin Rathod on 27/11/25.
//
//  DESCRIPTION:
//  Authentication service for managing user sessions in demo mode.
//  Provides user switching capability with UserDefaults persistence.
//  
//  ARCHITECTURE:
//  - Protocol-based design for testability and future real auth integration
//  - Mock implementation with predefined demo users
//  - UserDefaults for session persistence across app launches
//  
//  DEMO USERS:
//  - user_1: Alex Chen (default)
//  - user_2: Jordan Kim
//  - user_3: Sam Rivera
//  - user_4: Taylor Lee
//  
//  USAGE:
//  let authService = MockAuthenticationService.shared
//  let currentUser = authService.getCurrentUserId()
//  authService.switchUser(to: "user_2")
//  
//  THREAD SAFETY:
//  - All operations are @MainActor to ensure thread-safe UI updates
//  - UserDefaults access is thread-safe by default
//

import Foundation
import SwiftUI

// MARK: - Authentication Service Protocol

/// Protocol defining authentication operations for user management
@MainActor
protocol AuthenticationServiceProtocol {
    /// Get the currently authenticated user ID
    func getCurrentUserId() -> String
    
    /// Switch to a different user
    /// - Parameter userId: The user ID to switch to
    func switchUser(to userId: String)
    
    /// Get list of all available demo users
    func getAvailableUsers() -> [DemoUser]
}

// MARK: - Demo User Model

/// Represents a demo user for authentication testing
struct DemoUser: Identifiable, Codable {
    let id: String
    let name: String
    let avatar: String
    
    var displayName: String {
        name
    }
}

// MARK: - Mock Authentication Service

/// Mock authentication service for demo mode
/// Uses UserDefaults to persist selected user across app launches
@MainActor
class MockAuthenticationService: AuthenticationServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = MockAuthenticationService()
    
    // MARK: - Constants
    
    private let userDefaultsKey = "luna_selected_user_id"
    private let defaultUserId = "user_1"
    
    // MARK: - Demo Users
    
    private let demoUsers: [DemoUser] = [
        DemoUser(
            id: "user_1",
            name: "Alex Chen",
            avatar: "https://i.pravatar.cc/150?img=1"
        ),
        DemoUser(
            id: "user_2",
            name: "Jordan Kim",
            avatar: "https://i.pravatar.cc/150?img=2"
        ),
        DemoUser(
            id: "user_3",
            name: "Sam Rivera",
            avatar: "https://i.pravatar.cc/150?img=3"
        ),
        DemoUser(
            id: "user_4",
            name: "Taylor Lee",
            avatar: "https://i.pravatar.cc/150?img=4"
        )
    ]
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default user if none is set
        if UserDefaults.standard.string(forKey: userDefaultsKey) == nil {
            UserDefaults.standard.set(defaultUserId, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Protocol Methods
    
    func getCurrentUserId() -> String {
        return UserDefaults.standard.string(forKey: userDefaultsKey) ?? defaultUserId
    }
    
    func switchUser(to userId: String) {
        // Validate that user exists
        guard demoUsers.contains(where: { $0.id == userId }) else {
            print("⚠️ Warning: Attempted to switch to invalid user ID: \(userId)")
            return
        }
        
        UserDefaults.standard.set(userId, forKey: userDefaultsKey)
        print("✅ Switched to user: \(userId)")
    }
    
    func getAvailableUsers() -> [DemoUser] {
        return demoUsers
    }
}
