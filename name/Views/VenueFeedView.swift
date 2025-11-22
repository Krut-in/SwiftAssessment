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

import SwiftUI

struct VenueFeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = VenueFeedViewModel()
    @ObservedObject private var appState = AppState.shared
    
    // MARK: - Computed Properties
    
    /// Filters out venues that are already shown in recommendations
    private var filteredVenues: [VenueListItem] {
        let recommendedVenueIds = Set(viewModel.recommendations.map { $0.venue.id })
        return viewModel.venues.filter { !recommendedVenueIds.contains($0.id) }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.venues.isEmpty {
                    // Show loading indicator when initially loading
                    loadingView
                } else if shouldShowError {
                    // Show error message if no venues and error exists
                    errorView
                } else if viewModel.venues.isEmpty {
                    // Show empty state
                    emptyStateView
                } else {
                    // Show venue list
                    venueListView
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
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
            .alert("🎉 Booking Created!", isPresented: $appState.showBookingAlert) {
                Button("Awesome!") {
                    appState.clearBookingAlert()
                }
            } message: {
                if let message = appState.bookingAgentMessage {
                    Text(message)
                }
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
        ProgressView("Loading venues...")
            .progressViewStyle(CircularProgressViewStyle())
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error Loading Venues")
                .font(.headline)
            
            Text(viewModel.errorMessage ?? "Unknown error")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.loadVenues()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Venues Found")
                .font(.headline)
            
            Text("Check back later for new venues")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var venueListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Recommended for You Section
                if !viewModel.recommendations.isEmpty {
                    recommendationsSection
                }
                
                // All Venues Section
                if !viewModel.venues.isEmpty {
                    allVenuesSection
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.green)
                Text("Recommended for You")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Recommended Venues
            ForEach(viewModel.recommendations) { recommendation in
                NavigationLink(destination: VenueDetailView(venueId: recommendation.venue.id)) {
                    RecommendedVenueCardView(
                        recommendation: recommendation,
                        onInterestToggled: {
                            Task {
                                // Refresh recommendations after interest toggle
                                await viewModel.loadRecommendations()
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
            
            // Divider
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    private var allVenuesSection: some View {
        Group {
            // Section header (only show if recommendations exist)
            if !viewModel.recommendations.isEmpty {
                HStack {
                    Text("All Venues")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Filter out venues already shown in recommendations
            ForEach(filteredVenues) { venue in
                NavigationLink(destination: VenueDetailView(venueId: venue.id)) {
                    VenueCardView(
                        venue: venue,
                        onInterestToggled: {
                            Task {
                                // Refresh after interest toggle
                                await viewModel.loadRecommendations()
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VenueFeedView()
}
