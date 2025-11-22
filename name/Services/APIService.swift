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
            return "Unable to connect to server"
        case .networkError(let error):
            let nsError = error as NSError
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return "No internet connection. Please check your network."
            } else if nsError.code == NSURLErrorTimedOut {
                return "Request timed out. Please try again."
            } else if nsError.code == NSURLErrorCannotConnectToHost {
                return "Unable to connect to server. Please try again."
            }
            return "Network error. Please check your connection."
        case .decodingError:
            return "Something went wrong. Please try again."
        case .serverError(let statusCode, _):
            if statusCode == 404 {
                return "Content not found."
            } else if statusCode == 500 {
                return "Server error. Please try again later."
            } else if statusCode >= 500 {
                return "Server is experiencing issues. Please try again later."
            }
            return "Something went wrong. Please try again."
        case .noData:
            return "No data received. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - API Service Protocol

protocol APIServiceProtocol {
    func fetchVenues() async throws -> [VenueListItem]
    func fetchVenueDetail(venueId: String) async throws -> VenueDetailResponse
    func expressInterest(userId: String, venueId: String) async throws -> InterestResponse
    func fetchUserProfile(userId: String) async throws -> UserProfileResponse
    func fetchRecommendations(userId: String) async throws -> [RecommendationItem]
    func fetchUserBookings(userId: String) async throws -> [BookingItem]
    func fetchVenueBooking(venueId: String) async throws -> VenueBookingResponse
}

// MARK: - API Service Implementation

class APIService: ObservableObject, APIServiceProtocol {
    
    // MARK: - Properties
    
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization
    
    init(baseURL: String = "http://localhost:8000", session: URLSession = .shared) {
        self.baseURL = baseURL
        
        // Configure session with timeout for production
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
        
        // Configure JSON decoder for date handling
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        // Configure JSON encoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Public API Methods
    
    /// Fetches list of all venues
    /// - Returns: Array of venue list items with interested counts
    /// - Throws: APIError if request fails
    func fetchVenues() async throws -> [VenueListItem] {
        let endpoint = "/venues"
        let response: VenuesResponse = try await performRequest(endpoint: endpoint, method: "GET")
        return response.venues
    }
    
    /// Fetches detailed information about a specific venue
    /// - Parameter venueId: The unique identifier of the venue
    /// - Returns: Venue detail response with venue info and interested users
    /// - Throws: APIError if request fails
    func fetchVenueDetail(venueId: String) async throws -> VenueDetailResponse {
        let endpoint = "/venues/\(venueId)"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    /// Expresses user interest in a venue
    /// - Parameters:
    ///   - userId: The unique identifier of the user
    ///   - venueId: The unique identifier of the venue
    /// - Returns: Interest response with success status and booking agent info
    /// - Throws: APIError if request fails
    func expressInterest(userId: String, venueId: String) async throws -> InterestResponse {
        let endpoint = "/interests"
        let requestBody = InterestRequest(user_id: userId, venue_id: venueId)
        return try await performRequest(endpoint: endpoint, method: "POST", body: requestBody)
    }
    
    /// Fetches user profile with their interested venues
    /// - Parameter userId: The unique identifier of the user
    /// - Returns: User profile response with user info and interested venues
    /// - Throws: APIError if request fails
    func fetchUserProfile(userId: String) async throws -> UserProfileResponse {
        let endpoint = "/users/\(userId)"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    /// Fetches personalized venue recommendations for a user
    /// - Parameter userId: The unique identifier of the user
    /// - Returns: Array of recommendation items with scores and reasons
    /// - Throws: APIError if request fails
    func fetchRecommendations(userId: String) async throws -> [RecommendationItem] {
        let endpoint = "/recommendations"
        let urlString = "\(baseURL)\(endpoint)?user_id=\(userId)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let response: RecommendationsResponse = try await performRequest(url: url, method: "GET")
        return response.recommendations
    }
    
    /// Fetches all active bookings for a user
    /// - Parameter userId: The unique identifier of the user
    /// - Returns: Array of booking items with venue and reservation details
    /// - Throws: APIError if request fails
    func fetchUserBookings(userId: String) async throws -> [BookingItem] {
        let endpoint = "/bookings/\(userId)"
        let response: UserBookingsResponse = try await performRequest(endpoint: endpoint, method: "GET")
        return response.bookings
    }
    
    /// Checks if a venue has an active booking
    /// - Parameter venueId: The unique identifier of the venue
    /// - Returns: Venue booking response with booking status and details
    /// - Throws: APIError if request fails
    func fetchVenueBooking(venueId: String) async throws -> VenueBookingResponse {
        let endpoint = "/venues/\(venueId)/booking"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Private Helper Methods
    
    /// Performs a network request with the given parameters
    /// - Parameters:
    ///   - endpoint: The API endpoint path
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Optional request body to encode
    /// - Returns: Decoded response of type T
    /// - Throws: APIError if request fails
    private func performRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(url: url, method: method, body: body)
    }
    
    /// Performs a network request with the given URL
    /// - Parameters:
    ///   - url: The complete URL for the request
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Optional request body to encode
    /// - Returns: Decoded response of type T
    /// - Throws: APIError if request fails
    private func performRequest<T: Decodable>(
        url: URL,
        method: String,
        body: Encodable? = nil
    ) async throws -> T {
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
