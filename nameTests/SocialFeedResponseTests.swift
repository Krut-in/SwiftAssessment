//
//  SocialFeedResponseTests.swift
//  nameTests
//
//  Created by Antigravity on 02/12/25.
//
//  DESCRIPTION:
//  Unit tests for SocialFeedResponse JSON decoding, verifying the CodingKey
//  mapping between backend API field 'interest_activities' and iOS model 'activities'.
//

import XCTest
@testable import name

final class SocialFeedResponseTests: XCTestCase {
    
    // MARK: - Test SocialFeedResponse Decoding
    
    func testSocialFeedResponseDecoding() throws {
        // Arrange: Create JSON matching backend API response format
        let json = """
        {
            "interest_activities": [
                {
                    "id": "activity-1",
                    "user": {
                        "id": "user-1",
                        "name": "John Doe",
                        "avatar_url": "https://example.com/avatar.jpg"
                    },
                    "venue": {
                        "id": "venue-1",
                        "name": "The Coffee Shop",
                        "category": "Coffee Shop",
                        "address": "123 Main St"
                    },
                    "action": "interested",
                    "timestamp": "2025-12-02T20:00:00Z",
                    "is_active": true
                }
            ],
            "highlighted_venues": [],
            "has_more": false,
            "page": 1,
            "limit": 20,
            "total_count": 1
        }
        """.data(using: .utf8)!
        
        // Create ISO8601 date formatter for decoding
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Act: Decode the JSON
        let response = try decoder.decode(SocialFeedResponse.self, from: json)
        
        // Assert: Verify decoding was successful
        XCTAssertEqual(response.activities.count, 1, "Should decode 1 activity")
        XCTAssertEqual(response.activities.first?.id, "activity-1", "Activity ID should match")
        XCTAssertEqual(response.activities.first?.user.name, "John Doe", "User name should match")
        XCTAssertEqual(response.activities.first?.venue.name, "The Coffee Shop", "Venue name should match")
        XCTAssertEqual(response.highlightedVenues.count, 0, "Should have no highlighted venues")
        XCTAssertEqual(response.hasMore, false, "hasMore should be false")
        XCTAssertEqual(response.page, 1, "Page should be 1")
        XCTAssertEqual(response.limit, 20, "Limit should be 20")
        XCTAssertEqual(response.totalCount, 1, "Total count should be 1")
    }
    
    func testSocialFeedResponseWithHighlightedVenues() throws {
        // Arrange: Create JSON with highlighted venues
        let json = """
        {
            "interest_activities": [],
            "highlighted_venues": [
                {
                    "id": "highlight-1",
                    "venue_id": "venue-1",
                    "venue_name": "Popular Bar",
                    "venue_image_url": "https://example.com/bar.jpg",
                    "venue_category": "Bar",
                    "venue_address": "456 Party St",
                    "interested_friends": [
                        {
                            "id": "friend-1",
                            "name": "Alice Smith",
                            "avatar_url": "https://example.com/alice.jpg",
                            "interested_timestamp": "2025-12-02T19:00:00Z"
                        }
                    ],
                    "total_interested_count": 5,
                    "threshold": 5,
                    "last_activity_timestamp": "2025-12-02T20:30:00Z"
                }
            ],
            "has_more": true,
            "page": 1,
            "limit": 20,
            "total_count": 1
        }
        """.data(using: .utf8)!
        
        // Create ISO8601 date formatter for decoding
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Act: Decode the JSON
        let response = try decoder.decode(SocialFeedResponse.self, from: json)
        
        // Assert: Verify decoding was successful
        XCTAssertEqual(response.activities.count, 0, "Should have no activities")
        XCTAssertEqual(response.highlightedVenues.count, 1, "Should have 1 highlighted venue")
        XCTAssertEqual(response.highlightedVenues.first?.venueName, "Popular Bar", "Venue name should match")
        XCTAssertEqual(response.highlightedVenues.first?.totalInterestedCount, 5, "Total interested count should be 5")
        XCTAssertEqual(response.highlightedVenues.first?.interestedFriends.count, 1, "Should have 1 interested friend")
        XCTAssertEqual(response.hasMore, true, "hasMore should be true")
    }
    
    func testSocialFeedResponseDecodingFailsWithWrongKey() throws {
        // Arrange: Create JSON with wrong key name (should fail if CodingKey is not correctly mapped)
        let json = """
        {
            "activities": [],
            "highlighted_venues": [],
            "has_more": false,
            "page": 1,
            "limit": 20,
            "total_count": 0
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Act & Assert: Decoding should fail with wrong key
        XCTAssertThrowsError(try decoder.decode(SocialFeedResponse.self, from: json)) { error in
            // Verify it's a decoding error
            XCTAssertTrue(error is DecodingError, "Expected DecodingError")
        }
    }
}
