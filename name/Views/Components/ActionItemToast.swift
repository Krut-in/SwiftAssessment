//
//  ActionItemToast.swift
//  name
//
//  Created by GitHub Copilot
//
//  DESCRIPTION:
//  Toast notification component for displaying action item creation alerts.
//  Shows a subtle, elegant card that slides down from top and auto-dismisses after 3 seconds.
//  Features confetti animation, haptic feedback, screen dimming, and tap-to-navigate.
//  
//  DESIGN SPECIFICATIONS:
//  - Position: Top of screen, centered horizontally
//  - Animation: Slide down entry with spring, fade out exit
//  - Confetti: Upward particles from below toast to top
//  - Dimming: Subtle 0.7 opacity background overlay
//  - Haptic: Medium impact on appearance
//  - Auto-dismiss: 3 seconds with smooth animation
//  - Tap: Navigate to profile tab
//  
//  USAGE:
//  ActionItemToast(
//      actionItem: $appState.pendingActionItem,
//      isShowing: $appState.showActionItemToast
//  )
//  .zIndex(999) // Place above other content
//

import SwiftUI

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

// MARK: - Action Item Toast

struct ActionItemToast: View {
    @Binding var actionItem: ActionItem?
    @Binding var isShowing: Bool
    @ObservedObject private var appState = AppState.shared
    
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var animateConfetti = false
    
    var body: some View {
        ZStack {
            // Dimming overlay
            if isShowing {
                Color.black
                    .opacity(0.3) // 30% dimming (0.7 opacity means 30% dim)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(Theme.Animation.gentle, value: isShowing)
            }
            
            VStack {
                if isShowing, let item = actionItem {
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
                        toastContent(item: item)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
                    .onAppear {
                        triggerEffects()
                        startAutoDismissTimer()
                    }
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func toastContent(item: ActionItem) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Goal Reached!")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(item.description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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
        .onTapGesture {
            navigateToProfile()
        }
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
        
        // Create 20 particles
        for i in 0..<20 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: -150...150),
                y: toastYPosition + 80, // Start below toast
                color: [Theme.Colors.accent, Theme.Colors.primary, Theme.Colors.success, Theme.Colors.warning].randomElement() ?? Theme.Colors.accent,
                size: CGFloat.random(in: 4...8),
                rotation: Double.random(in: 0...360),
                delay: Double(i) * 0.02 // Stagger animation
            )
            confettiParticles.append(particle)
        }
    }
    
    private func navigateToProfile() {
        // Navigate to profile tab (index 2)
        appState.selectedTab = 2
        dismissToast()
    }
    
    private func startAutoDismissTimer() {
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
        
        // Clear action item and confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            actionItem = nil
            confettiParticles = []
            animateConfetti = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isShowing = true
    @Previewable @State var actionItem: ActionItem? = ActionItem(
        id: "action_1",
        venue_id: "venue_1",
        interested_user_ids: ["user_1", "user_2", "user_3", "user_4"],
        action_type: "book_venue",
        action_code: "LUNA-venue_1-1234",
        description: "4 friends interested - coordinate plans!",
        threshold_met: true,
        status: "pending",
        created_at: "2025-11-22T10:00:00Z",
        venue: nil
    )
    
    return ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        ActionItemToast(
            actionItem: $actionItem,
            isShowing: $isShowing
        )
    }
}
