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
//  - Category badge with color-coded visual hierarchy
//  - Inline heart button for interest toggling with haptic feedback
//  - Animated heart interaction with spring physics
//  - Optimistic interest count updates for immediate feedback
//  - Robust error recovery with count reversion
//  - Proper pluralization for interest count display
//  
//  DESIGN DECISIONS:
//  - Card shadow for depth perception and visual separation
//  - AsyncImage with comprehensive loading state handling
//  - Proper fallback for failed image loads (placeholder icon)
//  - Category colors consistent across all venue views
//  - Touch targets meet minimum 44x44pt accessibility guidelines
//  
//  INTERACTION:
//  - Heart button tap triggers immediate animation and haptic feedback
//  - Optimistic update shows predicted result before API response
//  - Rapid tap prevention avoids race conditions
//  - Reverts on API error to maintain data accuracy
//  - Booking agent responses preserve optimistic update
//  - Parent view notified on successful toggle for list refresh
//  
//  STATE MANAGEMENT:
//  - ObservedObject for AppState (shared singleton, not owned by this view)
//  - Local @State for interested count (supports optimistic updates)
//  - Local @State for animation trigger (transient UI state)
//  - Computed property for interest status derived from AppState
//  
//  PERFORMANCE:
//  - Lightweight view optimized for scrolling lists
//  - AsyncImage prevents blocking main thread
//  - Animation isolated to button scale only
//  - Efficient count update without full view refresh
//  
//  ACCESSIBILITY:
//  - VoiceOver labels for all interactive elements
//  - Semantic accessibility hints for button actions
//  - Proper accessibility element grouping
//  - Clear visual hierarchy with sufficient contrast
//
//  ERROR HANDLING:
//  - Image load failures show placeholder icon
//  - Toggle failures revert optimistic updates
//  - All errors logged for debugging without crashing UI
//  - Graceful degradation for network issues
//

import SwiftUI

struct VenueCardView: View {
    
    // MARK: - Properties
    
    let venue: VenueListItem
    var onInterestToggled: (() -> Void)? = nil
    
    // MARK: - State
    
    /// Shared application state for interest tracking (observed, not owned)
    @ObservedObject private var appState = AppState.shared
    
    /// Local interested count for optimistic updates
    @State private var localInterestedCount: Int
    
    /// Animation state for heart button scale effect
    @State private var isAnimating = false
    
    // MARK: - Initialization
    
    /// Initializes the venue card with venue data
    /// - Parameters:
    ///   - venue: The venue list item containing basic venue information
    ///   - onInterestToggled: Optional callback invoked after successful interest toggle
    init(venue: VenueListItem, onInterestToggled: (() -> Void)? = nil) {
        self.venue = venue
        self.onInterestToggled = onInterestToggled
        _localInterestedCount = State(initialValue: venue.interested_count)
    }
    
    // MARK: - Computed Properties
    
    /// Returns whether the current user has marked interest in this venue
    private var isInterested: Bool {
        appState.isInterested(in: venue.id)
    }
    
    /// Formatted interested count text with proper pluralization
    private var interestedCountText: String {
        if localInterestedCount == 1 {
            return "1 person interested"
        } else {
            return "\(localInterestedCount) people interested"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Venue Image
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
                    // Failed to load image - show placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                @unknown default:
                    // Fallback for future AsyncImagePhase cases
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                }
            }
            .clipped()
            
            // MARK: Venue Info Section
            VStack(alignment: .leading, spacing: 8) {
                // MARK: Category Badge and Heart Button Row
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
                        .accessibilityLabel("Category: \(venue.category)")
                    
                    Spacer()
                    
                    // Heart Button for Interest Toggle
                    Button {
                        handleInterestTap()
                    } label: {
                        Image(systemName: isInterested ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isInterested ? .red : .gray)
                            .frame(width: 44, height: 44)
                    }
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                    .accessibilityLabel(isInterested ? "Remove from interested venues" : "Mark as interested")
                    .accessibilityHint("Double tap to toggle interest")
                }
                .padding(.top, 12)
                
                // MARK: Venue Name
                Text(venue.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // MARK: Interested Count
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(interestedCountText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(interestedCountText)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    /// Handles interest button tap with optimistic updates and animation
    /// Implements the following flow:
    /// 1. Trigger heart scale animation
    /// 2. Optimistically update local count
    /// 3. Call API to persist change
    /// 4. Revert count if API fails
    /// 5. Notify parent view on success
    private func handleInterestTap() {
        // Prevent multiple rapid taps by checking if already animating
        guard !isAnimating else { return }
        
        // Trigger scale animation
        isAnimating = true
        
        // Capture current interest state before toggle
        let wasInterested = isInterested
        
        // Optimistically update the count for immediate UI feedback
        if wasInterested {
            localInterestedCount = max(0, localInterestedCount - 1)
        } else {
            localInterestedCount += 1
        }
        
        // Provide haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Toggle interest via AppState (persists to API)
        Task {
            do {
                let response = try await appState.toggleInterest(venueId: venue.id)
                
                // Check if operation was successful
                if response.success {
                    // Notify parent to refresh on successful toggle
                    await MainActor.run {
                        onInterestToggled?()
                    }
                } else {
                    // API returned success: false, revert optimistic update
                    await MainActor.run {
                        if wasInterested {
                            localInterestedCount += 1
                        } else {
                            localInterestedCount = max(0, localInterestedCount - 1)
                        }
                    }
                    print("Interest toggle failed: \(response.message ?? "Unknown error")")
                }
            } catch {
                // Network or decoding error occurred, revert optimistic update
                await MainActor.run {
                    if wasInterested {
                        localInterestedCount += 1
                    } else {
                        localInterestedCount = max(0, localInterestedCount - 1)
                    }
                }
                print("Failed to toggle interest for venue \(venue.id): \(error.localizedDescription)")
            }
        }
        
        // Reset animation state after spring animation completes
        // Spring animation duration: response (0.3s) * dampingFraction (0.6) ≈ 0.4s
        Task { @MainActor [weak appState] in
            guard appState != nil else { return }
            do {
                try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
                isAnimating = false
            } catch {
                // Task cancelled, view likely dismissed - safe to ignore
            }
        }
    }
    
    /// Returns a color based on venue category for consistent visual coding
    /// - Parameter category: The venue category string
    /// - Returns: Color associated with the category
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "coffee shop", "coffee", "café", "cafe":
            return Color.blue
        case "restaurant", "food", "dining":
            return Color.orange
        case "bar", "nightlife", "pub", "lounge":
            return Color.purple
        case "museum", "cultural", "culture", "art", "gallery":
            return Color.green
        case "park", "outdoor", "nature":
            return Color.teal
        case "entertainment", "theater", "cinema":
            return Color.pink
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
