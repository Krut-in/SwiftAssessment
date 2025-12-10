//
//  StatusBadgeView.swift
//  name
//
//  Created by Antigravity AI on 10/12/25.
//
//  DESCRIPTION:
//  Visual indicator component showing confirmation status.
//  Displays appropriate icon and color based on status (pending/confirmed/declined).
//

import SwiftUI

struct StatusBadgeView: View {
    
    // MARK: - Properties
    
    let status: ConfirmationStatus.Status
    let showText: Bool
    
    init(status: ConfirmationStatus.Status, showText: Bool = true) {
        self.status = status
        self.showText = showText
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
            
            if showText {
                Text(statusText)
                    .font(Theme.Fonts.caption)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, showText ? 8 : 4)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch status {
        case .pending:
            return "clock"
        case .confirmed:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .confirmed:
            return "Confirmed"
        case .declined:
            return "Declined"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return Theme.Colors.textTertiary
        case .confirmed:
            return Theme.Colors.success
        case .declined:
            return Theme.Colors.error
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StatusBadgeView(status: .pending)
        StatusBadgeView(status: .confirmed)
        StatusBadgeView(status: .declined)
        
        HStack(spacing: 16) {
            StatusBadgeView(status: .pending, showText: false)
            StatusBadgeView(status: .confirmed, showText: false)
            StatusBadgeView(status: .declined, showText: false)
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
