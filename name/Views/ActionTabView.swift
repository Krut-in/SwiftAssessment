//
//  ActionTabView.swift
//  name
//
//  Created by Antigravity AI on 10/12/25.
//
//  DESCRIPTION:
//  Main view for the Action Items tab, displaying pending action items
//  where 5+ friends are interested in the same venue.
//
//  FEATURES:
//  - List of action item cards with venue info
//  - Friend avatar stacks showing who's interested
//  - "Go Ahead" and "Dismiss" actions per item
//  - Empty state when no action items
//  - Pull-to-refresh support
//  - Navigation to venue details on card tap
//
//  DESIGN:
//  - Large navigation title "Action Items"
//  - Cards with venue image, name, distance, avatars
//  - Primary blue "Go Ahead" button
//  - Secondary gray "Dismiss" button
//  - No action_code display (LUNA-xxx hidden)
//

import SwiftUI

struct ActionTabView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ProfileViewModel(appState: .shared)
    @StateObject private var statusManager = ActionItemStatusManager()
    @ObservedObject private var appState = AppState.shared
    @State private var navigationPath = NavigationPath()
    @State private var pendingConfirmations: [String: PendingConfirmationInfo] = [:] // actionItemId -> info
    @State private var initiatedItems: Set<String> = [] // Track locally initiated items
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.actionItems.isEmpty {
                    loadingView
                } else if viewModel.actionItems.isEmpty {
                    emptyStateView
                } else {
                    actionItemsList
                }
            }
            .navigationTitle("Action Items")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { destination in
                if destination.hasPrefix("venue_") {
                    VenueDetailView(venueId: String(destination.dropFirst(6)))
                } else if destination.hasPrefix("detail_") {
                    ActionItemDetailView(actionItemId: String(destination.dropFirst(7)))
                } else {
                    VenueDetailView(venueId: destination)
                }
            }
            .refreshable {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                await viewModel.loadProfile()
                await checkPendingConfirmations()
            }
            .task {
                await viewModel.loadProfile()
                await checkPendingConfirmations()
            }
            .onDisappear {
                statusManager.stopAllPolling()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Loading skeleton view
    private var loadingView: some View {
        VStack {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonLoadingView()
                    .frame(height: 160)
                    .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    /// Empty state when no action items
    private var emptyStateView: some View {
        VStack(spacing: Theme.Layout.largeSpacing) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textTertiary)
            
            VStack(spacing: Theme.Layout.smallSpacing) {
                Text("No action items yet")
                    .font(Theme.Fonts.title3)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("When 5 friends are interested in the same venue, you'll see it here")
                    .font(Theme.Fonts.callout)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // CTA to go to Discover
            Button {
                appState.selectedTab = 0
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Discover Venues")
                }
                .font(Theme.Fonts.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Theme.Colors.primary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
            .padding(.top, Theme.Layout.spacing)
            
            Spacer()
        }
    }
    
    /// Main action items list
    private var actionItemsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.spacing) {
                ForEach(viewModel.actionItems) { item in
                    // Check if user has pending confirmation for this item
                    if let pendingInfo = pendingConfirmations[item.id] {
                        ConfirmationRequestCardView(
                            actionItem: item,
                            initiatorName: pendingInfo.initiatorName,
                            initiatorAvatar: pendingInfo.initiatorAvatar,
                            otherInterestedUsers: pendingInfo.otherUsers,
                            onConfirm: {
                                Task {
                                    await confirmItem(item.id)
                                }
                            },
                            onDecline: {
                                Task {
                                    await declineItem(item.id)
                                }
                            },
                            onTapCard: {
                                navigationPath.append("detail_\(item.id)")
                            }
                        )
                        .padding(.horizontal)
                    } else {
                        // Regular action item card
                        let isInitiated = initiatedItems.contains(item.id) || statusManager.isGoAheadInitiated(actionItemId: item.id)
                        let statuses = statusManager.confirmationStatuses[item.id] ?? []
                        let chatId = statusManager.getChatId(actionItemId: item.id)
                        
                        ActionItemCardView(
                            actionItem: item,
                            onGoAhead: {
                                Task {
                                    await initiateGoAhead(item.id)
                                }
                            },
                            onDismiss: {
                                Task {
                                    await viewModel.dismissActionItem(item.id)
                                    statusManager.stopPolling(actionItemId: item.id)
                                }
                            },
                            onTapCard: {
                                navigationPath.append("detail_\(item.id)")
                            },
                            isInitiated: isInitiated,
                            confirmationStatuses: statuses,
                            chatId: chatId,
                            onViewChat: chatId != nil ? {
                                // TODO: Navigate to chat view when implemented
                                // For now, show detail view
                                navigationPath.append("detail_\(item.id)")
                            } : nil
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Private Methods
    
    /// Initiates the Go Ahead flow for an action item
    private func initiateGoAhead(_ itemId: String) async {
        // Mark as initiated locally first (optimistic)
        initiatedItems.insert(itemId)
        
        do {
            let apiService = APIService()
            let response = try await apiService.initiateActionItem(itemId: itemId, userId: appState.currentUserId)
            
            // Update status manager with initial response
            statusManager.confirmationStatuses[itemId] = response.confirmations
            
            // Start polling for status updates
            statusManager.startPolling(actionItemId: itemId)
            
        } catch {
            // Rollback on error
            initiatedItems.remove(itemId)
            viewModel.errorMessage = "Failed to initiate: \(error.localizedDescription)"
        }
    }
    
    /// Confirms interest in an action item
    private func confirmItem(_ itemId: String) async {
        do {
            let apiService = APIService()
            let response = try await apiService.confirmActionItem(itemId: itemId, userId: appState.currentUserId)
            
            // Remove from pending confirmations
            pendingConfirmations.removeValue(forKey: itemId)
            
            // If chat was created, update status
            if response.chat_created == true {
                // Refresh to get updated state
                await statusManager.fetchStatusOnce(actionItemId: itemId)
            }
            
        } catch {
            viewModel.errorMessage = "Failed to confirm: \(error.localizedDescription)"
        }
    }
    
    /// Declines interest in an action item
    private func declineItem(_ itemId: String) async {
        do {
            let apiService = APIService()
            _ = try await apiService.declineActionItem(itemId: itemId, userId: appState.currentUserId)
            
            // Remove from pending confirmations
            pendingConfirmations.removeValue(forKey: itemId)
            
            // Remove from action items list
            await viewModel.loadProfile()
            
        } catch {
            viewModel.errorMessage = "Failed to decline: \(error.localizedDescription)"
        }
    }
    
    /// Checks for pending confirmation requests for the current user
    private func checkPendingConfirmations() async {
        let apiService = APIService()
        
        for item in viewModel.actionItems {
            do {
                let status = try await apiService.getActionItemStatus(itemId: item.id)
                
                // Check if current user has pending confirmation
                if let userConfirmation = status.confirmations.first(where: { $0.user_id == appState.currentUserId }),
                   userConfirmation.status == .pending,
                   let initiator = status.initiator {
                    
                    // Build other users list
                    let otherUsers = status.confirmations
                        .filter { $0.user_id != appState.currentUserId }
                        .map { SimpleUser(id: $0.user_id, name: $0.name, avatar: $0.avatar) }
                    
                    pendingConfirmations[item.id] = PendingConfirmationInfo(
                        initiatorName: initiator.name,
                        initiatorAvatar: initiator.avatar,
                        otherUsers: otherUsers
                    )
                }
                
                // Check if this item was initiated (has confirmations)
                if !status.confirmations.isEmpty {
                    initiatedItems.insert(item.id)
                    statusManager.confirmationStatuses[item.id] = status.confirmations
                    statusManager.statusResponses[item.id] = status
                }
                
            } catch {
                // Ignore errors for individual items
                continue
            }
        }
    }
}

// MARK: - Helper Structs

/// Info about a pending confirmation for displaying ConfirmationRequestCardView
struct PendingConfirmationInfo {
    let initiatorName: String
    let initiatorAvatar: String
    let otherUsers: [SimpleUser]
}

// MARK: - Preview

#Preview {
    ActionTabView()
}
