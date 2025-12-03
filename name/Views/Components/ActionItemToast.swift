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



// MARK: - Action Item Toast

struct ActionItemToast: View {
    @Binding var actionItem: ActionItem?
    @Binding var isShowing: Bool
    @ObservedObject private var appState = AppState.shared
    
    @State private var dismissTask: Task<Void, Never>?
    
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
                        // Toast content
                        toastContent(item: item)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
                }
                Spacer()
            }
        }
        .onChange(of: isShowing) { _, newValue in
            // Trigger effects only when toast is shown (not when hidden)
            if newValue {
                triggerEffects()
                startAutoDismissTimer()
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
    }
    

    
    private func navigateToProfile() {
        // Navigate to profile tab (index 3)
        appState.selectedTab = 3
        dismissToast()
    }
    
    private func startAutoDismissTimer() {
        // Cancel any existing dismiss task to prevent duplicates
        dismissTask?.cancel()
        
        // Create new dismiss task with cancellation support
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        // Cancel the auto-dismiss task to prevent double dismissal
        dismissTask?.cancel()
        dismissTask = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
        
        // Clear action item after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            actionItem = nil
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
