//
//  VenueDetailView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import SwiftUI

struct VenueDetailView: View {
    
    // MARK: - Properties
    
    let venueId: String
    @StateObject private var viewModel: VenueDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(venueId: String) {
        self.venueId = venueId
        _viewModel = StateObject(wrappedValue: VenueDetailViewModel(venueId: venueId))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let venue = viewModel.venue {
                    // Hero Image
                    AsyncImage(url: URL(string: venue.image)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                        default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        // Venue Name
                        Text(venue.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Category and Address
                        VStack(alignment: .leading, spacing: 8) {
                            Text(venue.category)
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle")
                                    .font(.caption)
                                Text(venue.address)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // Interested Count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(viewModel.interestedUsers.count) people interested")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                        
                        // Interest Button (placeholder for Phase 3)
                        Button {
                            // Action will be implemented in Phase 3
                        } label: {
                            Text("I'm Interested")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(venue.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                        
                        // Interested Users Section
                        if !viewModel.interestedUsers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("People Who Want to Go")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.interestedUsers) { user in
                                            VStack(spacing: 8) {
                                                AsyncImage(url: URL(string: user.avatar)) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 60, height: 60)
                                                            .clipShape(Circle())
                                                    default:
                                                        Circle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .frame(width: 60, height: 60)
                                                            .overlay {
                                                                Image(systemName: "person.fill")
                                                                    .foregroundColor(.gray)
                                                            }
                                                    }
                                                }
                                                
                                                Text(user.name)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 70)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                } else if viewModel.isLoading {
                    // Loading State
                    ProgressView("Loading venue details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Venue")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.loadVenueDetail()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadVenueDetail()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        VenueDetailView(venueId: "venue_1")
    }
}
