//
//  VenueDetailViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
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
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let venueId: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(venueId: String, apiService: APIServiceProtocol = APIService()) {
        self.venueId = venueId
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    /// Loads venue details from the API
    func loadVenueDetail() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchVenueDetail(venueId: venueId)
            
            // Update UI on main thread
            await MainActor.run {
                self.venue = response.venue
                self.interestedUsers = response.interested_users
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
    /// - Parameter userId: The ID of the current user
    func toggleInterest(userId: String) async {
        // This will be implemented in Phase 3
        // Placeholder for now
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
}
