//
//  APIServiceTests.swift
//  nameTests
//
//  Created for MVI Foundation Sprint - CI-1
//
//  DESCRIPTION:
//  Integration tests for APIService using URLProtocol mocking.
//  Tests network layer, JSON decoding, and error handling.
//

import XCTest
@testable import name

final class APIServiceTests: XCTestCase {
    
    var apiService: APIService!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        // Configure URLProtocol for mocking
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        apiService = APIService(baseURL: "https://api.test.com", session: mockSession)
    }
    
    override func tearDown() {
        apiService = nil
        mockSession = nil
        MockURLProtocol.reset()
        super.tearDown()
    }
    
    // MARK: - Successful Decoding Tests
    
    func testFetchVenues_SuccessfulDecoding() async throws {
        // Given
        let json = """
        {
            "venues": [
                {
                    "id": "venue_1",
                    "name": "Test Venue",
                    "category": "Coffee Shop",
                    "image": "https://example.com/image.jpg",
                    "interested_count": 10,
                    "distance_km": 2.5
                }
            ]
        }
        """
        MockURLProtocol.mockResponse = (json.data(using: .utf8)!, 200)
        
        // When
        let venues = try await apiService.fetchVenues(userId: "user_1", filters: nil)
        
        // Then
        XCTAssertEqual(venues.count, 1)
        XCTAssertEqual(venues[0].id, "venue_1")
        XCTAssertEqual(venues[0].name, "Test Venue")
        XCTAssertEqual(venues[0].category, "Coffee Shop")
        XCTAssertEqual(venues[0].interested_count, 10)
        XCTAssertEqual(venues[0].distance_km, 2.5)
    }
    
    func testFetchVenueDetail_SuccessfulDecoding() async throws {
        // Given
        let json = """
        {
            "venue": {
                "id": "venue_1",
                "name": "Test Venue",
                "category": "Restaurant",
                "description": "Great food",
                "image": "https://example.com/image.jpg",
                "address": "123 Main St",
                "latitude": 40.7128,
                "longitude": -74.0060,
                "distance_km": 1.5
            },
            "interested_users": []
        }
        """
        MockURLProtocol.mockResponse = (json.data(using: .utf8)!, 200)
        
        // When
        let response = try await apiService.fetchVenueDetail(venueId: "venue_1")
        
        // Then
        XCTAssertEqual(response.venue.id, "venue_1")
        XCTAssertEqual(response.venue.name, "Test Venue")
        XCTAssertEqual(response.venue.description, "Great food")
        XCTAssertEqual(response.interested_users.count, 0)
    }
    
    func testExpressInterest_SuccessfulDecoding() async throws {
        // Given
        let json = """
        {
            "success": true,
            "message": "Interest toggled",
            "action_item": null
        }
        """
        MockURLProtocol.mockResponse = (json.data(using: .utf8)!, 200)
        
        // When
        let response = try await apiService.expressInterest(userId: "user_1", venueId: "venue_1")
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Interest toggled")
        XCTAssertNil(response.action_item)
    }
    
    // MARK: - Decoding Error Tests
    
    func testFetchVenues_InvalidJSON() async throws {
        // Given
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        MockURLProtocol.mockResponse = (invalidJSON, 200)
        
        // When/Then
        do {
            _ = try await apiService.fetchVenues(userId: "user_1", filters: nil)
            XCTFail("Should throw decoding error")
        } catch let error as APIError {
            if case .decodingError = error {
                XCTAssertTrue(true, "Correctly threw decoding error")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testFetchVenues_MissingRequiredFields() async throws {
        // Given - Missing 'interested_count' field
        let json = """
        {
            "venues": [
                {
                    "id": "venue_1",
                    "name": "Test Venue",
                    "category": "Coffee Shop",
                    "image": "https://example.com/image.jpg"
                }
            ]
        }
        """
        MockURLProtocol.mockResponse = (json.data(using: .utf8)!, 200)
        
        // When/Then
        do {
            _ = try await apiService.fetchVenues(userId: "user_1", filters: nil)
            XCTFail("Should throw decoding error for missing fields")
        } catch let error as APIError {
            if case .decodingError = error {
                XCTAssertTrue(true, "Correctly threw decoding error")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Network Error Tests
    
    func testFetchVenues_NetworkError() async throws {
        // Given
        MockURLProtocol.mockError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        
        // When/Then
        do {
            _ = try await apiService.fetchVenues(userId: "user_1", filters: nil)
            XCTFail("Should throw network error")
        } catch let error as APIError {
            if case .networkError(let nsError) = error {
                XCTAssertEqual((nsError as NSError).code, NSURLErrorNotConnectedToInternet)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testFetchVenues_Timeout() async throws {
        // Given
        MockURLProtocol.mockError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: nil
        )
        
        // When/Then
        do {
            _ = try await apiService.fetchVenues(userId: "user_1", filters: nil)
            XCTFail("Should throw timeout error")
        } catch let error as APIError {
            if case .networkError = error {
                XCTAssertTrue(error.localizedDescription?.contains("timed out") ?? false)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - Server Error Tests
    
    func testFetchVenues_ServerError404() async throws {
        // Given
        let json = "Not Found".data(using: .utf8)!
        MockURLProtocol.mockResponse = (json, 404)
        
        // When/Then
        do {
            _ = try await apiService.fetchVenues(userId: "user_1", filters: nil)
            XCTFail("Should throw server error")
        } catch let error as APIError {
            if case .serverError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testFetchVenues_ServerError500() async throws {
        // Given
        let json = "Internal Server Error".data(using: .utf8)!
        MockURLProtocol.mockResponse = (json, 500)
        
        // When/Then
        do {
            _ = try await apiService.fetchVenues(userId: "user_1", filters: nil)
            XCTFail("Should throw server error")
        } catch let error as APIError {
            if case .serverError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Query Parameters Tests
    
    func testFetchVenues_WithFilters() async throws {
        // Given
        let filters = VenueFilters(
            selectedCategories: ["Coffee Shop"],
            distanceFilter: .within(5.0),
            sortBy: .distance
        )
        
        let json = """
        {
            "venues": []
        }
        """
        MockURLProtocol.mockResponse = (json.data(using: .utf8)!, 200)
        
        // When
        _ = try await apiService.fetchVenues(userId: "user_1", filters: filters)
        
        // Then
        let lastRequest = MockURLProtocol.lastRequest
        XCTAssertNotNil(lastRequest)
        
        let url = lastRequest?.url
        XCTAssertTrue(url?.query?.contains("user_id=user_1") ?? false)
        XCTAssertTrue(url?.query?.contains("categories=Coffee%20Shop") ?? false)
        XCTAssertTrue(url?.query?.contains("max_distance=5") ?? false)
        XCTAssertTrue(url?.query?.contains("sort_by=distance") ?? false)
    }
    
    // MARK: - Error Description Tests
    
    func testAPIError_Descriptions() {
        XCTAssertNotNil(APIError.invalidURL.errorDescription)
        XCTAssertNotNil(APIError.noData.errorDescription)
        XCTAssertNotNil(APIError.unknown.errorDescription)
        
        let networkError = APIError.networkError(NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        ))
        XCTAssertTrue(networkError.errorDescription?.contains("internet") ?? false)
        
        let serverError = APIError.serverError(statusCode: 404, message: "Not Found")
        XCTAssertTrue(serverError.errorDescription?.contains("not found") ?? false)
    }
}

// MARK: - MockURLProtocol
//
// DESCRIPTION:
// Custom URLProtocol subclass for intercepting network requests in tests.
// Allows complete control over HTTP responses and errors without actual network calls.
//
// USAGE:
// 1. Configure URLSession with this protocol: config.protocolClasses = [MockURLProtocol.self]
// 2. Set mockResponse or mockError before making requests
// 3. Call reset() in tearDown to clean state between tests
//
// THREAD SAFETY:
// Static properties are accessed from test thread only (single-threaded test execution)

class MockURLProtocol: URLProtocol {
    static var mockResponse: (Data, Int)?
    static var mockError: Error?
    static var lastRequest: URLRequest?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        // Track the request for verification in tests
        MockURLProtocol.lastRequest = request
        
        // Simulate network error if configured
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        // Simulate HTTP response if configured
        if let (data, statusCode) = MockURLProtocol.mockResponse {
            // Safely create URL from request (should never be nil in practice)
            guard let url = request.url else {
                let error = NSError(domain: "MockURLProtocol", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid URL in request"
                ])
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            // Create HTTP response
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            ) else {
                let error = NSError(domain: "MockURLProtocol", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create HTTP response"
                ])
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            // Deliver response to client
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        } else {
            // No mock configured - fail with helpful error
            let error = NSError(domain: "MockURLProtocol", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "No mock response configured. Set MockURLProtocol.mockResponse or mockError"
            ])
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        // Signal completion
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // No cleanup needed - all state is static
    }
    
    /// Resets all mock state. Call this in tearDown() to ensure test isolation.
    static func reset() {
        mockResponse = nil
        mockError = nil
        lastRequest = nil
    }
}
