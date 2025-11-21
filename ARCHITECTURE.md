# Luna iOS App Architecture - Phase 2

## Project Structure

```
name/
│
├── nameApp.swift                 # App Entry Point
│   └── ContentView               # Main TabView Container
│
├── Models/                       # Data Layer
│   ├── User.swift               # User model
│   ├── Venue.swift              # Venue & VenueListItem models
│   ├── Interest.swift           # Interest model
│   └── APIModels.swift          # Request/Response wrappers
│
├── Services/                     # Network Layer
│   └── APIService.swift         # HTTP client (URLSession)
│       ├── fetchVenues()
│       ├── fetchVenueDetail()
│       ├── expressInterest()
│       ├── fetchUserProfile()
│       └── fetchRecommendations()
│
├── ViewModels/                   # Business Logic Layer
│   ├── VenueFeedViewModel       # Manages venue list state
│   └── VenueDetailViewModel     # Manages detail view state
│
└── Views/                        # Presentation Layer
    ├── ContentView.swift        # Tab container
    ├── VenueFeedView.swift      # Venue list screen
    ├── VenueCardView.swift      # Venue card component
    ├── VenueDetailView.swift    # Venue detail screen
    └── ProfileView.swift        # Profile screen
```

## Data Flow (MVVM Pattern)

```
┌─────────────────────────────────────────────────────────┐
│                        View Layer                        │
│                     (SwiftUI Views)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ ContentView  │  │VenueFeedView │  │ ProfileView  │ │
│  └──────────────┘  └──────┬───────┘  └──────────────┘ │
│                            │                             │
│                     ┌──────▼───────┐                    │
│                     │VenueCardView │                    │
│                     └──────────────┘                    │
└─────────────────────────┬───────────────────────────────┘
                          │
                          │ @StateObject
                          │ @Published
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    ViewModel Layer                       │
│                  (@MainActor Classes)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │         VenueFeedViewModel                        │  │
│  │  @Published var venues: [VenueListItem]          │  │
│  │  @Published var isLoading: Bool                  │  │
│  │  @Published var errorMessage: String?            │  │
│  │                                                    │  │
│  │  func loadVenues() async                         │  │
│  │  func refresh() async                            │  │
│  └──────────────────────┬───────────────────────────┘  │
└───────────────────────┬─┴───────────────────────────────┘
                        │
                        │ Dependency Injection
                        │ (APIServiceProtocol)
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Service Layer                         │
│                   (Network + Logic)                      │
│  ┌──────────────────────────────────────────────────┐  │
│  │              APIService                           │  │
│  │  - baseURL: String                               │  │
│  │  - session: URLSession                           │  │
│  │                                                    │  │
│  │  func fetchVenues() async throws                 │  │
│  │  func fetchVenueDetail() async throws            │  │
│  │  func expressInterest() async throws             │  │
│  │  func fetchUserProfile() async throws            │  │
│  │  func fetchRecommendations() async throws        │  │
│  └──────────────────────┬───────────────────────────┘  │
└───────────────────────┬─┴───────────────────────────────┘
                        │
                        │ HTTP Requests
                        │ (URLSession + async/await)
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   Backend API                            │
│              FastAPI (localhost:8000)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │  GET  /venues                                    │  │
│  │  GET  /venues/{venue_id}                         │  │
│  │  POST /interests                                 │  │
│  │  GET  /users/{user_id}                           │  │
│  │  GET  /recommendations?user_id={user_id}         │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────┐
│                    ContentView (TabView)                 │
│  ┌────────────────────────┬───────────────────────────┐ │
│  │  Tab 1: Discover       │  Tab 2: Profile           │ │
│  │  ┌──────────────────┐  │  ┌──────────────────────┐ │ │
│  │  │ VenueFeedView    │  │  │   ProfileView        │ │ │
│  │  │                  │  │  │   (Placeholder)      │ │ │
│  │  │ ┌──────────────┐ │  │  │                      │ │ │
│  │  │ │VenueCardView │ │  │  └──────────────────────┘ │ │
│  │  │ │  (x12)       │ │  │                            │ │
│  │  │ └──────────────┘ │  │                            │ │
│  │  └──────────────────┘  │                            │ │
│  └────────────────────────┴───────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## State Management Flow

```
User Action
    │
    ▼
┌─────────┐
│  View   │  Triggers action (onAppear, button tap, pull-to-refresh)
└────┬────┘
     │
     ▼
┌─────────────┐
│ ViewModel   │  Updates @Published properties
└──────┬──────┘  Shows loading, handles errors
       │
       ▼
┌─────────────┐
│   Service   │  Makes async network calls
└──────┬──────┘  Returns typed data or throws error
       │
       ▼
┌─────────────┐
│   Backend   │  FastAPI returns JSON
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Service   │  Decodes JSON to Swift models
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ ViewModel   │  Updates @Published properties
└──────┬──────┘  on @MainActor
       │
       ▼
