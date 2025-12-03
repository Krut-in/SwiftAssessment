//
//  Theme.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Centralized design system for the Luna application.
//  Defines semantic colors, typography, layout constants, and animations to ensure consistency.
//  Includes comprehensive dark mode support with WCAG-compliant color contrast.
//  
//  USAGE:
//  Text("Hello").foregroundColor(Theme.Colors.textPrimary)
//  .font(Theme.Fonts.title)
//  .shadow(color: Theme.Colors.Shadows.medium, radius: 8)
//

import SwiftUI

struct Theme {
    
    // MARK: - Colors
    
    struct Colors {
        // MARK: Brand Colors (Premium Palette)
        
        /// Primary brand color - Vibrant blue for main actions
        static let primary = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
        
        /// Secondary brand color - Deep purple for emphasis
        static let secondary = Color(red: 0.345, green: 0.337, blue: 0.839) // #5856D6
        
        /// Accent color - Energetic coral for key interactions
        static let accent = Color(red: 1.0, green: 0.271, blue: 0.227) // #FF4538
        
        // MARK: Semantic Background Colors (Auto-adapting)
        
        /// Primary background - Adapts to light/dark mode
        static let background = Color(uiColor: .systemBackground)
        
        /// Secondary background - Slightly elevated surfaces
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        
        /// Tertiary background - Cards and elevated content (dark mode specific)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        
        /// Elevated card background with subtle differentiation
        static let cardBackground = Color(uiColor: .systemBackground)
        
        /// Elevated surface for dark mode (slightly lighter than background)
        static let elevatedBackground = Color(uiColor: .secondarySystemBackground)
        
        // MARK: Text Colors (Auto-adapting)
        
        /// Primary text - Maximum contrast
        static let textPrimary = Color(uiColor: .label)
        
        /// Secondary text - Reduced emphasis
        static let textSecondary = Color(uiColor: .secondaryLabel)
        
        /// Tertiary text - Minimal emphasis
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        
        /// Quaternary text - Disabled or placeholder
        static let textQuaternary = Color(uiColor: .quaternaryLabel)
        
        // MARK: Status Colors (Enhanced)
        
        /// Success state - Green with proper contrast
        static let success = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
        
        /// Warning state - Orange with proper contrast
        static let warning = Color(red: 1.0, green: 0.584, blue: 0.0) // #FF9500
        
        /// Error state - Red with proper contrast
        static let error = Color(red: 1.0, green: 0.231, blue: 0.188) // #FF3B30
        
        /// Info state - Blue with proper contrast
        static let info = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
        
        // MARK: UI Element Colors
        
        /// Separator lines and borders
        static let separator = Color(uiColor: .separator)
        
        /// Grouped background (for lists and table views)
        static let groupedBackground = Color(uiColor: .systemGroupedBackground)
        
        /// Fill color for UI elements
        static let fill = Color(uiColor: .systemFill)
        
        // MARK: Category Colors (Consistent across app)
        
        struct Category {
            /// Coffee shops and cafés
            static let coffee = Color(red: 0.545, green: 0.353, blue: 0.169) // Brown
            
            /// Restaurants and dining
            static let restaurant = Color(red: 1.0, green: 0.584, blue: 0.0) // Orange
            
            /// Bars and nightlife
            static let bar = Color(red: 0.686, green: 0.322, blue: 0.871) // Purple
            
            /// Cultural venues and museums
            static let cultural = Color(red: 0.204, green: 0.780, blue: 0.349) // Green
            
            /// Parks and outdoor
            static let outdoor = Color(red: 0.188, green: 0.690, blue: 0.780) // Teal
            
            /// Entertainment venues
            static let entertainment = Color(red: 1.0, green: 0.176, blue: 0.333) // Pink
            
