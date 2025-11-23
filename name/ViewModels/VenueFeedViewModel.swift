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
    @Published var recommendations: [RecommendationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String? = nil
    @Published var lastUpdated: Date? = nil
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var recommendationScores: [String: Double] = [:] // venueId -> score mapping
    
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
            // Pass user_1 as the current user to get distance calculations
            let fetchedVenues = try await apiService.fetchVenues(userId: "user_1")
            
            // Update UI on main thread
            await MainActor.run {
                self.venues = sortVenuesByRecommendation(fetchedVenues)
                self.isLoading = false
                self.lastUpdated = Date()
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
    
    /// Loads personalized recommendations for the current user
    /// Updates recommendations array and merges scores with venue list
    func loadRecommendations() async {
        // Note: Using hardcoded user ID - in production, get from AppState/Auth
        let userId = "user_1"
        
        do {
            let fetchedRecommendations = try await apiService.fetchRecommendations(userId: userId)
            
            await MainActor.run {
                // Limit to top 3 recommendations by score
                let topRecommendations = fetchedRecommendations
                    .sorted { $0.score > $1.score }
                    .prefix(3)
                
                self.recommendations = Array(topRecommendations)
                
                // Build score mapping for sorting venues (include all scores)
                self.recommendationScores = Dictionary(
                    uniqueKeysWithValues: fetchedRecommendations.map { ($0.venue.id, $0.score) }
                )
                
                // Re-sort existing venues by recommendation score
                self.venues = sortVenuesByRecommendation(self.venues)
            }
        } catch {
            // Silent fail for recommendations - they're supplementary
            print("Failed to load recommendations: \(error.localizedDescription)")
        }
    }
    
    /// Loads both venues and recommendations concurrently
    func loadAll() async {
        await loadVenues()
        await loadRecommendations()
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
    
    /// Returns recommendation score for a venue if available
    func recommendationScore(for venueId: String) -> Double? {
        return recommendationScores[venueId]
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
        guard let lastUpdated = lastUpdated else {
            return "Never"
        }
        
        let now = Date()
        let seconds = Int(now.timeIntervalSince(lastUpdated))
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    // MARK: - Private Methods
    
    /// Sorts venues by recommendation score (highest first), then by interested count
    private func sortVenuesByRecommendation(_ venues: [VenueListItem]) -> [VenueListItem] {
        return venues.sorted { venue1, venue2 in
            let score1 = recommendationScores[venue1.id] ?? 0
            let score2 = recommendationScores[venue2.id] ?? 0
            
            if score1 != score2 {
                return score1 > score2
            }
            
            // If scores equal, sort by interested count
            return venue1.interested_count > venue2.interested_count
        }
    }
}
