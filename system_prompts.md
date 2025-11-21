# System Prompts for CODING AI Agent - Luna Venue Discovery App

## Overview

These system prompts are designed to guide a CODING AI agent through building a full-stack venue discovery application. Each prompt corresponds to a specific development phase and should be given sequentially to maintain project structure and prevent hallucination.

**Scope Note:** This is a **Track 3 (Full Stack)** implementation that focuses on core integration quality within the 72-hour constraint. The prompts implement a **simplified subset** of Track 1 and Track 2 requirements, prioritizing a working end-to-end prototype over comprehensive feature coverage. Advanced features such as spatial analysis, complex social compatibility scoring, and friend invitation systems are intentionally simplified or deferred to meet the time constraint while demonstrating full-stack competency.

---

## PROMPT 1A: Backend Foundation & Data Models

**Objective:** Set up FastAPI project structure, create data models, and generate synthetic test data.

**Context:** You are building a FastAPI backend for a venue discovery application. This is Phase 1A of a 7-phase project (1A → 1B → 1C → 2 → 3 → 4 → 5). Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **Project Setup:**

   - Create `Luna-Backend/` directory structure as specified in the plan
   - Initialize FastAPI project with proper dependencies (FastAPI, uvicorn, pydantic)
   - Create `requirements.txt` with: FastAPI, uvicorn, pydantic
   - Use Python 3.8+ with type hints throughout
   - No ORM needed - use simple dictionary-based in-memory data store
   - Create a basic `main.py` file with FastAPI app instance (endpoints will be added in Phase 1B)

2. **Data Models (`models.py`):**

   - Create Pydantic models matching the exact JSON schemas from the plan:
     - `User`: id (str), name (str), avatar (str), bio (str), interests (List[str])
     - `Venue`: id (str), name (str), category (str), description (str), image (str), address (str)
     - `Interest`: user_id (str), venue_id (str), timestamp (datetime)
   - Include proper validation and serialization
   - Use exact field names as specified in the plan document
   - Add docstrings to each model class

