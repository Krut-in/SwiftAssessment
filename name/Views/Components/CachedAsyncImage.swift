//
//  CachedAsyncImage.swift
//  name
//
//  Created by Antigravity on 27/11/25.
//
//  DESCRIPTION:
//  Drop-in replacement for AsyncImage that uses ImageCacheService for offline support.
//  Provides smooth loading states and automatic caching.
//  
//  USAGE:
//  CachedAsyncImage(url: venue.image) { image in
//      image.resizable().aspectRatio(contentMode: .fill)
//  } placeholder: {
//      ProgressView()
//  }
//

import SwiftUI

/// Cached async image loader with placeholder support
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    
    // MARK: - Properties
    
    let url: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    // MARK: - Initialization
    
    /// Create a cached async image view
    /// - Parameters:
    ///   - url: URL string of the image
    ///   - content: View builder for the loaded image
    ///   - placeholder: View builder for loading state
    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let uiImage = loadedImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Load image from cache or network
    private func loadImage() {
        guard !isLoading else { return }
        
        isLoading = true
        Task {
            let image = await ImageCacheService.shared.loadImage(from: url)
            await MainActor.run {
                self.loadedImage = image
                self.isLoading = false
            }
        }
    }
}
