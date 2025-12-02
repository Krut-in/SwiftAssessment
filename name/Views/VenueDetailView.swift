//
//  VenueDetailView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Detailed view for a single venue showing full information and interested users.
//  Implements custom navigation with overlay back button and interest toggling.
//  
//  KEY FEATURES:
//  - Hero image with overlay back button (custom navigation)
//  - Interest button with loading states and animations
//  - List of interested users with avatars
//  - Category-based color coding for visual hierarchy
//  - Success/error message handling
//  - Automatic booking agent alert propagation
//  - Uses centralized Theme for consistent styling
//  
//  DESIGN PATTERNS:
//  - Custom back button (navigationBarBackButtonHidden)
//  - AsyncImage for lazy image loading
//  - Optimistic UI updates via AppState
//  - Observable state synchronization with ViewModel
//  
//  STATE MANAGEMENT:
//  - VenueDetailViewModel manages venue data and loading
//  - AppState handles interest toggle and alert state
//  - Interest state synced via Combine observers
//  
//  UX CONSIDERATIONS:
//  - Disabled button during interest toggle prevents double-taps
//  - Success messages auto-dismiss after 2 seconds
//  - Booking agent messages shown in global alert (ContentView)
//  - Reload venue detail after interest toggle to update count
//  - Consistent error and loading states
//
//

import SwiftUI
import MapKit

struct VenueDetailView: View {
    
    // MARK: - Properties
    
    let venueId: String
    @StateObject private var viewModel: VenueDetailViewModel
    @ObservedObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isButtonPressed = false
    
    // MARK: - Initialization
    
