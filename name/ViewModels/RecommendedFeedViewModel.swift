//
//  RecommendedFeedViewModel.swift
//  name
//
//  Created by Krutin Rathod on 24/11/25.
//
//  DESCRIPTION:
//  ViewModel managing state and business logic for the personalized recommendations feed.
//  Handles recommendation fetching, filtering by category, sorting, loading states, and error handling.
//  
//  RESPONSIBILITIES:
//  - Fetch personalized recommendations from API service
//  - Manage category filter state (All, Bar, Coffee Shop, Restaurant, etc.)
//  - Manage sort state (Distance, Popularity, Friends Interested, Name)
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
//  - recommendations: Array of recommendation items to display
//  - selectedCategory: Current category filter (nil = "All")
//  - sortBy: Current sort option
//  - isLoading: Loading indicator state
//  - errorMessage: Current error to display (if any)
//  
//  SORTING OPTIONS:
//  - Distance: Sort by venue.distance_km (ascending - closest first)
//  - Popularity: Sort by total_interested (descending - most popular first)
//  - Friends Interested: Sort by friends_interested (descending - most friends first)
//  - Name: Sort alphabetically by venue.name (A-Z)
//  
//  FILTERING:
//  - Filter recommendations by venue.category
//  - Uses existing backend categories: All, Bar, Coffee Shop, Restaurant, Nightclub, Activity
//  
//  USAGE:
//  @StateObject private var viewModel = RecommendedFeedViewModel()
//  // ViewModel automatically manages all state
//

import Foundation
import Combine

@MainActor
class RecommendedFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var recommendations: [RecommendationItem] = []
    @Published var selectedCategory: String? = nil
    @Published var sortBy: SortOption = .popularity
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date? = nil
    
    // MARK: - Computed Properties
    
    /// Returns filtered recommendations based on selected category
    var filteredRecommendations: [RecommendationItem] {
        var filtered = recommendations
        
        // Apply category filter if selected
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.venue.category == selectedCategory }
        }
        
        return sortRecommendations(filtered)
    }
    
    /// Returns unique categories from all recommendations
    var availableCategories: [String] {
        let categories = Set(recommendations.map { $0.venue.category })
        return Array(categories).sorted()
    }
    
    /// Returns count of recommendations per category
    var categoryCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for recommendation in recommendations {
            counts[recommendation.venue.category, default: 0] += 1
        }
        return counts
    }
    
    /// Returns formatted relative time since last update
    var lastUpdatedText: String {
        lastUpdated?.relativeTimeString() ?? "Never"
    }
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiService: APIServiceProtocol = APIService(), appState: AppState) {
        self.apiService = apiService
        self.appState = appState
    }
    
    // MARK: - Public Methods
    
    /// Loads personalized recommendations from the API
    /// Updates recommendations array, loading state, and error message
    func loadRecommendations() async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use current user ID from AppState
            let fetchedRecommendations = try await apiService.fetchRecommendations(userId: appState.currentUserId)
            
            // Update UI - already on main thread due to @MainActor
            // Store ALL recommendations (no limit of 3)
            self.recommendations = fetchedRecommendations
            self.isLoading = false
            self.lastUpdated = Date()
        } catch let error as APIError {
            // Handle API-specific errors
            self.errorMessage = error.errorDescription
            self.isLoading = false
        } catch {
            // Handle unexpected errors
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Applies the current sort option to recommendations
    func applySort() {
        // Trigger re-computation of filteredRecommendations
        // SwiftUI will automatically refresh the view
        objectWillChange.send()
    }
    
    /// Refreshes the recommendation list
    /// Used for pull-to-refresh functionality
    func refresh() async {
        await loadRecommendations()
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Sorts recommendations based on the current sort option
    private func sortRecommendations(_ recommendations: [RecommendationItem]) -> [RecommendationItem] {
        switch sortBy {
        case .distance:
            return recommendations.sorted {
                // Sort by distance ascending (closest first)
                // Treat nil distance as farthest
                guard let dist1 = $0.venue.distance_km else { return false }
                guard let dist2 = $1.venue.distance_km else { return true }
                return dist1 < dist2
            }
            
        case .popularity:
            return recommendations.sorted {
                // Sort by total_interested descending (highest first)
                if $0.total_interested != $1.total_interested {
                    return $0.total_interested > $1.total_interested
                }
                // Secondary sort by recommendation score
                if $0.score != $1.score {
                    return $0.score > $1.score
                }
                // Tertiary sort by name
                return $0.venue.name < $1.venue.name
            }
            
        case .friends:
            return recommendations.sorted {
                // Sort by friends_interested descending (highest first)
                if $0.friends_interested != $1.friends_interested {
                    return $0.friends_interested > $1.friends_interested
                }
                // Secondary sort by recommendation score
                if $0.score != $1.score {
                    return $0.score > $1.score
                }
                // Tertiary sort by name
                return $0.venue.name < $1.venue.name
            }
            
        case .name:
            return recommendations.sorted {
                // Sort by name ascending (A-Z)
                $0.venue.name.localizedCaseInsensitiveCompare($1.venue.name) == .orderedAscending
            }
        }
    }
}
