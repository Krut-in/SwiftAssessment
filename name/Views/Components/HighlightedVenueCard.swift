//
//  HighlightedVenueCard.swift
//  name
//
//  Created by Krutin Rathod on 02/12/25.
//
//  DESCRIPTION:
//  A prominent card component for displaying venues that have reached the
//  interest threshold (5+ friends interested). Featured in the "Hot Right Now"
//  section of the Social tab to encourage group meetups.
//
//  FEATURES:
//  - Eye-catching gradient background with fire emoji
//  - Venue image with category color accent
//  - Friend avatar stack showing who's interested
//  - "Plan Meetup" and "View Venue" action buttons
//  - Animated appearance
//
//  USAGE:
//  HighlightedVenueCard(
//      venue: highlightedVenue,
//      onViewVenue: { venueId in ... },
//      onPlanMeetup: { venue in ... }
//  )
//

import SwiftUI

struct HighlightedVenueCard: View {
    
    // MARK: - Properties
    
    let venue: HighlightedVenue
    var onViewVenue: ((String) -> Void)?
    var onPlanMeetup: ((HighlightedVenue) -> Void)?
    
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
            // Header with fire indicator
            HStack {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 16))
                    
                    Text("\(venue.totalInterestedCount) friends interested")
                        .font(Theme.Fonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.warning)
                }
                
                Spacer()
                
                Text(venue.relativeTimestamp)
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            
            // Venue info row
            HStack(spacing: Theme.Layout.spacing) {
                // Venue image
                AsyncImage(url: URL(string: venue.venueImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        placeholderImage
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Theme.Colors.secondaryBackground)
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius)
                        .stroke(categoryColor.opacity(0.5), lineWidth: 2)
                )
                
                // Venue details
                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.venueName)
                        .font(Theme.Fonts.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    // Category badge
                    Text(venue.venueCategory)
                        .font(Theme.Fonts.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(categoryColor)
                        .clipShape(Capsule())
                    
                    // Address
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                        Text(venue.venueAddress)
                            .font(Theme.Fonts.caption2)
                    }
                    .foregroundColor(Theme.Colors.textTertiary)
                    .lineLimit(1)
                }
                
                Spacer()
            }
            
            // Friend avatars with names in a scrollable row
            ScrollView(.horizontal, showsIndicators: false) {
                FriendAvatarStack(
                    friends: venue.interestedFriends,
                    maxDisplay: 6,
                    avatarSize: 36,
                    spacing: 12,
                    showNames: true
                )
            }
            
            // Action buttons
            HStack(spacing: Theme.Layout.spacing) {
                // Plan Meetup - Primary action
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onPlanMeetup?(venue)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Plan Meetup")
                            .font(Theme.Fonts.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                }
                
                // View Venue - Secondary action
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onViewVenue?(venue.venueId)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("View")
                            .font(Theme.Fonts.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 90)
                    .frame(height: 40)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                }
            }
        }
        .padding(Theme.Layout.padding)
        .background(
            RoundedRectangle(cornerRadius: Theme.Layout.largeCornerRadius)
                .fill(Theme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.largeCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.warning.opacity(0.5), Theme.Colors.accent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .elevationMedium()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
    }
    
    // MARK: - Subviews
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(categoryColor.opacity(0.2))
            .overlay {
                Image(systemName: categoryIcon)
                    .font(.system(size: 24))
                    .foregroundColor(categoryColor)
            }
    }
    
    // MARK: - Helper Properties
    
    private var categoryColor: Color {
        switch venue.venueCategory.lowercased() {
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
    
    private var categoryIcon: String {
        switch venue.venueCategory.lowercased() {
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
            return "mappin.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Layout.padding) {
            HighlightedVenueCard(
                venue: HighlightedVenue(
                    id: "1",
                    venueId: "venue_1",
                    venueName: "Blue Bottle Coffee",
                    venueImageURL: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb",
                    venueCategory: "Coffee Shop",
                    venueAddress: "315 Linden St, San Francisco",
                    interestedFriends: [
                        FriendSummary(id: "1", name: "Sarah Chen", avatarURL: "https://i.pravatar.cc/150?img=1", interestedTimestamp: Date()),
                        FriendSummary(id: "2", name: "Alex Kim", avatarURL: "https://i.pravatar.cc/150?img=2", interestedTimestamp: Date()),
                        FriendSummary(id: "3", name: "Jordan Lee", avatarURL: "https://i.pravatar.cc/150?img=3", interestedTimestamp: Date()),
                        FriendSummary(id: "4", name: "Maya Patel", avatarURL: "https://i.pravatar.cc/150?img=4", interestedTimestamp: Date()),
                        FriendSummary(id: "5", name: "Chris Wong", avatarURL: "https://i.pravatar.cc/150?img=5", interestedTimestamp: Date()),
                        FriendSummary(id: "6", name: "Emma Davis", avatarURL: "https://i.pravatar.cc/150?img=6", interestedTimestamp: Date())
                    ],
                    totalInterestedCount: 6,
                    threshold: 5,
                    lastActivityTimestamp: Date().addingTimeInterval(-1800)
                ),
                onViewVenue: { venueId in
                    print("View venue: \(venueId)")
                },
                onPlanMeetup: { venue in
                    print("Plan meetup at: \(venue.venueName)")
                }
            )
            
            HighlightedVenueCard(
                venue: HighlightedVenue(
                    id: "2",
                    venueId: "venue_2",
                    venueName: "The Rustic Table",
                    venueImageURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4",
                    venueCategory: "Restaurant",
                    venueAddress: "456 Market St, San Francisco",
                    interestedFriends: [
                        FriendSummary(id: "1", name: "Sarah Chen", avatarURL: "https://i.pravatar.cc/150?img=1", interestedTimestamp: Date()),
                        FriendSummary(id: "2", name: "Alex Kim", avatarURL: "https://i.pravatar.cc/150?img=2", interestedTimestamp: Date()),
                        FriendSummary(id: "3", name: "Jordan Lee", avatarURL: "https://i.pravatar.cc/150?img=3", interestedTimestamp: Date()),
                        FriendSummary(id: "4", name: "Maya Patel", avatarURL: "https://i.pravatar.cc/150?img=4", interestedTimestamp: Date()),
                        FriendSummary(id: "5", name: "Chris Wong", avatarURL: "https://i.pravatar.cc/150?img=5", interestedTimestamp: Date())
                    ],
                    totalInterestedCount: 5,
                    threshold: 5,
                    lastActivityTimestamp: Date().addingTimeInterval(-5400)
                )
            )
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