    init(venueId: String) {
        self.venueId = venueId
        _viewModel = StateObject(wrappedValue: VenueDetailViewModel(venueId: venueId, appState: .shared))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let venue = viewModel.venue {
                    // Multi-Image Gallery with overlay back button
                    ZStack(alignment: .topLeading) {
                        // TabView image carousel
                        TabView {
                            ForEach(venue.allImages, id: \.self) { imageUrl in
                                CachedAsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 400)
                                        .clipped()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Theme.Colors.secondaryBackground)
                                        .frame(height: 400)
                                        .overlay {
                                            ProgressView()
                                        }
                                } failure: {
                                    Rectangle()
                                        .fill(categoryColor(for: venue.category).opacity(0.2))
                                        .frame(height: 400)
                                        .overlay {
                                            VStack(spacing: 12) {
                                                Image(systemName: categoryIcon(for: venue.category))
                                                    .font(.system(size: 60))
                                                    .foregroundColor(categoryColor(for: venue.category))
                                                Text("Image unavailable")
                                                    .font(Theme.Fonts.subheadline)
                                                    .foregroundColor(Theme.Colors.textSecondary)
                                            }
                                        }
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 400)
                        
                        // Button overlay container
                        HStack {
                            // Back button
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.Colors.cardBackground)
                                    .clipShape(Circle())
                                    .elevationLow()
                            }
                            
                            Spacer()
                            
                            // Share button with deep link
                            ShareLink(
                                item: URL(string: "luna://venues/\(venue.id)")!,
                                subject: Text(venue.name),
                                message: Text("Check out \(venue.name) on Luna! 🎉")
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.Colors.cardBackground)
                                    .clipShape(Circle())
                                    .elevationLow()
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            })
                        }
                        .padding([.leading, .trailing, .top], Theme.Layout.padding)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                        // Venue Name
                        Text(venue.name)
                            .font(Theme.Fonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        // Category Badge and Address
                        HStack(spacing: Theme.Layout.spacing) {
                            Text(venue.category)
                                .font(Theme.Fonts.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(categoryColor(for: venue.category))
                                .clipShape(Capsule())
                            
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle")
                                    .font(Theme.Fonts.caption)
                                Text(venue.address)
                                    .font(Theme.Fonts.subheadline)
                            }
                            .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        // Distance Badge
                        if let distance = venue.distance_km {
                            HStack(spacing: Theme.Layout.smallSpacing) {
                                DistanceBadge(distance_km: distance)
                                
                                // Get Directions Button
                                if let latitude = venue.latitude, let longitude = venue.longitude {
                                    Button {
                                        openInMaps(latitude: latitude, longitude: longitude, name: venue.name)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                                .font(.system(size: 12, weight: .medium))
                                            Text("Get Directions")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(Theme.Colors.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Theme.Colors.primary.opacity(0.15))
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Interested Count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(viewModel.interestedUsers.count) people interested")
                                .font(Theme.Fonts.subheadline)
                        }
                        .foregroundColor(Theme.Colors.textSecondary)
                        
                        // Interest Button
                        Button {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Animation
                            withAnimation(Theme.Animation.spring) {
                                isButtonPressed = true
                            }
                            
                            Task {
                                await viewModel.toggleInterest()
                                
                                // Reset animation state
                                await MainActor.run {
                                    withAnimation(Theme.Animation.spring) {
                                        isButtonPressed = false
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isTogglingInterest {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: viewModel.isInterested ? "heart.fill" : "heart")
                                    Text(viewModel.isInterested ? "Interested" : "I'm Interested")
                                }
                            }
                            .font(Theme.Fonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.isInterested ? Theme.Colors.error : Theme.Colors.primary)
                            .cornerRadius(Theme.Layout.cornerRadius)
                        }
                        .scaleEffect(isButtonPressed ? 0.95 : 1.0)
                        .disabled(viewModel.isTogglingInterest)
                        .padding(.vertical, 8)
                        
                        // People Who Want to Go Section
                        if !viewModel.interestedUsers.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                                Text("People Who Want to Go")
                                    .font(Theme.Fonts.title3)
                                    .fontWeight(.bold)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Layout.spacing) {
                                        ForEach(viewModel.interestedUsers) { user in
                                            VStack(spacing: 8) {
                                                CachedAsyncImage(url: user.avatar) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Theme.Colors.secondaryBackground)
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(Theme.Colors.textSecondary)
                                        }
                                } failure: {
                                    Circle()
                                        .fill(Theme.Colors.secondaryBackground)
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(Theme.Colors.textSecondary)
                                        }
                                }
                                                
                                                Text(user.name)
                                                    .font(Theme.Fonts.caption)
                                                    .foregroundColor(Theme.Colors.textPrimary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 70)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(Theme.Fonts.title3)
                                .fontWeight(.bold)
                            
                            Text(venue.description)
                                .font(Theme.Fonts.body)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                } else if viewModel.isLoading {
                    // Loading State
                    VStack(spacing: Theme.Layout.spacing) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                            .scaleEffect(1.5)
                        Text("Loading venue details...")
                            .font(Theme.Fonts.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: Theme.Layout.spacing) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.warning)
                        
                        Text("Error Loading Venue")
                            .font(Theme.Fonts.headline)
                        
                        Text(errorMessage)
                            .font(Theme.Fonts.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.loadVenueDetail()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.Colors.primary)
                    }
                    .padding()
                    .frame(height: 400)
                }
            }
            }  // Close ScrollView
        }  // Close ZStack
        .enableNativeSwipeBack()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadVenueDetail()
        }
    }  // Close body
    
    
    // MARK: - Helper Methods
    
    /// Opens Apple Maps with directions to the venue
    /// - Parameters:
    ///   - latitude: Venue latitude
    ///   - longitude: Venue longitude
    ///   - name: Venue name for the map marker
    private func openInMaps(latitude: Double, longitude: Double, name: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "coffee shop", "coffee", "café", "cafe":
            return Theme.Colors.Category.coffee
        case "restaurant", "food", "dining":
            return Theme.Colors.Category.restaurant
        case "bar", "nightlife", "pub", "lounge":
            return Theme.Colors.Category.bar
        case "museum", "cultural", "culture", "art", "gallery":
            return Theme.Colors.Category.cultural
        case "park", "outdoor", "nature":
            return Theme.Colors.Category.outdoor
        case "entertainment", "theater", "cinema":
            return Theme.Colors.Category.entertainment
        default:
            return Theme.Colors.textSecondary
        }
    }
    
    /// Returns an icon based on venue category
    /// - Parameter category: The venue category string
    /// - Returns: SF Symbol name for the category
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "coffee shop", "coffee", "café", "cafe":
            return "cup.and.saucer.fill"
        case "restaurant", "food", "dining":
            return "fork.knife"
        case "bar", "nightlife", "pub", "lounge":
            return "wineglass.fill"
        case "museum", "cultural", "culture", "art", "gallery":
            return "building.columns.fill"
        case "park", "outdoor", "nature":
            return "leaf.fill"
        case "entertainment", "theater", "cinema":
            return "theatermasks.fill"
        default:
            return "photo.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VenueDetailView(venueId: "venue_1")
    }
}
