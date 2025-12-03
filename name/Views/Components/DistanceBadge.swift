//
//  DistanceBadge.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Reusable SwiftUI component for displaying distance from user to venue.
//  Provides contextual color-coded visual feedback based on proximity and travel mode.
//  
//  FEATURES:
//  - Contextual color coding based on travel mode
//  - Dynamic SF Symbol icons (walk, bicycle, car, location)
//  - Pulse animation for walking distance venues
//  - Compact design suitable for cards and detail views
//  - Full dark/light mode compatibility
//  
//  DESIGN SPECIFICATIONS:
//  - System font, 12pt, semibold weight
//  - Capsule-shaped chip background
//  - Context-aware SF Symbol icon
//  - Format: "X.X km away"
//  
//  USAGE:
//  DistanceBadge(distance_km: 0.3)  // Shows "0.3 km away" in green with walk icon + pulse
//  DistanceBadge(distance_km: 1.5)  // Shows "1.5 km away" in blue with bicycle icon
//  DistanceBadge(distance_km: 3.0)  // Shows "3.0 km away" in orange with car icon
//  DistanceBadge(distance_km: nil)  // Returns EmptyView (nothing displayed)
//  
//  DISTANCE THRESHOLDS:
//  - Walking (Green): < 0.5 km - figure.walk icon + pulse animation
//  - Biking (Blue): 0.5-2 km - bicycle icon
//  - Driving (Orange): 2-5 km - car.fill icon
//  - Far (Gray): > 5 km - location.fill icon
//

import SwiftUI

/// Badge component displaying distance from user to venue with contextual color and icon coding
struct DistanceBadge: View {
    let distance_km: Double?
    
    @State private var isPulsing = false
    
    var body: some View {
        if let distance = distance_km {
            HStack(spacing: 4) {
                Image(systemName: distanceIcon(for: distance))
                    .font(.system(size: 12, weight: .semibold))
                Text("\(distance, specifier: "%.1f") km away")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(distanceColor(for: distance))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(distanceColor(for: distance).opacity(0.15))
            )
            .scaleEffect(shouldPulse(for: distance) && isPulsing ? 1.05 : 1.0)
            .animation(
                shouldPulse(for: distance) ? Theme.Animation.nearbyPulse : nil,
                value: isPulsing
            )
            .onAppear {
                if shouldPulse(for: distance) {
                    isPulsing = true
                }
            }
        }
    }
    
    /// Determines color based on distance thresholds and travel mode
    /// - Parameter distance: Distance in kilometers
    /// - Returns: Color for the badge (green, blue, orange, or gray)
    private func distanceColor(for distance: Double) -> Color {
        if distance < 0.5 {
            return Theme.Colors.success // Green for walking distance
        } else if distance < 2.0 {
            return Theme.Colors.info // Blue for biking distance
        } else if distance < 5.0 {
            return Theme.Colors.warning // Orange for short drive
        } else {
            return Theme.Colors.textSecondary // Gray for far distance
        }
    }
    
    /// Returns appropriate SF Symbol icon based on distance
    /// - Parameter distance: Distance in kilometers
    /// - Returns: SF Symbol icon name
    private func distanceIcon(for distance: Double) -> String {
        if distance < 0.5 {
            return "figure.walk" // Walking distance
        } else if distance < 2.0 {
            return "bicycle" // Biking distance
        } else if distance < 5.0 {
            return "car.fill" // Driving distance
        } else {
            return "location.fill" // Far distance
        }
    }
    
    /// Determines if the badge should pulse based on distance
    /// - Parameter distance: Distance in kilometers
    /// - Returns: True if distance is walkable (<0.5km)
    private func shouldPulse(for distance: Double) -> Bool {
        return distance < 0.5
    }
}

// MARK: - Preview Provider

#Preview("Close Distance") {
    DistanceBadge(distance_km: 1.2)
        .padding()
}

#Preview("Moderate Distance") {
    DistanceBadge(distance_km: 3.5)
        .padding()
}

#Preview("Far Distance") {
    DistanceBadge(distance_km: 7.8)
        .padding()
}

#Preview("No Distance") {
    DistanceBadge(distance_km: nil)
        .padding()
}
