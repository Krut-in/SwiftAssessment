//
//  VenueFeedView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import SwiftUI

struct VenueFeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = VenueFeedViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
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
                                VenueCardView(venue: venue)
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
