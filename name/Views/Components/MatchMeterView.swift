//
//  MatchMeterView.swift
//  name
//
//  Created by Krutin Rathod on 03/12/25.
//
//  DESCRIPTION:
//  Gamified circular progress ring component for displaying recommendation match scores.
//  Replaces the basic score badge with an engaging, animated meter that provides
//  at-a-glance quality indication through dynamic color gradients.
//
//  KEY FEATURES:
//  - Circular progress ring (56x56pt) with score-based fill
//  - Dynamic gradient colors based on score ranges:
//    • 0-3: Red → Orange (poor match)
//    • 4-6: Orange → Yellow (moderate match)
//    • 7-8.5: Yellow → Light Green (good match)
//    • 8.6-10: Light Green → Vibrant Green (excellent match)
//  - Animated fill on appearance (0° → score-based angle)
//  - Particle effect overlay for exceptional scores (9+)
//  - Colored glow shadow matching gradient end color
//  - Spring bounce animation on info button tap
//
//  DESIGN DECISIONS:
//  - Larger size (56x56) for increased visual prominence
//  - Angular gradient for smooth color transition around ring
//  - Ring thickness of 6pt for optimal visibility
//  - White center background for score number contrast
//  - Particle effects reserved for 9+ to highlight excellence
//
//  PERFORMANCE:
//  - Lightweight view using native SwiftUI shapes
//  - Single animation on appearance to avoid repeated renders
//  - Conditional particle rendering only when needed
//

import SwiftUI

struct MatchMeterView: View {
    
    // MARK: - Properties
    
    /// Score value from 0-10
    let score: Double
    
    /// Optional score breakdown for info popover
    let scoreBreakdown: ScoreBreakdown?
    
    /// Callback when info button is tapped
    var onInfoTap: (() -> Void)?
    
    // MARK: - State
    
    /// Animation state for progress ring fill
    @State private var animatedProgress: Double = 0
    
    /// Controls score breakdown popover display
    @State private var showScoreBreakdown = false
    
    // MARK: - Computed Properties
    
    /// Progress value from 0.0 to 1.0
    private var progress: Double {
        min(max(score / 10.0, 0.0), 1.0)
    }
    
    /// Formatted score text (e.g., "8.5")
    private var scoreText: String {
        String(format: "%.1f", score)
    }
    
    /// Single solid color based on score (yellow for low, green for high)
    private var meterColor: Color {
        if score < 6.0 {
            // Lower ratings: Yellow
            return Color.yellow
        } else {
            // Higher ratings: Green
            return Color.green
        }
    }
    
    /// Subtle shadow color
    private var glowColor: Color {
        meterColor.opacity(0.2)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Progress ring background (unfilled portion)
            Circle()
                .stroke(
                    Theme.Colors.separator.opacity(0.3),
                    lineWidth: 5
                )
                .frame(width: 50, height: 50)
            
            // Progress ring (filled portion) - single solid color
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    meterColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
            
            // White background circle for score text (adapts to dark mode)
            Circle()
                .fill(Color(uiColor: .systemBackground))
                .frame(width: 40, height: 40)
            
            // Center score text
            Text(scoreText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .frame(width: 56, height: 56)
        .shadow(color: glowColor, radius: 4, x: 0, y: 2)
        .onAppear {
            // Animate progress fill on appearance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .accessibilityLabel("Match score \(scoreText) out of 10")
        .popover(isPresented: $showScoreBreakdown) {
            if let breakdown = scoreBreakdown {
                ScoreBreakdownView(breakdown: breakdown)
                    .presentationCompactAdaptation(.popover)
            }
        }
        .onTapGesture {
            if scoreBreakdown != nil {
                showScoreBreakdown.toggle()
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
}

// MARK: - Preview

#Preview("Match Meter - Various Scores") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            VStack {
                MatchMeterView(
                    score: 9.2,
                    scoreBreakdown: ScoreBreakdown(
                        popularity: 25,
                        categoryMatch: 30,
                        friendSignal: 25,
                        proximity: 20
                    )
                )
                Text("9.2 - High")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            VStack {
                MatchMeterView(
                    score: 7.5,
                    scoreBreakdown: nil
                )
                Text("7.5 - Good")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        
        HStack(spacing: 20) {
            VStack {
                MatchMeterView(
                    score: 5.0,
                    scoreBreakdown: nil
                )
                Text("5.0 - Moderate")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            VStack {
                MatchMeterView(
                    score: 2.5,
                    scoreBreakdown: nil
                )
                Text("2.5 - Low")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }
    .padding()
}