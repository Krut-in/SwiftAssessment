//
//  VenueFeedViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  ViewModel managing state and business logic for the venue discovery feed.
//  Handles venue fetching, loading states, error handling, and pull-to-refresh.
//  
//  RESPONSIBILITIES:
//  - Fetch venue list from API service
//  - Manage loading and error states
//  - Provide refresh functionality
//  - Handle API errors with user-friendly messages
//  
//  ARCHITECTURE:
//  - MVVM pattern: Separates view logic from UI
//  - ObservableObject: Publishes state changes to SwiftUI views
//  - @MainActor: Ensures all UI updates on main thread
//  - Protocol-based APIService: Enables testing with mocks
//  
//  STATE PROPERTIES:
//  - venues: Array of venue items to display
//  - isLoading: Loading indicator state
//  - errorMessage: Current error to display (if any)
//  
//  PUBLISHED PROPERTIES:
//  All @Published properties automatically notify views of changes,
//  triggering SwiftUI view updates when values change.
//  
//  ERROR HANDLING:
//  Distinguishes between:
//  - APIError: Known errors with descriptive messages
//  - Unknown errors: Unexpected errors with generic messages
//  
//  THREAD SAFETY:
//  - @MainActor ensures all property updates on main thread
//  - Async/await pattern for clean asynchronous code
//  - No manual DispatchQueue.main.async needed
//  
//  LOADING PREVENTION:
//  Guard clause prevents multiple simultaneous loads,
//  avoiding race conditions and duplicate API calls.
//  
//  USAGE:
//  @StateObject private var viewModel = VenueFeedViewModel()
//  // ViewModel automatically manages all state
//

import Foundation
import Combine

@MainActor
class VenueFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var venues: [VenueListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    /// Loads venues from the API
    /// Updates venues array, loading state, and error message
    func loadVenues() async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedVenues = try await apiService.fetchVenues()
            
            // Update UI on main thread
            await MainActor.run {
                self.venues = fetchedVenues
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
    
    /// Refreshes the venue list
    /// Used for pull-to-refresh functionality
    func refresh() async {
        await loadVenues()
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
}
