//
//  User.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import Foundation

/// Represents a user in the Luna venue discovery system
struct User: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let avatar: String
    let bio: String?
    let interests: [String]?
    
    /// Custom coding keys to match backend API JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatar
        case bio
        case interests
    }
    
    /// Helper computed properties with default values
    var displayBio: String {
        bio ?? ""
    }
    
    var displayInterests: [String] {
        interests ?? []
    }
}
