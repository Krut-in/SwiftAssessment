//
//  FilterComponents.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Reusable UI components for filter sheet functionality.
//  Provides consistent styling and interaction patterns.
//
//  COMPONENTS:
//  - FilterCheckboxRow: Multi-select checkbox row
//  - FilterRadioRow: Single-select radio button row
//  - FilterSectionHeader: Consistent section headers
//
//  DESIGN:
//  - SF Pro font family for iOS consistency
//  - Haptic feedback on selection
//  - Smooth animations
//  - Accessible design with proper labels
//

import SwiftUI

// MARK: - Filter Section Header

struct FilterSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}

// MARK: - Filter Checkbox Row (Multi-select)

struct FilterCheckboxRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                
                // Label
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Radio Row (Single-select)

struct FilterRadioRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Label
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FilterComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            FilterSectionHeader(title: "Categories")
            
            FilterCheckboxRow(title: "Coffee Shop", isSelected: true) {}
            FilterCheckboxRow(title: "Restaurant", isSelected: false) {}
            
            FilterSectionHeader(title: "Distance")
            
            FilterRadioRow(title: "Any Distance", isSelected: false) {}
            FilterRadioRow(title: "Within 3 km", isSelected: true) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
