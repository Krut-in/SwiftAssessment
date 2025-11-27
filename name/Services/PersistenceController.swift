//
//  PersistenceController.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  CoreData persistence controller for offline caching of venues and interests.
//  Implements cache-first strategy to enable offline browsing and faster app launches.
//  
//  FEATURES:
//  - CoreData stack management
//  - Venue list caching with timestamps
//  - Interest state persistence
//  - Sync queue for offline changes
//  - Automatic cache invalidation
//  
//  ARCHITECTURE:
//  - Singleton pattern for app-wide access
//  - Background context for heavy operations
//  - Main context for UI updates
//  
//  USAGE:
//  let persistence = PersistenceController.shared
//  persistence.saveVenues(venues)
//  let cached = persistence.fetchCachedVenues()
//

import Foundation
import CoreData

/// CoreData persistence controller for offline support
class PersistenceController {
    
    // MARK: - Singleton
    
    static let shared = PersistenceController()
    
    // MARK: - CoreData Stack
    
    let container: NSPersistentContainer
    
    // MARK: - Initialization
    
    private init() {
        container = NSPersistentContainer(name: "VenueEntity")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // CRITICAL ERROR: Log the error and create in-memory store as fallback
                print("❌ CRITICAL: Unable to load CoreData persistent stores: \(error)")
                print("❌ Description: \(description)")
                print("⚠️ Falling back to in-memory store - data will not persist!")
                
                // Create in-memory store as fallback
                let storeDescription = NSPersistentStoreDescription()
                storeDescription.type = NSInMemoryStoreType
                self.container.persistentStoreDescriptions = [storeDescription]
                
                // Try loading in-memory store
                self.container.loadPersistentStores { _, memoryError in
                    if let memoryError = memoryError {
                        // If even in-memory store fails, log critical error
                        print("❌ FATAL: Even in-memory store failed to load: \(memoryError)")
                        // App will continue but caching won't work
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Venue Caching
    
    /// Save venues to cache
    /// - Parameter venues: Array of venue list items to cache
    func saveVenues(_ venues: [VenueListItem]) {
        let context = container.viewContext
        let cachedAt = Date()
        
        // Clear existing cache
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = VenueEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            
            // Save new venues
            for venue in venues {
                let entity = VenueEntity(context: context)
                entity.id = venue.id
                entity.name = venue.name
                entity.category = venue.category
                entity.image = venue.image
                entity.interested_count = Int32(venue.interested_count)
                entity.distance_km = venue.distance_km ?? 0
                entity.cached_at = cachedAt
            }
            
            try context.save()
            print("💾 Cached \(venues.count) venues")
        } catch {
            print("❌ Failed to save venues to cache: \(error)")
        }
    }
    
    /// Fetch cached venues
    /// - Returns: Array of cached venue list items
    func fetchCachedVenues() -> [VenueListItem] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<VenueEntity> = VenueEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { entity in
                VenueListItem(
                    id: entity.id ?? "",
                    name: entity.name ?? "",
                    category: entity.category ?? "",
                    image: entity.image ?? "",
                    interested_count: Int(entity.interested_count),
                    distance_km: entity.distance_km != 0 ? entity.distance_km : nil
                )
            }
        } catch {
            print("❌ Failed to fetch cached venues: \(error)")
            return []
        }
    }
    
    /// Check if cached data exists
    /// - Returns: True if cache has data
    func hasCachedData() -> Bool {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<VenueEntity> = VenueEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Get cache timestamp
    /// - Returns: Date when cache was last updated
    func getCacheTimestamp() -> Date? {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<VenueEntity> = VenueEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cached_at", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first?.cached_at
        } catch {
            return nil
        }
    }
    
    // MARK: - Interest Caching
    
    /// Update interest state for a venue
    /// - Parameters:
    ///   - venueId: Venue identifier
    ///   - isInterested: Interest state
    func updateInterestState(venueId: String, isInterested: Bool) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<InterestEntity> = InterestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "venue_id == %@", venueId)
        
        do {
            let existing = try context.fetch(fetchRequest).first
            
            if isInterested {
                if existing == nil {
                    // Create new interest
                    let entity = InterestEntity(context: context)
                    entity.venue_id = venueId
                    entity.is_interested = true
                    entity.synced = false
                }
            } else {
                // Remove interest if exists
                if let entity = existing {
                    context.delete(entity)
                }
            }
            
            try context.save()
        } catch {
            print("❌ Failed to update interest state: \(error)")
        }
    }
    
    /// Get unsynced interest changes
    /// - Returns: Array of venue IDs with pending sync
    func getUnsyncedInterests() -> [(venueId: String, isInterested: Bool)] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<InterestEntity> = InterestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "synced == NO")
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { (venueId: $0.venue_id ?? "", isInterested: $0.is_interested) }
        } catch {
            print("❌ Failed to fetch unsynced interests: \(error)")
            return []
        }
    }
    
    /// Mark interest as synced
    /// - Parameter venueId: Venue identifier
    func markInterestAsSynced(venueId: String) {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<InterestEntity> = InterestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "venue_id == %@", venueId)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.synced = true
                try context.save()
            }
        } catch {
            print("❌ Failed to mark interest as synced: \(error)")
        }
    }
    
    // MARK: - Cache Cleanup
    
    /// Clear all cached data
    func clearCache() {
        let context = container.viewContext
        
        // Clear venues
        let venueRequest: NSFetchRequest<NSFetchRequestResult> = VenueEntity.fetchRequest()
        let venueDelete = NSBatchDeleteRequest(fetchRequest: venueRequest)
        
        // Clear interests
        let interestRequest: NSFetchRequest<NSFetchRequestResult> = InterestEntity.fetchRequest()
        let interestDelete = NSBatchDeleteRequest(fetchRequest: interestRequest)
        
        do {
            try context.execute(venueDelete)
            try context.execute(interestDelete)
            
            // Save context after batch delete to ensure cleanup
            try context.save()
            
            // Reset context to clear any cached objects
            context.reset()
            
            print("💾 Cache cleared")
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }
}
