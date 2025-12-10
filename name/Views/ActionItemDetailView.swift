//
//  ActionItemDetailView.swift
//  name
//
//  Created by Antigravity AI on 10/12/25.
//
//  DESCRIPTION:
//  Expanded view showing action item details with confirmation tracking.
//  Shows venue info, confirmation list with status badges, and action buttons.
//
//  FEATURES:
//  - Venue header (image, name, distance)
//  - Real-time confirmation status updates via polling
//  - User avatars with status badges
//  - "X of Y confirmed" count display
//  - "View Chat" button when chat is created
//

import SwiftUI

struct ActionItemDetailView: View {
    
    // MARK: - Properties
    
    let actionItemId: String
    
    @StateObject private var statusManager = ActionItemStatusManager()
    @ObservedObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = true
    @State private var chatId: String?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.largeSpacing) {
                // Venue Header
                if let status = statusManager.statusResponses[actionItemId] {
                    venueHeaderView(venue: status.venue)
                }
                
                // Status Section
                statusSection
                
                // Confirmation List
                confirmationListSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding()
        }
        .background(Theme.Colors.background)
        .navigationTitle("Action Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAndStartPolling()
        }
        .onDisappear {
            statusManager.stopPolling(actionItemId: actionItemId)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func venueHeaderView(venue: ActionItemVenueInfo?) -> some View {
        if let venue = venue {
            HStack(spacing: Theme.Layout.spacing) {
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
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(venue.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(venue.category)
                        .font(Theme.Fonts.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text("Nearby")
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                }
                
                Spacer()
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            .elevationMedium()
        } else if isLoading {
            SkeletonLoadingView()
                .frame(height: 100)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
            Text("Status")
                .font(Theme.Fonts.headline)
                .foregroundColor(Theme.Colors.textPrimary)
            
            let counts = statusManager.getConfirmationCount(actionItemId: actionItemId)
            
            HStack(spacing: Theme.Layout.spacing) {
                // Waiting indicator
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(Theme.Colors.warning)
                    Text("Waiting for confirmations...")
                        .font(Theme.Fonts.callout)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Confirmation count
                if counts.total > 0 {
                    Text("\(counts.confirmed) of \(counts.total) confirmed")
                        .font(Theme.Fonts.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.success)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.success.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            .elevationLow()
        }
    }
    
    private var confirmationListSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
            Text("Confirmations")
                .font(Theme.Fonts.headline)
                .foregroundColor(Theme.Colors.textPrimary)
            
            VStack(spacing: 0) {
                // Initiator (always confirmed)
                if let initiator = statusManager.getInitiator(actionItemId: actionItemId) {
                    confirmationRow(
                        name: initiator.name,
                        avatar: initiator.avatar,
                        status: .confirmed,
                        isInitiator: true
                    )
                    
                    if !(statusManager.confirmationStatuses[actionItemId]?.isEmpty ?? true) {
                        Divider()
                            .padding(.horizontal)
                    }
                }
                
                // Other users
                if let statuses = statusManager.confirmationStatuses[actionItemId] {
                    ForEach(Array(statuses.enumerated()), id: \.element.id) { index, status in
                        confirmationRow(
                            name: status.name,
                            avatar: status.avatar,
                            status: status.status,
                            isInitiator: false
                        )
                        
                        if index < statuses.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            .elevationLow()
        }
    }
    
    private func confirmationRow(name: String, avatar: String, status: ConfirmationStatus.Status, isInitiator: Bool) -> some View {
        HStack(spacing: Theme.Layout.spacing) {
            // Avatar
            AsyncImage(url: URL(string: avatar)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Theme.Colors.secondaryBackground)
                        .overlay {
                            Text(name.prefix(1).uppercased())
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Name and initiator badge
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(Theme.Fonts.body)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if isInitiator {
                        Text("Initiator")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.primary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // Status badge
            StatusBadgeView(status: status)
        }
        .padding()
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: Theme.Layout.spacing) {
            // View Chat button (if chat created)
            if let chatId = statusManager.getChatId(actionItemId: actionItemId) {
                Button {
                    // TODO: Navigate to chat view
                    // For now, just show the chat ID
                    self.chatId = chatId
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("View Chat")
                    }
                    .font(Theme.Fonts.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                }
            }
            
            // Dismiss button
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(Theme.Fonts.headline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
        }
        .padding(.top, Theme.Layout.spacing)
    }
    
    // MARK: - Private Methods
    
    private func loadAndStartPolling() async {
        isLoading = true
        await statusManager.fetchStatusOnce(actionItemId: actionItemId)
        isLoading = false
        statusManager.startPolling(actionItemId: actionItemId)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActionItemDetailView(actionItemId: "action_1")
    }
}
