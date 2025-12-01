import SwiftUI

/// Cached async image loader with placeholder and failure support
struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    
    // MARK: - Properties
    
    let url: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    let failure: () -> Failure
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var loadTimeout = false
    
    // Timeout duration in seconds
    private let timeoutDuration: TimeInterval = 10.0
    
    // MARK: - Initialization
    
    /// Create a cached async image view with failure handling
    /// - Parameters:
    ///   - url: URL string of the image
    ///   - content: View builder for the loaded image
    ///   - placeholder: View builder for loading state
    ///   - failure: View builder for failure state
    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let uiImage = loadedImage {
                // Successfully loaded image
                content(Image(uiImage: uiImage))
            } else if loadFailed || loadTimeout {
                // Failed to load or timed out
                failure()
            } else {
                // Still loading
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Load image from cache or network with timeout
    private func loadImage() {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Start timeout timer
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
            await MainActor.run {
                if isLoading && loadedImage == nil {
                    loadTimeout = true
                    isLoading = false
                }
            }
        }
        
        // Load image
        Task {
            let image = await ImageCacheService.shared.loadImage(from: url)
            await MainActor.run {
                if let image = image {
                    self.loadedImage = image
                    self.loadFailed = false
                } else {
                    self.loadFailed = true
                }
                self.isLoading = false
                timeoutTask.cancel()
            }
        }
    }
}

// MARK: - Convenience Initializer with Default Failure View

extension CachedAsyncImage where Failure == DefaultFailureView {
    /// Create a cached async image view with default failure placeholder
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
        self.failure = { DefaultFailureView() }
    }
}

// MARK: - Default Failure View

struct DefaultFailureView: View {
    var body: some View {
        Rectangle()
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay {
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
    }
}

