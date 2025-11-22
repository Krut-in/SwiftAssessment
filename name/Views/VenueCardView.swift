//
//  VenueCardView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Reusable card component displaying venue preview information in the feed.
//  Implements inline interest toggling with optimistic updates and animations.
//  
//  KEY FEATURES:
//  - Aspect ratio constrained venue image (4:3)
//  - Category badge with color coding
//  - Inline heart button for interest toggling
//  - Animated heart interaction (scale effect)
//  - Optimistic interest count updates
//  - Error recovery with count reversion
//  
//  DESIGN DECISIONS:
//  - Card shadow for depth perception
//  - AsyncImage with loading states
//  - Proper fallback for failed image loads
//  - Category colors match detail view for consistency
//  
//  INTERACTION:
//  - Heart button tap triggers animation
//  - Optimistic update shows immediate feedback
//  - Reverts on API error for accuracy
//  - Booking agent responses preserve optimistic update
//  
//  STATE MANAGEMENT:
//  - Local count state for optimistic updates
//  - AppState for persistent interest tracking
//  - Computed property for interest status
//  
//  PERFORMANCE:
//  - Lightweight view for list scrolling
//  - AsyncImage prevents blocking main thread
//  - Animation isolated to button scale only
//  
//  ACCESSIBILITY:
//  - Proper button labels for VoiceOver
//  - Semantic image presentation
//  - Clear visual hierarchy
//

import SwiftUI

struct VenueCardView: View {
    
    // MARK: - Properties
    
    let venue: VenueListItem
    @StateObject private var appState = AppState.shared
    @State private var isAnimating = false
    @State private var localInterestedCount: Int
    
    // MARK: - Initialization
    
    init(venue: VenueListItem) {
        self.venue = venue
        _localInterestedCount = State(initialValue: venue.interested_count)
    }
    
    // MARK: - Computed Properties
    
    private var isInterested: Bool {
        appState.isInterested(in: venue.id)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Venue Image
            AsyncImage(url: URL(string: venue.image)) { phase in
                switch phase {
                case .empty:
                    // Placeholder while loading
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    // Successfully loaded image
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                case .failure:
                    // Failed to load image
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                @unknown default:
                    // Fallback for future cases
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                }
            }
            .clipped()
            
            // Venue Info
            VStack(alignment: .leading, spacing: 8) {
                // Category Badge and Heart Button
                HStack {
                    // Category Badge
                    Text(venue.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor(for: venue.category))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Heart Button
                    Button {
                        handleInterestTap()
                    } label: {
                        Image(systemName: isInterested ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isInterested ? .red : .gray)
                    }
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                }
                .padding(.top, 12)
                
                // Venue Name
                Text(venue.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Interested Count
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(localInterestedCount) people interested")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    /// Handles interest button tap with animation
    private func handleInterestTap() {
        // Trigger animation
        isAnimating = true
        
        // Optimistically update the count
        let wasInterested = isInterested
        if wasInterested {
            localInterestedCount = max(0, localInterestedCount - 1)
        } else {
            localInterestedCount += 1
        }
        
        // Toggle interest via AppState
        Task {
            do {
                let response = try await appState.toggleInterest(venueId: venue.id)
                
                // Don't revert if booking agent was triggered - the actual count is now different
                // The count will be updated when user navigates to detail view
                if response.agent_triggered == true {
                    // Keep the optimistic update for better UX
                }
            } catch {
                // Revert count on error
                if wasInterested {
                    localInterestedCount += 1
                } else {
                    localInterestedCount = max(0, localInterestedCount - 1)
                }
                print("Failed to toggle interest: \(error.localizedDescription)")
            }
        }
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = false
        }
    }
    
    /// Returns a color based on venue category
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "coffee shop", "coffee":
            return Color.blue
        case "restaurant", "food":
            return Color.orange
        case "bar", "nightlife":
            return Color.purple
        case "museum", "cultural", "culture":
            return Color.green
        default:
            return Color.gray
        }
    }
}

// MARK: - Preview

#Preview {
    VenueCardView(venue: VenueListItem(
        id: "venue_1",
        name: "Blue Bottle Coffee",
        category: "Coffee Shop",
        image: "https://picsum.photos/400/300",
        interested_count: 5
    ))
    .padding()
}
