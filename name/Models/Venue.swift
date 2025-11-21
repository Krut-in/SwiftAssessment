//
//  Venue.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import Foundation

/// Represents a venue with full details
struct Venue: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let description: String
    let image: String
    let address: String
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case image
        case address
    }
}

/// Represents a venue in list view with interested count
struct VenueListItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let image: String
    let interested_count: Int
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case image
        case interested_count
    }
}
