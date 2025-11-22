//
//  VenueDetailViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  ViewModel managing state and business logic for venue detail view.
//  Handles venue detail fetching, interest toggling, and state synchronization.
//  
//  RESPONSIBILITIES:
//  - Fetch detailed venue information from API
//  - Display list of interested users
//  - Handle interest toggle with loading states
//  - Sync interest state with global AppState
//  - Show success/error messages for user actions
//  - Reload venue data after interest changes
//  
//  ARCHITECTURE:
//  - MVVM pattern with ObservableObject
//  - @MainActor for thread-safe UI updates
//  - Combine observers for AppState synchronization
//  - Protocol-based dependency injection for testing
//  
//  STATE PROPERTIES:
//  - venue: Full venue details (optional until loaded)
//  - interestedUsers: Array of users interested in venue
//  - isLoading: Main loading state for initial fetch
//  - isTogglingInterest: Loading state for interest button
//  - isInterested: Current user's interest status
//  - errorMessage: Current error to display
//  - successMessage: Success feedback (auto-dismissing)
//  
//  STATE SYNCHRONIZATION:
//  Uses Combine to observe AppState.interestedVenueIds:
//  - Automatically updates isInterested when global state changes
//  - Ensures consistency across app (e.g., after interest from feed)
//  - Weak self prevents retain cycles in observer closures
//  
//  INTEREST TOGGLE FLOW:
//  1. User taps interest button
//  2. isTogglingInterest = true (disables button)
//  3. Call AppState.toggleInterest (handles API)
//  4. Reload venue detail (updates interested users count)
//  5. Show success message (if not booking agent)
//  6. Auto-dismiss success after 2 seconds
//  7. isTogglingInterest = false (enables button)
//  
//  ERROR RECOVERY:
//  - API errors displayed in errorMessage
//  - Can retry via loadVenueDetail()
//  - Interest toggle errors revert optimistic updates
//  
//  LOADING PREVENTION:
//  Guard clause prevents multiple simultaneous detail loads.
//  Interest toggle is separately protected by isTogglingInterest.
//  
//  THREAD SAFETY:
//  - All state updates on main thread via @MainActor
//  - Combine observers use DispatchQueue.main
//  - No manual thread management required
//

import Foundation
import Combine

@MainActor
class VenueDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var venue: Venue?
    @Published var interestedUsers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isInterested = false
    @Published var isTogglingInterest = false
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let venueId: String
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(venueId: String, apiService: APIServiceProtocol = APIService(), appState: AppState = .shared) {
        self.venueId = venueId
        self.apiService = apiService
        self.appState = appState
        
        // Observe app state for interest changes
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Update isInterested when app state changes
        appState.$interestedVenueIds
            .map { [weak self] venueIds in
                guard let self = self else { return false }
                return venueIds.contains(self.venueId)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInterested in
                self?.isInterested = isInterested
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads venue details from the API
    func loadVenueDetail() async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchVenueDetail(venueId: venueId)
            
            // Update UI on main thread
            await MainActor.run {
                self.venue = response.venue
                self.interestedUsers = response.interested_users
                // Check if current user is in interested users
                self.isInterested = self.appState.isInterested(in: self.venueId)
                self.isLoading = false
            }
        } catch let error as APIError {
            // Handle API-specific errors
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isLoading = false
            }
        } catch {
            // Handle unexpected errors
            await MainActor.run {
                self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Toggles user interest in the venue
    func toggleInterest() async {
        isTogglingInterest = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await appState.toggleInterest(venueId: venueId)
            
            // Reload venue details to get updated interested users count
            await loadVenueDetail()
            
            // Show success feedback if not booking agent message
            if response.agent_triggered != true {
                await MainActor.run {
                    self.successMessage = response.message ?? "Interest updated successfully"
                }
                
                // Clear success message after 2 seconds
                Task { @MainActor in
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                        self.successMessage = nil
                    } catch {
                        // Task cancelled - safe to ignore
                    }
                }
            }
            
            await MainActor.run {
                self.isTogglingInterest = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isTogglingInterest = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update interest: \(error.localizedDescription)"
                self.isTogglingInterest = false
            }
        }
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
}
