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
                                VStack(spacing: 16) {
                                    Image(systemName: "heart.slash")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    
                                    Text("No Saved Places")
                                        .font(.headline)
                                    
                                    Text("Explore venues and tap the heart to save them")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .refreshable {
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
