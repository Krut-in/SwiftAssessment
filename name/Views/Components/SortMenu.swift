//
//  SortMenu.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Dropdown menu component for venue sorting.
//  Displays current sort option with icon and allows quick sorting changes.
//
//  FEATURES:
//  - Native iOS Menu component
//  - Icon indicators for each sort option
//  - Checkmark on selected option
//  - Haptic feedback on selection
//  - Compact design suitable for toolbar
//
//  SORT OPTIONS:
//  - Distance (requires user location)
//  - Popularity (interested count)
//  - Friends Interested (requires user)
//  - Recently Added (newest first)
//  - Name (A-Z alphabetical)
//
//  USAGE:
//  SortMenu(selectedSort: $filters.sortBy) {
//      applySort()
//  }
//

import SwiftUI

struct SortMenu: View {
    @Binding var selectedSort: SortOption
    let onChange: () -> Void
    
    var body: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selectedSort = option
                    onChange()
                }) {
                    Label(
                        option.displayName,
                        systemImage: option == selectedSort ? "checkmark" : option.icon
                    )
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedSort.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Sort: \(selectedSort.displayName)")
                    .font(.system(size: 15, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct SortMenu_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SortMenu(selectedSort: .constant(.popularity)) {}
            SortMenu(selectedSort: .constant(.distance)) {}
            SortMenu(selectedSort: .constant(.friends)) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