            /// Returns a linear gradient for the given category (light to dark)
            /// Compatible with both light and dark modes
            static func gradient(for category: String) -> LinearGradient {
                let color = self.color(for: category)
                return LinearGradient(
                    colors: [
                        color.opacity(0.7),
                        color
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            /// Returns the category color for a given category string
            static func color(for category: String) -> Color {
                switch category.lowercased() {
                case "coffee shop", "coffee", "café", "cafe":
                    return coffee
                case "restaurant", "food", "dining":
                    return restaurant
                case "bar", "nightlife", "pub", "lounge":
                    return bar
                case "museum", "cultural", "culture", "art", "gallery":
                    return cultural
                case "park", "outdoor", "nature":
                    return outdoor
                case "entertainment", "theater", "cinema":
                    return entertainment
                default:
                    return Color(uiColor: .systemGray)
                }
            }
            
            /// Returns SF Symbol icon name for a given category
            static func icon(for category: String) -> String {
                switch category.lowercased() {
                case "coffee shop", "coffee", "café", "cafe":
                    return "cup.and.saucer.fill"
                case "restaurant", "food", "dining":
                    return "fork.knife"
                case "bar", "nightlife", "pub", "lounge":
                    return "wineglass.fill"
                case "museum", "cultural", "culture", "art", "gallery":
                    return "building.columns.fill"
                case "park", "outdoor", "nature":
                    return "leaf.fill"
                case "entertainment", "theater", "cinema":
                    return "theatermasks.fill"
                default:
                    return "mappin.circle.fill"
                }
            }
        }
        
        // MARK: Shadow Colors (Elevation System)
        
        struct Shadows {
            /// Low elevation shadow (subtle)
            static let low = Color.black.opacity(0.05)
            
            /// Medium elevation shadow (standard cards)
            static let medium = Color.black.opacity(0.1)
            
            /// High elevation shadow (modals, overlays)
            static let high = Color.black.opacity(0.2)
        }
    }
    
    // MARK: - Typography
    
    struct Fonts {
        /// Extra large title (34pt, bold) - Hero headlines
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        
        /// Title 1 (28pt, bold) - Page titles
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        
        /// Title 2 (22pt, semibold) - Section headers
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        
        /// Title 3 (20pt, semibold) - Subsection headers
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        /// Headline (17pt, semibold) - Emphasised content
        static let headline = Font.system(size: 17, weight: .semibold)
        
        /// Body (17pt, regular) - Primary content
        static let body = Font.system(size: 17, weight: .regular)
        
        /// Callout (16pt, regular) - Secondary content
        static let callout = Font.system(size: 16, weight: .regular)
        
        /// Subheadline (15pt, regular) - Less prominent text
        static let subheadline = Font.system(size: 15, weight: .regular)
        
        /// Footnote (13pt, regular) - Supplementary info
        static let footnote = Font.system(size: 13, weight: .regular)
        
        /// Caption 1 (12pt, regular) - Small labels
        static let caption = Font.system(size: 12, weight: .regular)
        
        /// Caption 2 (11pt, regular) - Tiny labels
        static let caption2 = Font.system(size: 11, weight: .regular)
    }
    
    // MARK: - Layout
    
    struct Layout {
        // MARK: Spacing Scale
        
        /// Micro spacing (4pt) - Tight spacing between related elements
        static let microSpacing: CGFloat = 4.0
        
        /// Small spacing (8pt) - Compact layouts
        static let smallSpacing: CGFloat = 8.0
        
        /// Default spacing (12pt) - Standard element spacing
        static let spacing: CGFloat = 12.0
        
        /// Medium spacing (16pt) - Comfortable spacing
        static let padding: CGFloat = 16.0
        
        /// Large spacing (24pt) - Section separation
        static let largeSpacing: CGFloat = 24.0
        
        /// Extra large spacing (32pt) - Major sections
        static let xlSpacing: CGFloat = 32.0
        
        /// XXL spacing (48pt) - Maximum separation
        static let xxlSpacing: CGFloat = 48.0
        
        // MARK: Corner Radius
        
        /// Small corner radius (8pt) - Subtle rounding
        static let smallCornerRadius: CGFloat = 8.0
        
        /// Default corner radius (12pt) - Standard cards
        static let cornerRadius: CGFloat = 12.0
        
        /// Large corner radius (16pt) - Prominent cards
        static let largeCornerRadius: CGFloat = 16.0
        
        /// Extra large corner radius (24pt) - Hero elements
        static let xlCornerRadius: CGFloat = 24.0
        
        // MARK: Sizing
        
        /// Minimum tap target size (44pt) - iOS HIG standard
        static let minTapTarget: CGFloat = 44.0
        
        /// Icon size small (16pt)
        static let iconSmall: CGFloat = 16.0
        
        /// Icon size medium (24pt)
        static let iconMedium: CGFloat = 24.0
        
        /// Icon size large (32pt)
        static let iconLarge: CGFloat = 32.0
        
        // MARK: Aspect Ratios
        
        /// Hero card image aspect ratio (16:9) - Cinematic widescreen
        static let heroImageAspectRatio: CGFloat = 16.0 / 9.0
        
        /// Standard card image aspect ratio (4:3) - Balanced composition
        static let standardImageAspectRatio: CGFloat = 4.0 / 3.0
        
        // MARK: Border and Accent Sizes
        
        /// Category accent border width (2pt) - Subtle but visible
        static let categoryBorderWidth: CGFloat = 2.0
        
        /// Watermark icon size (80pt) - Large background accent
        static let watermarkIconSize: CGFloat = 80.0
        
        /// Watermark opacity (0.05) - Subtle background element
        static let watermarkOpacity: CGFloat = 0.05
        
        /// Category glow radius (4pt) - Soft accent halo
        static let categoryGlowRadius: CGFloat = 4.0
    }
    
    // MARK: - Animation
    
    struct Animation {
        /// Quick animation (0.2s) - Instant feedback
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        
        /// Default animation (0.3s) - Standard transitions
        static let `default` = SwiftUI.Animation.easeInOut(duration: 0.3)
        
        /// Gentle animation (0.4s) - Smooth transitions
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.4)
        
        /// Spring animation - Natural bouncy motion
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        /// Bouncy spring - Playful overshoot
        static let bouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.6)
        
