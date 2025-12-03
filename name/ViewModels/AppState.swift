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
    
    /// Current user's display name (from authentication service)
    @Published var currentUserName: String = ""
    
    /// Current user's avatar URL (from authentication service)
    @Published var currentUserAvatar: String = ""
    
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
    
    // MARK: - Social Feed State
    
    /// Friend interest activities for social feed
    @Published var socialFeedActivities: [InterestActivity] = []
    
    /// Venues that have reached the interest threshold
    @Published var highlightedVenues: [HighlightedVenue] = []
    
    /// Count of new social activities since last view (for badge)
    @Published var newSocialActivityCount: Int = 0
    
    /// Last time social feed was viewed
    @Published var socialFeedLastViewed: Date?
    
    /// Social feed loading state
    @Published var socialFeedIsLoading: Bool = false
    
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
            self.updateCurrentUserInfo()
            await loadUserInterests()
        }
    }
    
    // MARK: - Private Methods
    
    /// Updates current user name and avatar from auth service
    private func updateCurrentUserInfo() {
        let availableUsers = authService.getAvailableUsers()
        if let currentUser = availableUsers.first(where: { $0.id == currentUserId }) {
            currentUserName = currentUser.name
            currentUserAvatar = currentUser.avatar
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
    /// - Parameter venueInfo: Optional venue info for social feed broadcast
    /// - Returns: Interest response with booking agent info
    @discardableResult
    func toggleInterest(venueId: String, venueInfo: ActivityVenue? = nil) async throws -> InterestResponse {
        let wasInterested = interestedVenueIds.contains(venueId)
        
        // Optimistic update
        if wasInterested {
            interestedVenueIds.remove(venueId)
        } else {
            interestedVenueIds.insert(venueId)
        }
        
        // Determine action for social feed
        let socialAction: InterestAction = wasInterested ? .notInterested : .interested
        
        do {
            let response = try await apiService.expressInterest(userId: currentUserId, venueId: venueId)
            
            // Broadcast to social feed
            await broadcastInterestToFriends(venueId: venueId, action: socialAction, venue: venueInfo)
            
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
        updateCurrentUserInfo()
        
        // Clear current state
        interestedVenueIds.removeAll()
        actionItemCount = 0
        
        // Clear social feed data for new user context
        socialFeedActivities.removeAll()
        highlightedVenues.removeAll()
        newSocialActivityCount = 0
        
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
    
    // MARK: - Social Feed Methods
    
    /// Broadcasts interest action to friends' social feeds
    /// Called when user expresses or removes interest in a venue
    /// - Parameters:
    ///   - venueId: The venue ID
    ///   - action: The interest action (interested or notInterested)
    ///   - venue: Optional venue details for creating local activity
    func broadcastInterestToFriends(venueId: String, action: InterestAction, venue: ActivityVenue?) async {
        // Create local activity for immediate feedback
        if action == .interested, let venue = venue {
            // Use actual user name and avatar from profile
            let displayName = currentUserName.isEmpty ? "Unknown User" : currentUserName
            let avatarURL = currentUserAvatar
            
            let newActivity = InterestActivity(
                id: UUID().uuidString,
                user: ActivityUser(
                    id: currentUserId,
                    name: displayName,
                    avatar: avatarURL
                ),
                venue: venue,
                action: action,
                timestamp: Date(),
                isActive: true
            )
            
            // Add to local feed (will be synced with backend)
            socialFeedActivities.insert(newActivity, at: 0)
            
            // Check if this venue should be highlighted
            updateHighlightedVenues(for: venueId, action: action)
        } else if action == .notInterested {
            // Remove activity from feed when user removes interest
            socialFeedActivities.removeAll { $0.venue.id == venueId && $0.user.id == currentUserId }
            
            // Update highlighted venues
            updateHighlightedVenues(for: venueId, action: action)
        }
    }
    
    /// Updates highlighted venues when interest changes
    /// - Parameters:
    ///   - venueId: The venue ID that changed
    ///   - action: The interest action performed
    private func updateHighlightedVenues(for venueId: String, action: InterestAction) {
        if let index = highlightedVenues.firstIndex(where: { $0.venueId == venueId }) {
            var venue = highlightedVenues[index]
            var friends = venue.interestedFriends
            
            if action == .interested {
                // Add current user to interested friends with actual profile info
                let displayName = currentUserName.isEmpty ? "Unknown User" : currentUserName
                let friendSummary = FriendSummary(
                    id: currentUserId,
                    name: displayName,
                    avatarURL: currentUserAvatar,
                    interestedTimestamp: Date()
                )
                if !friends.contains(where: { $0.id == currentUserId }) {
                    friends.append(friendSummary)
                }
            } else {
                // Remove current user from interested friends
                friends.removeAll { $0.id == currentUserId }
            }
            
            // Update the venue with new count
            let updatedVenue = HighlightedVenue(
                id: venue.id,
                venueId: venue.venueId,
                venueName: venue.venueName,
                venueImageURL: venue.venueImageURL,
                venueCategory: venue.venueCategory,
                venueAddress: venue.venueAddress,
                interestedFriends: friends,
                totalInterestedCount: friends.count,
                threshold: venue.threshold,
                lastActivityTimestamp: Date()
            )
            
            // Remove if below threshold, otherwise update
            if updatedVenue.totalInterestedCount < updatedVenue.threshold {
                highlightedVenues.remove(at: index)
            } else {
                highlightedVenues[index] = updatedVenue
            }
        }
    }
    
    /// Marks social feed as viewed and resets badge count
    func markSocialFeedAsViewed() {
        socialFeedLastViewed = Date()
        newSocialActivityCount = 0
    }
    
    /// Adds a new activity from friend to the social feed
    /// - Parameter activity: The new interest activity
    func addFriendActivity(_ activity: InterestActivity) {
        // Only add if it's not from current user
        guard activity.user.id != currentUserId else { return }
        
        // Insert at beginning for chronological order
        socialFeedActivities.insert(activity, at: 0)
        
        // Increment badge if not currently viewing social feed
        if selectedTab != 2 {
            newSocialActivityCount += 1
        }
    }
    
    /// Removes an activity when friend removes their interest
    /// - Parameters:
    ///   - userId: The friend's user ID
    ///   - venueId: The venue they removed interest from
    func removeFriendActivity(userId: String, venueId: String) {
        socialFeedActivities.removeAll { $0.user.id == userId && $0.venue.id == venueId }
    }
}
