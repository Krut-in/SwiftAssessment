//
//  EmptyStateView.swift
//  name
//
//  Created by Krutin Rathod on 22/11/25.
//
//  DESCRIPTION:
//  Reusable empty state component for consistent UX across the app.
//  Displays icon, title, message, and optional action button.
//  Supports both general empty states and filtered result variants.
//  
//  KEY FEATURES:
//  - Configurable icon, title, and message
//  - Optional action button with callback
//  - Consistent styling across all empty states
//  - Smooth animations for appearance
//  - Special variant for filtered results
//  - Uses centralized Theme for consistent styling
//  
//  USAGE:
//  EmptyStateView(
//      icon: "heart.slash",
//      title: "No Saved Places",
//      message: "Explore venues and tap the heart to save them",
//      actionTitle: "Explore Venues",
//      action: { /* Navigate to discover tab */ }
//  )
//
//  // Filtered results variant:
//  EmptyStateView.filteredResults(onClearFilters: { ... })
//
//

import SwiftUI

struct EmptyStateView: View {
    
    // MARK: - Properties
    
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Theme.Layout.spacing) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
            
            Text(title)
                .font(Theme.Fonts.title3)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text(message)
                .font(Theme.Fonts.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .transition(.opacity)
    }
    
    // MARK: - Convenience Initializers
    
    /// Filtered results empty state variant
    static func filteredResults(onClearFilters: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: "No venues match your filters",
            message: "Try adjusting your filters to see more venues",
            actionTitle: "Clear Filters",
            action: onClearFilters
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        EmptyStateView(
            icon: "heart.slash",
            title: "No Saved Places",
            message: "Explore venues and tap the heart to save them",
            actionTitle: "Explore Venues",
            action: { print("Explore tapped") }
        )
        
        EmptyStateView(
            icon: "map",
            title: "No Coffee Shops Found",
            message: "Try another filter to discover more venues"
        )
        
        EmptyStateView.filteredResults(onClearFilters: { print("Clear filters") })
    }
}