        /// Snappy spring - Quick responsive feel
        static let snappy = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        
        /// Tab selection spring - Bouncy with overshoot
        static let tabSelection = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.65)
        
        /// Icon micro-interaction - Quick playful bounce
        static let iconBounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        
        /// Badge pulse - Continuous gentle pulsing
        static let badgePulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        /// Count-up animation - Smooth number transitions
        static let countUp = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.75)
        
        /// Nearby venue pulse - Gentle attention-grabbing pulse
        static let nearbyPulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        /// Glow effect - Soft pulsing glow for category accents
        static let glow = SwiftUI.Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
        
        /// Hero parallax - Subtle scroll-linked movement
        static let heroParallax = SwiftUI.Animation.linear(duration: 0.1)
    }
    
    // MARK: - Elevation (Shadow System)
    
    struct Elevation {
        /// Low elevation - Subtle depth (2pt blur)
        static func low(color: Color = Colors.Shadows.low) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color, 2, 0, 1)
        }
        
        /// Medium elevation - Standard cards (8pt blur)
        static func medium(color: Color = Colors.Shadows.medium) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color, 8, 0, 4)
        }
        
        /// High elevation - Modals and overlays (16pt blur)
        static func high(color: Color = Colors.Shadows.high) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color, 16, 0, 8)
        }
    }
}

// MARK: - View Extensions for Elevation

extension View {
    /// Applies low elevation shadow
    func elevationLow() -> some View {
        let shadow = Theme.Elevation.low()
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Applies medium elevation shadow
    func elevationMedium() -> some View {
        let shadow = Theme.Elevation.medium()
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Applies high elevation shadow
    func elevationHigh() -> some View {
        let shadow = Theme.Elevation.high()
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Applies small elevation shadow (alias for low elevation)
    func elevationSmall() -> some View {
        elevationLow()
    }
}
