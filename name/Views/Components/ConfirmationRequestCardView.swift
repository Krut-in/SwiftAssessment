//
//  ConfirmationRequestCardView.swift
//  name
//
//  Created by Antigravity AI on 10/12/25.
//
//  DESCRIPTION:
//  Card view shown to users who received a confirmation request.
//  Displays initiator info, venue details, and confirm/decline buttons.
//
//  DESIGN SPECIFICATIONS:
//  - 🎉 emoji header
//  - Message: "{Name} wants to create a plan to visit {Venue}"
//  - "Yes, I'm in!" primary button
//  - "Not this time" secondary button
//  - Avatars of other interested users
//

import SwiftUI

struct ConfirmationRequestCardView: View {
    
    // MARK: - Properties
    
    let actionItem: ActionItem
    let initiatorName: String
    let initiatorAvatar: String
    let otherInterestedUsers: [SimpleUser]
    let onConfirm: () -> Void
    let onDecline: () -> Void
    let onTapCard: () -> Void
    
    @State private var isConfirming = false
    @State private var isDeclining = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTapCard) {
            VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                // Header with emoji
                headerView
                
                // Venue Info
                venueInfoView
                
                // Message
                messageView
                
                // Other interested users
                if !otherInterestedUsers.isEmpty {
                    otherUsersView
                }
                
                // Action Buttons
                actionButtons
            }
            .padding(Theme.Layout.padding)
            .background(
                LinearGradient(
                    colors: [
                        Theme.Colors.success.opacity(0.05),
                        Theme.Colors.cardBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(Theme.Colors.success.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            .elevationMedium()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Celebration emoji
            Text("🎉")
                .font(.system(size: 32))
            
            // Initiator info
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: initiatorAvatar)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Circle()
                            .fill(Theme.Colors.secondaryBackground)
                            .overlay {
                                Text(initiatorName.prefix(1).uppercased())
                                    .font(Theme.Fonts.headline)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(initiatorName)
                        .font(Theme.Fonts.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("wants to make plans!")
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.Colors.success)
                }
            }
            
            Spacer()
        }
    }
    
    private var venueInfoView: some View {
        Group {
            if let venue = actionItem.venue {
                HStack(spacing: Theme.Layout.spacing) {
                    // Venue Image
                    AsyncImage(url: URL(string: venue.image)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius)
                                .fill(Theme.Colors.secondaryBackground)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text(venue.category)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text("Nearby")
                        }
                        .font(Theme.Fonts.caption2)
                        .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var messageView: some View {
        Text("Are you still interested in joining?")
            .font(Theme.Fonts.callout)
            .foregroundColor(Theme.Colors.textSecondary)
            .padding(.vertical, 4)
    }
    
    private var otherUsersView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Also interested:")
                .font(Theme.Fonts.caption)
                .foregroundColor(Theme.Colors.textTertiary)
            
            HStack(spacing: -8) {
                ForEach(Array(otherInterestedUsers.prefix(5).enumerated()), id: \.element.id) { index, user in
                    AsyncImage(url: URL(string: user.avatar)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Circle()
                                .fill(Theme.Colors.secondaryBackground)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Colors.cardBackground, lineWidth: 2))
                    .zIndex(Double(5 - index))
                }
                
                if otherInterestedUsers.count > 5 {
                    Text("+\(otherInterestedUsers.count - 5)")
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.leading, 8)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: Theme.Layout.spacing) {
            // Yes, I'm in! Button (Primary)
            Button(action: {
                isConfirming = true
                onConfirm()
            }) {
                HStack(spacing: 6) {
                    if isConfirming {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("Yes, I'm in!")
                }
                .font(Theme.Fonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isConfirming || isDeclining)
            
            // Not this time Button (Secondary)
            Button(action: {
                isDeclining = true
                onDecline()
            }) {
                HStack(spacing: 6) {
                    if isDeclining {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("Not this time")
                }
                .font(Theme.Fonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isConfirming || isDeclining)
        }
    }
}

// MARK: - Simple User Model (for other interested users)

struct SimpleUser: Identifiable {
    let id: String
    let name: String
    let avatar: String
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ConfirmationRequestCardView(
            actionItem: ActionItem(
                id: "action_1",
                venue_id: "venue_1",
                interested_user_ids: ["user_1", "user_2", "user_3"],
                action_type: "book_venue",
                action_code: "LUNA-venue_1-1234",
                description: "5 friends interested",
                threshold_met: true,
                status: "active",
                created_at: "2025-12-10T10:00:00Z",
                venue: Venue(
                    id: "venue_1",
                    name: "The Cozy Café",
                    category: "Coffee Shop",
                    description: "A cozy café",
                    image: "https://example.com/cafe.jpg",
                    images: nil,
                    address: "123 Main St",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    distance_km: 0.5,
                    interested_count: 5
                )
            ),
            initiatorName: "Sarah Chen",
            initiatorAvatar: "https://i.pravatar.cc/100?img=1",
            otherInterestedUsers: [
                SimpleUser(id: "u1", name: "John", avatar: "https://i.pravatar.cc/100?img=2"),
                SimpleUser(id: "u2", name: "Jane", avatar: "https://i.pravatar.cc/100?img=3"),
                SimpleUser(id: "u3", name: "Mike", avatar: "https://i.pravatar.cc/100?img=4")
            ],
            onConfirm: {},
            onDecline: {},
            onTapCard: {}
        )
        .padding()
    }
    .background(Theme.Colors.background)
}
