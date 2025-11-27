//
//  NotificationService.swift
//  name
//
//  Created by Krutin Rathod on 27/11/25.
//
//  DESCRIPTION:
//  Service for managing push notifications and local notifications.
//  Handles permission requests, APNs registration, and notification delivery.
//  
//  FEATURES:
//  - Request notification permissions
//  - Register for APNs (Apple Push Notification service)
//  - Send local notifications for demo mode
//  - Handle notification responses for deep linking
//  
//  ARCHITECTURE:
//  - Protocol-based design for testability
//  - Singleton pattern for global access
//  - @MainActor for thread-safe UI updates
//  
//  USAGE:
//  await NotificationService.shared.requestPermission()
//  await NotificationService.shared.sendLocalNotification(
//      title: "New Booking Opportunity",
//      body: "3 friends interested in Blue Bottle Coffee!",
//      venueId: "venue_1"
//  )
//

import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Service Protocol

/// Protocol defining notification operations
@MainActor
protocol NotificationServiceProtocol {
    /// Request notification permission from user
    func requestPermission() async -> Bool
    
    /// Register for remote notifications (APNs)
    func registerForRemoteNotifications()
    
    /// Send a local notification
    func sendLocalNotification(title: String, body: String, venueId: String?) async
    
    /// Handle device token registration
    func didRegisterForRemoteNotifications(deviceToken: Data)
    
    /// Handle device token registration failure
    func didFailToRegisterForRemoteNotifications(error: Error)
}

// MARK: - Notification Service Implementation

/// Service for managing local and remote notifications
@MainActor
class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Stored device token for APNs (hex string format)
    private(set) var deviceToken: String?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission Management
    
    /// Requests notification permission from the user
    /// - Returns: True if permission granted, false otherwise
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            if granted {
                print("✅ Notification permission granted")
                registerForRemoteNotifications()
            } else {
                print("⚠️ Notification permission denied")
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Checks current notification authorization status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Remote Notifications (APNs)
    
    /// Register for remote push notifications
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Called when device token is successfully registered
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        
        print("📱 APNs Device Token: \(token)")
        
        // TODO: Send token to backend server for push notification delivery
        // In production, you would send this to your server:
        // await apiService.registerDeviceToken(token: token, userId: currentUserId)
    }
    
    /// Called when device token registration fails
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Local Notifications
    
    /// Sends a local notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    ///   - venueId: Optional venue ID for deep linking
    func sendLocalNotification(title: String, body: String, venueId: String?) async {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Add venue ID to userInfo for deep linking
        if let venueId = venueId {
            content.userInfo = ["venueId": venueId]
        }
        
        // Create trigger (1 second delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request with unique identifier
        let requestId = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
            print("📬 Local notification scheduled: \(title)")
        } catch {
            print("❌ Error scheduling notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when notification is received while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    /// Called when user taps on notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle deep link to venue
        if let venueId = userInfo["venueId"] as? String {
            await handleNotificationTap(venueId: venueId)
        }
    }
    
    /// Handles notification tap for deep linking
    private func handleNotificationTap(venueId: String) async {
        print("🔔 Notification tapped for venue: \(venueId)")
        
        // Construct deep link URL
        if let url = URL(string: "luna://venues/\(venueId)") {
            await MainActor.run {
                AppState.shared.handleDeepLink(url)
            }
        }
    }
}
