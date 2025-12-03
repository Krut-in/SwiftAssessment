//
//  DynamicBadgeView.swift
//  name
//
//  Created by AI Assistant on 03/12/25.
//
//  DESCRIPTION:
//  Animated badge component with pulsing ring and threshold-based animations.
//  Displays notification counts with special effects when reaching 5+ threshold.
//  
//  FEATURES:
//  - Pulsing ring animation (triggers at count >= 5)
//  - Solid accent background (bold red)
//  - Entry animation with spring when reaching threshold
//  - Count-up number animation
//  - Haptic feedback for threshold notifications
//  
//  THRESHOLD BEHAVIOR:
//  - Standard badge: 1-4 notifications (no pulsing)
//  - Enhanced badge: 5+ notifications (pulsing ring + haptics)
//  
//  DESIGN APPROACH:
//  - Cool, minimal, solid & bold aesthetic
//  - No gradients (per user feedback)
//  - System font for readability
//

import SwiftUI

struct DynamicBadgeView: View {
    
    // MARK: - Properties
    
    let count: Int
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var previousCount: Int = 0
    @State private var hasReachedThreshold: Bool = false
    @State private var scaleAnimation: CGFloat = 1.0
    
    private let threshold: Int = 5
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Pulsing ring (only when count >= 5)
            if count >= threshold {
                Circle()
                    .stroke(Theme.Colors.accent, lineWidth: 2)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
            }
            
            // Badge circle with number
            Circle()
                .fill(Theme.Colors.accent)
                .frame(width: badgeSize, height: badgeSize)
                .overlay(
                    Text(displayText)
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
                .scaleEffect(scaleAnimation)
        }
        .frame(width: badgeSize, height: badgeSize)
        .onAppear {
            previousCount = count
            checkThreshold()
        }
        .onChange(of: count) { oldValue, newValue in
            if newValue > oldValue {
                animateCountUp()
            }
            
            // Check if we just reached threshold
            if oldValue < threshold && newValue >= threshold {
                reachedThreshold()
            }
            
            previousCount = newValue
        }
    }
    
    // MARK: - Computed Properties
    
    private var badgeSize: CGFloat {
        count >= 10 ? 22 : 20
    }
    
    private var fontSize: CGFloat {
        count >= 10 ? 10 : 11
    }
    
    private var displayText: String {
        if count > 99 {
            return "99+"
        } else {
            return "\(count)"
        }
    }
    
    // MARK: - Animation Methods
    
    private func checkThreshold() {
        if count >= threshold {
            hasReachedThreshold = true
            startPulseAnimation()
        }
    }
    
    private func animateCountUp() {
        // Quick scale bounce on increment
        scaleAnimation = 1.2
        withAnimation(Theme.Animation.countUp) {
            scaleAnimation = 1.0
        }
    }
    
    private func reachedThreshold() {
        hasReachedThreshold = true
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Entry animation with spring
        scaleAnimation = 0.5
        withAnimation(Theme.Animation.spring) {
            scaleAnimation = 1.0
        }
        
        // Start pulsing
        startPulseAnimation()
    }
    
    private func startPulseAnimation() {
        guard count >= threshold else {
            // Stop pulsing if we drop below threshold
            pulseScale = 1.0
            return
        }
        
        // Continuous pulsing ring
        withAnimation(Theme.Animation.badgePulse) {
            pulseScale = 1.5
        }
        
        // Reset and repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            pulseScale = 1.0
            if count >= threshold {
                startPulseAnimation()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Standard badge (< 5)
        HStack(spacing: 30) {
            DynamicBadgeView(count: 1)
            DynamicBadgeView(count: 3)
            DynamicBadgeView(count: 4)
        }
        
        Text("Standard Badges (1-4)")
            .font(Theme.Fonts.caption)
            .foregroundColor(Theme.Colors.textSecondary)
        
        Divider()
        
        // Threshold badge (>= 5)
        HStack(spacing: 30) {
            DynamicBadgeView(count: 5)
            DynamicBadgeView(count: 7)
            DynamicBadgeView(count: 12)
        }
        
        Text("Threshold Badges (5+) - Pulsing")
            .font(Theme.Fonts.caption)
            .foregroundColor(Theme.Colors.textSecondary)
        
        Divider()
        
        // Edge cases
        HStack(spacing: 30) {
            DynamicBadgeView(count: 99)
            DynamicBadgeView(count: 100)
        }
        
        Text("Edge Cases (99, 99+)")
            .font(Theme.Fonts.caption)
            .foregroundColor(Theme.Colors.textSecondary)
    }
    .padding()
}
