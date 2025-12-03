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
//  - Uses centralized Theme for consistent styling
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
    /// Formatted interested count text with proper pluralization
    private var interestedCountText: String {
        if localInterestedCount == 1 {
            return "1 person interested"
        } else {
            return "\(localInterestedCount) people interested"
        }
    }
    
    /// Returns true if the venue is nearby (<1km) and should pulse
    private var shouldPulse: Bool {
        guard let distance = venue.distance_km else { return false }
        return distance < 1.0
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Venue Image (Cached for offline support)
            CachedAsyncImage(url: venue.image) { image in
                image
                    .resizable()
                    .aspectRatio(4/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.secondaryBackground)
                    .aspectRatio(4/3, contentMode: .fill)
                    .overlay {
                        ProgressView()
                    }
            } failure: {
                Rectangle()
                    .fill(categoryColor(for: venue.category).opacity(0.2))
                    .aspectRatio(4/3, contentMode: .fill)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: categoryIcon(for: venue.category))
                                .font(.system(size: 40))
                                .foregroundColor(categoryColor(for: venue.category))
                            Text("Image unavailable")
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
            }
            .overlay(alignment: .bottomTrailing) {
                // MARK: Category Watermark Icon
                Image(systemName: categoryIcon(for: venue.category))
                    .font(.system(size: Theme.Layout.watermarkIconSize))
                    .foregroundColor(categoryColor(for: venue.category).opacity(Theme.Layout.watermarkOpacity))
                    .padding(Theme.Layout.padding)
            }
            .clipped()
            
            // MARK: Venue Info Section
            VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                // MARK: Category Badge and Heart Button Row
                HStack {
                    // Category Badge
                    Text(venue.category)
                        .font(Theme.Fonts.caption)
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
                            .foregroundColor(isInterested ? Theme.Colors.error : Theme.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(Theme.Animation.spring, value: isAnimating)
                    .accessibilityLabel(isInterested ? "Remove from interested venues" : "Mark as interested")
                    .accessibilityHint("Double tap to toggle interest")
                }
                .padding(.top, Theme.Layout.spacing)
                
                // MARK: Distance Badge
                if venue.distance_km != nil {
                    DistanceBadge(distance_km: venue.distance_km)
                }
                
                // MARK: Venue Name
                Text(venue.name)
                    .font(Theme.Fonts.title3)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // MARK: Interested Count
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text(interestedCountText)
                        .font(Theme.Fonts.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.bottom, Theme.Layout.spacing)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(interestedCountText)
            }
            .padding(.horizontal, Theme.Layout.padding)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .overlay(
            // MARK: Subtle Category Border (minimal and clean)
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .strokeBorder(
                    categoryColor(for: venue.category).opacity(0.15),
                    lineWidth: 0.5
                )
        )
        .elevationMedium()
        .scaleEffect(shouldPulse ? 1.02 : 1.0)
        .animation(shouldPulse ? Theme.Animation.nearbyPulse : nil, value: shouldPulse)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
        .animation(Theme.Animation.spring, value: localInterestedCount)
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
                // Create venue info for social feed broadcast
                let venueInfo = ActivityVenue(
                    id: venue.id,
                    name: venue.name,
                    category: venue.category,
                    image: venue.image
                )
                
                let response = try await appState.toggleInterest(venueId: venue.id, venueInfo: venueInfo)
                
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
            return Theme.Colors.Category.coffee
        case "restaurant", "food", "dining":
            return Theme.Colors.Category.restaurant
        case "bar", "nightlife", "pub", "lounge":
            return Theme.Colors.Category.bar
        case "museum", "cultural", "culture", "art", "gallery":
            return Theme.Colors.Category.cultural
        case "park", "outdoor", "nature":
            return Theme.Colors.Category.outdoor
        case "entertainment", "theater", "cinema":
            return Theme.Colors.Category.entertainment
        default:
            return Theme.Colors.textSecondary
        }
    }
    
    /// Returns an icon based on venue category
    /// - Parameter category: The venue category string
    /// - Returns: SF Symbol name for the category
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "coffee shop", "coffee", "café", "cafe":
            return "cup.and.saucer.fill"
        case "restaurant", "food", "dining":
            return "fork.knife"
        case "bar", "nightlife", "pub", "lounge":
            return "wineglass.fill"
        case "museum", "cultural", "culture", "art", "gallery":
            return "building.columns.fill"
        case "park", "outdoor", "nature":
            return "leaf.fill"
        case "entertainment", "theater", "cinema":
            return "theatermasks.fill"
        default:
            return "photo.fill"
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
        interested_count: 5,
        distance_km: 2.5
    ))
    .padding()
}
