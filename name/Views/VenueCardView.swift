//
//  VenueCardView.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//

import SwiftUI

struct VenueCardView: View {
    
    // MARK: - Properties
    
    let venue: VenueListItem
    @State private var isHeartPressed = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Venue Image
            AsyncImage(url: URL(string: venue.image)) { phase in
                switch phase {
                case .empty:
                    // Placeholder while loading
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    // Successfully loaded image
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                case .failure:
                    // Failed to load image
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                @unknown default:
                    // Fallback for future cases
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fill)
                }
            }
            .clipped()
            
            // Venue Info
            VStack(alignment: .leading, spacing: 8) {
                // Category Badge and Heart Button
                HStack {
                    // Category Badge
                    Text(venue.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor(for: venue.category))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Heart Button (placeholder for now)
                    Button {
                        // Action will be implemented in Phase 3
                        isHeartPressed.toggle()
                    } label: {
                        Image(systemName: isHeartPressed ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isHeartPressed ? .red : .gray)
                    }
                    .scaleEffect(isHeartPressed ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHeartPressed)
                }
                .padding(.top, 12)
                
                // Venue Name
                Text(venue.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Interested Count
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(venue.interested_count) people interested")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    /// Returns a color based on venue category
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "coffee shop", "coffee":
            return Color.blue
        case "restaurant", "food":
            return Color.orange
        case "bar", "nightlife":
            return Color.purple
        case "museum", "cultural", "culture":
            return Color.green
        default:
            return Color.gray
        }
    }
}

// MARK: - Preview

#Preview {
    VenueCardView(venue: VenueListItem(
        id: "venue_1",
        name: "Blue Bottle Coffee",
        category: "Coffee Shop",
        image: "https://picsum.photos/400/300",
        interested_count: 5
    ))
    .padding()
}
