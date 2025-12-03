//
//  VenueFeedView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Main discovery feed displaying all available venues in a scrollable list.
//  Implements pull-to-refresh, error handling, and empty state patterns.
//  
//  KEY FEATURES:
//  - Lazy loading with LazyVStack for performance
//  - Pull-to-refresh gesture support
//  - Comprehensive error states with retry functionality
//  - Empty state messaging for better UX
//  - Loading indicators during data fetch
//  - Navigation to venue detail views
//  - Uses centralized Theme for consistent styling
//  
//  STATE MANAGEMENT:
//  - Uses VenueFeedViewModel for data and loading states
//  - Automatically loads venues on view appear (.task modifier)
//  - Error messages displayed in alerts when venues already loaded
//  
//  UX PATTERNS:
//  - Shows full-screen loading only on initial load
//  - Inline errors after first load to preserve list
//  - Clear error messages with retry actions
//  - Smooth transitions between loading/error/content states
//
//

import SwiftUI

struct VenueFeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = VenueFeedViewModel(appState: .shared)
    @ObservedObject private var appState = AppState.shared
    @AppStorage("venueViewMode") private var viewMode: ViewMode = .list
    @State private var selectedVenueId: String?
    
    enum ViewMode: String {
        case list, map
    }
    
    // MARK: - Computed Properties
    
    /// Filters venues by selected category
    private var filteredVenues: [VenueListItem] {
        var filtered = viewModel.venues
        
        // Apply category filter if selected
        if let selectedCategory = viewModel.selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.venues.isEmpty {
                    // Show loading indicator when initially loading
                    loadingView
                } else if shouldShowError {
                    // Show error message if no venues and error exists
                    errorView
                } else if viewModel.venues.isEmpty && !viewModel.filters.isDefault {
                    // Show filtered empty state
                    filteredEmptyState
                } else if viewModel.venues.isEmpty {
                    // Show empty state
                    emptyStateView
                } else if viewMode == .map {
                    // Show map view
                    mapView
                } else {
                    // Show venue list
                    venueListView
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Map/List Toggle
                    Button(action: {
                        withAnimation(Theme.Animation.spring) {
                            viewMode = viewMode == .list ? .map : .list
                        }
                    }) {
                        Image(systemName: viewMode == .list ? "map" : "list.bullet")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.Colors.primary)
                            .overlay(alignment: .topTrailing) {
                                FilterBadge(count: viewModel.activeFilterCount)
                            }
                    }
                }
            }
            .task {
                await viewModel.loadAll()
            }
            .alert("Error", isPresented: errorAlertBinding) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheet(filters: $viewModel.filters) {
                    Task {
                        await viewModel.applyFilters()
                    }
                }
            }
            .navigationDestination(item: $selectedVenueId) { venueId in
                VenueDetailView(venueId: venueId)
            }
        }
    }
    
    // MARK: - Computed Properties for Conditional Views
    
    private var shouldShowError: Bool {
        viewModel.errorMessage != nil && viewModel.venues.isEmpty
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && !viewModel.venues.isEmpty },
            set: { _ in }
        )
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        ScrollView {
            SkeletonLoadingView(count: 4)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: Theme.Layout.spacing) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.warning)
            
            Text("Error Loading Venues")
                .font(Theme.Fonts.headline)
            
            Text(viewModel.errorMessage ?? "Unknown error")
                .font(Theme.Fonts.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.loadVenues()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.primary)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "map",
            title: "No Venues Found",
            message: "Check back later for new venues"
        )
    }
    
    private var filteredEmptyState: some View {
        EmptyStateView.filteredResults {
            Task {
                await viewModel.clearFilters()
            }
        }
    }
    
    private var venueListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.spacing) {
                // Sort Menu and Active Filter Summary
                VStack(spacing: Theme.Layout.spacing) {

                    
                    // Active Filter Summary (if filters applied)
                    if let summary = viewModel.activeSummary {
                        ActiveFilterSummary(summary: summary) {
                            Task {
                                await viewModel.clearFilters()
                            }
                        }
                    }
                }
                
                // All Venues Section
                if !viewModel.venues.isEmpty {
                    allVenuesSection
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            // Haptic feedback on refresh start
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            await viewModel.refresh()
        }
    }
    
    private var mapView: some View {
        MapFeedView(venues: filteredVenues) { venueId in
            selectedVenueId = venueId
        }
        .id(filteredVenues.map { $0.id }) // Force recreation when venue list changes
    }
    
    private var allVenuesSection: some View {
        Group {
            // Section header with filter
            if !viewModel.venues.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                    HStack {
                        Text("All Venues")
                            .font(Theme.Fonts.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        SortMenu(selectedSort: $viewModel.filters.sortBy) {
                            Task {
                                await viewModel.applyFilters()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Category Filter Bar
                    if !viewModel.availableCategories.isEmpty {
                        CategoryFilterView(
                            categories: viewModel.availableCategories,
                            categoryCounts: viewModel.categoryCounts,
                            selectedCategory: $viewModel.selectedCategory
                        )
                    }
                }
            }
            
            // Check if filtered venues is empty
            if filteredVenues.isEmpty {
                // Show empty state for filtered results
                if viewModel.selectedCategory != nil {
                    EmptyStateView(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "No \(viewModel.selectedCategory ?? "") Venues",
                        message: "Try another filter to discover more venues"
                    )
                    .padding(.top, 40)
                }
            } else {
                // Show filtered venues
                ForEach(filteredVenues) { venue in
                    NavigationLink(destination: VenueDetailView(venueId: venue.id)) {
                        VenueCardView(
                            venue: venue,
                            onInterestToggled: {
                                // No action needed - AppState handles it
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VenueFeedView()
}
