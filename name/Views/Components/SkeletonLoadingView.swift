//
//  SkeletonLoadingView.swift
//  name
//
//  Created by Krutin Rathod on 25/11/25.
//
//  DESCRIPTION:
//  Reusable skeleton loading component for venue cards and lists.
//  Provides elegant shimmer animation during data loading states.
//  
//  KEY FEATURES:
//  - Shimmer animation effect (gradient moving left to right)
//  - Matches VenueCardView layout structure
//  - Configurable number of skeleton cards
//  - Smooth transition to actual content
//  - Uses Theme system for consistent styling
//  
//  USAGE:
//  if viewModel.isLoading {
//      SkeletonLoadingView(count: 3)
//  } else {
//      // Actual content
//  }
//

import SwiftUI

struct SkeletonLoadingView: View {
    
    // MARK: - Properties
    
    /// Number of skeleton cards to display
    var count: Int = 3
    
    /// Animation state for shimmer effect
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Theme.Layout.spacing) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonVenueCard()
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Skeleton Venue Card

struct SkeletonVenueCard: View {
    
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image skeleton
            shimmerRectangle()
                .frame(height: 200)
                .aspectRatio(4/3, contentMode: .fill)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                HStack {
                    // Category badge skeleton
                    shimmerRectangle()
                        .frame(width: 100, height: 24)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                .padding(.top, Theme.Layout.spacing)
                
                // Title skeleton
                shimmerRectangle()
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
                
                shimmerRectangle()
                    .frame(height: 24)
                    .frame(maxWidth: 200)
                
                // Interested count skeleton
                HStack(spacing: 4) {
                    shimmerRectangle()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    
                    shimmerRectangle()
                        .frame(width: 120, height: 16)
                }
                .padding(.bottom, Theme.Layout.spacing)
            }
            .padding(.horizontal, Theme.Layout.padding)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .elevationMedium()
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
    
    /// Creates a shimmering rectangle with gradient animation
    @ViewBuilder
    private func shimmerRectangle() -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Theme.Colors.secondaryBackground)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Theme.Colors.background.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * geometry.size.width * 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
        }
    }
}

// MARK: - Skeleton Recommendation Card

struct SkeletonRecommendationCard: View {
    
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image skeleton
            shimmerRectangle()
                .frame(height: 200)
                .aspectRatio(4/3, contentMode: .fill)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                HStack {
                    // Category badge skeleton
                    shimmerRectangle()
                        .frame(width: 100, height: 24)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Score badge skeleton
                    shimmerRectangle()
                        .frame(width: 60, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, Theme.Layout.spacing)
                
                // Title skeleton
                shimmerRectangle()
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
                
                shimmerRectangle()
                    .frame(height: 24)
                    .frame(maxWidth: 200)
                
                // Distance skeleton
                HStack(spacing: 4) {
                    shimmerRectangle()
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                    
                    shimmerRectangle()
                        .frame(width: 80, height: 16)
                }
                .padding(.bottom, Theme.Layout.spacing)
            }
            .padding(.horizontal, Theme.Layout.padding)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .elevationMedium()
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
    
    /// Creates a shimmering rectangle with gradient animation
    @ViewBuilder
    private func shimmerRectangle() -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Theme.Colors.secondaryBackground)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Theme.Colors.background.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * geometry.size.width * 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
        }
    }
}

// MARK: - Skeleton Activity Card

struct SkeletonActivityCard: View {
    
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        HStack(spacing: Theme.Layout.padding) {
            // Avatar skeleton
            shimmerRectangle()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                // Name and action line
                shimmerRectangle()
                    .frame(height: 18)
                    .frame(maxWidth: .infinity)
                
                // Venue name line
                shimmerRectangle()
                    .frame(height: 18)
                    .frame(maxWidth: 220)
                
                // Timestamp line
                shimmerRectangle()
                    .frame(height: 14)
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, Theme.Layout.padding)
        .padding(.vertical, Theme.Layout.spacing)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Layout.cornerRadius)
        .elevationMedium()
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
    
    /// Creates a shimmering rectangle with gradient animation
    @ViewBuilder
    private func shimmerRectangle() -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Theme.Colors.secondaryBackground)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Theme.Colors.background.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * geometry.size.width * 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.smallCornerRadius))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SkeletonLoadingView(count: 2)
        
        Spacer()
    }
    .background(Theme.Colors.background)
}
