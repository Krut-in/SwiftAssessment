//
//  CategoryFilterView.swift
//  name
//
//  Created by Krutin Rathod on 22/11/25.
//
//  DESCRIPTION:
//  Horizontal scrollable category filter bar for venue filtering.
//  Minimal design with icons and simple selection highlighting.
//  
//  KEY FEATURES:
//  - SF Symbol category icons
//  - Clean selected state with solid background
//  - Optional count display
//  - Smooth selection animation
//  - Full dark/light mode compatibility
//  
//  STATE MANAGEMENT:
//  - selectedCategory: Currently selected category (nil = "All")
//  
//  USAGE:
//  CategoryFilterView(
//      categories: ["Coffee Shop", "Restaurant", "Bar"],
//      categoryCounts: ["Coffee Shop": 3, "Restaurant": 5, "Bar": 2],
//      selectedCategory: $selectedCategory
//  )
//

import SwiftUI

struct CategoryFilterView: View {
    
    // MARK: - Properties
    
    let categories: [String]
    let categoryCounts: [String: Int]
    @Binding var selectedCategory: String?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" filter chip
                FilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    count: nil,
                    color: Theme.Colors.primary,
                    isSelected: selectedCategory == nil,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = nil
                        }
                    }
                )
                
                // Category filter chips
                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        title: category,
                        icon: Theme.Colors.Category.icon(for: category),
                        count: categoryCounts[category],
                        color: Theme.Colors.Category.color(for: category),
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    
    let title: String
    let icon: String
    let count: Int?
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Category Icon
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                
                // Title - always show
                Text(title)
                    .font(Theme.Fonts.subheadline)
                    .fontWeight(.medium)
                
                // Count (if available)
                if let count = count, count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : color.opacity(0.7))
                }
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CategoryFilterView(
            categories: ["Coffee Shop", "Restaurant", "Bar", "Cultural"],
            categoryCounts: ["Coffee Shop": 3, "Restaurant": 5, "Bar": 2, "Cultural": 1],
            selectedCategory: .constant(nil)
        )
        
        CategoryFilterView(
            categories: ["Coffee Shop", "Restaurant", "Bar", "Cultural"],
            categoryCounts: ["Coffee Shop": 3, "Restaurant": 5, "Bar": 2, "Cultural": 1],
            selectedCategory: .constant("Coffee Shop")
        )
    }
    .padding()
}
