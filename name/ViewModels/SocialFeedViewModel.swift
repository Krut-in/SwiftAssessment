//
//  SocialFeedViewModel.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  ViewModel for the social feed view, managing friend activity data.
//  Handles fetching, pagination, and refresh logic for the activity timeline.
//  
//  FEATURES:
//  - Paginated activity loading
//  - Pull-to-refresh support
//  - Loading and error states
//  - Analytics tracking
//  
//  ARCHITECTURE:
//  - MVVM pattern with ObservableObject
//  - Async/await for network calls
//  - Published properties for SwiftUI binding
//

import Foundation
import Combine

@MainActor
class SocialFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activities: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMore: Bool = true
    
    // MARK: - Private Properties
    
    private let apiService: APIServiceProtocol
    private let analytics: AnalyticsServiceProtocol
    private let userId: String
    private var currentPage: Int = 1
    private let pageLimit: Int = 20
    
    // MARK: - Initialization
    
    init(
        apiService: APIServiceProtocol = APIService(),
        analytics: AnalyticsServiceProtocol,
        userId: String = "user_1"  // Default to primary user
    ) {
        self.apiService = apiService
        self.analytics = analytics
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    /// Load initial activities
    func loadActivities() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let response = try await apiService.fetchActivities(
                userId: userId,
                page: currentPage,
                limit: pageLimit
            )
            
            activities = response.activities
            hasMore = activities.count < response.total_count
            
            // Track analytics
            analytics.track(
                event: "social_feed_loaded",
                properties: [
                    "activity_count": activities.count,
                    "page": currentPage
                ]
            )
            
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
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
            let response = try await apiService.fetchActivities(
                userId: userId,
                page: currentPage,
                limit: pageLimit
            )
            
            activities.append(contentsOf: response.activities)
            hasMore = activities.count < response.total_count
            
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            currentPage -= 1  // Revert page increment on error
        }
        
        isLoading = false
    }
    
    /// Track activity tap
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
}
