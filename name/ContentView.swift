//
//  ContentView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
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
