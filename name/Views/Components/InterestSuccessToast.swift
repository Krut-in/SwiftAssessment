//
//  InterestSuccessToast.swift
//  name
//
//  Created for Luna Demo Enhancement
//
//  DESCRIPTION:
//  Toast notification component for celebrating successful venue interest toggle.
//  Shows a delightful top notification with confetti animation and haptic feedback.
//  
//  DESIGN SPECIFICATIONS:
//  - Position: Top of screen, centered horizontally (50pt below status bar)
//  - Animation: Slide down entry with spring, fade out exit
//  - Confetti: Upward particles from below toast
//  - Haptic: Medium impact on appearance
//  - Auto-dismiss: 2-3 seconds with smooth animation
//  
//  USAGE:
//  InterestSuccessToast(isShowing: $viewModel.showInterestToast)
//      .zIndex(100) // Place above content
//

import SwiftUI

// MARK: - Interest Success Toast

struct InterestSuccessToast: View {
    @Binding var isShowing: Bool
    
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var animateConfetti = false
    @State private var dismissTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            VStack {
                if isShowing {
                    ZStack {
                        // Confetti particles
                        ForEach(confettiParticles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                                .rotationEffect(.degrees(particle.rotation))
                                .offset(
                                    x: particle.x,
                                    y: animateConfetti ? particle.y - 200 : particle.y
                                )
                                .opacity(animateConfetti ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 1.2)
                                        .delay(particle.delay),
                                    value: animateConfetti
                                )
                        }
                        
                        // Toast content
                        toastContent
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
                }
                Spacer()
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                triggerEffects()
                startAutoDismissTimer()
            }
        }
    }
    
    @ViewBuilder
    private var toastContent: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("You're in!")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Time to make plans!")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: {
                dismissToast()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 50) // Below status bar
    }
    
    private func triggerEffects() {
        // Haptic feedback - device shake
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Generate confetti particles
        generateConfetti()
        
        // Animate confetti upward
        withAnimation {
            animateConfetti = true
        }
    }
    
    private func generateConfetti() {
        confettiParticles = []
        let toastYPosition: CGFloat = 100 // Approximate toast position
        
        // Create 15 particles (lighter than ActionItemToast)
        for i in 0..<15 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: -150...150),
                y: toastYPosition + 80, // Start below toast
                color: [Theme.Colors.accent, Theme.Colors.primary, Theme.Colors.success].randomElement() ?? Theme.Colors.accent,
                size: CGFloat.random(in: 4...8),
                rotation: Double.random(in: 0...360),
                delay: Double(i) * 0.02 // Stagger animation
            )
            confettiParticles.append(particle)
        }
    }
    
    private func startAutoDismissTimer() {
        // Cancel any existing dismiss task
        dismissTask?.cancel()
        
        // Create new dismiss task with 2.5 second delay
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        // Cancel the auto-dismiss task
        dismissTask?.cancel()
        dismissTask = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
        
        // Clear confetti after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiParticles = []
            animateConfetti = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isShowing = true
    
    return ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        InterestSuccessToast(isShowing: $isShowing)
    }
}
