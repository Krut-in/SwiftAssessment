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
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self.successMessage = nil
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