┌─────────┐
│  View   │  Automatically re-renders (SwiftUI)
└─────────┘
```

## Error Handling Flow

```
Network Request
    │
    ├──► Success ──► Decode ──► Update State ──► Render UI
    │
    └──► Failure ──┬──► Network Error
                   ├──► Decoding Error
                   ├──► Server Error
                   └──► Unknown Error
                          │
                          ▼
                   Set errorMessage
                          │
                          ▼
                   View shows error UI
                          │
                          ▼
                   User taps Retry
                          │
                          ▼
                   Retry network request
```

## Key Design Patterns

### 1. MVVM (Model-View-ViewModel)
- **Models**: Pure data structures (Codable, Identifiable)
- **Views**: SwiftUI views, declarative UI
- **ViewModels**: Business logic, @Published state

### 2. Dependency Injection
```swift
class VenueFeedViewModel {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
}
```

### 3. Protocol-Oriented Programming
```swift
protocol APIServiceProtocol {
    func fetchVenues() async throws -> [VenueListItem]
    // ... other methods
}
```

### 4. Async/Await Concurrency
```swift
func loadVenues() async {
    isLoading = true
    do {
        let venues = try await apiService.fetchVenues()
        await MainActor.run {
            self.venues = venues
            self.isLoading = false
        }
    } catch {
        // Handle error
    }
}
```

### 5. Combine Framework
- `@Published` for reactive state updates
- `@StateObject` for ViewModel lifecycle
- `ObservableObject` protocol

## Thread Safety

```
┌─────────────────────────────────────────┐
│           Main Thread                    │
│         (@MainActor)                     │
│  ┌────────────────────────────────────┐ │
│  │  All ViewModels                    │ │
│  │  All @Published updates            │ │
│  │  All UI updates                    │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│        Background Threads                │
│  ┌────────────────────────────────────┐ │
│  │  URLSession network calls          │ │
│  │  JSON decoding                     │ │
│  │  Image loading                     │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Network Configuration

```
┌─────────────────────────────────────────┐
│            Info.plist                    │
│  ┌────────────────────────────────────┐ │
│  │  NSAppTransportSecurity            │ │
│  │    - NSAllowsLocalNetworking       │ │
│  │    - localhost exception           │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         URLSession                       │
│  HTTP allowed for localhost:8000         │
└─────────────────────────────────────────┘
```

## Model Relationships

```
┌──────────────┐
│     User     │
│  - id        │
│  - name      │
│  - avatar    │
│  - bio       │
│  - interests │
└──────┬───────┘
       │
       │ interested in
       │
       ▼
┌──────────────┐      ┌──────────────┐
│  Interest    │◄────►│    Venue     │
│  - user_id   │      │  - id        │
│  - venue_id  │      │  - name      │
│  - timestamp │      │  - category  │
└──────────────┘      │  - image     │
                      │  - address   │
                      └──────────────┘
                            │
                            │ displayed as
                            ▼
                      ┌──────────────┐
                      │VenueListItem │
                      │  - id        │
                      │  - name      │
                      │  - category  │
                      │  - image     │
                      │  - interested│
                      │    _count    │
                      └──────────────┘
```

## View Component Hierarchy

```
ContentView (TabView)
│
├── VenueFeedView (NavigationView)
│   ├── Loading State (ProgressView)
│   ├── Error State (VStack with retry)
│   ├── Empty State (VStack with icon)
│   └── List State (ScrollView)
│       └── LazyVStack
│           └── VenueCardView (x12)
│               ├── AsyncImage (4:3 ratio)
│               ├── Category Badge
│               ├── Venue Name (Text)
│               ├── Interested Count (HStack)
│               └── Heart Button
│
└── ProfileView (NavigationView)
    └── Placeholder (VStack)
```

## API Response Mapping

```
Backend JSON              Swift Model
────────────              ───────────
{                         VenuesResponse {
  "venues": [               venues: [
    {                         VenueListItem(
      "id": "venue_1",          id: "venue_1",
      "name": "Blue Bottle",    name: "Blue Bottle",
      "category": "Coffee",     category: "Coffee",
      "image": "https://...",   image: "https://...",
      "interested_count": 4     interested_count: 4
    }                         )
  ]                         ]
}                         }
```

## Category Color Mapping

```
┌──────────────────┬─────────┬───────────┐
│    Category      │  Color  │   Badge   │
├──────────────────┼─────────┼───────────┤
│  Coffee Shop     │  Blue   │    🔵     │
│  Restaurant      │ Orange  │    🟠     │
│  Bar             │ Purple  │    🟣     │
│  Cultural        │  Green  │    🟢     │
└──────────────────┴─────────┴───────────┘
```

## Phase 2 Implementation Status

```
✅ Models Layer          100%
✅ Services Layer        100%
✅ ViewModels Layer      100%
✅ Views Layer           100%
✅ Network Config        100%
✅ Error Handling        100%
✅ Loading States        100%
✅ Documentation         100%

⏳ Xcode Integration     Pending
⏳ Build Verification    Pending
⏳ Runtime Testing       Pending
```

---

**Architecture designed for:**
- Testability (Protocol-based)
- Scalability (Clean separation)
- Maintainability (MVVM pattern)
- Type Safety (Swift's type system)
- Performance (Async/await, lazy loading)
- User Experience (Loading, error, empty states)
