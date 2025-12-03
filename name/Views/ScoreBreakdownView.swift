//
//  ScoreBreakdownView.swift
//  name
//
//  Created by Krutin Rathod on 27/11/25.
//
//  DESCRIPTION:
//  Reusable component for displaying recommendation score breakdowns.
//  Shows factor contributions with visual progress bars for transparency.
//  
//  FEATURES:
//  - Factor breakdown with percentages
//  - Visual progress bars for each factor
//  - Color-coded factors for visual hierarchy
//  - Compact popover-friendly design
//  
//  USAGE:
//  .popover(isPresented: $showBreakdown) {
//      ScoreBreakdownView(breakdown: recommendation.score_breakdown)
//  }
//

import SwiftUI

struct ScoreBreakdownView: View {
    
    // MARK: - Properties
    
    let breakdown: ScoreBreakdown
    
    // MARK: - Computed Properties
    
    private var factors: [(String, Double, Color, String)] {
        [
            ("Popularity", breakdown.popularity, Theme.Colors.accent, "star.fill"),
            ("Category Match", breakdown.categoryMatch, Theme.Colors.success, "tag.fill"),
            ("Friend Signal", breakdown.friendSignal, Theme.Colors.warning, "person.2.fill"),
            ("Proximity", breakdown.proximity, Theme.Colors.info, "location.fill")
        ]
    }
    
    private var total: Double {
        breakdown.popularity + breakdown.categoryMatch + breakdown.friendSignal + breakdown.proximity
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.padding) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Theme.Colors.primary)
                Text("Score Breakdown")
                    .font(Theme.Fonts.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            // Factors
            VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                ForEach(factors, id: \.0) { factor in
                    FactorRow(
                        name: factor.0,
                        value: factor.1,
                        color: factor.2,
                        icon: factor.3,
                        total: total
                    )
                }
            }
            
            // Total
            Divider()
            
            HStack {
                Text("Total Score")
                    .font(Theme.Fonts.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(total))%")
                    .font(Theme.Fonts.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(Theme.Layout.padding)
        .frame(width: 300)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .elevationMedium()
    }
}

// MARK: - Factor Row

struct FactorRow: View {
    let name: String
    let value: Double
    let color: Color
    let icon: String
    let total: Double
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (value / total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Factor name and value
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(color)
                    
                    Text(name)
                        .font(Theme.Fonts.caption)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(Theme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.secondaryBackground)
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (value / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    ScoreBreakdownView(
        breakdown: ScoreBreakdown(
            popularity: 25,
            categoryMatch: 30,
            friendSignal: 25,
            proximity: 20
        )
    )
    .padding()
}
