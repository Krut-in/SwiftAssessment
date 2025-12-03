//
//  VenueFeedViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  ViewModel managing state and business logic for the venue discovery feed.
//  Handles venue fetching, filtering, sorting, loading states, and error handling.
//  
//  RESPONSIBILITIES:
//  - Fetch venue list from API service with filters
//  - Manage filter state and active filter counts
//  - Manage loading and error states
//  - Provide refresh functionality
//  - Handle API errors with user-friendly messages
//  
//  ARCHITECTURE:
//  - MVVM pattern: Separates view logic from UI
//  - ObservableObject: Publishes state changes to SwiftUI views
//  - @MainActor: Ensures all UI updates on main thread
//  - Protocol-based APIService: Enables testing with mocks
//  - Uses AppState for current user ID
//  
//  STATE PROPERTIES:
//  - venues: Array of venue items to display
//  - filters: Current filter state
//  - showFilterSheet: Controls filter sheet presentation
//  - isLoading: Loading indicator state
//  - errorMessage: Current error to display (if any)
//  
//  PUBLISHED PROPERTIES:
//  All @Published properties automatically notify views of changes,
//  triggering SwiftUI view updates when values change.
//  
//  FILTER MANAGEMENT:
//  - filters property holds all filter state
//  - activeFilterCount computed from filters
//  - activeSummary provides human-readable filter description
//  - clearFilters() resets to defaults
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
//

import Foundation
import Combine

@MainActor
class VenueFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var venues: [VenueListItem] = []
    @Published var filters = VenueFilters()
    @Published var showFilterSheet = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String? = nil
    @Published var lastUpdated: Date? = nil
    
    // MARK: - Computed Properties
    
    var activeFilterCount: Int {
        filters.activeFilterCount
    }
    
    var activeSummary: String? {
        filters.activeSummary
    }
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let appState: AppState
    private let persistence: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    
    // MARK: - Initialization
    
    init(apiService: APIServiceProtocol = APIService(), appState: AppState, persistence: PersistenceController = .shared) {
        self.apiService = apiService
        self.appState = appState
        self.persistence = persistence
    }
    
    // MARK: - Public Methods
    
    /// Loads venues from the API with current filters
    /// Implements cache-first strategy: loads cached data first, then fetches from network
    /// Updates venues array, loading state, and error message
    func loadVenues() async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }
        
        // Check if we have cached data
        let hasCached = persistence.hasCachedData()
        
        // Load from cache first for instant UI
        if hasCached {
            let cachedVenus = persistence.fetchCachedVenues()
            // Trust cached order (matches last server response)
            self.venues = cachedVenus
            if let cacheTime = persistence.getCacheTimestamp() {
                self.lastUpdated = cacheTime
            }
        }
        
        // Always try to fetch fresh data from network
        isLoading = true
        errorMessage = nil
        
        do {
            // Use current user ID from AppState
            let fetchedVenues = try await apiService.fetchVenues(userId: appState.currentUserId, filters: filters)
            
            // Save to cache for offline access
            persistence.saveVenues(fetchedVenues)
            
            // Update UI - already on main thread due to @MainActor
            // Trust backend-provided sort order (server-side sorting)
            self.venues = fetchedVenues
            self.isLoading = false
            self.lastUpdated = Date()
        } catch let error as APIError {
            // Handle API-specific errors
            // Only show error if we don't have cached data
            if !hasCached {
                self.errorMessage = error.errorDescription
            }
            self.isLoading = false
        } catch {
            // Handle unexpected errors
            // Only show error if we don't have cached data
            if !hasCached {
                self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
    
    /// Applies current filters by reloading venues
    func applyFilters() async {
        await loadVenues()
    }
    
    /// Clears all filters and reloads venues
    func clearFilters() async {
        filters.reset()
        await loadVenues()
    }

    
    /// Loads venues from the API
    func loadAll() async {
        await loadVenues()
    }
    
    /// Refreshes the venue list
    /// Used for pull-to-refresh functionality
    func refresh() async {
        await loadAll()
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }

    
    /// Returns unique categories from all venues
    var availableCategories: [String] {
        let categories = Set(venues.map { $0.category })
        return Array(categories).sorted()
    }
    
    /// Returns count of venues per category
    var categoryCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for venue in venues {
            counts[venue.category, default: 0] += 1
        }
        return counts
    }
    
    /// Returns formatted relative time since last update
    var lastUpdatedText: String {
        lastUpdated?.relativeTimeString() ?? "Never"
    }
}
