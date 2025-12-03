//
//  CustomTabBarView.swift
//  name
//
//  Created by AI Assistant on 03/12/25.
//
//  DESCRIPTION:
//  Custom floating tab bar with frosted glass design and pill animations.
//  Replaces standard iOS TabView with a premium, animated navigation experience.
//  
//  FEATURES:
//  - Frosted glass background with .ultraThinMaterial
//  - Rounded capsule shape (24pt corner radius)
//  - Solid primary color pill for active tab
//  - 40% opacity for inactive tabs
//  - Spring animation with overshoot on selection
//  - Dynamic badges for Social and Profile tabs
//  
//  DESIGN SPECS:
//  - 8pt vertical padding from bottom safe area
//  - 16pt horizontal margins
//  - 60pt height for tab bar
//  - Bold, minimal, cool aesthetic
//

import SwiftUI

struct CustomTabBarView: View {
    
    // MARK: - Properties
    
    @Binding var selectedTab: Int
    let socialBadgeCount: Int
    let profileBadgeCount: Int
    
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Tab Items
    
    private let tabs: [(icon: String, label: String, index: Int)] = [
        ("house.fill", "Discover", 0),
        ("star.fill", "For You", 1),
        ("person.2.fill", "Social", 2),
        ("person.fill", "Profile", 3)
    ]
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.index) { tab in
                tabButton(
                    icon: tab.icon,
                    label: tab.label,
                    index: tab.index,
                    badgeCount: badgeCount(for: tab.index)
                )
            }
        }
        .frame(height: 70)
        .padding(.horizontal, 20)
        .background(
            ZStack {
                // Liquid glass layers - dark mode adaptive
                RoundedRectangle(cornerRadius: 35)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ] : [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 35)
                            .fill(.ultraThinMaterial)
                    )
                
                // Vibrant border - dark mode adaptive
                RoundedRectangle(cornerRadius: 35)
                    .strokeBorder(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ] : [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // Inner glow
                RoundedRectangle(cornerRadius: 35)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary.opacity(colorScheme == .dark ? 0.4 : 0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                    .blur(radius: 2)
            }
            .shadow(color: Theme.Colors.primary.opacity(0.15), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    handleSwipe(value: value)
                }
        )
    }
    
    // MARK: - Swipe Handler
    
    private func handleSwipe(value: DragGesture.Value) {
        let horizontalSwipe = value.translation.width
        
        // Swipe left = next tab
        if horizontalSwipe < -30 && selectedTab < tabs.count - 1 {
            withAnimation(Theme.Animation.tabSelection) {
                selectedTab += 1
            }
        }
        // Swipe right = previous tab
        else if horizontalSwipe > 30 && selectedTab > 0 {
            withAnimation(Theme.Animation.tabSelection) {
                selectedTab -= 1
            }
        }
    }
    
    // MARK: - Tab Button
    
    @ViewBuilder
    private func tabButton(icon: String, label: String, index: Int, badgeCount: Int) -> some View {
        Button {
            withAnimation(Theme.Animation.tabSelection) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Icon glow for selected state
                    if selectedTab == index {
                        AnimatedTabIcon(
                            type: tabType(for: index),
                            isSelected: true
                        )
                        .blur(radius: 8)
                        .opacity(0.6)
                    }
                    
                    // Animated Tab Icon
                    AnimatedTabIcon(
                        type: tabType(for: index),
                        isSelected: selectedTab == index
                    )
                    
                    // Badge overlay
                    if badgeCount > 0 {
                        DynamicBadgeView(count: badgeCount)
                            .offset(x: 14, y: -14)
                    }
                }
                .frame(width: 32, height: 32)
                
                // Label - BOLD and PROMINENT
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTab == index ? .white : Theme.Colors.textSecondary)
                    .shadow(
                        color: selectedTab == index ? Color.black.opacity(0.3) : .clear,
                        radius: 1,
                        x: 0,
                        y: 1
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedTab == index {
                        // Glassmorphic bubble indicator with padding
                        ZStack {
                            // Base glass layer
                            RoundedRectangle(cornerRadius: 35)
                                .fill(.ultraThinMaterial)
                            
                            // White gradient overlay for glass effect - dark mode adaptive
                            RoundedRectangle(cornerRadius: 35)
                                .fill(
                                    LinearGradient(
                                        colors: colorScheme == .dark ? [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.03)
                                        ] : [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Subtle border for definition - dark mode adaptive
                            RoundedRectangle(cornerRadius: 35)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: colorScheme == .dark ? [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ] : [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .padding(.vertical, 4)
                        .matchedGeometryEffect(id: "TAB_INDICATOR", in: animation)
                        .shadow(color: Color.white.opacity(colorScheme == .dark ? 0.15 : 0.2), radius: 8, x: 0, y: 2)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func badgeCount(for index: Int) -> Int {
        switch index {
        case 2: return socialBadgeCount
        case 3: return profileBadgeCount
        default: return 0
        }
    }
    
    private func tabType(for index: Int) -> AnimatedTabIcon.TabIconType {
        switch index {
        case 0: return .discover
        case 1: return .forYou
        case 2: return .social
        case 3: return .profile
        default: return .discover
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedTab = 0
    
    return ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            CustomTabBarView(
                selectedTab: $selectedTab,
                socialBadgeCount: 3,
                profileBadgeCount: 7
            )
        }
    }
}
