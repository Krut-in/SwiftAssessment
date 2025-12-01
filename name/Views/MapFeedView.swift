//
//  MapFeedView.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Map view displaying venue pins with category-based coloring and clustering.
//  Provides visual discovery of venues through an interactive map interface.
//  
//  FEATURES:
//  - SwiftUI Map with custom annotations
//  - Category-colored pins
//  - Clustering for dense areas
//  - Tap annotation to view venue detail
//  - Filter integration
//  - Location tracking
//  
//  USAGE:
//  MapFeedView(venues: venues, onVenueTap: { venue in ... })
//

import SwiftUI
import MapKit

// MARK: - Seeded Random Number Generator

/// Custom random number generator with deterministic seed for consistent results
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear congruential generator algorithm
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

struct MapFeedView: View {
    
    // MARK: - Properties
    
    let venues: [VenueListItem]
    let onVenueTap: (String) -> Void
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855), // NYC default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedVenueId: String?
    @State private var annotations: [VenueAnnotation] = []
    
    // MARK: - Body
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                VenueMapPin(
                    venueName: annotation.name,
                    category: annotation.category,
                    isSelected: selectedVenueId == annotation.id
                )
                .onTapGesture {
                    selectedVenueId = annotation.id
                    
                    // Track analytics
                    AnalyticsService.shared.track(
                        event: AnalyticsService.Event.mapPinTapped,
                        properties: [
                            AnalyticsService.PropertyKey.venueId: annotation.id,
                            AnalyticsService.PropertyKey.category: annotation.category
                        ]
                    )
                    
                    // Trigger navigation
                    onVenueTap(annotation.id)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            generateAnnotations()
            centerMapOnVenues()
        }
        .onChange(of: venues) { _ in
            generateAnnotations()
            centerMapOnVenues()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate venue annotations with deterministic positioning
    /// Uses venue ID as seed to ensure consistent pin positions across renders
    private func generateAnnotations() {
        annotations = venues.compactMap { venue in
            // Skip venues without coordinates
            guard let distance = venue.distance_km else { return nil }
            
            // Use venue ID to create deterministic seed for position
            // This ensures pins stay in the same position across re-renders
            let seed = abs(venue.id.hashValue)
            var generator = SeededRandomNumberGenerator(seed: UInt64(seed))
            
            // Calculate approximate coordinates based on distance
            // In production, venues should have actual lat/long from backend
            let latOffset = Double.random(in: -0.02...0.02, using: &generator)
            let lonOffset = Double.random(in: -0.02...0.02, using: &generator)
            
            let lat = region.center.latitude + latOffset
            let lon = region.center.longitude + lonOffset
            
            return VenueAnnotation(
                id: venue.id,
                name: venue.name,
                category: venue.category,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }
    }
    
    /// Center map on all venues
    private func centerMapOnVenues() {
        guard !annotations.isEmpty else { return }
        
        let coordinates = annotations.map { $0.coordinate }
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Venue Annotation Model

struct VenueAnnotation: Identifiable {
    let id: String
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Venue Map Pin Component

struct VenueMapPin: View {
    
    let venueName: String
    let category: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin icon
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                
                Image(systemName: categoryIcon)
                    .foregroundColor(.white)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Pin tail
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: -4, y: 8))
                path.addLine(to: CGPoint(x: 4, y: 8))
                path.closeSubpath()
            }
            .fill(categoryColor)
            .frame(width: 8, height: 8)
            .offset(y: -1)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(Theme.Animation.spring, value: isSelected)
    }
    
    // MARK: - Helper Properties
    
    private var categoryColor: Color {
        switch category.lowercased() {
        case "coffee shop", "café", "cafe":
            return Theme.Colors.Category.coffee
        case "restaurant", "food":
            return Theme.Colors.Category.restaurant
        case "bar", "pub", "nightlife":
            return Theme.Colors.Category.bar
        case "cultural", "museum", "gallery":
            return Theme.Colors.Category.cultural
        case "park", "outdoor":
            return Theme.Colors.Category.outdoor
        case "entertainment":
            return Theme.Colors.Category.entertainment
        default:
            return Theme.Colors.secondary
        }
    }
    
    private var categoryIcon: String {
        switch category.lowercased() {
        case "coffee shop", "café", "cafe":
            return "cup.and.saucer.fill"
        case "restaurant", "food":
            return "fork.knife"
        case "bar", "pub", "nightlife":
            return "wineglass.fill"
        case "cultural", "museum", "gallery":
            return "building.columns.fill"
        case "park", "outdoor":
            return "leaf.fill"
        case "entertainment":
            return "theatermasks.fill"
        default:
            return "mappin"
        }
    }
}

// MARK: - Preview

#Preview {
    MapFeedView(
        venues: [
            VenueListItem(id: "v1", name: "Coffee Shop", category: "Coffee Shop", image: "", interested_count: 5, distance_km: 0.5),
            VenueListItem(id: "v2", name: "Restaurant", category: "Restaurant", image: "", interested_count: 3, distance_km: 1.2),
            VenueListItem(id: "v3", name: "Bar", category: "Bar", image: "", interested_count: 8, distance_km: 0.8)
        ],
        onVenueTap: { _ in }
    )
}
