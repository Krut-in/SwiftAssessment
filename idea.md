# Luna Take-Home Assessment — Minimal 72-Hour Full Stack Plan

---

## Project Scope Statement

**What We're Building:**

A minimal but polished full-stack venue discovery prototype demonstrating:

- Users can browse venues
- Users can see who else is interested in venues
- Users can express interest in venues
- A simple recommendation system suggests relevant venues
- A mock booking agent simulates automated reservations
- Clean MVVM architecture with working API integration

**What We're NOT Building:**

Complex social networks, messaging, real-time updates, advanced ML, maps, viral growth loops, extensive animations, or production-ready features.

**Success Criteria:**

Demonstrate full-stack competency with clean code, working integration, and thoughtful design decisions within 72 hours.

---

## Core Feature Set (Golden Path Only)

### Frontend Features (SwiftUI)

1. **Venue Feed** — Scrollable list of venue cards
2. **Venue Detail** — Full venue info with interested users list
3. **Interest Button** — Tap to save/unsave venue
4. **User Profile** — View saved venues
5. **Basic Navigation** — Tab bar (Discover, Profile)

### Backend Features (FastAPI)

1. **Data Models** — User, Venue, Interest
2. **5 API Endpoints** — Venues list, venue detail, express interest, user profile, recommendations
3. **Simple Recommendation Logic** — 3 weighted factors (popularity, category match, friend interest)
4. **Mock Booking Agent** — Simulates automated reservation when interest threshold met

---

## Technical Architecture

### Frontend Stack

- **SwiftUI** — UI framework
- **MVVM** — Architecture pattern
- **Combine** — Reactive data flow
- **URLSession** — API calls

### Backend Stack

- **FastAPI** — Python web framework
- **Pydantic** — Data validation
- **SQLite** — In-memory database
- **Simple dictionary-based data store** — No ORM needed

### Project Structure

```
Luna-iOS/
├── Models/
│   ├── User.swift
│   ├── Venue.swift
│   └── Interest.swift
├── ViewModels/
│   ├── VenueFeedViewModel.swift
│   └── VenueDetailViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── VenueFeedView.swift
│   ├── VenueDetailView.swift
│   └── ProfileView.swift
└── Services/
    └── APIService.swift

Luna-Backend/
├── main.py
├── models.py
├── data.py
└── agent.py

```

---

## Simplified Data Models

### User

```json
{
  "id": "user_1",
  "name": "Alex Chen",
  "avatar": "<https://i.pravatar.cc/150?img=1>",
  "bio": "Coffee enthusiast",
  "interests": ["coffee", "food"]
}

```

### Venue

```json
{
  "id": "venue_1",
  "name": "Blue Bottle Coffee",
  "category": "Coffee Shop",
  "description": "Artisan coffee in minimalist space",
  "image": "<https://picsum.photos/400/300?random=1>",
  "address": "450 W 15th St, NYC"
}

```

### Interest

```json
{
  "user_id": "user_1",
  "venue_id": "venue_1",
  "timestamp": "2024-11-20T10:30:00"
}

```

---

## Minimal Synthetic Data

### Users (8 total)

1. Alex Chen — Coffee lover
2. Jordan Kim — Foodie
3. Sam Rivera — Social butterfly
4. Taylor Lee — Culture seeker
5. Morgan Park — Bar enthusiast
6. Casey Wu — Brunch fan
7. Riley Brooks — Museum goer
8. Quinn Davis — Casual diner

### Venues (12 total)

**Coffee (3):** Blue Bottle, Stumptown, La Colombe

**Restaurants (3):** The Smith, Joe's Pizza, Sushi Place

**Bars (3):** Dead Rabbit, Employees Only, Rooftop Bar

**Cultural (3):** MoMA, Whitney Museum, Comedy Cellar

### Interest Relationships (25 pre-populated)

- Each user interested in 2-4 venues
- Some overlap to create social proof
- Example: Alex, Jordan, Sam all interested in Blue Bottle

---

## API Specification (5 Endpoints)

### 1. GET `/venues`

Returns list of all venues.

**Response:**

```json
{
  "venues": [
    {
      "id": "venue_1",
      "name": "Blue Bottle Coffee",
      "category": "Coffee Shop",
      "image": "<https://picsum.photos/400/300?random=1>",
      "interested_count": 3
    }
  ]
}
```

### 2. GET `/venues/{venue_id}`

Returns venue details with list of interested users.

**Response:**

```json
{
  "venue": { /* venue object */ },
  "interested_users": [
    {
      "id": "user_1",
      "name": "Alex Chen",
      "avatar": "<https://i.pravatar.cc/150?img=1>"
    }
  ]
}

```

### 3. POST `/interests`

User expresses interest in venue.

**Request:**

```json
{
  "user_id": "user_1",
  "venue_id": "venue_1"
}

```

**Response:**

```json
{
  "success": true,
  "agent_triggered": true,
  "message": "Mock booking agent activated: Reservation simulated for Blue Bottle Coffee"
}

```

### 4. GET `/users/{user_id}`

Returns user profile with their interested venues.

**Response:**

```json
{
  "user": { /* user object */ },
  "interested_venues": [ /* array of venue objects */ ]
}

```

