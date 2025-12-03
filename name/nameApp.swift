//
//  nameApp.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Main application entry point for the Luna venue discovery iOS app.
//  This file defines the SwiftUI App structure and initializes the root view.
//  
//  ARCHITECTURE:
//  - Uses SwiftUI's @main attribute to mark the app entry point
//  - ContentView serves as the root view containing tab navigation
//  - AppState is initialized as a singleton for global state management
//  - ThemeManager provides dark mode support with persistence
//  - NotificationService handles push notifications and permissions
//  - Deep link support via onOpenURL for luna:// scheme
//

import SwiftUI

@main
struct nameApp: App {
    
    // MARK: - Properties
    
    /// Theme manager for dark mode support
    @StateObject private var themeManager = ThemeManager()
    
    /// Notification service for push notifications
    private let notificationService = NotificationService.shared
    
    /// App state for global state management
    @ObservedObject private var appState = AppState.shared
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onOpenURL { url in
                    // Handle deep links (luna://venues/{id})
                    appState.handleDeepLink(url)
                }
                .task {
                    // Request notification permission on first launch
                    _ = await notificationService.requestPermission()
                }
        }
    }
}
