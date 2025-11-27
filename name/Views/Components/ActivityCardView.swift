//
//  ActivityCardView.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Reusable card component for displaying friend activities in the social feed.
//  Shows user avatar, action description, venue thumbnail, and relative timestamp.
//  
//  DESIGN:
//  - Horizontal layout: avatar | text content | venue thumbnail
//  - Category color accent on venue image
//  - Subtle tap animation
//  - Uses Theme.swift for consistent styling
//  
//  USAGE:
//  ActivityCardView(activity: activity)
//

import SwiftUI

struct ActivityCardView: View {
    
    // MARK: - Properties
    
    let activity: Activity
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Layout.spacing) {
            // User Avatar
            AsyncImage(url: URL(string: activity.user.avatar)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Theme.Colors.fill)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Activity Text
            VStack(alignment: .leading, spacing: Theme.Layout.microSpacing) {
                // User name and action
                Group {
                    Text(activity.user.name)
                        .font(Theme.Fonts.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    +
                    Text(" \(activity.actionDescription) ")
                        .font(Theme.Fonts.callout)
                        .foregroundColor(Theme.Colors.textSecondary)
                    +
                    Text(activity.venue.name)
                        .font(Theme.Fonts.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                // Category and timestamp
                HStack(spacing: Theme.Layout.microSpacing) {
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
            AsyncImage(url: URL(string: activity.venue.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Theme.Colors.fill)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius)
                    .stroke(categoryColor(for: activity.venue.category).opacity(0.3), lineWidth: 2)
            )
        }
        .padding(Theme.Layout.padding)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .elevationSmall()
    }
    
    // MARK: - Helper Methods
    
    /// Get color for venue category
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "coffee shop", "café", "cafe":
            return Theme.Colors.Category.coffee
        case "restaurant", "food":
            return Theme.Colors.Category.restaurant
        case "bar", "pub", "nightlife":
            return Theme.Colors.Category.bar
        case "cultural", "museum", "gallery":
            return Theme.Colors.Category.cultural
        case "park", "outdoor":
            return Theme.Colors.Category.outdoor
        case "entertainment":
            return Theme.Colors.Category.entertainment
        default:
            return Theme.Colors.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Layout.spacing) {
        ActivityCardView(
            activity: Activity(
                id: "activity_1",
                user: ActivityUser(
                    id: "user_2",
                    name: "Sarah Chen",
                    avatar: "https://i.pravatar.cc/150?img=1"
                ),
                venue: ActivityVenue(
                    id: "venue_1",
                    name: "Bluestone Coffee",
                    category: "Coffee Shop",
                    image: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb"
                ),
                action: "interested",
                timestamp: Date().addingTimeInterval(-7200)  // 2 hours ago
            )
        )
        
        ActivityCardView(
            activity: Activity(
                id: "activity_2",
                user: ActivityUser(
                    id: "user_3",
                    name: "Mike Johnson",
                    avatar: "https://i.pravatar.cc/150?img=2"
                ),
                venue: ActivityVenue(
                    id: "venue_2",
                    name: "The Rustic Table",
                    category: "Restaurant",
                    image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4"
                ),
                action: "booked",
                timestamp: Date().addingTimeInterval(-86400)  // 1 day ago
            )
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
