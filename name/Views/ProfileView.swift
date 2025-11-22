//
//  ProfileView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  User profile view displaying user information and their saved venues.
//  Shows user avatar, bio, interests, and a grid of interested venues.
//  
//  KEY FEATURES:
//  - User profile header with avatar, name, and stats
//  - Interest tags with custom styling
//  - Grid layout for saved venues (2 columns)
//  - Pull-to-refresh support
//  - Empty state for users with no saved venues
//  - Navigation to venue details from grid
//  
//  LAYOUT:
//  - ScrollView with VStack for vertical layout
//  - LazyVGrid for efficient grid rendering
//  - Flexible grid items adapt to screen width
//  - Proper spacing and padding for visual hierarchy
//  
//  STATE MANAGEMENT:
//  - ProfileViewModel manages user data and venues
//  - Reloads on view appear to reflect latest changes
//  - Error handling with alerts
//  
//  UX PATTERNS:
//  - Loading state during initial fetch
//  - Error state with retry button
//  - Empty state guides users to discover venues
//  - Smooth transitions between states
//  
//  PERFORMANCE:
//  - LazyVGrid only renders visible items
//  - AsyncImage for progressive image loading
//  - Pull-to-refresh for manual updates
//

import SwiftUI

struct ProfileView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var appState = AppState.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.user == nil {
                    // Loading State
                    ProgressView("Loading profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = viewModel.errorMessage, viewModel.user == nil {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Profile")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.loadProfile()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let user = viewModel.user {
                    // Profile Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // User Header
                            VStack(spacing: 12) {
                                // User Avatar
                                AsyncImage(url: URL(string: user.avatar)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 120, height: 120)
                                            .overlay {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(.gray)
                                            }
                                    }
                                }
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                // User Name
                                Text(user.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                // Places Saved Count
                                Text("\(viewModel.interestedVenues.count) places saved")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // User Bio
                                if !user.displayBio.isEmpty {
                                    Text(user.displayBio)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                
                                // User Interests
                                if !user.displayInterests.isEmpty {
                                    HStack(spacing: 8) {
                                        ForEach(user.displayInterests, id: \.self) { interest in
                                            Text(interest.capitalized)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
                            // Action Items Section
                            if !viewModel.actionItems.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Action Items")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        Text("\(viewModel.actionItems.count)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.horizontal)
                                    
                                    ForEach(viewModel.actionItems) { item in
                                        ActionItemCard(
                                            actionItem: item,
                                            onComplete: {
                                                Task {
                                                    await viewModel.completeActionItem(item.id)
                                                }
                                            },
                                            onDismiss: {
                                                Task {
                                                    await viewModel.dismissActionItem(item.id)
                                                }
                                            }
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Interested Venues Grid
                            if !viewModel.interestedVenues.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Saved Places")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(viewModel.interestedVenues) { venue in
                                            NavigationLink(destination: VenueDetailView(venueId: venue.id)) {
                                                VenueGridCard(venue: venue)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                // Empty State
                                EmptyStateView(
                                    icon: "heart.slash",
                                    title: "No Saved Places",
                                    message: "Explore venues and tap the heart to save them",
                                    actionTitle: "Explore Venues",
                                    action: {
                                        // Navigate to Discover tab
                                        appState.selectedTab = 0
                                    }
                                )
                                .padding()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        // Haptic feedback on refresh start
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadProfile()
            }
            .onAppear {
                // Reload profile when view appears to show latest interests
                Task {
                    await viewModel.loadProfile()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil && viewModel.user != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Action Item Card

struct ActionItemCard: View {
    let actionItem: ActionItem
    let onComplete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Venue Image
                if let venue = actionItem.venue {
                    AsyncImage(url: URL(string: venue.image)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                        }
                    }
                    
                    // Venue Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(venue.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(actionItem.interested_user_ids.count) interested")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            
            // Description
            Text(actionItem.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Action Code
            Text(actionItem.action_code)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Timestamp
            Text(relativeTime(from: actionItem.created_at))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onComplete) {
                    Text("Mark Done")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func relativeTime(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return "Recently"
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "Created \(days)d ago"
        } else if hours > 0 {
            return "Created \(hours)h ago"
        } else {
            return "Created recently"
        }
    }
}

// MARK: - Venue Grid Card

struct VenueGridCard: View {
    let venue: Venue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Venue Image
            AsyncImage(url: URL(string: venue.image)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            ProgressView()
                        }
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Venue Name
            Text(venue.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
