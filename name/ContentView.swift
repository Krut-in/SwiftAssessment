//
//  ContentView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Root view of the application containing the main tab navigation.
//  Manages the tab bar with two primary sections: Discover and Profile.
//  Also handles global booking agent alerts triggered from anywhere in the app.
//  
//  FEATURES:
//  - Tab-based navigation between Discover and Profile views
//  - Global alert system for booking agent confirmations
//  - Uses AppState singleton for cross-view state management
//
//  ARCHITECTURE NOTES:
//  - This is the only place where booking alerts are displayed
//  - AppState.shared is used to avoid multiple instances
//  - Alert binding uses AppState.showBookingAlert for automatic presentation
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    
    @State private var selectedTab = 0
    @StateObject private var appState = AppState.shared
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Discover Tab
            VenueFeedView()
                .tabItem {
                    Label("Discover", systemImage: "house.fill")
                }
                .tag(0)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
        }
        .alert("Booking Confirmed! 🎉", isPresented: $appState.showBookingAlert) {
            Button("OK") {
                appState.clearBookingAlert()
            }
        } message: {
            if let message = appState.bookingAgentMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
