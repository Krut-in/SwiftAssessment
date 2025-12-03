//
//  InterestActivityCard.swift
//  name
//
//  Created by Krutin Rathod on 02/12/25.
//
//  DESCRIPTION:
//  Card component for displaying individual friend interest activities
//  in the social feed. Shows who expressed interest in which venue.
//
//  FEATURES:
//  - Friend avatar with name
//  - Action description ("is interested in")
//  - Venue thumbnail with category accent
//  - Relative timestamp
//  - Tap to navigate to venue detail
//
//  USAGE:
//  InterestActivityCard(activity: interestActivity)
//

import SwiftUI

struct InterestActivityCard: View {
    
    // MARK: - Properties
    
    let activity: InterestActivity
    var currentUserId: String = AppState.shared.currentUserId
    var onTap: (() -> Void)?
    
    /// Check if this is the current user's own activity
    private var isOwnActivity: Bool {
        activity.user.id == currentUserId
    }
    
    /// Display name - "You" for own activities
    private var displayName: String {
        isOwnActivity ? "You" : activity.user.name
    }
    
    /// Action description adjusted for grammar
    private var displayAction: String {
        if isOwnActivity {
            return activity.action == .interested ? "are interested in" : "are no longer interested in"
        }
        return activity.actionDescription
    }
    
    // MARK: - Body
    
    var body: some View {
        cardContent
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onTap?()
            }
    }
    
    // MARK: - Content View
    
    private var cardContent: some View {
        HStack(alignment: .top, spacing: Theme.Layout.spacing) {
                // User Avatar (with special indicator for own activity)
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: activity.user.avatar)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.secondary.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay {
                                    Text(activity.user.name.prefix(1).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.Colors.primary)
                                }
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isOwnActivity ? Theme.Colors.primary : Theme.Colors.separator.opacity(0.5), lineWidth: isOwnActivity ? 2 : 1)
                    )
                    
                    // "You" badge for own activity
                    if isOwnActivity {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // Activity Text Content
                VStack(alignment: .leading, spacing: Theme.Layout.microSpacing) {
                    // User name + action + venue name
                    Group {
                        Text(displayName)
                            .font(Theme.Fonts.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(isOwnActivity ? Theme.Colors.primary : Theme.Colors.textPrimary)
                        +
                        Text(" \(displayAction) ")
                            .font(Theme.Fonts.callout)
                            .foregroundColor(Theme.Colors.textSecondary)
                        +
                        Text(activity.venue.name)
                            .font(Theme.Fonts.callout)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .lineLimit(2)
                    
                    // Category and timestamp
                    HStack(spacing: Theme.Layout.microSpacing) {
                        // Interest indicator
                        if activity.action == .interested {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.accent)
                        }
                        
                        Text(activity.venue.category)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(categoryColor(for: activity.venue.category))
                        
                        Text("•")
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        Text(activity.relativeTimestamp)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Venue Thumbnail
                AsyncImage(url: URL(string: activity.venue.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(categoryColor(for: activity.venue.category).opacity(0.2))
                            .overlay {
                                Image(systemName: categoryIcon(for: activity.venue.category))
                                    .font(.system(size: 18))
                                    .foregroundColor(categoryColor(for: activity.venue.category))
                            }
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius)
                        .stroke(categoryColor(for: activity.venue.category).opacity(0.3), lineWidth: 1.5)
                )
            }
            .padding(Theme.Layout.padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .fill(Theme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                            .stroke(isOwnActivity ? Theme.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .elevationLow()
    }
    
    // MARK: - Helper Methods
    
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
            return "mappin.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Layout.spacing) {
        InterestActivityCard(
            activity: InterestActivity(
                id: "1",
                user: ActivityUser(
                    id: "user_2",
                    name: "Sarah Chen",
                    avatar: "https://i.pravatar.cc/150?img=1"
                ),
                venue: ActivityVenue(
                    id: "venue_1",
                    name: "Blue Bottle Coffee",
                    category: "Coffee Shop",
                    image: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb"
                ),
                action: .interested,
                timestamp: Date().addingTimeInterval(-7200),
                isActive: true
            )
        )
        
        InterestActivityCard(
            activity: InterestActivity(
                id: "2",
                user: ActivityUser(
                    id: "user_3",
                    name: "Alex Kim",
                    avatar: "https://i.pravatar.cc/150?img=2"
                ),
                venue: ActivityVenue(
                    id: "venue_2",
                    name: "The Rustic Table",
                    category: "Restaurant",
                    image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4"
                ),
                action: .interested,
                timestamp: Date().addingTimeInterval(-86400),
                isActive: true
            )
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
