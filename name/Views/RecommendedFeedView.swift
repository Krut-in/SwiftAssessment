//
//  RecommendedFeedView.swift
//  name
//
//  Created by Krutin Rathod on 24/11/25.
//
//  DESCRIPTION:
//  Personalized recommendations feed displaying venues tailored to the user's interests.
//  Implements pull-to-refresh, error handling, empty state patterns, sorting, and filtering.
//  
//  KEY FEATURES:
//  - Lazy loading with LazyVStack for performance
//  - Pull-to-refresh gesture support
//  - Comprehensive error states with retry functionality
//  - Empty state messaging for better UX
//  - Loading indicators during data fetch
//  - Navigation to venue detail views
//  - Category filtering (All, Bar, Coffee Shop, Restaurant, Nightclub, Activity)
//  - Multiple sort options (Distance, Popularity, Friends Interested, Name)
//  - Uses centralized Theme for consistent styling
//  - Shows ALL recommendations (no artificial limit)
//  
//  STATE MANAGEMENT:
//  - Uses RecommendedFeedViewModel for data and loading states
//  - Automatically loads recommendations on view appear (.task modifier)
//  - Error messages displayed in alerts when recommendations already loaded
//  
//  UX PATTERNS:
//  - Shows full-screen loading only on initial load
//  - Inline errors after first load to preserve list
//  - Clear error messages with retry actions
//  - Smooth transitions between loading/error/content states
//

import SwiftUI

struct RecommendedFeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = RecommendedFeedViewModel()
    @ObservedObject private var appState = AppState.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.recommendations.isEmpty {
                    // Show loading indicator when initially loading
                    loadingView
                } else if shouldShowError {
                    // Show error message if no recommendations and error exists
                    errorView
                } else if viewModel.recommendations.isEmpty {
                    // Show empty state
                    emptyStateView
                } else {
                    // Show recommendation list
                    recommendationListView
                }
            }
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadRecommendations()
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
        }
    }
    
    // MARK: - Computed Properties for Conditional Views
    
    private var shouldShowError: Bool {
        viewModel.errorMessage != nil && viewModel.recommendations.isEmpty
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && !viewModel.recommendations.isEmpty },
            set: { _ in }
        )
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: Theme.Layout.spacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                .scaleEffect(1.5)
            Text("Loading recommendations...")
                .font(Theme.Fonts.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: Theme.Layout.spacing) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.warning)
            
            Text("Error Loading Recommendations")
                .font(Theme.Fonts.headline)
            
            Text(viewModel.errorMessage ?? "Unknown error")
                .font(Theme.Fonts.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.loadRecommendations()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.primary)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "star.slash",
            title: "No Recommendations",
            message: "We'll recommend venues based on your interests",
            actionTitle: "Explore All Venues",
            action: {
                // Navigate to Discover tab
                appState.selectedTab = 0
            }
        )
    }
    
    private var recommendationListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.spacing) {
                // Header Section with Sort Menu
                HStack {
                    Text("For You")
                        .font(Theme.Fonts.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    SortMenu(selectedSort: $viewModel.sortBy) {
                        viewModel.applySort()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Category Filter Bar
                if !viewModel.availableCategories.isEmpty {
                    CategoryFilterView(
                        categories: viewModel.availableCategories,
                        categoryCounts: viewModel.categoryCounts,
                        selectedCategory: $viewModel.selectedCategory
                    )
                }
                
                // Check if filtered recommendations is empty
                if viewModel.filteredRecommendations.isEmpty {
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
                    // Show filtered recommendations
                    ForEach(viewModel.filteredRecommendations) { recommendation in
                        NavigationLink(destination: VenueDetailView(venueId: recommendation.venue.id)) {
                            RecommendedVenueCardView(
                                recommendation: recommendation,
                                onInterestToggled: {
                                    // No need to reload recommendations here
                                    // AppState will handle the update
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
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
}

// MARK: - Preview

#Preview {
    RecommendedFeedView()
}
