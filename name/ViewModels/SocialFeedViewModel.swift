//
//  SocialFeedViewModel.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//  Updated on 02/12/25 for Social Interest Activity Feed feature.
//
//  DESCRIPTION:
//  ViewModel for the social feed view, managing friend interest activities
//  and highlighted venues that have reached critical mass for group meetups.
//  
//  FEATURES:
//  - Friend interest activity feed with real-time updates
//  - Highlighted venues section for venues with 5+ interested friends
//  - Pull-to-refresh and pagination support
//  - Mock data generation for demonstration
//  - Analytics tracking for user interactions
//  
//  ARCHITECTURE:
//  - MVVM pattern with ObservableObject
//  - Integrates with AppState for global state synchronization
//  - Async/await for network calls
//  - Published properties for SwiftUI binding
//

import Foundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

@MainActor
class SocialFeedViewModel: ObservableObject {
    
    // MARK: - Configuration
    
    /// Threshold for highlighting a venue (number of interested friends)
    static let highlightThreshold: Int = 5
    
    // MARK: - Published Properties
    
    @Published var activities: [Activity] = []
    @Published var interestActivities: [InterestActivity] = []
    @Published var highlightedVenues: [HighlightedVenue] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMore: Bool = true
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let analytics: AnalyticsServiceProtocol
    private let appState: AppState
    private let userId: String
    private var currentPage: Int = 1
    private let pageLimit: Int = 20
    private var cancellables = Set<AnyCancellable>()
    
    // Real-time polling
    private var refreshTimer: Timer?
    private var lastRefreshTime: Date?
    
    // MARK: - Initialization
    
    init(
        apiService: APIServiceProtocol = APIService(),
        analytics: AnalyticsServiceProtocol,
        appState: AppState = .shared,
        userId: String = "user_1"
    ) {
        self.apiService = apiService
        self.analytics = analytics
        self.appState = appState
        self.userId = userId
        
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe AppState for social feed updates
        appState.$socialFeedActivities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activities in
                self?.interestActivities = activities
            }
            .store(in: &cancellables)
        
        appState.$highlightedVenues
            .receive(on: DispatchQueue.main)
            .sink { [weak self] venues in
                self?.highlightedVenues = venues
            }
            .store(in: &cancellables)
        
        // Observe user switching to reload data with mock activities for the new user
        appState.$currentUserId
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Clear current activities and reload with new mock data
                self.activities = []
                Task {
                    await self.loadActivities()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load initial activities from social feed endpoint (real data from backend)
    func loadActivities() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let response = try await apiService.fetchSocialFeed(
                userId: userId,
                page: currentPage,
                limit: pageLimit,
                since: nil
            )
            
            // Store real backend data (NO MOCK DATA)
            interestActivities = response.activities
            highlightedVenues = response.highlightedVenues
            hasMore = response.hasMore
            
            // Update AppState for global sync
            appState.socialFeedActivities = response.activities
            appState.highlightedVenues = response.highlightedVenues
            
            // Store timestamp for incremental updates
            lastRefreshTime = Date()
            
            // Track analytics
            analytics.track(
                event: "social_feed_loaded",
                properties: [
                    "activity_count": response.activities.count,
                    "highlighted_count": response.highlightedVenues.count,
                    "page": currentPage
                ]
            )
            
            // Mark social feed as viewed
            appState.markSocialFeedAsViewed()
            
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            
            // NO MOCK DATA - show real error
            analytics.track(
                event: "social_feed_error",
                properties: ["error": errorMessage ?? "Unknown"]
            )
        }
        
        isLoading = false
    }
    
    /// Refresh activities (pull-to-refresh)
    func refreshActivities() async {
        currentPage = 1
        await loadActivities()
    }
    
    
    /// Load more activities (pagination)
    func loadMoreActivities() async {
        guard !isLoading, hasMore else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let response = try await apiService.fetchSocialFeed(
                userId: userId,
                page: currentPage,
                limit: pageLimit,
                since: nil
            )
            
            interestActivities.append(contentsOf: response.activities)
            hasMore = response.hasMore
            
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            currentPage -= 1
        }
        
        isLoading = false
    }
    
    // MARK: - Real-Time Updates
    
    /// Start auto-refresh timer for real-time updates
    func startAutoRefresh(interval: TimeInterval = 30.0) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNewActivities()
            }
        }
    }
    
    /// Stop auto-refresh timer
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Check for new activities since last refresh
    private func checkForNewActivities() async {
        guard let lastRefresh = lastRefreshTime else {
            await loadActivities()
            return
        }
        
        do {
            let response = try await apiService.fetchSocialFeed(
                userId: userId,
                page: 1,
                limit: 20,
                since: lastRefresh
            )
            
            // Check if we got new activities (comparing with current count)
            let hasNewActivities = !response.activities.isEmpty && 
                                   response.activities.first?.id != interestActivities.first?.id
            
            if hasNewActivities {
                // New activities found!
                let oldCount = interestActivities.count
                interestActivities = response.activities
                highlightedVenues = response.highlightedVenues
                lastRefreshTime = Date()
                
                // Update AppState
                appState.socialFeedActivities = response.activities
                appState.highlightedVenues = response.highlightedVenues
                
                // Show notification (haptic feedback only for now)
                let newCount = response.activities.count - oldCount
                if newCount > 0 {
                    showNewActivityFeedback()
                }
            }
        } catch {
            // Silently fail for background refresh
        }
    }
    
    private func showNewActivityFeedback() {
        // Trigger haptic feedback for new activities
        Task { @MainActor in
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
    }
    
    /// Track activity tap for analytics
    /// - Parameter activity: Activity that was tapped
    func trackActivityTap(_ activity: Activity) {
        analytics.track(
            event: AnalyticsService.Event.socialActivityTapped,
            properties: [
                AnalyticsService.PropertyKey.venueId: activity.venue.id,
                AnalyticsService.PropertyKey.venueName: activity.venue.name,
                AnalyticsService.PropertyKey.category: activity.venue.category,
                AnalyticsService.PropertyKey.action: activity.action
            ]
        )
    }
    
    /// Track interest activity tap for analytics
    /// - Parameter activity: InterestActivity that was tapped
    func trackInterestActivityTap(_ activity: InterestActivity) {
        analytics.track(
            event: AnalyticsService.Event.socialActivityTapped,
            properties: [
                AnalyticsService.PropertyKey.venueId: activity.venue.id,
                AnalyticsService.PropertyKey.venueName: activity.venue.name,
                AnalyticsService.PropertyKey.category: activity.venue.category,
                AnalyticsService.PropertyKey.action: activity.action.rawValue
            ]
        )
    }
    
    /// Track highlighted venue tap for analytics
    /// - Parameter venue: HighlightedVenue that was tapped
    func trackHighlightedVenueTap(_ venue: HighlightedVenue) {
        analytics.track(
            event: "highlighted_venue_tapped",
            properties: [
                "venue_id": venue.venueId,
                "venue_name": venue.venueName,
                "interested_count": venue.totalInterestedCount,
                "category": venue.venueCategory
            ]
        )
    }
    
    /// Track plan meetup action for analytics
    /// - Parameter venue: HighlightedVenue for which meetup was initiated
    func trackPlanMeetupTap(_ venue: HighlightedVenue) {
        analytics.track(
            event: "plan_meetup_initiated",
            properties: [
                "venue_id": venue.venueId,
                "venue_name": venue.venueName,
                "friend_count": venue.interestedFriends.count
            ]
        )
    }
}
