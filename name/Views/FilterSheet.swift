//
//  FilterSheet.swift
//  name
//
//  Created by Krutin Rathod on 23/11/25.
//
//  DESCRIPTION:
//  Modal sheet for comprehensive venue filtering.
//  Allows users to filter by category, distance, friend interest, and personal interest.
//
//  FEATURES:
//  - Multi-select category filtering
//  - Single-select distance ranges
//  - Friend interest levels
//  - Personal interest status
//  - Clear all filters button
//  - Apply filters with count indicator
//
//  UI DESIGN:
//  - Half-height sheet with medium detent
//  - Scrollable content for smaller devices
//  - Sticky footer with action buttons
//  - Smooth animations and haptic feedback
//  - iOS-native styling with SF Pro fonts
//
//  USAGE:
//  .sheet(isPresented: $showFilterSheet) {
//      FilterSheet(filters: $filters, onApply: { applyFilters() })
//  }
//

import SwiftUI

struct FilterSheet: View {
    @Binding var filters: VenueFilters
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var localFilters: VenueFilters
    
    init(filters: Binding<VenueFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._localFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Category Filter Section
                        FilterSectionHeader(title: "Categories")
                        
                        VStack(spacing: 4) {
                            ForEach(VenueFilters.availableCategories, id: \.self) { category in
                                FilterCheckboxRow(
                                    title: category,
                                    isSelected: localFilters.selectedCategories.contains(category)
                                ) {
                                    toggleCategory(category)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Distance Filter Section
                        FilterSectionHeader(title: "Distance")
                        
                        VStack(spacing: 4) {
                            ForEach(DistanceOption.allCases, id: \.id) { option in
                                FilterRadioRow(
                                    title: option.displayName,
                                    isSelected: localFilters.distanceFilter == option
                                ) {
                                    localFilters.distanceFilter = option
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Friend Interest Filter Section
                        FilterSectionHeader(title: "Friend Interest")
                        
                        VStack(spacing: 4) {
                            ForEach(FriendInterestOption.allCases) { option in
                                FilterRadioRow(
                                    title: option.displayName,
                                    isSelected: localFilters.friendInterestFilter == option
                                ) {
                                    localFilters.friendInterestFilter = option
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Personal Interest Filter Section
                        FilterSectionHeader(title: "Your Interest")
                        
                        VStack(spacing: 4) {
                            ForEach(PersonalInterestOption.allCases) { option in
                                FilterRadioRow(
                                    title: option.displayName,
                                    isSelected: localFilters.personalInterestFilter == option
                                ) {
                                    localFilters.personalInterestFilter = option
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Bottom padding for footer
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, 8)
                }
                
                // Footer with action buttons
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // Clear All Button (Enhanced with count and disabled state)
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            localFilters.reset()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Clear All")
                                    .font(.system(size: 16, weight: .medium))
                                if localFilters.activeFilterCount > 0 {
                                    Text("(\(localFilters.activeFilterCount))")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(localFilters.activeFilterCount > 0 ? .red : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(localFilters.activeFilterCount > 0 ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .disabled(localFilters.activeFilterCount == 0)
                        .opacity(localFilters.activeFilterCount == 0 ? 0.5 : 1.0)
                        
                        // Apply Filters Button
                        Button(action: {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            filters = localFilters
                            onApply()
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Text("Apply Filters")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                if localFilters.activeFilterCount > 0 {
                                    Text("(\(localFilters.activeFilterCount))")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Helper Methods
    
    private func toggleCategory(_ category: String) {
        if category == "All" {
            // If "All" is selected, clear other selections
            localFilters.selectedCategories = ["All"]
        } else {
            // Remove "All" if other category is selected
            localFilters.selectedCategories.remove("All")
            
            // Toggle the category
            if localFilters.selectedCategories.contains(category) {
                localFilters.selectedCategories.remove(category)
                
                // If no categories selected, default to "All"
                if localFilters.selectedCategories.isEmpty {
                    localFilters.selectedCategories = ["All"]
                }
            } else {
                localFilters.selectedCategories.insert(category)
            }
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FilterSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("Tap to show filters")
            .sheet(isPresented: .constant(true)) {
                FilterSheet(
                    filters: .constant(VenueFilters()),
                    onApply: {}
                )
            }
    }
}
#endif
