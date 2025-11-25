//
//  AppState.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Centralized application state manager for global user data and interests.
//  Implements the singleton pattern to ensure consistent state across all views.
//  Handles interest toggling with optimistic updates and automatic rollback on errors.
//  
//  KEY RESPONSIBILITIES:
//  - Manages current user ID and their interested venue IDs
//  - Provides interest toggling with network synchronization
//  - Handles booking agent alert state for global notifications
//  - Loads user interests on app initialization
//  
//  ARCHITECTURE NOTES:
//  - Singleton pattern ensures single source of truth
//  - @MainActor ensures all UI updates happen on main thread
//  - Uses optimistic updates for better UX (updates UI before API confirmation)
//  - Automatically reverts changes if API calls fail
//  
//  THREAD SAFETY:
//  - All methods are @MainActor to ensure thread-safe UI updates
//  - Async/await pattern used for all network operations
//

import Foundation
import Combine

/// Shared application state for managing user data and interests across views
@MainActor
class AppState: ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = AppState()
    
    // MARK: - Published Properties
    
    /// Current user ID (hardcoded for MVP)
    @Published var currentUserId: String = "user_1"
    
    /// Set of venue IDs that the current user is interested in
    @Published var interestedVenueIds: Set<String> = []
    
    /// Action item toast state
    @Published var pendingActionItem: ActionItem?
    @Published var showActionItemToast = false
    
    /// Action item count for badge display
    @Published var actionItemCount: Int = 0
    
    /// Selected tab index for tab navigation
    @Published var selectedTab: Int = 0
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    nonisolated private init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
        
        // Load user's interested venues on initialization
        Task { @MainActor in
            await loadUserInterests()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the current user's interested venues from the API
    func loadUserInterests() async {
        do {
            let response = try await apiService.fetchUserProfile(userId: currentUserId)
            
            await MainActor.run {
                self.interestedVenueIds = Set(response.interested_venues.map { $0.id })
                self.actionItemCount = response.action_items.count
            }
        } catch {
            // Silent fail - we'll show interest state as empty
            print("Failed to load user interests: \(error.localizedDescription)")
        }
    }
    
    /// Toggles interest for a venue
    /// - Parameter venueId: The venue ID to toggle interest for
    /// - Returns: Interest response with booking agent info
    @discardableResult
    func toggleInterest(venueId: String) async throws -> InterestResponse {
        let wasInterested = interestedVenueIds.contains(venueId)
        
        // Optimistic update
        if wasInterested {
            interestedVenueIds.remove(venueId)
        } else {
            interestedVenueIds.insert(venueId)
        }
        
        do {
            let response = try await apiService.expressInterest(userId: currentUserId, venueId: venueId)
            
            // Handle action item response
            if let actionItemData = response.action_item,
               actionItemData.action_item_created,
               let itemId = actionItemData.action_item_id,
               let description = actionItemData.description,
               let actionCode = actionItemData.action_code,
               let interestedUserIds = actionItemData.interested_user_ids {
                
                // Create ActionItem for toast display
                let actionItem = ActionItem(
                    id: itemId,
                    venue_id: venueId,
                    interested_user_ids: interestedUserIds,
                    action_type: "book_venue", // Will be provided by backend
                    action_code: actionCode,
                    description: description,
                    threshold_met: true,
                    status: "pending",
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    venue: nil
                )
                
                showActionItemNotification(actionItem)
            }
            
            return response
        } catch {
            // Revert optimistic update on error
            if wasInterested {
                interestedVenueIds.insert(venueId)
            } else {
                interestedVenueIds.remove(venueId)
            }
            throw error
        }
    }
    
    /// Shows action item notification toast
    /// - Parameter actionItem: The action item to display
    func showActionItemNotification(_ actionItem: ActionItem) {
        pendingActionItem = actionItem
        showActionItemToast = true
    }
    
    /// Checks if user is interested in a venue
    /// - Parameter venueId: The venue ID to check
    /// - Returns: True if user is interested, false otherwise
    func isInterested(in venueId: String) -> Bool {
        interestedVenueIds.contains(venueId)
    }
}
