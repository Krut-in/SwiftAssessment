//
//  SocialFeedView.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//  Updated on 02/12/25 for Social Interest Activity Feed feature.
//
//  DESCRIPTION:
//  Social feed view displaying friend interest activities and highlighted venues.
//  Shows real-time updates when friends express interest in venues, and promotes
//  venues that have reached critical mass (5+ interested friends) for group meetups.
//  
//  FEATURES:
//  - "Hot Right Now" section for highlighted venues (5+ friends interested)
//  - Chronological friend activity timeline
//  - Pull-to-refresh for manual updates
//  - Infinite scrolling (pagination)
//  - Loading, empty, and error states
//  - Tap to navigate to venue detail
//  - "Plan Meetup" action for highlighted venues
//  
//  ARCHITECTURE:
//  - Uses SocialFeedViewModel for data management
//  - Integrates with AppState for global state
//  - NavigationLink for venue navigation
//  - Theme.swift for consistent styling
//

import SwiftUI

struct SocialFeedView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SocialFeedViewModel(analytics: AnalyticsService.shared)
    @ObservedObject private var appState = AppState.shared
    @State private var navigationPath = NavigationPath()
    @State private var showPlanMeetupSheet = false
    @State private var selectedHighlightedVenue: HighlightedVenue?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.activities.isEmpty && viewModel.interestActivities.isEmpty {
                    loadingView
                } else if viewModel.activities.isEmpty && viewModel.interestActivities.isEmpty && viewModel.highlightedVenues.isEmpty {
                    emptyView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { venueId in
                VenueDetailView(venueId: venueId)
            }
            .task {
                await viewModel.loadActivities()
            }
            .onAppear {
                // Start auto-refresh for real-time updates (every 30 seconds)
                viewModel.startAutoRefresh(interval: 30.0)
            }
            .onDisappear {
                // Stop auto-refresh to save battery
                viewModel.stopAutoRefresh()
            }
        }
        .sheet(isPresented: $showPlanMeetupSheet) {
            if let venue = selectedHighlightedVenue {
                PlanMeetupSheet(venue: venue)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Loading skeleton view
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.spacing) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonActivityCard()
                }
            }
            .padding()
        }
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
                
                Text("When your friends express interest in venues, their activity will appear here. Start exploring to inspire your friends!")
                    .font(Theme.Fonts.callout)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Layout.xlSpacing)
            }
            
            // CTA to go to Discover
            Button {
                appState.selectedTab = 0
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Discover Venues")
                }
                .font(Theme.Fonts.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Theme.Colors.primary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
            .padding(.top, Theme.Layout.padding)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background)
    }
    
    /// Main content with highlighted venues and activity feed
    private var mainContentView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.largeSpacing) {
                // Hot Right Now Section (Highlighted Venues)
                if !viewModel.highlightedVenues.isEmpty {
                    highlightedVenuesSection
                }
                
                // Friend Activity Feed Section
                activityFeedSection
            }
            .padding(.vertical, Theme.Layout.padding)
        }
        .background(Theme.Colors.background)
        .refreshable {
            await viewModel.refreshActivities()
        }
    }
    
    /// Highlighted venues section ("Hot Right Now")
    private var highlightedVenuesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 20))
                    
                    Text("Hot Right Now")
                        .font(Theme.Fonts.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                Spacer()
                
                Text("\(viewModel.highlightedVenues.count) venues")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Layout.padding)
            
            // Highlighted venue cards with proper navigation
            ForEach(viewModel.highlightedVenues) { venue in
                HighlightedVenueCard(
                    venue: venue,
                    onViewVenue: { venueId in
                        viewModel.trackHighlightedVenueTap(venue)
                        navigationPath.append(venueId)
                    },
                    onPlanMeetup: { highlightedVenue in
                        viewModel.trackPlanMeetupTap(highlightedVenue)
                        selectedHighlightedVenue = highlightedVenue
                        showPlanMeetupSheet = true
                    }
                )
                .padding(.horizontal, Theme.Layout.padding)
            }
        }
    }
    
    /// Friend activity feed section
    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Friend Activity")
                        .font(Theme.Fonts.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, Theme.Layout.padding)
            
            // Interest activities from AppState (real-time)
            if !viewModel.interestActivities.isEmpty {
                ForEach(viewModel.interestActivities) { activity in
                    NavigationLink(value: activity.venue.id) {
                        InterestActivityCard(activity: activity) {
                            viewModel.trackInterestActivityTap(activity)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, Theme.Layout.padding)
                }
            }
            
            // Legacy activities from API
            ForEach(viewModel.activities) { activity in
                NavigationLink(value: activity.venue.id) {
                    ActivityCardView(activity: activity)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, Theme.Layout.padding)
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
            if viewModel.isLoading && (!viewModel.activities.isEmpty || !viewModel.interestActivities.isEmpty) {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(Theme.Layout.padding)
                    Spacer()
                }
            }
            
            // Empty activity state (when only highlighted venues exist)
            if viewModel.activities.isEmpty && viewModel.interestActivities.isEmpty {
                VStack(spacing: Theme.Layout.spacing) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text("No recent activity from friends")
                        .font(Theme.Fonts.callout)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Layout.xlSpacing)
            }
        }
    }
}

// MARK: - Plan Meetup Sheet

struct PlanMeetupSheet: View {
    
    let venue: HighlightedVenue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Layout.largeSpacing) {
                // Venue info header
                VStack(spacing: Theme.Layout.spacing) {
                    AsyncImage(url: URL(string: venue.venueImageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(Theme.Colors.secondaryBackground)
                        }
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    
                    Text(venue.venueName)
                        .font(Theme.Fonts.title2)
                        .fontWeight(.bold)
                    
                    Text(venue.venueAddress)
                        .font(Theme.Fonts.callout)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, Theme.Layout.padding)
                
                // Interested friends
                VStack(alignment: .leading, spacing: Theme.Layout.spacing) {
                    Text("Friends Interested (\(venue.interestedFriends.count))")
                        .font(Theme.Fonts.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Layout.spacing) {
                            ForEach(venue.interestedFriends) { friend in
                                VStack(spacing: 6) {
                                    AsyncImage(url: URL(string: friend.avatarURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        default:
                                            Circle()
                                                .fill(Theme.Colors.primary.opacity(0.2))
                                                .overlay {
                                                    Text(friend.firstName.prefix(1).uppercased())
                                                        .font(.system(size: 20, weight: .semibold))
                                                        .foregroundColor(Theme.Colors.primary)
                                                }
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                                    
                                    Text(friend.firstName)
                                        .font(Theme.Fonts.caption)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Layout.padding)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: Theme.Layout.spacing) {
                    Text("Coming Soon!")
                        .font(Theme.Fonts.headline)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text("Group chat and meetup planning features are being developed. Stay tuned!")
                        .font(Theme.Fonts.callout)
                        .foregroundColor(Theme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Layout.padding)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Got it!")
                            .font(Theme.Fonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.Colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .padding(.horizontal, Theme.Layout.padding)
                }
                .padding(.bottom, Theme.Layout.largeSpacing)
            }
            .navigationTitle("Plan Meetup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SocialFeedView()
}
