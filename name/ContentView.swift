//
//  ContentView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Root view of the application containing the main tab navigation.
//  Manages the tab bar with two primary sections: Discover and Profile.
//  Also handles global action item toast notifications triggered from anywhere in the app.
//  
//  FEATURES:
//  - Tab-based navigation between Discover and Profile views
//  - Global toast overlay system for action item notifications
//  - Uses AppState singleton for cross-view state management
//
//  ARCHITECTURE NOTES:
//  - This is the only place where action item toasts are displayed
//  - AppState.shared is used to avoid multiple instances
//  - Toast overlay positioned above all content with proper z-index
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var appState = AppState.shared
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            TabView(selection: $appState.selectedTab) {
                // Discover Tab
                VenueFeedView()
                    .tabItem {
                        Label("Discover", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // For You Tab
                RecommendedFeedView()
                    .tabItem {
                        Label("For You", systemImage: "star.fill")
                    }
                    .tag(1)
                
                // Social Tab
                SocialFeedView()
                    .tabItem {
                        Label("Social", systemImage: "person.2.fill")
                    }
                    .tag(2)
                    .badge(appState.newSocialActivityCount > 0 ? appState.newSocialActivityCount : 0)
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
                    .badge(appState.actionItemCount > 0 ? "\(appState.actionItemCount)" : "")
            }
            
            // Global Action Item Toast Overlay
            ActionItemToast(
                actionItem: $appState.pendingActionItem,
                isShowing: $appState.showActionItemToast
            )
            .zIndex(999)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
