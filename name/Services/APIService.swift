//
//  APIService.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Network service layer handling all API communication with the Luna backend.
//  Implements APIServiceProtocol for easy testing and dependency injection.
//  Provides type-safe API calls with comprehensive error handling.
//  
//  KEY FEATURES:
//  - Generic performRequest methods for DRY code
//  - Automatic JSON encoding/decoding with ISO8601 date support
//  - Detailed error types for better error handling
//  - Configurable base URL and URLSession for testing
//  - Production-ready timeout and connectivity settings
//  - URLComponents for safe URL construction
//  
//  API ENDPOINTS COVERED:
//  - GET /venues - Fetch all venues with interested counts
//  - GET /venues/{id} - Fetch detailed venue information
//  - POST /interests - Express or remove interest in a venue
//  - GET /users/{id} - Fetch user profile with interested venues
//  - GET /recommendations - Fetch personalized venue recommendations
//  
//  ERROR HANDLING:
//  - Network errors (connectivity issues, timeouts)
//  - Server errors (4xx, 5xx status codes)
//  - Decoding errors (malformed JSON)
//  - Invalid URL errors
//  
//  THREAD SAFETY:
//  - All async methods automatically return to main actor
//  - URLSession handles background thread operations internally
//  
//  TESTING:
//  - Protocol-based design enables easy mocking
//  - Injectable URLSession for integration tests
//  - Configurable base URL for different environments
//
//

import Foundation
import Combine

// MARK: - API Error Types

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
    case noData
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect to server (Invalid URL)"
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return "No internet connection. Please check your network."
            } else if nsError.code == NSURLErrorTimedOut {
                return "Request timed out. Please try again."
            } else if nsError.code == NSURLErrorCannotConnectToHost {
                return "Unable to connect to server. Please try again."
            } else if nsError.code == NSURLErrorNetworkConnectionLost {
                return "Network connection was lost. Please check your connection and try again."
            }
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            if statusCode == 404 {
                return "Content not found."
            } else if statusCode == 500 {
                return "Server error. Please try again later."
            } else if statusCode >= 500 {
                return "Server is experiencing issues. Please try again later."
            }
            return "Server error (\(statusCode)): \(message)"
        case .noData:
            return "No data received from server."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - API Service Protocol

protocol APIServiceProtocol {
    func fetchVenues(userId: String?, filters: VenueFilters?) async throws -> [VenueListItem]
    func fetchVenueDetail(venueId: String) async throws -> VenueDetailResponse
    func expressInterest(userId: String, venueId: String) async throws -> InterestResponse
    func fetchUserProfile(userId: String) async throws -> UserProfileResponse
    func fetchRecommendations(userId: String) async throws -> [RecommendationItem]
    func fetchUserBookings(userId: String) async throws -> [BookingItem]
    func fetchVenueBooking(venueId: String) async throws -> VenueBookingResponse
    func completeActionItem(itemId: String, userId: String) async throws -> SuccessResponse
    func dismissActionItem(itemId: String, userId: String) async throws -> SuccessResponse
    func fetchActivities(userId: String, page: Int, limit: Int) async throws -> ActivitiesResponse
    func fetchSocialFeed(userId: String, page: Int, limit: Int, since: Date?) async throws -> SocialFeedResponse
}

// MARK: - API Service Implementation

class APIService: ObservableObject, APIServiceProtocol {
    
    // MARK: - Properties
    
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization
    
