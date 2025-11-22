//
//  VenueDetailView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Detailed view for a single venue showing full information and interested users.
//  Implements custom navigation with overlay back button and interest toggling.
//  
//  KEY FEATURES:
//  - Hero image with overlay back button (custom navigation)
//  - Interest button with loading states and animations
//  - List of interested users with avatars
//  - Category-based color coding for visual hierarchy
//  - Success/error message handling
//  - Automatic booking agent alert propagation
//  
//  DESIGN PATTERNS:
//  - Custom back button (navigationBarBackButtonHidden)
//  - AsyncImage for lazy image loading
//  - Optimistic UI updates via AppState
//  - Observable state synchronization with ViewModel
//  
//  STATE MANAGEMENT:
//  - VenueDetailViewModel manages venue data and loading
//  - AppState handles interest toggle and alert state
//  - Interest state synced via Combine observers
//  
//  UX CONSIDERATIONS:
//  - Disabled button during interest toggle prevents double-taps
//  - Success messages auto-dismiss after 2 seconds
//  - Booking agent messages shown in global alert (ContentView)
//  - Reload venue detail after interest toggle to update count
//

import SwiftUI

struct VenueDetailView: View {
    
    // MARK: - Properties
    
    let venueId: String
    @StateObject private var viewModel: VenueDetailViewModel
    @StateObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(venueId: String) {
        self.venueId = venueId
        _viewModel = StateObject(wrappedValue: VenueDetailViewModel(venueId: venueId))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let venue = viewModel.venue {
                    // Hero Image with overlay back button
                    ZStack(alignment: .topLeading) {
                        AsyncImage(url: URL(string: venue.image)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 300)
                                    .clipped()
                            default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 300)
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                        }
                        
                        // Back button overlay
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding([.leading, .top], 16)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        // Venue Name
                        Text(venue.name)
                            .font(.system(size: 28, weight: .bold))
                        
                        // Category Badge and Address
                        HStack(spacing: 12) {
                            Text(venue.category)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(categoryColor(for: venue.category))
                                .clipShape(Capsule())
                            
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle")
                                    .font(.caption)
                                Text(venue.address)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // Interested Count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(viewModel.interestedUsers.count) people interested")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                        
                        // Interest Button
                        Button {
                            Task {
                                await viewModel.toggleInterest()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isTogglingInterest {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: viewModel.isInterested ? "heart.fill" : "heart")
                                    Text(viewModel.isInterested ? "Interested" : "I'm Interested")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.isInterested ? Color.red : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isTogglingInterest)
                        .padding(.vertical, 8)
                        
                        // Success Message
                        if let successMessage = viewModel.successMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(successMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // People Who Want to Go Section
                        if !viewModel.interestedUsers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("People Who Want to Go")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.interestedUsers) { user in
                                            VStack(spacing: 8) {
                                                AsyncImage(url: URL(string: user.avatar)) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 60, height: 60)
                                                            .clipShape(Circle())
                                                    default:
                                                        Circle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(width: 60, height: 60)
                                                            .overlay {
                                                                Image(systemName: "person.fill")
                                                                    .foregroundColor(.gray)
                                                            }
                                                    }
                                                }
                                                
                                                Text(user.name)
                                                    .font(.system(size: 12))
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 70)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(venue.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                } else if viewModel.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView("Loading venue details...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Venue")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.loadVenueDetail()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(height: 400)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadVenueDetail()
        }
    }
    
    // MARK: - Helper Methods
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "coffee shop", "coffee":
            return Color.brown
        case "restaurant", "food":
            return Color.orange
        case "bar":
            return Color.purple
        case "cultural", "museum":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VenueDetailView(venueId: "venue_1")
    }
}
