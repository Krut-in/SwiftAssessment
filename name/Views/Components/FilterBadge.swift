//
//  FilterBadge.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Badge indicator showing count of active filters.
//  Displays as a red circle with white text in the top-right corner.
//
//  FEATURES:
//  - Only visible when filters are active
//  - Compact circular design
//  - High contrast (red background, white text)
//  - Positioned as overlay on filter button
//  - Smooth appearance/disappearance animation
//
//  USAGE:
//  Button("Filter") { ... }
//      .overlay(alignment: .topTrailing) {
//          FilterBadge(count: filters.activeFilterCount)
//      }
//

import SwiftUI

struct FilterBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.red)
                )
                .fixedSize()
                .frame(minWidth: 20, minHeight: 20)
                .offset(x: 10, y: -10)
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Active Filter Summary

struct ActiveFilterSummary: View {
    let summary: String?
    let onClear: () -> Void
    
    var body: some View {
        if let summary = summary {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text(summary)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onClear()
                }) {
                    Text("Clear")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.08))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FilterBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Filter Badge
            Button(action: {}) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 24))
            }
            .overlay(alignment: .topTrailing) {
                FilterBadge(count: 3)
            }
            
            // Active Filter Summary
            VStack(spacing: 12) {
                ActiveFilterSummary(
                    summary: "Coffee shops within 3 km where friends are interested",
                    onClear: {}
                )
                
                ActiveFilterSummary(
                    summary: "Restaurants sorted by distance",
                    onClear: {}
                )
                
                ActiveFilterSummary(
                    summary: nil,
                    onClear: {}
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
