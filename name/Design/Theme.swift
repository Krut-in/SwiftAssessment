//
//  Theme.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Centralized design system for the Luna application.
//  Defines semantic colors, typography, and layout constants to ensure consistency.
//  
//  USAGE:
//  Text("Hello").foregroundColor(Theme.Colors.textPrimary)
//  .font(Theme.Fonts.title)
//

import SwiftUI

struct Theme {
    
    // MARK: - Colors
    
    struct Colors {
        // Brand Colors
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.blue
        
        // Semantic Colors
        static let background = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // UI Elements
        static let cardBackground = Color(uiColor: .systemBackground)
        static let separator = Color(uiColor: .separator)
        static let shadow = Color.black.opacity(0.1)
    }
    
    // MARK: - Typography
    
    struct Fonts {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .semibold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)
    }
    
    // MARK: - Layout
    
    struct Layout {
        static let padding: CGFloat = 16.0
        static let cornerRadius: CGFloat = 12.0
        static let smallCornerRadius: CGFloat = 8.0
        static let spacing: CGFloat = 12.0
        static let smallSpacing: CGFloat = 8.0
        static let largeSpacing: CGFloat = 24.0
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let `default` = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}
