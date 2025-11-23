//
//  DistanceBadge.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Reusable SwiftUI component for displaying distance from user to venue.
//  Provides color-coded visual feedback based on proximity.
//  
//  FEATURES:
//  - Color coding: Green (0-2km), Blue (2-5km), Gray (5+km)
//  - Location icon using SF Symbols
//  - Compact design suitable for cards and detail views
//  - Optional display (only shown when distance is available)
//  
//  DESIGN SPECIFICATIONS:
//  - System font, 12pt, medium weight
//  - Rounded rectangle background with padding
//  - Location.fill SF Symbol icon
//  - Format: "X.X km away"
//  
//  USAGE:
//  DistanceBadge(distance_km: 1.5)  // Shows "1.5 km away" in green
//  DistanceBadge(distance_km: 3.2)  // Shows "3.2 km away" in blue
//  DistanceBadge(distance_km: nil)  // Returns EmptyView (nothing displayed)
//  
//  COLOR THRESHOLDS:
//  - Green: 0-2 km (very close, walkable)
//  - Blue: 2-5 km (moderate, short trip)
//  - Gray: 5+ km (far, requires transportation)
//

import SwiftUI

/// Badge component displaying distance from user to venue with color coding
struct DistanceBadge: View {
    let distance_km: Double?
    
    var body: some View {
        if let distance = distance_km {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10, weight: .medium))
                Text("\(distance, specifier: "%.1f") km away")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(distanceColor(for: distance))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(distanceColor(for: distance).opacity(0.15))
            )
        }
    }
    
    /// Determines color based on distance thresholds
    /// - Parameter distance: Distance in kilometers
    /// - Returns: Color for the badge (green, blue, or gray)
    private func distanceColor(for distance: Double) -> Color {
        if distance <= 2.0 {
            return .green
        } else if distance <= 5.0 {
            return .blue
        } else {
            return .gray
        }
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
