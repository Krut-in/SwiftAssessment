//
//  ProfileView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import SwiftUI

struct ProfileView: View {
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Placeholder Icon
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Placeholder Text
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming in Phase 3")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