### 5. GET `/recommendations?user_id={user_id}`

Returns recommended venues for user.

**Response:**

```json
{
  "recommendations": [
    {
      "venue": { /* venue object */ },
      "score": 8.5,
      "reason": "2 friends interested"
    }
  ]
}

```

---

## Simple Recommendation Algorithm

```python
def calculate_recommendation_score(user, venue):
    score = 0

    # Factor 1: Popularity (0-3 points)
    score += min(venue.interested_count / 3, 3)

    # Factor 2: Category match (0-4 points)
    if venue.category.lower() in user.interests:
        score += 4

    # Factor 3: Friend interest (0-3 points)
    friends_interested = count_friends_interested(user, venue)
    score += min(friends_interested, 3)

    return score  # Max score: 10

```

**That's it.** No time decay, no spatial analysis, no ML. Just 3 simple rules.

---

## Mock Booking Agent (Required Feature)

**Purpose:** Satisfy Track 2 requirement for automated agents.

**Implementation:**

```python
def booking_agent(venue_id, user_count):
    """
    Simulates automated booking when interest threshold is reached.
    """
    threshold = 3  # Trigger when 3+ users interested

    if user_count >= threshold:
        return {
            "agent_triggered": True,
            "action": "reservation_simulated",
            "venue_id": venue_id,
            "message": f"Mock booking agent: Reserved table for {user_count} at {venue.name}",
            "reservation_code": f"LUNA-{venue_id}-{random.randint(1000, 9999)}"
        }
    return {"agent_triggered": False}

```

**When It Triggers:**

Automatically called after POST `/interests` if interested user count >= 3.

**What It Does:**

Returns a mock reservation confirmation. In README, explain this would integrate with OpenTable/Resy APIs in production.

---

## 72-Hour Development Timeline

### Day 1: Foundation (12 hours)

**Morning (4 hours)**

- Set up FastAPI project
- Create data models (User, Venue, Interest)
- Write synthetic data generator
- Implement 5 API endpoints
- Test with curl/Postman

**Afternoon (4 hours)**

- Initialize SwiftUI project
- Set up MVVM structure
- Create Swift models matching API
- Build APIService with URLSession
- Test API connection

**Evening (4 hours)**

- Build VenueFeedView with list
- Create VenueCardView component
- Connect to GET `/venues` endpoint
- Display venues from API
- Add basic styling

**Deliverable:** Working venue feed pulling from backend

---

### Day 2: Core Features (12 hours)

**Morning (4 hours)**

- Build VenueDetailView
- Display interested users list
- Add interest button
- Connect to POST `/interests`
- Implement optimistic UI updates

**Afternoon (4 hours)**

- Build ProfileView
- Display user's interested venues
- Connect to GET `/users/{id}`
- Add tab navigation (Discover, Profile)
- Test full user flow

**Evening (4 hours)**

- Implement recommendation endpoint logic
- Add booking agent to POST `/interests`
- Sort feed by recommendation scores
- Add "Recommended for You" section
- Polish UI and fix bugs

**Deliverable:** Complete golden path working end-to-end

---

### Day 3: Polish & Submission (8 hours)

**Morning (3 hours)**

- Add subtle animations (button press, card tap)
- Implement pull-to-refresh
- Add loading states
- Handle error cases
- Final bug fixes

**Afternoon (3 hours)**

- Write comprehensive [README.md](http://readme.md/)
- Create architecture diagram
- Document agent usage
- Document API endpoints
- Add setup instructions

**Evening (2 hours)**

- Record 7-minute video walkthrough
- Show venue discovery flow
- Explain recommendation logic
- Demonstrate booking agent
- Upload to YouTube (unlisted)
- Submit to [nico@lunacommunity.ai](mailto:nico@lunacommunity.ai)

**Deliverable:** Polished submission package

---

## Views Specification

### 1. Venue Feed View

**Layout:**

- Navigation title: "Discover"
- Vertical scroll list
- Venue cards with:
    - Image (aspect ratio 4:3)
    - Name (bold, 18pt)
    - Category badge
    - "X people interested" text
    - Heart button (outline/filled states)

**Animations:**

- Heart button: Scale on tap
- Card: Subtle scale on press

---

### 2. Venue Detail View

**Layout:**

- Full-width hero image
- Back button (top-left)
- Scrollable content:
    - Venue name (large title)
    - Category + address
    - "X people interested"
    - Large "I'm Interested" button
    - "People Who Want to Go" section
        - Horizontal scroll
        - User avatar + name
    - "About" section with description

**Animations:**

- Button: Scale feedback
- Sheet presentation for detail

---

### 3. Profile View

**Layout:**

- User avatar (centered, large)
- User name
- "X places saved" count
- Grid of interested venue cards (smaller)
- Tap card → navigate to detail

---

## Success Checklist

- [ ]  Venue feed loads and displays venues
- [ ]  Tapping venue shows detail with interested users
- [ ]  Interest button toggles and persists
- [ ]  Profile shows user's interested venues
- [ ]  Recommendations endpoint returns sorted venues
- [ ]  Booking agent triggers when threshold met
- [ ]  API handles errors gracefully
- [ ]  README includes setup instructions
- [ ]  README documents AI assistance