//
//  ActionItemToast.swift
//  name
//
//  Created by GitHub Copilot
//
//  DESCRIPTION:
//  Toast notification component for displaying action item creation alerts.
//  Shows a subtle, elegant card that slides down from top and auto-dismisses after 3 seconds.
//  
//  DESIGN SPECIFICATIONS:
//  - Position: Top of screen, centered horizontally
//  - Animation: Slide down entry with spring, fade out exit
//  - Auto-dismiss: 3 seconds with smooth animation
//  - Non-blocking: Doesn't interfere with user interactions
//  - Style: System background with blur, shadow, rounded corners
//  
//  USAGE:
//  ActionItemToast(
//      actionItem: $appState.pendingActionItem,
//      isShowing: $appState.showActionItemToast
//  )
//  .zIndex(999) // Place above other content
//

import SwiftUI

struct ActionItemToast: View {
    @Binding var actionItem: ActionItem?
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            if isShowing, let item = actionItem {
                toastContent(item: item)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
                    .onAppear {
                        startAutoDismissTimer()
                    }
            }
            Spacer()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
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
        
        // Clear action item after animation
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
