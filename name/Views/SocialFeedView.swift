//
//  SocialFeedView.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Social feed view displaying friend activities in chronological order.
//  Shows interests, bookings, and check-ins from connected friends.
//  
//  FEATURES:
//  - Scrollable activity timeline
//  - Pull-to-refresh
//  - Infinite scrolling (pagination)
//  - Loading and empty states
//  - Tap to navigate to venue detail
//  
//  ARCHITECTURE:
//  - Uses SocialFeedViewModel for data management
//  - NavigationLink for venue navigation
//  - Theme.swift for consistent styling
//

import SwiftUI

struct SocialFeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SocialFeedViewModel(analytics: AnalyticsService.shared)
    @State private var selectedVenueId: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.activities.isEmpty {
                    // Initial loading state
                    loadingView
                } else if viewModel.activities.isEmpty && !viewModel.isLoading {
                    // Empty state
                    emptyView
                } else {
                    // Activity list
                    activityListView
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadActivities()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Loading skeleton view
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading activities...")
                .font(Theme.Fonts.callout)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.top, Theme.Layout.padding)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background)
    }
    
    /// Empty state view
    private var emptyView: some View {
        VStack(spacing: Theme.Layout.largeSpacing) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textTertiary)
            
            VStack(spacing: Theme.Layout.smallSpacing) {
                Text("No Friend Activity Yet")
                    .font(Theme.Fonts.title3)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("When your friends express interest in venues or make bookings, their activity will appear here.")
                    .font(Theme.Fonts.callout)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Layout.xlSpacing)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background)
    }
    
    /// Activity list with pull-to-refresh
    private var activityListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.spacing) {
                ForEach(viewModel.activities) { activity in
                    NavigationLink(
                        destination: VenueDetailView(venueId: activity.venue.id),
                        tag: activity.venue.id,
                        selection: $selectedVenueId
                    ) {
                        ActivityCardView(activity: activity)
                            .onTapGesture {
                                viewModel.trackActivityTap(activity)
                                selectedVenueId = activity.venue.id
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        // Load more when reaching near the end
                        if activity.id == viewModel.activities.last?.id {
                            Task {
                                await viewModel.loadMoreActivities()
                            }
                        }
                    }
                }
                
                // Loading indicator for pagination
                if viewModel.isLoading && !viewModel.activities.isEmpty {
                    ProgressView()
                        .padding(Theme.Layout.padding)
                }
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background)
        .refreshable {
            await viewModel.refreshActivities()
        }
    }
}

// MARK: - Preview

#Preview {
    SocialFeedView()
}
