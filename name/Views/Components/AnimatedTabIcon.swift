//
//  AnimatedTabIcon.swift
//  name
//
//  Created by AI Assistant on 03/12/25.
//
//  DESCRIPTION:
//  Animated SF Symbol icons with unique micro-interactions per tab.
//  Each tab has its own signature animation that plays on selection.
//  
//  TAB-SPECIFIC ANIMATIONS:
//  - Discover: Bounce (scale 0.8 → 1.2 → 1.0) + shimmer sweep
//  - For You: 360° rotation + yellow pulse glow
//  - Social: Color shift (grayscale → vibrant primary blue)
//  - Profile: Bottom-to-top fill wave + subtle halo
//  
//  DESIGN APPROACH:
//  - Cool, minimal, bold aesthetic
//  - No purple gradients (per user feedback)
//  - Smooth spring animations
//  - Playful brand personality
//

import SwiftUI

struct AnimatedTabIcon: View {
    
    // MARK: - Types
    
    enum TabIconType {
        case discover
        case forYou
        case social
        case profile
        
        var systemImage: String {
            switch self {
            case .discover: return "house.fill"
            case .forYou: return "star.fill"
            case .social: return "person.2.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    // MARK: - Properties
    
    let type: TabIconType
    let isSelected: Bool
    
    @State private var animationTrigger = false
    @State private var rotationAngle: Double = 0
    @State private var scaleValue: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var fillProgress: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -100
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            switch type {
            case .discover:
                discoverIcon
            case .forYou:
                forYouIcon
            case .social:
                socialIcon
            case .profile:
                profileIcon
            }
        }
        .frame(width: 32, height: 32)
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue && !oldValue {
                triggerAnimation()
            } else if !newValue {
                resetAnimation()
            }
        }
    }
    
    // MARK: - Icon Views
    
    // Discover: Bounce + Shimmer
    private var discoverIcon: some View {
        ZStack {
            Image(systemName: type.systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
                .scaleEffect(scaleValue)
            
            // Shimmer overlay when selected
            if isSelected {
                Image(systemName: type.systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                    )
            }
        }
    }
    
    // For You: Rotation + Pulse Glow
    private var forYouIcon: some View {
        ZStack {
            // Glow behind
            if glowOpacity > 0 {
                Image(systemName: type.systemImage)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.yellow)
                    .blur(radius: 10)
                    .opacity(glowOpacity)
            }
            
            // Main icon
            Image(systemName: type.systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isSelected ? .yellow : Theme.Colors.textSecondary)
                .rotationEffect(.degrees(rotationAngle))
        }
    }
    
    // Social: Color Shift
    private var socialIcon: some View {
        Image(systemName: type.systemImage)
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
            .scaleEffect(scaleValue)
    }
    
    // Profile: Fill Wave + Halo
    private var profileIcon: some View {
        ZStack {
            // Halo effect when selected
            if isSelected && glowOpacity > 0 {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.4))
                    .frame(width: 38, height: 38)
                    .blur(radius: 6)
                    .opacity(glowOpacity)
            }
            
            // Main icon with fill effect
            ZStack {
                // Background (gray when not selected)
                if !isSelected {
                    Image(systemName: type.systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                // Fill wave from bottom
                if isSelected {
                    Image(systemName: type.systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                        .mask(
                            Rectangle()
                                .frame(height: 32 * fillProgress)
                                .offset(y: 32 * (0.5 - fillProgress / 2))
                        )
                }
            }
        }
    }
    
    // MARK: - Animation Methods
    
    private func triggerAnimation() {
        animationTrigger = true
        
        switch type {
        case .discover:
            animateBounce()
            animateShimmer()
            
        case .forYou:
            animateRotation()
            animatePulse()
            
        case .social:
            animateColorShift()
            
        case .profile:
            animateFillWave()
            animateHalo()
        }
    }
    
    private func resetAnimation() {
        animationTrigger = false
        scaleValue = 1.0
        rotationAngle = 0
        glowOpacity = 0
        fillProgress = 0
        shimmerOffset = -100
    }
    
    // Discover animations
    private func animateBounce() {
        scaleValue = 0.8
        withAnimation(Theme.Animation.iconBounce) {
            scaleValue = 1.2
        }
        withAnimation(Theme.Animation.iconBounce.delay(0.15)) {
            scaleValue = 1.0
        }
    }
    
    private func animateShimmer() {
        shimmerOffset = -100
        withAnimation(.linear(duration: 0.6).delay(0.2)) {
            shimmerOffset = 100
        }
    }
    
    // For You animations
    private func animateRotation() {
        rotationAngle = 0
        withAnimation(.easeInOut(duration: 0.6)) {
            rotationAngle = 360
        }
    }
    
    private func animatePulse() {
        glowOpacity = 0
        withAnimation(.easeOut(duration: 0.4)) {
            glowOpacity = 0.8
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
            glowOpacity = 0
        }
    }
    
    // Social animation
    private func animateColorShift() {
        scaleValue = 0.9
        withAnimation(Theme.Animation.spring) {
            scaleValue = 1.1
        }
        withAnimation(Theme.Animation.spring.delay(0.15)) {
            scaleValue = 1.0
        }
    }
    
    // Profile animations
    private func animateFillWave() {
        fillProgress = 0
        withAnimation(.easeInOut(duration: 0.5)) {
            fillProgress = 1.0
        }
    }
    
    private func animateHalo() {
        glowOpacity = 0
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            glowOpacity = 0.6
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.6)) {
            glowOpacity = 0.2
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 30) {
            AnimatedTabIcon(type: .discover, isSelected: true)
            AnimatedTabIcon(type: .forYou, isSelected: true)
            AnimatedTabIcon(type: .social, isSelected: true)
            AnimatedTabIcon(type: .profile, isSelected: true)
        }
        
        HStack(spacing: 30) {
            AnimatedTabIcon(type: .discover, isSelected: false)
            AnimatedTabIcon(type: .forYou, isSelected: false)
            AnimatedTabIcon(type: .social, isSelected: false)
            AnimatedTabIcon(type: .profile, isSelected: false)
        }
    }
    .padding()
}
