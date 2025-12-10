//
//  ActionItemStatusManager.swift
//  name
//
//  Created by Antigravity AI on 10/12/25.
//
//  DESCRIPTION:
//  Observable manager for tracking action item confirmation statuses.
//  Polls the backend at regular intervals to provide real-time updates.
//
//  FEATURES:
//  - 3-second polling interval for confirmation status updates
//  - Auto-stop when all users have responded
//  - Cleanup on view disappear
//  - Thread-safe state updates via @MainActor
//

import Foundation
import Combine

@MainActor
class ActionItemStatusManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Dictionary of action item IDs to their confirmation statuses
    @Published var confirmationStatuses: [String: [ConfirmationStatus]] = [:]
    
    /// Dictionary of action item IDs to their status response (includes chat info)
    @Published var statusResponses: [String: ActionItemStatusResponse] = [:]
    
    /// Currently polling action item IDs
    @Published var pollingItems: Set<String> = []
    
    /// Error message if polling fails
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private let pollingInterval: TimeInterval = 3.0
    
    // MARK: - Initialization
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    /// Starts polling for an action item's confirmation status
    /// - Parameter actionItemId: The ID of the action item to poll
    func startPolling(actionItemId: String) {
        // Don't start if already polling
        guard !pollingItems.contains(actionItemId) else { return }
        
        pollingItems.insert(actionItemId)
        
        // Create polling task
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled && self.pollingItems.contains(actionItemId) {
                await self.fetchStatus(actionItemId: actionItemId)
                
                // Check if all users have responded
                if self.shouldStopPolling(actionItemId: actionItemId) {
                    self.stopPolling(actionItemId: actionItemId)
                    break
                }
                
                // Wait before next poll
                try? await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
            }
        }
        
        pollingTasks[actionItemId] = task
    }
    
    /// Stops polling for an action item's confirmation status
    /// - Parameter actionItemId: The ID of the action item to stop polling
    func stopPolling(actionItemId: String) {
        pollingTasks[actionItemId]?.cancel()
        pollingTasks.removeValue(forKey: actionItemId)
        pollingItems.remove(actionItemId)
    }
    
    /// Stops all active polling
    func stopAllPolling() {
        for (itemId, task) in pollingTasks {
            task.cancel()
            pollingItems.remove(itemId)
        }
        pollingTasks.removeAll()
    }
    
    /// Manually fetches status once (useful for initial load)
    /// - Parameter actionItemId: The ID of the action item
    func fetchStatusOnce(actionItemId: String) async {
        await fetchStatus(actionItemId: actionItemId)
    }
    
    /// Gets the count of confirmed users for an action item
    /// - Parameter actionItemId: The ID of the action item
    /// - Returns: Tuple of (confirmed count, total count)
    func getConfirmationCount(actionItemId: String) -> (confirmed: Int, total: Int) {
        guard let statuses = confirmationStatuses[actionItemId] else {
            return (0, 0)
        }
        
        let confirmed = statuses.filter { $0.status == .confirmed }.count
        // Add 1 for initiator who is always confirmed
        let totalConfirmed = confirmed + (statusResponses[actionItemId]?.initiator != nil ? 1 : 0)
        // Total includes all users (confirmations + initiator)
        let total = statuses.count + (statusResponses[actionItemId]?.initiator != nil ? 1 : 0)
        
        return (totalConfirmed, total)
    }
    
    /// Checks if a chat has been created for an action item
    /// - Parameter actionItemId: The ID of the action item
    /// - Returns: Chat ID if created, nil otherwise
    func getChatId(actionItemId: String) -> String? {
        return statusResponses[actionItemId]?.chat_id
    }
    
    /// Checks if Go Ahead was initiated for an action item
    /// - Parameter actionItemId: The ID of the action item
    /// - Returns: True if initiated
    func isGoAheadInitiated(actionItemId: String) -> Bool {
        return statusResponses[actionItemId] != nil && 
               !(confirmationStatuses[actionItemId]?.isEmpty ?? true)
    }
    
    /// Gets the initiator info for an action item
    /// - Parameter actionItemId: The ID of the action item
    /// - Returns: ConfirmationStatus of initiator if available
    func getInitiator(actionItemId: String) -> ConfirmationStatus? {
        return statusResponses[actionItemId]?.initiator
    }
    
    // MARK: - Private Methods
    
    /// Fetches the current status from the API
    private func fetchStatus(actionItemId: String) async {
        do {
            let response = try await apiService.getActionItemStatus(itemId: actionItemId)
            
            // Update state
            statusResponses[actionItemId] = response
            confirmationStatuses[actionItemId] = response.confirmations
            errorMessage = nil
            
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to fetch status: \(error.localizedDescription)"
        }
    }
    
    /// Checks if polling should stop (all users have responded)
    private func shouldStopPolling(actionItemId: String) -> Bool {
        guard let statuses = confirmationStatuses[actionItemId] else {
            return false
        }
        
        // Stop if all users have responded (no pending statuses)
        let hasPending = statuses.contains { $0.status == .pending }
        return !hasPending
    }
}
