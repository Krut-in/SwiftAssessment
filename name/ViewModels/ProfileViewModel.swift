//
//  ProfileViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  ViewModel managing state and business logic for user profile view.
//  Handles user profile fetching and interested venues display.
//  
//  RESPONSIBILITIES:
//  - Fetch current user's profile from API
//  - Load user's interested venues with details
//  - Manage loading and error states
//  - Provide refresh functionality
//  - Handle API errors gracefully
//  
//  ARCHITECTURE:
//  - MVVM pattern with ObservableObject
//  - @MainActor for thread-safe UI updates
//  - Protocol-based APIService for testing
//  - Uses AppState for current user ID
//  
//  STATE PROPERTIES:
//  - user: Current user's profile data (optional until loaded)
//  - interestedVenues: Array of venues user is interested in
//  - isLoading: Loading indicator state
//  - errorMessage: Current error message to display
//  
//  STATE MANAGEMENT STRATEGY:
//  ProfileViewModel previously had an observer that caused infinite loops.
//  Current approach: Manual reload on view appear.
//  
//  REMOVED: Automatic reload on AppState.interestedVenueIds change
//  REASON: Caused infinite reload loop
//  SOLUTION: View calls loadProfile() on appear
//  
//  This ensures profile is up-to-date without the infinite loop:
//  - User expresses interest -> AppState updates
//  - User navigates to profile -> View appears
//  - Profile reloads with latest data
//  
//  WHY INFINITE LOOP OCCURRED:
//  1. User expresses interest
//  2. AppState.interestedVenueIds changes
//  3. ProfileViewModel observer triggers loadProfile()
//  4. loadProfile() updates interestedVenues
//  5. This can trigger observer again (cycle)
//  
//  ERROR HANDLING:
//  - APIError: Known errors with descriptive messages
//  - Generic errors: Fallback error messages
//  - Non-blocking: Errors don't prevent app usage
//  
//  THREAD SAFETY:
//  - @MainActor ensures main thread updates
//  - Async/await for clean asynchronous code
//  - Combine observers use main scheduler
//  
//  LOADING PREVENTION:
//  No guard needed here as View controls when to load.
//  Profile refresh is user-initiated via pull-to-refresh.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var user: User?
    @Published var interestedVenues: [Venue] = []
    @Published var actionItems: [ActionItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date? = nil
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(userId: String, apiService: APIServiceProtocol = APIService(), appState: AppState) {
        self.apiService = apiService
        self.appState = appState
        
        // Observe app state for interest changes to reload profile
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observer removed to prevent infinite reload loop
        // Profile will refresh on manual pull-to-refresh or when view appears
    }
    
    // MARK: - Public Methods
    
    /// Loads user profile from the API
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchUserProfile(userId: appState.currentUserId)
            
            // Update state - already on main thread due to @MainActor
            self.user = response.user
            self.interestedVenues = response.interested_venues
            self.actionItems = response.action_items
            self.isLoading = false
            self.lastUpdated = Date()
            
            // Update global action item count for badge
            appState.actionItemCount = response.action_items.count
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
            self.isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Completes an action item
    /// - Parameter itemId: The ID of the action item to complete
    func completeActionItem(_ itemId: String) async {
        do {
            _ = try await apiService.completeActionItem(itemId: itemId, userId: appState.currentUserId)
            
            // Remove from local list - already on main thread due to @MainActor
            actionItems.removeAll { $0.id == itemId }
            appState.actionItemCount = actionItems.count
        } catch {
            self.errorMessage = "Failed to complete action item: \(error.localizedDescription)"
        }
    }
    
    /// Dismisses an action item
    /// - Parameter itemId: The ID of the action item to dismiss
    func dismissActionItem(_ itemId: String) async {
        do {
            _ = try await apiService.dismissActionItem(itemId: itemId, userId: appState.currentUserId)
            
            // Remove from local list - already on main thread due to @MainActor
            actionItems.removeAll { $0.id == itemId }
            appState.actionItemCount = actionItems.count
        } catch {
            self.errorMessage = "Failed to dismiss action item: \(error.localizedDescription)"
        }
    }
    
    /// Refreshes the profile
    func refresh() async {
        await loadProfile()
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Returns formatted relative time since last update
    var lastUpdatedText: String {
        lastUpdated?.relativeTimeString() ?? "Never"
    }
}
