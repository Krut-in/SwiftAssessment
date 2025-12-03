//
//  UserSwitcherView.swift
//  name
//
//  Created by Krutin Rathod on 27/11/25.
//
//  DESCRIPTION:
//  Modal view for switching between demo users.
//  Displays available users with visual indication of current selection.
//  
//  FEATURES:
//  - Grid layout of available demo users
//  - Visual highlight for currently selected user
//  - Haptic feedback on selection
//  - Automatic data refresh on user switch
//  
//  USAGE:
//  .sheet(isPresented: $showUserSwitcher) {
//      UserSwitcherView()
//  }
//

import SwiftUI

struct UserSwitcherView: View {
    
    // MARK: - Properties
    
    @ObservedObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    
    private let authService: AuthenticationServiceProtocol = MockAuthenticationService.shared
    
    // MARK: - State
    
    @State private var isLoading = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Layout.largeSpacing) {
                    // Header
                    VStack(spacing: Theme.Layout.smallSpacing) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("Switch User")
                            .font(Theme.Fonts.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("Select a demo user to continue")
                            .font(Theme.Fonts.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Layout.padding)
                    
                    // User Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Theme.Layout.padding),
                            GridItem(.flexible(), spacing: Theme.Layout.padding)
                        ],
                        spacing: Theme.Layout.padding
                    ) {
                        ForEach(authService.getAvailableUsers()) { user in
                            UserSelectionCard(
                                user: user,
                                isSelected: user.id == appState.currentUserId,
                                isLoading: isLoading
                            ) {
                                await selectUser(user)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Info Banner
                    InfoBanner()
                        .padding(.horizontal)
                        .padding(.bottom, Theme.Layout.padding)
                }
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func selectUser(_ user: DemoUser) async {
        guard user.id != appState.currentUserId else {
            // Already selected, just dismiss
            dismiss()
            return
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = true
        
        // Switch user
        await appState.switchUser(to: user.id)
        
        isLoading = false
        
        // Dismiss sheet
        dismiss()
    }
}

// MARK: - User Selection Card

struct UserSelectionCard: View {
    let user: DemoUser
    let isSelected: Bool
    let isLoading: Bool
    let onSelect: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await onSelect()
            }
        } label: {
            VStack(spacing: Theme.Layout.spacing) {
                // Avatar
                ZStack {
                    AsyncImage(url: URL(string: user.avatar)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty:
                            ProgressView()
                        case .failure(_):
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.textSecondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Theme.Colors.primary : Color.clear,
                                lineWidth: 3
                            )
                    )
                    
                    // Selected checkmark
                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Theme.Colors.primary)
                                            .frame(width: 24, height: 24)
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .frame(width: 80, height: 80)
                    }
                }
                
                // Name
                Text(user.name)
                    .font(Theme.Fonts.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(
                        isSelected ? Theme.Colors.primary : Theme.Colors.textPrimary
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // User ID
                Text(user.id)
                    .font(Theme.Fonts.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Layout.padding)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Layout.cornerRadius)
            .elevationLow()
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(
                        isSelected ? Theme.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .disabled(isLoading)
        .opacity(isLoading && !isSelected ? 0.5 : 1.0)
    }
}

// MARK: - Info Banner

struct InfoBanner: View {
    var body: some View {
        HStack(spacing: Theme.Layout.spacing) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.Colors.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Demo Mode")
                    .font(Theme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("User selection persists across app launches")
                    .font(Theme.Fonts.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.Layout.spacing)
        .background(Theme.Colors.primary.opacity(0.1))
        .cornerRadius(Theme.Layout.smallCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    UserSwitcherView()
}
