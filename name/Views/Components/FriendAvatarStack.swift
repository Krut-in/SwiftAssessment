//
//  FriendAvatarStack.swift
//  name
//
//  Created by Krutin Rathod on 02/12/25.
//
//  DESCRIPTION:
//  A horizontal overlapping avatar stack showing friends interested in a venue.
//  Used in highlighted venue cards to display which friends are interested.
//
//  FEATURES:
//  - Overlapping circular avatars with border
//  - Configurable maximum display count
//  - "+N more" indicator when friends exceed max display
//  - Animated appearance
//  - Fallback placeholder for missing images
//
//  USAGE:
//  FriendAvatarStack(friends: friendList, maxDisplay: 4)
//

import SwiftUI

struct FriendAvatarStack: View {
    
    // MARK: - Properties
    
    let friends: [FriendSummary]
    var maxDisplay: Int = 4
    var avatarSize: CGFloat = 32
    var spacing: CGFloat = 8
    var showNames: Bool = false
    
    /// Number of additional friends beyond maxDisplay
    private var additionalCount: Int {
        max(0, friends.count - maxDisplay)
    }
    
    /// Friends to display (up to maxDisplay)
    private var displayedFriends: [FriendSummary] {
        Array(friends.prefix(maxDisplay))
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(displayedFriends) { friend in
                if showNames {
                    avatarWithName(for: friend)
                } else {
                    avatarView(for: friend)
                }
            }
            
            // "+N more" indicator
            if additionalCount > 0 {
                moreIndicator
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Single avatar view with border
    private func avatarView(for friend: FriendSummary) -> some View {
        AsyncImage(url: URL(string: friend.avatarURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_):
                placeholderView(for: friend)
            case .empty:
                placeholderView(for: friend)
            @unknown default:
                placeholderView(for: friend)
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    /// Avatar with name below
    private func avatarWithName(for friend: FriendSummary) -> some View {
        VStack(spacing: 4) {
            avatarView(for: friend)
            
            Text(friend.firstName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(1)
        }
    }
    
    /// Placeholder view for missing avatar
    private func placeholderView(for friend: FriendSummary) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.secondary.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(friend.firstName.prefix(1).uppercased())
                    .font(.system(size: avatarSize * 0.4, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            }
    }
    
    /// "+N more" indicator badge
    private var moreIndicator: some View {
        Circle()
            .fill(Theme.Colors.primary.opacity(0.15))
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Text("+\(additionalCount)")
                    .font(.system(size: avatarSize * 0.35, weight: .bold))
                    .foregroundColor(Theme.Colors.primary)
            )
    }
}

// MARK: - Large Avatar Stack Variant

/// A larger variant of the avatar stack for detail views with names
struct FriendAvatarStackLarge: View {
    
    let friends: [FriendSummary]
    var maxDisplay: Int = 4
    
    private var additionalCount: Int {
        max(0, friends.count - maxDisplay)
    }
    
    private var displayedFriends: [FriendSummary] {
        Array(friends.prefix(maxDisplay))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(displayedFriends) { friend in
                VStack(spacing: 6) {
                    AsyncImage(url: URL(string: friend.avatarURL)) { phase in
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
                                    Text(friend.firstName.prefix(1).uppercased())
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Theme.Colors.primary)
                                }
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 1.5)
                    )
                    
                    Text(friend.firstName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            if additionalCount > 0 {
                VStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text("+\(additionalCount)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                        )
                    
                    Text("more")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Friend Names List

/// Displays friend names with truncation
struct FriendNamesList: View {
    
    let friends: [FriendSummary]
    var maxDisplay: Int = 3
    
    private var additionalCount: Int {
        max(0, friends.count - maxDisplay)
    }
    
    private var displayedNames: String {
        let names = friends.prefix(maxDisplay).map { $0.firstName }
        return names.joined(separator: ", ")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(displayedNames)
                .font(Theme.Fonts.caption)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textPrimary)
            
            if additionalCount > 0 {
                Text("+\(additionalCount) more")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        // Compact stack without names
        VStack(alignment: .leading, spacing: 8) {
            Text("Compact (no names)")
                .font(.caption)
                .foregroundColor(.secondary)
            FriendAvatarStack(
                friends: [
                    FriendSummary(id: "1", name: "Sarah Chen", avatarURL: "https://i.pravatar.cc/150?img=1", interestedTimestamp: Date()),
                    FriendSummary(id: "2", name: "Alex Kim", avatarURL: "https://i.pravatar.cc/150?img=2", interestedTimestamp: Date()),
                    FriendSummary(id: "3", name: "Jordan Lee", avatarURL: "https://i.pravatar.cc/150?img=3", interestedTimestamp: Date()),
                    FriendSummary(id: "4", name: "Maya Patel", avatarURL: "https://i.pravatar.cc/150?img=4", interestedTimestamp: Date()),
                    FriendSummary(id: "5", name: "Chris Wong", avatarURL: "https://i.pravatar.cc/150?img=5", interestedTimestamp: Date()),
                    FriendSummary(id: "6", name: "Emma Davis", avatarURL: "https://i.pravatar.cc/150?img=6", interestedTimestamp: Date())
                ],
                maxDisplay: 4,
                avatarSize: 32,
                spacing: 8,
                showNames: false
            )
        }
        
        // Standard stack with names
        VStack(alignment: .leading, spacing: 8) {
            Text("With names")
                .font(.caption)
                .foregroundColor(.secondary)
            FriendAvatarStack(
                friends: [
                    FriendSummary(id: "1", name: "Sarah Chen", avatarURL: "https://i.pravatar.cc/150?img=1", interestedTimestamp: Date()),
                    FriendSummary(id: "2", name: "Alex Kim", avatarURL: "https://i.pravatar.cc/150?img=2", interestedTimestamp: Date()),
                    FriendSummary(id: "3", name: "Jordan Lee", avatarURL: "https://i.pravatar.cc/150?img=3", interestedTimestamp: Date()),
                    FriendSummary(id: "4", name: "Maya Patel", avatarURL: "https://i.pravatar.cc/150?img=4", interestedTimestamp: Date()),
                    FriendSummary(id: "5", name: "Chris Wong", avatarURL: "https://i.pravatar.cc/150?img=5", interestedTimestamp: Date()),
                    FriendSummary(id: "6", name: "Emma Davis", avatarURL: "https://i.pravatar.cc/150?img=6", interestedTimestamp: Date())
                ],
                maxDisplay: 5,
                avatarSize: 36,
                spacing: 12,
                showNames: true
            )
        }
        
        // Large stack
        VStack(alignment: .leading, spacing: 8) {
            Text("Large variant")
                .font(.caption)
                .foregroundColor(.secondary)
            FriendAvatarStackLarge(
                friends: [
                    FriendSummary(id: "1", name: "Sarah Chen", avatarURL: "https://i.pravatar.cc/150?img=1", interestedTimestamp: Date()),
                    FriendSummary(id: "2", name: "Alex Kim", avatarURL: "https://i.pravatar.cc/150?img=2", interestedTimestamp: Date()),
                    FriendSummary(id: "3", name: "Jordan Lee", avatarURL: "https://i.pravatar.cc/150?img=3", interestedTimestamp: Date()),
                    FriendSummary(id: "4", name: "Maya Patel", avatarURL: "https://i.pravatar.cc/150?img=4", interestedTimestamp: Date()),
                    FriendSummary(id: "5", name: "Chris Wong", avatarURL: "https://i.pravatar.cc/150?img=5", interestedTimestamp: Date())
                ]
            )
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
