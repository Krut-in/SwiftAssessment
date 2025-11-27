//
//  MockAppState.swift
//  nameTests
//
//  Created for MVI Foundation Sprint - CI-1
//
//  DESCRIPTION:
//  Mock implementation of AppState for unit testing.
//  Provides controllable state without network calls or singleton dependencies.
//
//  FEATURES:
//  - No network calls
//  - Configurable initial state
//  - Call tracking for verification
//

import Foundation
@testable import name

@MainActor
class MockAppState {
    
    // MARK: - Published Properties (Simulated)
    
    var currentUserId: String = "test_user_1"
    var interestedVenueIds: Set<String> = []
    var pendingActionItem: ActionItem?
    var showActionItemToast = false
    var actionItemCount: Int = 0
    var selectedTab: Int = 0
    
    // MARK: - Call Tracking
    
    var loadUserInterestsCalled = false
    var toggleInterestCalled = false
    var lastToggledVenueId: String?
    var shouldToggleFail = false
    var errorToThrow: Error = APIError.unknown
    
    // MARK: - Initializer
    
    init(userId: String = "test_user_1", interestedVenueIds: Set<String> = []) {
        self.currentUserId = userId
        self.interestedVenueIds = interestedVenueIds
    }
    
    // MARK: - Public Methods
    
    func loadUserInterests() async {
        loadUserInterestsCalled = true
        // In tests, we manually set interestedVenueIds
    }
    
    @discardableResult
    func toggleInterest(venueId: String) async throws -> InterestResponse {
        toggleInterestCalled = true
        lastToggledVenueId = venueId
        
        if shouldToggleFail {
            throw errorToThrow
        }
        
        // Toggle interest
        if interestedVenueIds.contains(venueId) {
            interestedVenueIds.remove(venueId)
        } else {
            interestedVenueIds.insert(venueId)
        }
        
        return InterestResponse(
            success: true,
            message: "Interest toggled",
            action_item: nil
        )
    }
    
    func showActionItemNotification(_ actionItem: ActionItem) {
        pendingActionItem = actionItem
        showActionItemToast = true
    }
    
    func isInterested(in venueId: String) -> Bool {
        return interestedVenueIds.contains(venueId)
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        currentUserId = "test_user_1"
        interestedVenueIds = []
        pendingActionItem = nil
        showActionItemToast = false
        actionItemCount = 0
        selectedTab = 0
        
        loadUserInterestsCalled = false
        toggleInterestCalled = false
        lastToggledVenueId = nil
        shouldToggleFail = false
    }
}
