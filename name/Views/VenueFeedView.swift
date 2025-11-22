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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.venues.isEmpty {
                    // Show loading indicator when initially loading
                    ProgressView("Loading venues...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = viewModel.errorMessage, viewModel.venues.isEmpty {
                    // Show error message if no venues and error exists
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Venues")
                            .font(.headline)
                        
                        Text(errorMessage)
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
                } else if viewModel.venues.isEmpty {
                    // Show empty state
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
                } else {
                    // Show venue list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.venues) { venue in
                                NavigationLink(destination: VenueDetailView(venueId: venue.id)) {
                                    VenueCardView(venue: venue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadVenues()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.venues.isEmpty)) {
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
}

// MARK: - Preview

#Preview {
    VenueFeedView()
}
