//
//  ProfileViewModel.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var user: User?
    @Published var interestedVenues: [Venue] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(apiService: APIServiceProtocol = APIService(), appState: AppState = .shared) {
        self.apiService = apiService
        self.appState = appState
        
        // Observe app state for interest changes to reload profile
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Reload profile when interested venues change
        appState.$interestedVenueIds
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    await self.loadProfile()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads user profile from the API
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchUserProfile(userId: appState.currentUserId)
            
            await MainActor.run {
                self.user = response.user
                self.interestedVenues = response.interested_venues
                self.isLoading = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                self.isLoading = false
            }
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
}
