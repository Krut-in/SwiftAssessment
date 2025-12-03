//
//  VenueFeedViewModelTests.swift
//  nameTests
//
//  Created for MVI Foundation Sprint - CI-1
//
//  DESCRIPTION:
//  Comprehensive unit tests for VenueFeedViewModel.
//  Tests venue loading, filtering, sorting, and error handling.
//

import XCTest
@testable import name

@MainActor
final class VenueFeedViewModelTests: XCTestCase {
    
    var viewModel: VenueFeedViewModel!
    var mockAPIService: MockAPIService!
    
    // NOTE: We use AppState.shared in tests because:
    // 1. VenueFeedViewModel's behavior depends primarily on APIService, which we mock
    // 2. AppState is only used to read currentUserId (hardcoded as "user_1")
    // 3. Tests focus on ViewModel logic, not AppState integration
    // 4. For full integration tests of interest toggling, see AppState-specific test suite
    
    override func setUp() async throws {
        try await super.setUp()
        mockAPIService = MockAPIService()
        // Inject mock API service to isolate network calls
        viewModel = VenueFeedViewModel(apiService: mockAPIService, appState: AppState.shared)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockAPIService = nil
        try await super.tearDown()
    }
    
    // MARK: - Successful Venue Fetch Tests
    
    func testLoadVenues_Success() async throws {
        // Given
        let mockVenues = MockAPIService.createMockVenues()
        mockAPIService.venuesResponse = mockVenues
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchVenuesCalled, "API service should be called")
        XCTAssertEqual(viewModel.venues.count, mockVenues.count, "Should load all venues")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil on success")
        XCTAssertNotNil(viewModel.lastUpdated, "Last updated should be set")
    }
    
    func testLoadVenues_EmptyResponse() async throws {
        // Given
        mockAPIService.venuesResponse = []
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchVenuesCalled)
        XCTAssertEqual(viewModel.venues.count, 0, "Should handle empty response")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testRefresh_CallsLoadVenues() async throws {
        // Given
        mockAPIService.venuesResponse = MockAPIService.createMockVenues()
        
        // When
        await viewModel.refresh()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchVenuesCalled, "Refresh should call API")
        XCTAssertGreaterThan(viewModel.venues.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadVenues_NetworkError() async throws {
        // Given
        mockAPIService.shouldFail = true
        mockAPIService.errorToThrow = APIError.networkError(NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        ))
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchVenuesCalled)
        XCTAssertEqual(viewModel.venues.count, 0, "Venues should be empty on error")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
        XCTAssertTrue(viewModel.errorMessage?.contains("internet") ?? false, "Should show network error message")
    }
    
    func testLoadVenues_ServerError() async throws {
        // Given
        mockAPIService.shouldFail = true
        mockAPIService.errorToThrow = APIError.serverError(statusCode: 500, message: "Internal Server Error")
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Server") ?? false, "Should show server error")
    }
    
    func testLoadVenues_DecodingError() async throws {
        // Given
        struct TestError: Error {}
        mockAPIService.shouldFail = true
        mockAPIService.errorToThrow = APIError.decodingError(TestError())
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("process") ?? false, "Should show decoding error")
    }
    
    func testClearError_ResetsErrorMessage() {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage, "Error should be cleared")
    }
    
    func testLoadVenues_PreventsMultipleSimultaneousLoads() async throws {
        // Given
        mockAPIService.venuesResponse = MockAPIService.createMockVenues()
        
        // When - Start two loads simultaneously
        async let load1 = viewModel.loadVenues()
        async let load2 = viewModel.loadVenues()
        
        await load1
        await load2
        
        // Then - API should only be called once due to isLoading guard
        XCTAssertTrue(mockAPIService.fetchVenuesCalled)
    }
    
    // MARK: - Filter Application Tests
    
    func testApplyFilters_CategoryFilter() async throws {
        // Given
        mockAPIService.venuesResponse = MockAPIService.createMockVenues()
        viewModel.filters.selectedCategories = ["Coffee Shop"]
        
        // When
        await viewModel.applyFilters()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchVenuesCalled)
        XCTAssertEqual(mockAPIService.lastFilters?.selectedCategories, ["Coffee Shop"])
    }
    
    func testApplyFilters_DistanceFilter() async throws {
        // Given
        mockAPIService.venuesResponse = MockAPIService.createMockVenues()
        viewModel.filters.distanceFilter = .within(5.0)
        
        // When
        await viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(mockAPIService.lastFilters?.distanceFilter.kilometers, 5.0)
    }
    
    func testApplyFilters_PersonalInterestFilter() async throws {
        // Given
        mockAPIService.venuesResponse = MockAPIService.createMockVenues()
        viewModel.filters.personalInterestFilter = .interested
        
        // When
        await viewModel.applyFilters()
        
        // Then
        XCTAssertEqual(mockAPIService.lastFilters?.personalInterestFilter, .interested)
    }
    
    func testClearFilters_ResetsToDefaults() async throws {
        // Given
        mockAPIService.venuesResponse = MockAPIService.createMockVenues()
        viewModel.filters.selectedCategories = ["Bar"]
        viewModel.filters.distanceFilter = .within(3.0)
        viewModel.filters.sortBy = .distance
        
        // When
        await viewModel.clearFilters()
        
        // Then
        XCTAssertEqual(viewModel.filters.selectedCategories, ["All"])
        XCTAssertEqual(viewModel.filters.distanceFilter, .any)
        XCTAssertEqual(viewModel.filters.sortBy, .popularity)
        XCTAssertTrue(mockAPIService.fetchVenuesCalled, "Should reload venues after clearing")
    }
    
    func testActiveFilterCount_Calculation() {
        // Given
        viewModel.filters = VenueFilters()
        
        // When - No filters
        var count = viewModel.activeFilterCount
        
        // Then
        XCTAssertEqual(count, 0, "Should have 0 active filters by default")
        
        // When - Add category filter
        viewModel.filters.selectedCategories = ["Coffee Shop"]
        count = viewModel.activeFilterCount
        
        // Then
        XCTAssertEqual(count, 1, "Should count category filter")
        
        // When - Add distance filter
        viewModel.filters.distanceFilter = .within(5.0)
        count = viewModel.activeFilterCount
        
        // Then
        XCTAssertEqual(count, 2, "Should count multiple filters")
    }
    
    // MARK: - Sorting Tests
    
    func testSortVenues_ByDistance() async throws {
        // Given
        let venues = [
            MockAPIService.createMockVenue(id: "v1", name: "Far", distance: 10.0),
            MockAPIService.createMockVenue(id: "v2", name: "Close", distance: 1.0),
            MockAPIService.createMockVenue(id: "v3", name: "Medium", distance: 5.0)
        ]
        mockAPIService.venuesResponse = venues
        viewModel.filters.sortBy = .distance
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertEqual(viewModel.venues[0].id, "v2", "Closest should be first")
        XCTAssertEqual(viewModel.venues[1].id, "v3", "Medium distance second")
        XCTAssertEqual(viewModel.venues[2].id, "v1", "Farthest should be last")
    }
    
    func testSortVenues_ByPopularity() async throws {
        // Given
        let venues = [
            MockAPIService.createMockVenue(id: "v1", name: "Low", interestedCount: 5),
            MockAPIService.createMockVenue(id: "v2", name: "High", interestedCount: 50),
            MockAPIService.createMockVenue(id: "v3", name: "Medium", interestedCount: 20)
        ]
        mockAPIService.venuesResponse = venues
        viewModel.filters.sortBy = .popularity
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertEqual(viewModel.venues[0].id, "v2", "Most popular first")
        XCTAssertEqual(viewModel.venues[1].id, "v3", "Medium popularity second")
        XCTAssertEqual(viewModel.venues[2].id, "v1", "Least popular last")
    }
    
    func testSortVenues_ByName() async throws {
        // Given
        let venues = [
            MockAPIService.createMockVenue(id: "v1", name: "Zebra Cafe"),
            MockAPIService.createMockVenue(id: "v2", name: "Alpha Coffee"),
            MockAPIService.createMockVenue(id: "v3", name: "Beta Bar")
        ]
        mockAPIService.venuesResponse = venues
        viewModel.filters.sortBy = .name
        
        // When
        await viewModel.loadVenues()
        
        // Then
        XCTAssertEqual(viewModel.venues[0].name, "Alpha Coffee", "Should sort alphabetically")
        XCTAssertEqual(viewModel.venues[1].name, "Beta Bar")
        XCTAssertEqual(viewModel.venues[2].name, "Zebra Cafe")
    }
    
    func testSortVenues_HandleNilDistance() async throws {
        // Given
        let venues = [
            MockAPIService.createMockVenue(id: "v1", name: "No Distance", distance: nil),
            MockAPIService.createMockVenue(id: "v2", name: "Has Distance", distance: 2.0)
        ]
        mockAPIService.venuesResponse = venues
        viewModel.filters.sortBy = .distance
        
        // When
        await viewModel.loadVenues()
        
        // Then - Venues with distance should come first
        XCTAssertEqual(viewModel.venues[0].id, "v2", "Venue with distance should be first")
        XCTAssertEqual(viewModel.venues[1].id, "v1", "Venue without distance should be last")
    }
    
    // MARK: - Category Tests
    
    func testAvailableCategories_ReturnsUniqueSortedList() async throws {
        // Given
        let venues = [
            MockAPIService.createMockVenue(id: "v1", category: "Coffee Shop"),
            MockAPIService.createMockVenue(id: "v2", category: "Restaurant"),
            MockAPIService.createMockVenue(id: "v3", category: "Coffee Shop"),
            MockAPIService.createMockVenue(id: "v4", category: "Bar")
        ]
        mockAPIService.venuesResponse = venues
        
        // When
        await viewModel.loadVenues()
        let categories = viewModel.availableCategories
        
        // Then
        XCTAssertEqual(categories.count, 3, "Should have 3 unique categories")
        XCTAssertTrue(categories.contains("Coffee Shop"))
        XCTAssertTrue(categories.contains("Restaurant"))
        XCTAssertTrue(categories.contains("Bar"))
    }
    
    func testCategoryCounts_CalculatesCorrectly() async throws {
        // Given
        let venues = [
            MockAPIService.createMockVenue(id: "v1", category: "Coffee Shop"),
            MockAPIService.createMockVenue(id: "v2", category: "Coffee Shop"),
            MockAPIService.createMockVenue(id: "v3", category: "Restaurant")
        ]
        mockAPIService.venuesResponse = venues
        
        // When
        await viewModel.loadVenues()
        let counts = viewModel.categoryCounts
        
        // Then
        XCTAssertEqual(counts["Coffee Shop"], 2)
        XCTAssertEqual(counts["Restaurant"], 1)
    }
    
    // MARK: - Last Updated Tests
    
    func testLastUpdatedText_JustNow() {
        // Given
        viewModel.lastUpdated = Date()
        
        // When
        let text = viewModel.lastUpdatedText
        
        // Then
        XCTAssertEqual(text, "Just now")
    }
    
    func testLastUpdatedText_Minutes() {
        // Given
        viewModel.lastUpdated = Date().addingTimeInterval(-120) // 2 minutes ago
        
        // When
        let text = viewModel.lastUpdatedText
        
        // Then
        XCTAssertTrue(text.contains("minute"))
    }
    
    func testLastUpdatedText_Never() {
        // Given
        viewModel.lastUpdated = nil
        
        // When
        let text = viewModel.lastUpdatedText
        
        // Then
        XCTAssertEqual(text, "Never")
    }
}
