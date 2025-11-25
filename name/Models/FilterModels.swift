//
//  FilterModels.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Data models for venue filtering and sorting functionality.
//  Provides type-safe filter state management with defaults.
//
//  KEY COMPONENTS:
//  - VenueFilters: Complete filter state container
//  - SortOption: Available sort criteria with display names
//  - DistanceOption: Predefined distance filter values
//  - FriendInterestOption: Friend interest filter levels
//  - PersonalInterestOption: User's interest filter states
//
//  DESIGN PATTERNS:
//  - Equatable: Enable filter comparison and change detection
//  - Codable: Support future persistence (UserDefaults/file storage)
//  - Computed properties: Convenient filter active state checking
//  - Type-safe enums: Prevent invalid filter values
//

import Foundation

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Identifiable {
    case distance = "distance"
    case popularity = "popularity"
    case friends = "friends"
    case name = "name"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .distance:
            return "Distance"
        case .popularity:
            return "Popularity"
        case .friends:
            return "Friends Interested"
        case .name:
            return "Name (A-Z)"
        }
    }
    
    var icon: String {
        switch self {
        case .distance:
            return "location.fill"
        case .popularity:
            return "heart.fill"
        case .friends:
            return "person.2.fill"
        case .name:
            return "textformat"
        }
    }
}

// MARK: - Distance Filter Options

enum DistanceOption: Equatable, Identifiable {
    case any
    case within(Double) // kilometers
    
    var id: String {
        switch self {
        case .any:
            return "any"
        case .within(let km):
            return "within_\(km)"
        }
    }
    
    var displayName: String {
        switch self {
        case .any:
            return "Any Distance"
        case .within(let km):
            return "Within \(Int(km)) km"
        }
    }
    
    var kilometers: Double? {
        switch self {
        case .any:
            return nil
        case .within(let km):
            return km
        }
    }
    
    static let allCases: [DistanceOption] = [
        .any,
        .within(1),
        .within(3),
        .within(5),
        .within(10)
    ]
}

// MARK: - Friend Interest Filter Options

enum FriendInterestOption: Int, CaseIterable, Identifiable {
    case all = 0
    case interested = 1
    case popular = 3
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .all:
            return "All Venues"
        case .interested:
            return "Friends Interested (1+)"
        case .popular:
            return "Popular with Friends (3+)"
        }
    }
    
    var minCount: Int? {
        switch self {
        case .all:
            return nil
        case .interested:
            return 1
        case .popular:
            return 3
        }
    }
}

// MARK: - Personal Interest Filter Options

enum PersonalInterestOption: String, CaseIterable, Identifiable {
    case all = "all"
    case interested = "interested"
    case notInterested = "notInterested"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .interested:
            return "Interested"
        case .notInterested:
            return "Not Interested"
        }
    }
}

// MARK: - Venue Filters Container

struct VenueFilters: Equatable {
    var selectedCategories: Set<String>
    var distanceFilter: DistanceOption
    var friendInterestFilter: FriendInterestOption
    var personalInterestFilter: PersonalInterestOption
    var sortBy: SortOption
    
    // Default initializer
    init(
        selectedCategories: Set<String> = ["All"],
        distanceFilter: DistanceOption = .any,
        friendInterestFilter: FriendInterestOption = .all,
        personalInterestFilter: PersonalInterestOption = .all,
        sortBy: SortOption = .popularity
    ) {
        self.selectedCategories = selectedCategories
        self.distanceFilter = distanceFilter
        self.friendInterestFilter = friendInterestFilter
        self.personalInterestFilter = personalInterestFilter
        self.sortBy = sortBy
    }
    
    // Check if filters are at default state
    var isDefault: Bool {
        return selectedCategories == ["All"] &&
               distanceFilter == .any &&
               friendInterestFilter == .all &&
               personalInterestFilter == .all &&
               sortBy == .popularity
    }
    
    // Count of active filters (excluding sort)
    var activeFilterCount: Int {
        var count = 0
        
        // Category filter (not counting "All")
        if selectedCategories != ["All"] && !selectedCategories.isEmpty {
            count += 1
        }
        
        // Distance filter
        if distanceFilter != .any {
            count += 1
        }
        
        // Friend interest filter
        if friendInterestFilter != .all {
            count += 1
        }
        
        // Personal interest filter
        if personalInterestFilter != .all {
            count += 1
        }
        
        return count
    }
    
    // Human-readable summary of active filters
    var activeSummary: String? {
        guard !isDefault else { return nil }
        
        var parts: [String] = []
        
        // Categories
        if selectedCategories != ["All"] && !selectedCategories.isEmpty {
            let categories = Array(selectedCategories).sorted()
            if categories.count == 1 {
                parts.append(categories[0])
            } else {
                parts.append("\(categories.count) categories")
            }
        }
        
        // Distance
        if case .within(let km) = distanceFilter {
            parts.append("within \(Int(km)) km")
        }
        
        // Friend interest
        switch friendInterestFilter {
        case .interested:
            parts.append("friends interested")
        case .popular:
            parts.append("popular with friends")
        case .all:
            break
        }
        
        // Personal interest
        switch personalInterestFilter {
        case .interested:
            parts.append("you're interested")
        case .notInterested:
            parts.append("you haven't tried")
        case .all:
            break
        }
        
        // Sort (always append if not default)
        if sortBy != .popularity {
            parts.append("sorted by \(sortBy.displayName.lowercased())")
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    // Reset to defaults
    mutating func reset() {
        self = VenueFilters()
    }
    
    // Available categories for filtering
    static let availableCategories = [
        "All",
        "Coffee Shop",
        "Restaurant",
        "Bar",
        "Nightclub",
        "Activity"
    ]
}
