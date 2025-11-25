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
//  - Uses centralized Theme for consistent styling
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
                    VStack(spacing: Theme.Layout.spacing) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.warning)
                        
                        Text("Error Loading Profile")
                            .font(Theme.Fonts.headline)
                        
                        Text(errorMessage)
                            .font(Theme.Fonts.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
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
                        VStack(spacing: Theme.Layout.largeSpacing) {
                            // User Header
                            VStack(spacing: Theme.Layout.spacing) {
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
                                            .fill(Theme.Colors.secondaryBackground)
                                            .frame(width: 120, height: 120)
                                            .overlay {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(Theme.Colors.textSecondary)
                                            }
                                    }
                                }
                                .shadow(color: Theme.Colors.shadow, radius: 8, x: 0, y: 4)
                                
                                // User Name
                                Text(user.name)
                                    .font(Theme.Fonts.title)
                                    .fontWeight(.bold)
                                
                                // Places Saved Count
                                Text("\(viewModel.interestedVenues.count) places saved")
                                    .font(Theme.Fonts.subheadline)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                // User Bio
                                if !user.displayBio.isEmpty {
                                    Text(user.displayBio)
                                        .font(Theme.Fonts.body)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                
                                // User Interests
                                if !user.displayInterests.isEmpty {
                                    HStack(spacing: Theme.Layout.smallSpacing) {
                                        ForEach(user.displayInterests, id: \.self) { interest in
                                            Text(interest.capitalized)
                                                .font(Theme.Fonts.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Theme.Colors.accent)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
                            // Action Items Section
                            if !viewModel.actionItems.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                                    HStack {
                                        Text("Action Items")
                                            .font(Theme.Fonts.title2)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        Text("\(viewModel.actionItems.count)")
                                            .font(Theme.Fonts.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.Colors.accent)
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
                                VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                                    Text("Saved Places")
                                        .font(Theme.Fonts.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: Theme.Layout.spacing),
                                        GridItem(.flexible(), spacing: Theme.Layout.spacing)
                                    ], spacing: Theme.Layout.spacing) {
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
        VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
            HStack(spacing: Theme.Layout.spacing) {
                // Venue Image
                if let venue = actionItem.venue {
                    AsyncImage(url: URL(string: venue.image)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                        default:
                            RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius)
                                .fill(Theme.Colors.secondaryBackground)
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                        }
                    }
                    
                    // Venue Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(Theme.Fonts.headline)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text(venue.category)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(Theme.Fonts.caption)
                            Text("\(actionItem.interested_user_ids.count) interested")
                                .font(Theme.Fonts.caption)
                        }
                        .foregroundColor(Theme.Colors.accent)
                    }
                    
                    Spacer()
                }
            }
            
            // Description
            Text(actionItem.description)
                .font(Theme.Fonts.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Action Code
            Text(actionItem.action_code)
                .font(Theme.Fonts.caption)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.Colors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Timestamp
            Text(relativeTime(from: actionItem.created_at))
                .font(Theme.Fonts.caption)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Action Buttons
            HStack(spacing: Theme.Layout.spacing) {
                Button(action: onComplete) {
                    Text("Mark Done")
                        .font(Theme.Fonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.success)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                }
                
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(Theme.Fonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                }
            }
        }
        .padding(Theme.Layout.padding)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        .shadow(color: Theme.Colors.shadow, radius: 8, x: 0, y: 2)
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
        VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
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
                        .fill(Theme.Colors.secondaryBackground)
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            ProgressView()
                        }
                case .failure:
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            
            // Venue Name
            Text(venue.name)
                .font(Theme.Fonts.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .shadow(color: Theme.Colors.shadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
