//
//  AppState.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import Foundation
import Combine

/// Shared application state for managing user data and interests across views
@MainActor
class AppState: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppState()
    
    // MARK: - Published Properties
    
    /// Current user ID (hardcoded for MVP)
    @Published var currentUserId: String = "user_1"
    
    /// Set of venue IDs that the current user is interested in
    @Published var interestedVenueIds: Set<String> = []
    
    /// Alert message for booking agent responses
    @Published var bookingAgentMessage: String?
    @Published var showBookingAlert = false
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
        
        // Load user's interested venues on initialization
        Task {
            await loadUserInterests()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the current user's interested venues from the API
    func loadUserInterests() async {
        do {
            let response = try await apiService.fetchUserProfile(userId: currentUserId)
            
            await MainActor.run {
                self.interestedVenueIds = Set(response.interested_venues.map { $0.id })
            }
        } catch {
            // Silent fail - we'll show interest state as empty
            print("Failed to load user interests: \(error.localizedDescription)")
        }
    }
    
    /// Toggles interest for a venue
    /// - Parameter venueId: The venue ID to toggle interest for
    /// - Returns: Interest response with booking agent info
    @discardableResult
    func toggleInterest(venueId: String) async throws -> InterestResponse {
        let wasInterested = interestedVenueIds.contains(venueId)
        
        // Optimistic update
        if wasInterested {
            interestedVenueIds.remove(venueId)
        } else {
            interestedVenueIds.insert(venueId)
        }
        
        do {
            let response = try await apiService.expressInterest(userId: currentUserId, venueId: venueId)
            
            // Handle booking agent response - delay to avoid view update conflicts
            if let agentTriggered = response.agent_triggered, agentTriggered,
               let message = response.message {
                // Use Task with slight delay to ensure we're not in a view update cycle
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    self.bookingAgentMessage = message
                    self.showBookingAlert = true
                }
            }
            
            return response
        } catch {
            // Revert optimistic update on error
            if wasInterested {
                interestedVenueIds.insert(venueId)
            } else {
                interestedVenueIds.remove(venueId)
            }
            throw error
        }
    }
    
    /// Checks if user is interested in a venue
    /// - Parameter venueId: The venue ID to check
    /// - Returns: True if user is interested, false otherwise
    func isInterested(in venueId: String) -> Bool {
        interestedVenueIds.contains(venueId)
    }
    
    /// Clears the booking agent alert
    func clearBookingAlert() {
        showBookingAlert = false
        bookingAgentMessage = nil
    }
}
