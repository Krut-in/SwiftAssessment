//
//  HeroVenueCard.swift
//  name
//
//  Created by Antigravity AI on 03/12/25.
//
//  DESCRIPTION:
//  Premium hero card for the first venue in the Discover feed.
//  Features cinematic 16:9 imagery, gradient overlays, floating badges, and parallax effects.
//
//  KEY FEATURES:
//  - 16:9 cinematic aspect ratio for dramatic first impression
//  - Gradient overlay for text readability on images
//  - Text directly overlaid on image (white text)
//  - Glassmorphic floating badge for interested count
//  - "✨ Top Match" featured ribbon banner
//  - Parallax scroll effect using GeometryReader
//  - Full dark/light mode compatibility
//
//  DESIGN PRINCIPLES:
//  - Maximum visual impact for first result
//  - Production-ready polish with attention to detail
//  - Proper spacing and typography hierarchy
//  - Accessibility labels for all elements
//  - Smooth animations and transitions
//

import SwiftUI

struct HeroVenueCard: View {
    
    // MARK: - Properties
    
    let venue: VenueListItem
    var onInterestToggled: (() -> Void)? = nil
    
    // MARK: - State
    
    @ObservedObject private var appState = AppState.shared
    @State private var localInterestedCount: Int
    @State private var isAnimating = false
    
    // MARK: - Initialization
    
    init(venue: VenueListItem, onInterestToggled: (() -> Void)? = nil) {
        self.venue = venue
        self.onInterestToggled = onInterestToggled
        _localInterestedCount = State(initialValue: venue.interested_count)
    }
    
    // MARK: - Computed Properties
    
    private var isInterested: Bool {
        appState.isInterested(in: venue.id)
    }
    
    private var categoryColor: Color {
        Theme.Colors.Category.color(for: venue.category)
    }
    
    private var categoryIcon: String {
        Theme.Colors.Category.icon(for: venue.category)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // MARK: Background Image with Parallax
                CachedAsyncImage(url: venue.image) { image in
                    image
                        .resizable()
                        .aspectRatio(Theme.Layout.heroImageAspectRatio, contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        // Parallax effect based on scroll position
                        .offset(y: parallaxOffset(for: geometry))
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondaryBackground)
                        .aspectRatio(Theme.Layout.heroImageAspectRatio, contentMode: .fill)
                        .overlay {
                            ProgressView()
                                .tint(Theme.Colors.primary)
                        }
                } failure: {
                    Rectangle()
                        .fill(categoryColor.opacity(0.2))
                        .aspectRatio(Theme.Layout.heroImageAspectRatio, contentMode: .fill)
                        .overlay {
                            VStack(spacing: Theme.Layout.smallSpacing) {
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 48))
                                    .foregroundColor(categoryColor)
                                Text("Image unavailable")
                                    .font(Theme.Fonts.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                }
                
                // MARK: Gradient Overlay (bottom to top fade for text readability)
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .center
                )
                
                // MARK: Content Overlay
                VStack(alignment: .leading) {
                    // Top bar with ribbon and score badge
                    HStack {
                        // Featured Ribbon
                        featuredRibbon
                        
                        Spacer()
                        
                        // Glassmorphic Score Badge
                        glassmorphicScoreBadge
                    }
                    .padding(Theme.Layout.padding)
                    
                    Spacer()
                    
                    // Bottom content: Category, Name, Distance
                    VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                        // Category Badge
                        HStack(spacing: Theme.Layout.smallSpacing) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 12, weight: .bold))
                            Text(venue.category)
                                .font(Theme.Fonts.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor)
                        .clipShape(Capsule())
                        
                        // Venue Name - Large and Bold
                        Text(venue.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // Distance Badge (if available)
                        if let distance = venue.distance_km {
                            HStack(spacing: 4) {
                                Image(systemName: distanceIcon(for: distance))
                                    .font(.system(size: 12))
                                Text(String(format: "%.1f km away", distance))
                                    .font(Theme.Fonts.subheadline)
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(Theme.Layout.padding)
                }
                
                // MARK: Heart Button (Top Right, below score badge)
                VStack {
                    HStack {
                        Spacer()
                        heartButton
                            .padding(.top, 72) // Below the score badge
                            .padding(.trailing, Theme.Layout.padding)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(Theme.Layout.heroImageAspectRatio, contentMode: .fit)
        .cornerRadius(Theme.Layout.largeCornerRadius)
        .elevationHigh()
        .animation(Theme.Animation.spring, value: localInterestedCount)
    }
    
    // MARK: - Subviews
    
    private var featuredRibbon: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
            Text("Top Match")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Theme.Colors.Category.gradient(for: venue.category)
        )
        .clipShape(Capsule())
        .shadow(color: categoryColor.opacity(0.4), radius: 8, x: 0, y: 2)
    }
    
    private var glassmorphicScoreBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 14))
            Text("\(localInterestedCount)")
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(width: 56, height: 56)
        .background(
            // Glassmorphic effect
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    private var heartButton: some View {
        Button {
            handleInterestTap()
        } label: {
            Image(systemName: isInterested ? "heart.fill" : "heart")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isInterested ? Theme.Colors.error : .white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .animation(Theme.Animation.spring, value: isAnimating)
        .accessibilityLabel(isInterested ? "Remove from interested venues" : "Mark as interested")
    }
    
    // MARK: - Helper Methods
    
    private func parallaxOffset(for geometry: GeometryProxy) -> CGFloat {
        let globalFrame = geometry.frame(in: .global)
        let screenHeight = UIScreen.main.bounds.height
        let midY = globalFrame.midY
        
        // Calculate parallax based on distance from screen center
        let offset = (midY - screenHeight / 2) / 30
        return -offset
    }
    
    private func distanceIcon(for distance: Double) -> String {
        if distance < 0.5 {
            return "figure.walk"
        } else if distance < 2.0 {
            return "bicycle"
        } else if distance < 5.0 {
            return "car.fill"
        } else {
            return "location.fill"
        }
    }
    
    private func handleInterestTap() {
        guard !isAnimating else { return }
        
        isAnimating = true
        let wasInterested = isInterested
        
        // Optimistic update
        if wasInterested {
            localInterestedCount = max(0, localInterestedCount - 1)
        } else {
            localInterestedCount += 1
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Toggle interest via AppState
        Task {
            do {
                let venueInfo = ActivityVenue(
                    id: venue.id,
                    name: venue.name,
                    category: venue.category,
                    image: venue.image
                )
                
                let response = try await appState.toggleInterest(venueId: venue.id, venueInfo: venueInfo)
                
                if response.success {
                    await MainActor.run {
                        onInterestToggled?()
                    }
                } else {
                    // Revert on failure
                    await MainActor.run {
                        if wasInterested {
                            localInterestedCount += 1
                        } else {
                            localInterestedCount = max(0, localInterestedCount - 1)
                        }
                    }
                }
            } catch {
                // Revert on error
                await MainActor.run {
                    if wasInterested {
                        localInterestedCount += 1
                    } else {
                        localInterestedCount = max(0, localInterestedCount - 1)
                    }
                }
                print("Failed to toggle interest: \(error.localizedDescription)")
            }
        }
        
        // Reset animation state
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            isAnimating = false
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        HeroVenueCard(venue: VenueListItem(
            id: "venue_1",
            name: "The Rooftop Garden Cafe",
            category: "Coffee Shop",
            image: "https://picsum.photos/800/450",
            interested_count: 12,
            distance_km: 0.8
        ))
        .padding()
        
        Spacer()
    }
    .background(Theme.Colors.background)
}
