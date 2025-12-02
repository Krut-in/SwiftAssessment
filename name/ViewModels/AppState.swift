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
/// Thread safety is guaranteed by @MainActor isolation - all access occurs on main thread
@MainActor
class AppState: ObservableObject {
    
    // MARK: - Singleton
    
    nonisolated(unsafe) static let shared = AppState()
    
    // MARK: - Published Properties
    
    /// Current user ID (from authentication service)
    @Published var currentUserId: String = ""
    
    /// Set of venue IDs that the current user is interested in
    @Published var interestedVenueIds: Set<String> = []
    
    /// Action item toast state
    @Published var pendingActionItem: ActionItem?
    @Published var showActionItemToast = false
    
    /// Action item count for badge display
    @Published var actionItemCount: Int = 0
    
    /// Selected tab index for tab navigation
    @Published var selectedTab: Int = 0
    
    /// Deep link venue ID for navigation
    @Published var deepLinkVenueId: String?
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    nonisolated private init(
        apiService: APIServiceProtocol = APIService(),
        authService: AuthenticationServiceProtocol = MockAuthenticationService.shared
    ) {
        self.apiService = apiService
        self.authService = authService
        
        // Initialize currentUserId from auth service
        Task { @MainActor in
            self.currentUserId = authService.getCurrentUserId()
            await loadUserInterests()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the current user's interested venues from the API
    func loadUserInterests() async {
        do {
            let response = try await apiService.fetchUserProfile(userId: currentUserId)
            
            // Update state - already on main thread due to @MainActor
            self.interestedVenueIds = Set(response.interested_venues.map { $0.id })
            self.actionItemCount = response.action_items.count
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
    
    /// Switches to a different user and reloads data
    /// - Parameter userId: The user ID to switch to
    func switchUser(to userId: String) async {
        authService.switchUser(to: userId)
        currentUserId = authService.getCurrentUserId()
        
        // Clear current state
        interestedVenueIds.removeAll()
        actionItemCount = 0
        
        // Reload data for new user
        await loadUserInterests()
    }
    
    /// Handles deep link navigation
    /// - Parameter url: The deep link URL to handle
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "luna" else { return }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // Parse luna://venues/{venue_id}
        if pathComponents.count == 2,
           pathComponents[0] == "venues" {
            deepLinkVenueId = pathComponents[1]
            print("🔗 Deep link: Opening venue \(pathComponents[1])")
        }
    }
}
