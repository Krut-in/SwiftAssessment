//
//  WhyThisCallout.swift
//  name
//
//  Created by Krutin Rathod on 03/12/25.
//
//  DESCRIPTION:
//  Enhanced callout card component that explains why a venue is recommended.
//  Replaces simple reason text with an engaging, interactive card that highlights
//  the key factors behind the recommendation.
//
//  KEY FEATURES:
//  - Context-aware icon based on reason keywords
//  - Category-colored left border (4pt) for visual hierarchy
//  - Slide-in animation from left with spring physics
//  - Tap to expand showing full scoring details
//  - Score breakdown display when available
//  - Adaptive background color for light/dark mode
//
//  DESIGN DECISIONS:
//  - Icons selected based on reason text content:
//    • "Popular"/"trending" → 🔥 flame icon
//    • "Friends"/"friend" → 👥 people icon
//    • "interests"/"matches" → 🎯 target icon
//    • "Nearby"/"close" → 📍 location icon
//  - Left border uses category color for consistency
//  - Expandable design allows progressive disclosure
//  - Subtle background to distinguish from card
//
//  INTERACTION:
//  - Tap anywhere on callout to expand/collapse
//  - Smooth height animation on state change
//  - Haptic feedback on tap
//  - Clear visual indication of expandability
//

import SwiftUI

struct WhyThisCallout: View {
    
    // MARK: - Properties
    
    /// Recommendation reason text
    let reason: String
    
    /// Venue category for border color
    let category: String
    
    /// Optional score breakdown for expanded view
    let scoreBreakdown: ScoreBreakdown?
    
    /// Total interested count
    let totalInterested: Int
    
    /// Friends interested count
    let friendsInterested: Int
    
    /// Distance in kilometers
    let distanceKm: Double
    
    // MARK: - State
    
    /// Controls expansion state
    @State private var isExpanded = false
    
    // MARK: - Computed Properties
    
    /// Icon determined by reason text content
    private var icon: String {
        let lowercasedReason = reason.lowercased()
        
        if lowercasedReason.contains("popular") || lowercasedReason.contains("trending") {
            return "flame.fill"
        } else if lowercasedReason.contains("friend") {
            return "person.2.fill"
        } else if lowercasedReason.contains("interest") || lowercasedReason.contains("match") {
            return "target"
        } else if lowercasedReason.contains("nearby") || lowercasedReason.contains("close") {
            return "location.fill"
        } else {
            return "star.fill"
        }
    }
    
    /// Border color based on category
    private var borderColor: Color {
        Theme.Colors.Category.color(for: category)
    }
    
    /// Icon color matching border
    private var iconColor: Color {
        borderColor
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main reason row (always visible)
            Button {
                handleTap()
            } label: {
                HStack(spacing: 8) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                    
                    // Reason text
                    Text(reason)
                        .font(Theme.Fonts.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(isExpanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 4)
                    
                    // Chevron indicator (if score breakdown available)
                    if scoreBreakdown != nil {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            
            // Expanded details (conditional)
            if isExpanded, let breakdown = scoreBreakdown {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 12)
                    
                    // Score breakdown details
                    VStack(alignment: .leading, spacing: 6) {
                        if friendsInterested > 0 {
                            DetailRow(
                                icon: "person.2.fill",
                                text: "\(friendsInterested) friend\(friendsInterested == 1 ? "" : "s") interested",
                                color: .blue
                            )
                        }
                        
                        if breakdown.popularity > 0 {
                            DetailRow(
                                icon: "flame.fill",
                                text: "Popularity score: \(breakdown.popularity)%",
                                color: .orange
                            )
                        }
                        
                        if breakdown.categoryMatch > 0 {
                            DetailRow(
                                icon: "target",
                                text: "Matches your interests: \(breakdown.categoryMatch)%",
                                color: .green
                            )
                        }
                        
                        if breakdown.proximity > 0 {
                            DetailRow(
                                icon: "location.fill",
                                text: "Just \(String(format: "%.1f", distanceKm)) km away",
                                color: .teal
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.Colors.secondaryBackground)
        .overlay(
            // Category-colored left border
            Rectangle()
                .fill(borderColor)
                .frame(width: 4)
            , alignment: .leading
        )
        .cornerRadius(8)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(Theme.Animation.spring, value: isExpanded)
    }
    
    // MARK: - Helper Methods
    
    /// Handles tap with expansion toggle and haptic feedback
    private func handleTap() {
        // Only toggle if score breakdown is available
        guard scoreBreakdown != nil else { return }
        
        // Toggle expansion
        isExpanded.toggle()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Detail Row

/// Individual detail row in expanded view
private struct DetailRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(Theme.Fonts.caption)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("Why This - With Breakdown") {
    VStack(spacing: 16) {
        WhyThisCallout(
            reason: "Popular venue, Matches your interests",
            category: "Coffee Shop",
            scoreBreakdown: ScoreBreakdown(
                popularity: 25,
                categoryMatch: 30,
                friendSignal: 25,
                proximity: 20
            ),
            totalInterested: 47,
            friendsInterested: 3,
            distanceKm: 0.8
        )
        
        WhyThisCallout(
            reason: "3 friends are interested in this place",
            category: "Restaurant",
            scoreBreakdown: ScoreBreakdown(
                popularity: 20,
                categoryMatch: 25,
                friendSignal: 35,
                proximity: 20
            ),
            totalInterested: 24,
            friendsInterested: 3,
            distanceKm: 1.2
        )
        
        WhyThisCallout(
            reason: "Trending spot near you",
            category: "Bar",
            scoreBreakdown: ScoreBreakdown(
                popularity: 35,
                categoryMatch: 15,
                friendSignal: 10,
                proximity: 40
            ),
            totalInterested: 89,
            friendsInterested: 0,
            distanceKm: 0.3
        )
    }
    .padding()
}

#Preview("Why This - No Breakdown") {
    VStack(spacing: 16) {
        WhyThisCallout(
            reason: "Close to your current location",
            category: "Coffee Shop",
            scoreBreakdown: nil,
            totalInterested: 12,
            friendsInterested: 0,
            distanceKm: 0.5
        )
    }
    .padding()
}