    nonisolated init(baseURL: String = "http://172.20.10.2:8000", session: URLSession = .shared) {
        self.baseURL = baseURL
        
        // Use custom session with production configuration if using shared session
        // Otherwise use injected session (e.g., for testing)
        if session === URLSession.shared {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30.0
            configuration.timeoutIntervalForResource = 60.0
            configuration.waitsForConnectivity = true
            
            self.session = URLSession(configuration: configuration)
        } else {
            // Use injected session (for testing or custom configs)
            self.session = session
        }
        
        // Configure JSON decoder for date handling
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        // Configure JSON encoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public API Methods
    
    /// Fetches list of all venues with optional filtering and sorting
    func fetchVenues(userId: String? = nil, filters: VenueFilters? = nil) async throws -> [VenueListItem] {
        var queryItems: [URLQueryItem] = []
        
        // Add user_id
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: userId))
        }
        
        // Add filters if provided
        if let filters = filters {
            // Categories filter
            if filters.selectedCategories != ["All"] && !filters.selectedCategories.isEmpty {
                let categoriesString = filters.selectedCategories.sorted().joined(separator: ",")
                queryItems.append(URLQueryItem(name: "categories", value: categoriesString))
            }
            
            // Distance filter
            if let maxDistance = filters.distanceFilter.kilometers {
                queryItems.append(URLQueryItem(name: "max_distance", value: String(maxDistance)))
            }
            
            // Friend interest filter
            if let minFriends = filters.friendInterestFilter.minCount {
                queryItems.append(URLQueryItem(name: "min_friend_interest", value: String(minFriends)))
            }
            
            // Personal interest filters
            switch filters.personalInterestFilter {
            case .interested:
                queryItems.append(URLQueryItem(name: "only_interested", value: "true"))
            case .notInterested:
                queryItems.append(URLQueryItem(name: "exclude_interested", value: "true"))
            case .all:
                break
            }
            
            // Sort option
            queryItems.append(URLQueryItem(name: "sort_by", value: filters.sortBy.rawValue))
        }
        
        let response: VenuesResponse = try await performRequest(endpoint: "/venues", method: "GET", queryItems: queryItems)
        return response.venues
    }
    
    /// Fetches detailed information about a specific venue
    func fetchVenueDetail(venueId: String) async throws -> VenueDetailResponse {
        return try await performRequest(endpoint: "/venues/\(venueId)", method: "GET")
    }
    
    /// Expresses user interest in a venue
    func expressInterest(userId: String, venueId: String) async throws -> InterestResponse {
        let requestBody = InterestRequest(user_id: userId, venue_id: venueId)
        return try await performRequest(endpoint: "/interests", method: "POST", body: requestBody)
    }
    
    /// Fetches user profile with their interested venues
    func fetchUserProfile(userId: String) async throws -> UserProfileResponse {
        return try await performRequest(endpoint: "/users/\(userId)", method: "GET")
    }
    
    /// Fetches personalized venue recommendations for a user
    func fetchRecommendations(userId: String) async throws -> [RecommendationItem] {
        let queryItems = [URLQueryItem(name: "user_id", value: userId)]
        let response: RecommendationsResponse = try await performRequest(endpoint: "/recommendations", method: "GET", queryItems: queryItems)
        return response.recommendations
    }
    
    /// Fetches all active bookings for a user
    func fetchUserBookings(userId: String) async throws -> [BookingItem] {
        let response: UserBookingsResponse = try await performRequest(endpoint: "/bookings/\(userId)", method: "GET")
        return response.bookings
    }
    
    /// Checks if a venue has an active booking
    func fetchVenueBooking(venueId: String) async throws -> VenueBookingResponse {
        return try await performRequest(endpoint: "/venues/\(venueId)/booking", method: "GET")
    }
    
    /// Completes an action item with retry logic
    func completeActionItem(itemId: String, userId: String) async throws -> SuccessResponse {
        let requestBody = CompleteActionItemRequest(user_id: userId)
        return try await performRequestWithRetry(endpoint: "/action-items/\(itemId)/complete", method: "POST", body: requestBody)
    }
    
    /// Dismisses an action item with retry logic
    func dismissActionItem(itemId: String, userId: String) async throws -> SuccessResponse {
        let queryItems = [URLQueryItem(name: "user_id", value: userId)]
        return try await performRequestWithRetry(endpoint: "/action-items/\(itemId)", method: "DELETE", queryItems: queryItems)
    }
    
    /// Fetches social feed activities for a user
    /// - Parameters:
    ///   - userId: User identifier to fetch friend activities
    ///   - page: Page number for pagination
    ///   - limit: Number of activities per page
    /// - Returns: ActivitiesResponse with paginated activities
    func fetchActivities(userId: String, page: Int = 1, limit: Int = 20) async throws -> ActivitiesResponse {
        let queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        return try await performRequest(endpoint: "/activities", method: "GET", queryItems: queryItems)
    }
    
    /// Fetches comprehensive social feed with friend activities and highlighted venues
    /// - Parameters:
    ///   - userId: User identifier to fetch friend activities
    ///   - page: Page number for pagination
    ///   - limit: Number of activities per page (max 100)
    ///   - since: Optional timestamp for incremental updates (real-time polling)
    /// - Returns: SocialFeedResponse with interest activities and highlighted venues
    func fetchSocialFeed(userId: String, page: Int = 1, limit: Int = 20, since: Date? = nil) async throws -> SocialFeedResponse {
        var queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        // Add since parameter if provided for incremental updates
        if let since = since {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            queryItems.append(URLQueryItem(name: "since", value: formatter.string(from: since)))
        }
        
        return try await performRequest(endpoint: "/social/feed", method: "GET", queryItems: queryItems)
    }
    
    // MARK: - Private Helper Methods
    
    /// Performs a network request with automatic retry on network errors
    /// Uses exponential backoff: 0.5s, 1.0s, 2.0s delays for 3 total attempts
    private func performRequestWithRetry<T: Decodable>(
        endpoint: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        maxRetries: Int = 3
    ) async throws -> T {
        var lastError: APIError?
        let retryDelays: [Double] = [0.5, 1.0, 2.0] // Exponential backoff delays in seconds
        
        for attempt in 0..<maxRetries {
            do {
                return try await performRequest(
                    endpoint: endpoint,
                    method: method,
                    queryItems: queryItems,
                    body: body
                )
            } catch let error as APIError {
                lastError = error
                
                // Only retry on network errors, not server errors (4xx, 5xx)
                switch error {
                case .networkError:
                    // Network error - retry if attempts remain
                    if attempt < maxRetries - 1 {
                        let delay = retryDelays[attempt]
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                case .serverError, .decodingError, .invalidURL, .noData, .unknown:
                    // Don't retry on server errors or other non-network issues
                    throw error
                }
            } catch {
                // Unknown error type - don't retry
                throw APIError.unknown
            }
        }
        
        // All retries exhausted
        throw lastError ?? APIError.unknown
    }
    
    /// Performs a network request with the given parameters
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        
        // Construct URL using URLComponents
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        components.path = endpoint
        components.queryItems = queryItems
        
        // Ensure the URL is valid
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Encode request body if provided
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.decodingError(error)
            }
        }
        
        // Perform the request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
        
        // Decode response
        do {
            // Check if we expect a Void response or empty body
            if T.self == SuccessResponse.self && data.isEmpty {
                 // Handle empty success response if needed, though SuccessResponse usually has fields
            }
            
            let decodedResponse = try decoder.decode(T.self, from: data)
            return decodedResponse
        } catch {
            print("Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            throw APIError.decodingError(error)
        }
    }
}
