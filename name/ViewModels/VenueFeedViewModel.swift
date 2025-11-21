//
//  VenueFeedViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
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