3. **Synthetic Data (`data.py`):**

   - Generate exactly 8 users with names: Alex Chen, Jordan Kim, Sam Rivera, Taylor Lee, Morgan Park, Casey Wu, Riley Brooks, Quinn Davis
   - Generate exactly 12 venues: 3 Coffee shops (Blue Bottle, Stumptown, La Colombe), 3 Restaurants (The Smith, Joe's Pizza, Sushi Place), 3 Bars (Dead Rabbit, Employees Only, Rooftop Bar), 3 Cultural (MoMA, Whitney Museum, Comedy Cellar)
   - Use `https://i.pravatar.cc/150?img={1-8}` for user avatars
   - Use `https://picsum.photos/400/300?random={1-12}` for venue images
   - Create 25 pre-populated interest relationships (each user interested in 2-4 venues, with overlap for social proof)
   - Store data in dictionaries: `users_dict`, `venues_dict`, `interests_list`
   - Ensure Alex, Jordan, and Sam are all interested in Blue Bottle Coffee
   - Create a function `initialize_data()` that returns these dictionaries/list

**Expected Output Example:**

After completion, you should be able to verify:

- `models.py` contains User, Venue, Interest classes
- `data.py` contains `users_dict` with exactly 8 users
- `data.py` contains `venues_dict` with exactly 12 venues
- `data.py` contains `interests_list` with exactly 25 interest relationships
- All field names match exactly with `idea.md` JSON schemas

**Verification Checklist:**

Before proceeding to Phase 1B, verify:

- [ ] All field names match `idea.md` exactly (id, name, avatar, bio, interests, category, description, image, address, user_id, venue_id, timestamp)
- [ ] No extra fields added beyond specification
- [ ] Data structures are dictionaries/lists as specified (not database tables)
- [ ] Code compiles without errors
- [ ] Can import models and data successfully

**Constraints:**

- DO NOT create API endpoints yet (that's Phase 1B)
- DO NOT use SQLite or any database - use in-memory dictionaries only
- DO NOT modify the data model structures from the plan
- DO NOT add fields not in the specification

**Deliverable:** Working data models and synthetic data generator with test data ready for API endpoints.

---

## PROMPT 1B: Backend API Endpoints & Core Logic

**Objective:** Implement all 5 API endpoints, recommendation algorithm, and basic error handling.

**Context:** You are continuing the FastAPI backend. This is Phase 1B of a 7-phase project. Data models and synthetic data from Phase 1A should be complete. Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **API Endpoints (`main.py`):**

   - Implement exactly 5 endpoints matching the plan specifications:
     - `GET /venues` - Returns `{"venues": [...]}` with id, name, category, image, interested_count
     - `GET /venues/{venue_id}` - Returns `{"venue": {...}, "interested_users": [...]}`
     - `POST /interests` - Accepts `{"user_id": str, "venue_id": str}`, returns `{"success": bool, "agent_triggered": bool, "message": str}`
     - `GET /users/{user_id}` - Returns `{"user": {...}, "interested_venues": [...]}`
     - `GET /recommendations?user_id={user_id}` - Returns `{"recommendations": [{"venue": {...}, "score": float, "reason": str}]}`
   - Calculate `interested_count` dynamically from interests list
   - Return interested users as simplified objects (id, name, avatar only)
   - Handle missing IDs with proper 404 responses
   - Use exact response formats from the plan document
   - Import and use data from `data.py`

2. **Recommendation Algorithm:**

   - Implement `calculate_recommendation_score()` function exactly as specified:
     - Factor 1: Popularity (0-3 points) = min(interested_count / 3, 3)
     - Factor 2: Category match (0-4 points) = 4 if venue.category.lower() in user.interests
     - Factor 3: Friend interest (0-3 points) = min(count_friends_interested(user, venue), 3)
   - For "friends", consider all other users (simplified for prototype)
   - Sort recommendations by score descending
   - Include reason string explaining why venue was recommended (e.g., "2 friends interested", "Popular venue", "Matches your interests")

3. **Code Quality:**

   - Add CORS middleware for iOS app integration
   - Include proper error handling (404, 400, 500)
   - Add docstrings to all functions
   - Use type hints consistently
   - Follow PEP 8 style guide

4. **Testing:**
   - Ensure all endpoints return correct JSON structures
   - Test with sample curl commands or Postman
   - Verify recommendation scores are calculated correctly

**Expected Output Example:**

`GET /venues` should return:

```json
{
  "venues": [
    {
      "id": "venue_1",
      "name": "Blue Bottle Coffee",
      "category": "Coffee Shop",
      "image": "https://picsum.photos/400/300?random=1",
      "interested_count": 3
    }
  ]
}
```

`GET /recommendations?user_id=user_1` should return:

```json
{
  "recommendations": [
    {
      "venue": {
        /* full venue object */
      },
      "score": 8.5,
      "reason": "2 friends interested"
    }
  ]
}
```

**Verification Checklist:**

Before proceeding to Phase 1C, verify:

- [ ] All 5 endpoints return correct JSON structures matching `idea.md`
- [ ] Response formats match specification exactly
- [ ] No extra fields added to responses
- [ ] 404 errors returned for missing IDs
- [ ] Recommendation scores are calculated correctly (max 10 points)
- [ ] Code compiles and runs without errors
- [ ] Can test endpoints with curl/Postman

**Constraints:**

- DO NOT implement booking agent yet (that's Phase 1C)
- DO NOT add features not in the plan (no real-time updates, no complex ML, no maps)
- DO NOT use SQLite or any database - use in-memory dictionaries only
- DO NOT create endpoints beyond the 5 specified
- DO NOT modify the data model structures from the plan

**Deliverable:** Fully functional FastAPI backend with all 5 endpoints working, testable via HTTP requests.

---

## PROMPT 1C: Booking Agent Integration & Finalization

**Objective:** Implement mock booking agent and integrate it with the POST /interests endpoint.

**Context:** You are finalizing the FastAPI backend. This is Phase 1C of a 7-phase project. API endpoints from Phase 1B should be complete. Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **Mock Booking Agent (`agent.py`):**

   - Create `booking_agent(venue_id: str, user_count: int)` function
   - Threshold = 3 users
   - When triggered, return dict with: agent_triggered=True, action="reservation_simulated", venue_id, message, reservation_code (format: "LUNA-{venue_id}-{random_4_digits}")
   - Message format: "Mock booking agent: Reserved table for {user_count} at {venue.name}" (as specified in plan)
   - Do NOT actually integrate with external APIs - this is a mock simulation
   - In README, explain this would integrate with OpenTable/Resy APIs in production

2. **Integration:**

   - Call booking agent in POST `/interests` endpoint after adding interest
   - Check if interested_count >= 3, then call agent
   - Include agent response in POST `/interests` response
   - If agent_triggered is True, include the message and reservation_code in response

3. **Testing:**
   - Verify booking agent triggers at threshold (3+ users)
   - Verify booking agent does NOT trigger below threshold (< 3 users)
   - Test POST `/interests` returns correct response with agent_triggered flag
   - Verify reservation_code format is correct

**Expected Output Example:**

When POST `/interests` triggers the agent (3+ users interested):

```json
{
  "success": true,
  "agent_triggered": true,
  "message": "Mock booking agent: Reserved table for 3 at Blue Bottle Coffee",
  "reservation_code": "LUNA-venue_1-4521"
}
```

When POST `/interests` does NOT trigger the agent (< 3 users):

```json
{
  "success": true,
  "agent_triggered": false,
  "message": "Interest recorded successfully"
}
```

**Verification Checklist:**

Before proceeding to Phase 2, verify:

- [ ] Booking agent triggers correctly at threshold (3+ users)
- [ ] Booking agent does NOT trigger below threshold
- [ ] Reservation code format matches "LUNA-{venue_id}-{4_digits}"
- [ ] Message format matches specification exactly
- [ ] POST `/interests` response includes agent_triggered flag
- [ ] All endpoints still work correctly
- [ ] Code compiles and runs without errors

**Constraints:**

- DO NOT actually integrate with external booking APIs (OpenTable/Resy)
- DO NOT modify the threshold (must be 3)
- DO NOT change the reservation code format
- DO NOT modify existing endpoint behavior beyond agent integration

**Deliverable:** Complete FastAPI backend with booking agent integrated, all 5 endpoints working, ready for iOS app integration.

---

## PROMPT 2: iOS Foundation & Basic UI

**Objective:** Set up SwiftUI project structure, create models, API service, and basic venue feed view.

**Context:** You are building a SwiftUI iOS app for venue discovery. This is Phase 2 of a 7-phase project (1A → 1B → 1C → 2 → 3 → 4 → 5). The backend API from Phases 1A-1C should be running. Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **Project Setup:**

   - Create `Luna-iOS/` directory structure matching the plan:
     - `Models/` folder: User.swift, Venue.swift, Interest.swift
     - `ViewModels/` folder: VenueFeedViewModel.swift, VenueDetailViewModel.swift
     - `Views/` folder: ContentView.swift, VenueFeedView.swift, VenueDetailView.swift, ProfileView.swift
     - `Services/` folder: APIService.swift
   - Use SwiftUI and Combine frameworks
   - Target iOS 15.0+ (or latest stable)
   - Configure app for proper network permissions (Info.plist)

2. **Data Models (`Models/`):**

   - Create `User.swift` struct conforming to `Codable`:
     - Properties: id (String), name (String), avatar (String), bio (String), interests ([String])
   - Create `Venue.swift` struct conforming to `Codable`:
     - Properties: id (String), name (String), category (String), description (String), image (String), address (String)
     - Include computed property or separate struct for `VenueListItem` with interested_count
   - Create `Interest.swift` struct conforming to `Codable`:
     - Properties: user_id (String), venue_id (String), timestamp (Date)
   - Create response wrapper structs matching API responses:
     - `VenuesResponse`: venues ([VenueListItem])
     - `VenueDetailResponse`: venue (Venue), interested_users ([User])
     - `UserProfileResponse`: user (User), interested_venues ([Venue])
     - `RecommendationsResponse`: recommendations ([RecommendationItem])
     - `RecommendationItem`: venue (Venue), score (Double), reason (String)
   - Use exact property names matching the backend API JSON

3. **API Service (`Services/APIService.swift`):**

   - Create `APIService` class as `ObservableObject`
   - Use `URLSession` for network requests (no third-party libraries)
   - Base URL should be configurable (default: "http://localhost:8000" for simulator)
   - Implement methods matching all 5 API endpoints:
     - `func fetchVenues() async throws -> [VenueListItem]`
     - `func fetchVenueDetail(venueId: String) async throws -> VenueDetailResponse`
     - `func expressInterest(userId: String, venueId: String) async throws -> InterestResponse`
     - `func fetchUserProfile(userId: String) async throws -> UserProfileResponse`
     - `func fetchRecommendations(userId: String) async throws -> [RecommendationItem]`
   - Include proper error handling (network errors, decoding errors, HTTP status codes)
   - Use async/await (Swift 5.5+) for all network calls
   - Create response models for POST `/interests`: `InterestResponse` with success, agent_triggered, message

4. **ViewModels (`ViewModels/VenueFeedViewModel.swift`):**

   - Create `VenueFeedViewModel` class conforming to `ObservableObject`
   - Properties: `@Published var venues: [VenueListItem] = []`, `@Published var isLoading = false`, `@Published var errorMessage: String?`
   - Inject `APIService` as dependency (use protocol for testability)
   - Methods:
     - `func loadVenues() async` - calls API service, updates published properties
     - Handle loading states and errors properly
   - Use `@MainActor` for UI updates

5. **Basic Views:**

   - **ContentView.swift:**

     - Set up TabView with two tabs: "Discover" and "Profile"
     - For now, Profile tab can show placeholder text
     - Use system icons: "house.fill" for Discover, "person.fill" for Profile

   - **VenueFeedView.swift:**
     - NavigationView with title "Discover"
     - Use `@StateObject` for VenueFeedViewModel
     - Display venues in `List` or `LazyVStack` within `ScrollView`
     - Create `VenueCardView` component (separate struct):
       - Image with 4:3 aspect ratio, rounded corners
       - Venue name (bold, 18pt font)
       - Category badge (rounded rectangle with background color)
       - "X people interested" text (secondary color)
       - Heart icon button (outline state for now, no functionality yet)
     - Call `loadVenues()` in `.onAppear`
     - Show loading indicator when `isLoading == true`
     - Show error message if `errorMessage != nil`
     - Add pull-to-refresh (use `.refreshable` modifier)

6. **Styling Guidelines:**

   - Use system colors and fonts (SF Pro)
   - Card design: white background, rounded corners (12pt), shadow
   - Category badges: colored background (e.g., blue for Coffee, orange for Restaurants)
   - Spacing: 16pt padding, 8pt between elements
   - Image loading: Use `AsyncImage` with placeholder

7. **Swift-Specific Requirements:**

   - Use `@MainActor` for all UI updates (all ViewModels should be marked with `@MainActor`)
   - Handle optionals safely (use `guard let` or `if let`, avoid force unwrapping `!`)
   - Use `async/await` for all network calls (Swift 5.5+)
   - Ensure all `@Published` properties are updated on main thread
   - Create custom Error enum for API errors (e.g., `APIError` with cases: networkError, decodingError, serverError)
   - Use proper error handling with `Result` types or `throws` keywords
   - Avoid memory leaks (no retain cycles in closures - use `[weak self]` when needed)
   - Follow Swift naming conventions (PascalCase for types, camelCase for properties)

8. **Code Quality:**
   - Add comments for complex logic
   - Use proper access control (private, internal, public)
   - Ensure consistent code style throughout

**Constraints:**

- DO NOT use third-party networking libraries (Alamofire, etc.) - use URLSession only
- DO NOT use third-party image loading libraries - use AsyncImage
- DO NOT implement interest functionality yet (that's Phase 3)
- DO NOT create ProfileView content yet (that's Phase 3)
- DO NOT add animations yet (that's Phase 5)

**Expected Output Example:**

After completion, the app should:

- Display a list of venues with images, names, categories, and interested counts
- Show loading indicator while fetching data
- Handle errors gracefully with user-friendly messages
- Support pull-to-refresh to reload venues

**Verification Checklist:**

Before proceeding to Phase 3, verify:

- [ ] All property names match backend API JSON exactly (id, name, avatar, bio, interests, category, description, image, address, user_id, venue_id, timestamp)
- [ ] No force unwrapping (`!`) used - all optionals handled safely
- [ ] All UI updates happen on `@MainActor`
- [ ] API service uses `async/await` (not completion handlers)
- [ ] Error handling implemented for network failures
- [ ] Code compiles without errors
- [ ] App runs in iOS Simulator and displays venues from backend

**Swift Code Quality Checklist:**

- [ ] No force unwrapping - use safe unwrapping
- [ ] All UI updates happen on `@MainActor`
- [ ] Proper error handling with Result types or throws
- [ ] Memory management (no retain cycles in closures)
- [ ] Follow Swift naming conventions

**Testing:**

- Ensure app compiles without errors
- Verify API calls work when backend is running
- Test with iOS Simulator (use localhost for API)
- Verify venues display correctly in feed
- Test pull-to-refresh functionality

**Deliverable:** Working iOS app that displays venue feed from backend API, with proper MVVM architecture and error handling.

---

## PROMPT 3: Core User Features & Navigation

**Objective:** Implement venue detail view, interest functionality, profile view, and complete navigation flow.

**Context:** You are continuing the SwiftUI iOS app. This is Phase 3 of a 7-phase project. Backend API and basic feed are complete. Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **Venue Detail View (`Views/VenueDetailView.swift`):**

   - Accept `venueId: String` as parameter
   - Use `@StateObject` for `VenueDetailViewModel`
   - Layout structure:
     - Full-width hero image at top (use AsyncImage, 300pt height)
     - Back button overlay (top-left, white circle background)
     - ScrollView with content:
       - Venue name (large title, 28pt font, bold)
       - Category badge + address (horizontal stack, secondary text)
       - "X people interested" text
       - Large "I'm Interested" button (primary color, full width, 50pt height, rounded corners)
       - "People Who Want to Go" section:
         - Section header: "People Who Want to Go"
         - Horizontal ScrollView with user avatars
         - Each item: circular avatar (60pt), name below (12pt)
         - Use AsyncImage for avatars
       - "About" section:
         - Section header: "About"
         - Description text (body font)
   - Button should show different state if user already interested (e.g., "Remove Interest" or filled heart icon)

2. **Venue Detail ViewModel (`ViewModels/VenueDetailViewModel.swift`):**

   - Properties: `@Published var venue: Venue?`, `@Published var interestedUsers: [User] = []`, `@Published var isInterested = false`, `@Published var isLoading = false`, `@Published var errorMessage: String?`
   - Inject `APIService` and `currentUserId: String` (hardcode as "user_1" for now)
   - Methods:
     - `func loadVenueDetail() async` - fetches venue and interested users
     - `func toggleInterest() async` - calls POST /interests, updates local state optimistically
     - Check if current user is in interestedUsers to set `isInterested`
   - Handle booking agent response (show alert or toast if agent_triggered == true)

3. **Interest Functionality:**

   - Update `VenueFeedView` to track interested venues (use `@AppStorage` or ViewModel state)
   - Update heart button in `VenueCardView` to show filled state if venue is interested
   - Add tap gesture to heart button that calls interest API
   - Implement optimistic UI updates (update UI immediately, revert on error)
   - Update `VenueFeedView` to navigate to detail on card tap

4. **Profile View (`Views/ProfileView.swift`):**

   - Use `@StateObject` for `ProfileViewModel`
   - Layout:
     - User avatar (centered, 120pt circle, top padding)
     - User name (title, centered)
     - "X places saved" count (secondary text, centered)
     - Grid of interested venue cards:
       - Use `LazyVGrid` with 2 columns
       - Smaller cards (just image + name)
       - Tap card → navigate to VenueDetailView
   - Load user profile data from GET `/users/{user_id}` endpoint

5. **Profile ViewModel:**

   - Create `ProfileViewModel` class
   - Properties: `@Published var user: User?`, `@Published var interestedVenues: [Venue] = []`, `@Published var isLoading = false`
   - Method: `func loadProfile() async` - fetches user and interested venues
   - Hardcode current user ID as "user_1" for now

6. **Navigation Updates:**

   - Update `ContentView` TabView to show actual ProfileView (not placeholder)
   - Implement NavigationLink from VenueFeedView → VenueDetailView
   - Implement NavigationLink from ProfileView → VenueDetailView
   - Use proper navigation stack management

7. **State Management:**

   - Create a shared `UserState` or `AppState` class to track current user ID
   - Update interest state across views when user toggles interest
   - Consider using Combine publishers for cross-view updates

8. **Error Handling:**
   - Show alerts for API errors
   - Handle network failures gracefully
   - Show success feedback when interest is toggled
   - Display booking agent message if triggered (use Alert or Toast)

**Constraints:**

- DO NOT implement recommendations sorting yet (that's Phase 4)
- DO NOT add complex animations yet (that's Phase 5)
- DO NOT create multiple user switching - hardcode "user_1" as current user
- DO NOT implement real-time updates

**Code Quality:**

- Ensure all navigation flows work correctly
- Handle edge cases (empty lists, missing data)
- Use proper SwiftUI lifecycle methods
- Avoid force unwrapping, use safe optionals

**Testing:**

- Test full user flow: Feed → Detail → Interest → Profile
- Verify interest state persists across views
- Test booking agent trigger (need 3+ interests)
- Verify profile shows correct interested venues
- Test navigation back and forth

**Deliverable:** Complete user flow working: browse venues, view details, express interest, see profile with saved venues.

---

## PROMPT 4: Recommendations & Booking Agent Integration

**Objective:** Implement recommendation system, integrate booking agent feedback, and enhance venue feed with recommendations.

**Context:** You are continuing the SwiftUI iOS app. This is Phase 4 of a 7-phase project. Core features are complete. Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **Recommendations Integration:**

   - Update `VenueFeedViewModel` to fetch recommendations from GET `/recommendations?user_id={user_id}`
   - Add property: `@Published var recommendations: [RecommendationItem] = []`
   - Method: `func loadRecommendations() async`
   - Call both `loadVenues()` and `loadRecommendations()` on view appear

2. **Enhanced Venue Feed:**

   - Add "Recommended for You" section at top of feed (if recommendations exist)
   - Display recommended venues with score badge showing recommendation score
   - Show reason text (e.g., "2 friends interested") below venue name
   - Use different card style for recommended venues (e.g., border highlight or badge)
   - Sort regular venues by recommendation score if available (merge with recommendations)
   - If venue appears in both lists, show it once with recommendation styling

3. **Recommendation Display:**

   - Create `RecommendedVenueCardView` component:
     - Similar to regular card but with:
       - Score badge (top-right corner, rounded, colored background)
       - Reason text (smaller font, secondary color)
       - Visual distinction (border or background tint)
   - Show score as integer or one decimal place (e.g., "8.5")

4. **Booking Agent Feedback:**

   - When POST `/interests` returns `agent_triggered: true`:
     - Show alert with agent message
     - Display reservation code if provided
     - Use friendly, celebratory messaging
   - Update UI to reflect booking status (optional: add badge to venue card)
   - Store booking information if needed (use UserDefaults or ViewModel state)

5. **Interest State Synchronization:**

   - Ensure when user expresses interest, the interested_count updates across all views
   - Refresh venue feed after interest toggle to get updated counts
   - Update recommendation scores dynamically (they may change after interest)

6. **User Experience Enhancements:**

   - Show loading states while fetching recommendations
   - Handle case when no recommendations available (don't show section)
   - Provide visual feedback when recommendations load
   - Ensure smooth scrolling with recommendations section

7. **Code Organization:**
   - Keep recommendation logic separate and testable
   - Update ViewModels to handle recommendation data properly
   - Ensure API service methods are called efficiently (avoid duplicate calls)

**Constraints:**

- DO NOT modify the recommendation algorithm (it's backend-only)
- DO NOT add complex ML features
- DO NOT implement real-time recommendation updates
- DO NOT add map integration or location features

**Code Quality:**

- Handle empty recommendation lists gracefully
- Ensure proper error handling for recommendation endpoint
- Use efficient data structures for merging venues and recommendations
- Avoid performance issues with large lists

**Testing:**

- Verify recommendations display correctly
- Test that recommendation scores match backend
- Verify booking agent alerts appear correctly
- Test interest toggle updates recommendations
- Ensure feed performance is smooth with recommendations

**Deliverable:** Venue feed enhanced with recommendations, booking agent feedback integrated, and all features working together seamlessly.

---

## PROMPT 5: Polish, Error Handling & Finalization

**Objective:** Add UI polish, comprehensive error handling, loading states, and prepare for submission.

**Context:** You are finalizing the SwiftUI iOS app. This is Phase 5 (final) of a 7-phase project. All core features are complete. Reference the plan document `idea.md` for complete specifications.

**Requirements:**

1. **UI Animations & Polish:**

   - Add subtle animations as specified in plan:
     - Heart button: Scale animation on tap (scale to 0.8, then back to 1.0)
     - Card tap: Subtle scale on press (scale to 0.98)
     - Button press: Scale feedback (0.95 scale)
   - Use SwiftUI `.animation()` modifier with spring or ease-in-out
   - Add smooth transitions for navigation
   - Implement loading shimmer or skeleton views (optional but recommended)

2. **Loading States:**

   - Show loading indicators for all async operations:
     - Venue feed loading
     - Venue detail loading
     - Profile loading
     - Interest toggle (disable button, show spinner)
   - Use `ProgressView()` or custom loading views
   - Ensure loading states don't block UI unnecessarily

3. **Error Handling:**

   - Comprehensive error handling for all API calls:
     - Network errors (no internet, timeout)
     - Server errors (500, 404, etc.)
     - Decoding errors (malformed JSON)
   - Display user-friendly error messages:
     - "Unable to load venues. Please check your connection."
     - "Venue not found."
     - "Something went wrong. Please try again."
   - Provide retry mechanisms for failed requests
   - Use SwiftUI Alert for critical errors
   - Handle edge cases:
     - Empty venue lists
     - Missing user data
     - Invalid venue IDs

4. **Pull-to-Refresh:**

   - Ensure pull-to-refresh works on VenueFeedView
   - Refresh both venues and recommendations
   - Show refresh indicator during pull
   - Update all related data when refreshed

5. **Code Quality & Best Practices:**

   - Review all code for:
     - Proper error handling
     - Memory leaks (check for retain cycles)
     - Performance optimizations
     - Code organization and readability
   - Add comments for complex logic
   - Ensure consistent naming conventions
   - Remove any debug print statements
   - Remove unused code or imports

6. **README.md Documentation:**

   - Create comprehensive README.md in project root:
     - **Project Overview**: Brief description of the app
     - **Architecture**: MVVM pattern explanation, folder structure
     - **Setup Instructions**:
       - Backend: Python version, dependencies, how to run
       - iOS: Xcode version, iOS deployment target, how to build
     - **Dependencies/Prerequisites**: List all required dependencies and prerequisites
     - **API Documentation**: List all 5 endpoints with request/response examples
     - **Features Implemented**: Document Track 3 scope decisions:
       - **Track 1 (iOS Frontend) Features Implemented**: List each implemented feature (venue feed, detail view, interest button, profile, navigation)
       - **Track 2 (Backend) Features Implemented**: List each implemented feature (recommendation engine approach, booking agent)
       - **Features Simplified**: Document which original task features were simplified (e.g., spatial analysis simplified to basic recommendation scoring, social compatibility simplified to friend interest counting, no real-time location data)
       - **Features Deferred**: List features intentionally excluded for MVP scope (e.g., friend invitation system, time-spent tracking, filter interaction tracking, advanced ML models)
       - **Rationale**: Explain scope decisions (72-hour constraint, focus on integration quality over feature breadth)
     - **Design Decisions**: Explain choices (MVVM, Combine, URLSession, etc.)
     - **AI Agent Usage**: Document templates and instances where coding agents were used, which phases used AI assistance
     - **Third-Party Resources**: Cite any third-party resources utilized
     - **Architecture Diagram**: Create ASCII or markdown diagram showing:
       - Frontend structure (Views → ViewModels → Services)
       - Backend structure (Endpoints → Models → Data)
       - Data flow
     - **Testing**: How to test the app
     - **Known Limitations**: Document constraints and simplifications:
       - Technical limitations (in-memory data store, hardcoded user ID, no authentication)
       - Simplified algorithms (basic recommendation scoring vs. advanced ML)
       - Missing Track 2 features (no spatial analysis with real location data, no time-spent tracking, no filter interaction analysis)
       - Missing Track 1 features (no friend invitation system, no social growth mechanisms)
       - Prototype constraints (synthetic data, mock booking agent vs. real API integration)

7. **Backend README Updates:**

   - Ensure backend has proper documentation:
     - How to install dependencies (`pip install -r requirements.txt`)
     - How to run (`uvicorn main:app --reload`)
     - API endpoint documentation
     - Data model explanations

8. **Final Checklist Verification:**

   - Verify all items from plan's success checklist:
     - [ ] Venue feed loads and displays venues
     - [ ] Tapping venue shows detail with interested users
     - [ ] Interest button toggles and persists
     - [ ] Profile shows user's interested venues
     - [ ] Recommendations endpoint returns sorted venues
     - [ ] Booking agent triggers when threshold met
     - [ ] API handles errors gracefully
     - [ ] README includes setup instructions
     - [ ] README documents AI assistance

9. **Submission Preparation:**

   - Ensure code is clean and production-ready
   - Remove any hardcoded test data that shouldn't be there
   - Verify all file paths are correct
   - Ensure project structure matches plan
   - Test on iOS Simulator (latest iOS version)
   - Verify backend runs without errors
   - **Video Walkthrough** (Required Deliverable):
     - Format: Unlisted YouTube link
     - 7 minute restriction
     - Share design inspiration and architectural decisions
     - Showcase why the application is most convenient and useful for users
     - Show venue discovery flow
     - Explain recommendation logic
     - Demonstrate booking agent
   - **GitHub Repository**: Ensure repository is publicly accessible
   - Submit to nico@lunacommunity.ai

10. **Optional Enhancements (if time permits):**
    - Add app icon
    - Add launch screen
    - Improve color scheme consistency
    - Add haptic feedback for button presses
    - Optimize image loading and caching

**Constraints:**

- DO NOT add features not in the original plan
- DO NOT over-engineer error handling (keep it simple but effective)
- DO NOT add complex animations (keep them subtle as specified)

**Code Quality Standards:**

- All code should be production-ready
- No placeholder code or TODOs
- Proper error handling throughout
- Clean, readable, maintainable code
- Follow Swift and Python best practices

**Final Testing:**

- Test complete user flow end-to-end
- Test error scenarios (network off, invalid data, etc.)
- Test on different iOS Simulator devices
- Verify backend API works correctly
- Test booking agent trigger (need 3+ users interested)
- Verify all navigation flows work

**Deliverable:** Polished, production-ready application with comprehensive documentation, ready for submission and video walkthrough.

---

## Usage Instructions

1. **Sequential Execution:** Give these prompts to your CODING AI agent one at a time, in order (1A → 1B → 1C → 2 → 3 → 4 → 5).

2. **Context Preservation:** Before giving each prompt, ensure the AI agent has access to:

   - The `idea.md` plan document
   - All code files created in previous phases
   - Any relevant context about the project

3. **Verification:** After each phase:

   - Complete the verification checklist provided in each prompt
   - Test the deliverables
   - Verify code compiles/runs
   - Check that requirements are met
   - Verify field names and data structures match `idea.md` exactly
   - Fix any issues before proceeding

4. **Customization:** Adjust prompts as needed based on:

   - Your specific AI agent's capabilities
   - Any changes to the plan
   - Technical constraints you encounter

5. **Quality Assurance:** The prompts are designed to prevent hallucination by:
   - Providing exact specifications
   - Referencing the plan document
   - Including constraints and "DO NOT" lists
   - Specifying exact data structures and formats
   - Including verification checkpoints
   - Providing expected output examples

---

## Notes for CODING AI Agent

- Always reference `idea.md` for complete project specifications
- Follow exact JSON structures and API contracts
- Use the specified project structure
- Implement only what's in the plan - avoid feature creep
- Test code after implementation
- Ask for clarification if requirements are ambiguous
- Prioritize working code over perfect code (72-hour constraint)
- **Track 3 Implementation Strategy**: This plan implements a simplified subset of the original task requirements:
  - Original task Track 2 requires "spatial analysis" and "real-time location data" - simplified to basic recommendation scoring
  - Original task Track 2 requires "time spent viewing posts" and "filter interaction frequency" - not implemented in MVP
  - Original task Track 1 requires "social growth features" and "invite friends" - not implemented in MVP
  - Focus is on demonstrating **integration quality** and **end-to-end functionality** over feature completeness
  - README must clearly document which features from original task are implemented vs. simplified vs. deferred
