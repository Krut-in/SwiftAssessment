# Luna - Social Venue Discovery Platform

**A full-stack iOS application for discovering venues with intelligent recommendations and automated booking**

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)

![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017+-blue.svg)

![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green.svg)

![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)

![iOS CI](https://github.com/Krut-in/SwiftAssessment/workflows/iOS%20CI/badge.svg)

![Backend CI](https://github.com/Krut-in/SwiftAssessment/workflows/Backend%20CI/badge.svg)

## 📬 Quick Links

- **GitHub:** [Krut-in/SwiftAssessment](https://github.com/Krut-in/SwiftAssessment)
- **Email:** krutin31@gmail.com
- **Video Walkthrough:** [Watch on YouTube](https://youtu.be/ovel1CUci7M?si=KTdXAMWz1mUxqpWi)
- **Documentation:** [PDF Overview](./resources/Luna_Full-Stack_Venue_Discovery_Platform.pdf)
- **Demo Summary by AI:** [Local Recording](./resources/Luna__A_Full-Stack_App.mp4)

## 🎯 Overview

Luna is a complete venue discovery application demonstrating full-stack iOS development with Swift/SwiftUI and Python/FastAPI. Users can discover venues, express interest, see who else is interested, and receive personalized recommendations. The app features an intelligent action item agent that automatically creates booking suggestions when interest thresholds are met.

**Core Value Proposition:**

- **Zero friction discovery** - Personalized venue feed on launch
- **Social coordination** - See which friends are interested
- **Intelligent automation** - Action items at 4+ interested users
- **Transparent recommendations** - Scored 0-10 with explanations

### Key Highlights

- Native iOS app with SwiftUI and MVVM architecture
- Python FastAPI backend with 5 RESTful endpoints
- Personalized recommendation engine (0-10 scoring scale)
- Automated booking agent (triggers at 3+ interested users)
- Social features with friend activity tracking
- Complete error handling and loading states

---

## ✅ Implemented Features

### Track 1: Frontend (iOS)

### Core Views

- **Venue Feed** - Scrollable list with lazy loading, pull-to-refresh, category badges
- **Venue Detail** - Hero image, interest toggle, list of interested users
- **User Profile** - Avatar, bio, interests, saved venues grid
- **Recommendation Section** - Top 3 personalized suggestions with scores

### Interactions

- **Interest Button** - One-tap heart toggle with spring animation (1.2x scale), haptic feedback
- **Optimistic Updates** - Instant UI feedback before API confirmation
- **Navigation** - Tab-based navigation (Discover, Profile) with custom styling

### Polish

- **Animations** - Scale animations with spring physics on buttons and cards
- **Loading States** - Full-screen and inline loading indicators
- **Error Handling** - User-friendly messages with retry buttons
- **Empty States** - Contextual messaging when no data available

### Track 2: Backend (Python/FastAPI)

### API Endpoints

1. `GET /venues` - List all venues with interested counts
2. `GET /venues/{id}` - Detailed venue info with interested users
3. `POST /interests` - Express/remove interest (toggle behavior)
4. `GET /users/{id}` - User profile with interested venues
5. `GET /recommendations?user_id={id}` - Personalized recommendations

### Recommendation Engine

**Multi-Factor Scoring Algorithm:**

```
score = (popularity * 0.4) + (category_match * 0.3) + (social_signal * 0.3) * 10
```

- **Popularity (40%)** - Based on total interested user count
- **Category Match (30%)** - Alignment with user's interests
- **Social Signal (30%)** - Friends interested in the venue

**Output:** Sorted recommendations (0-10 scale) with reasoning text

### Booking Agent

- **Trigger Condition:** 3+ users express interest in same venue
- **Behavior:** Automatically creates mock reservation
- **Response:** Date (tomorrow), time (7:00 PM), party size, interested users
- **Notification:** Global alert shown to all users

---

## 🏗️ Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     iOS App (SwiftUI)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐           │
│  │  Views   │─────▶│ViewModels│─────▶│ Services │           │
│  │          │◀─────│          │◀─────│          │           │
│  └──────────┘      └──────────┘      └──────────┘           │
│       │                  │                  │               │
│       │                  │                  │               │
│  ┌────▼────┐      ┌──────▼──────┐    ┌────▼────┐            │
│  │ Models  │      │  AppState   │    │   API   │            │
│  │         │      │ (Singleton) │    │ Models  │            │
│  └─────────┘      └─────────────┘    └─────────┘            │
│                                                             │
└────────────────────────────────┼────────────────────────────┘
                                 │
                         HTTP/JSON (REST)
                                 │
┌────────────────────────────────▼────────────────────────────┐
│              Backend (Python/FastAPI)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐           ┌──────────────┐                │
│  │API Endpoints │──────────▶│Business Logic│                │
│  │  (main.py)   │◀──────────│(Recommend)   │                │
│  └──────────────┘           └──────────────┘                │ 
│         │                           │                       │
│  ┌──────▼────────┐          ┌──────▼──────┐                 │
│  │Pydantic Models│          │ Data Store  │                 │
│  │               │          │(In-Memory)  │                 │
│  └───────────────┘          └─────────────┘                 │
│                                    │                        │
│                             ┌──────▼──────┐                 │
│                             │Booking Agent│                 │
│                             │  (agent.py) │                 │
│                             └─────────────┘                 │
└─────────────────────────────────────────────────────────────┘

```

### MVVM Pattern (iOS)

**Views** → User interface components (SwiftUI)

- `VenueFeedView` - Main discovery feed
- `VenueDetailView` - Detailed venue page
- `ProfileView` - User profile
- `VenueCardView` - Reusable venue component

**ViewModels** → Business logic (@MainActor ObservableObject)

- `VenueFeedViewModel` - Feed state management
- `VenueDetailViewModel` - Detail state and interest toggling
- `ProfileViewModel` - Profile data loading

**Services** → API communication (Protocol-based)

- `APIService` - REST API client with error handling
- `AppState` - Global state singleton

**Models** → Data structures

- `Venue`, `User`, `Interest`, `RecommendationItem`

### Interest Toggle Flow

```
1. User taps heart
   └─▶ VenueCardView: Animate (scale 1.2x), haptic feedback

2. Optimistic update
   └─▶ Local state: Update interest count immediately

3. API call
   └─▶ AppState.toggleInterest(venueId)
       └─▶ APIService.expressInterest(userId, venueId)

4. Backend processing
   └─▶ POST /interests
       ├─▶ Update interest dictionary
       ├─▶ Check threshold (3+ users?)
       └─▶ If yes: Trigger booking agent

5. Response handling
   └─▶ Success: Keep optimistic update
   └─▶ Booking: Show global alert
   └─▶ Error: Revert optimistic update

6. UI refresh
   └─▶ Reload recommendations
   └─▶ Update interested users list

```

---

## 🚀 Setup Instructions

### Prerequisites

**Backend:**

- Python 3.10 or higher
- pip package manager

**iOS:**

- macOS with Xcode 15.0+
- iOS 17.0+ Simulator or device
- Swift 5.9+

### Backend Setup

1. **Navigate to backend directory:**
    
    ```bash
    cd Luna-Backend
    
    ```
    
2. **Run setup script:**
    
    ```bash
    chmod +x setup.sh
    ./setup.sh
    
    ```
    
    This creates a virtual environment and installs dependencies.
    
3. **Activate virtual environment:**
    
    ```bash
    source venv/bin/activate
    
    ```
    
4. **Start the server:**
    
    ```bash
    uvicorn main:app --reload --port 8000
    
    ```
    
5. **Verify server:**
    - API Root: [http://localhost:8000](http://localhost:8000/)
    - Swagger Docs: http://localhost:8000/docs
    - Test: `curl <http://localhost:8000/venues`>

### iOS Setup

1. **Open Xcode project:**
    
    ```bash
    cd Luna-iOS
    open Luna.xcodeproj
    
    ```
    
2. **Select simulator:**
    - Choose iPhone 15 Pro (recommended)
3. **Build and run:**
    - Press `Cmd+R` or click Play button
    - Wait ~30 seconds for first build
4. **Verify connection:**
    - App should load venue feed automatically
    - If error appears, ensure backend is running

### Quick Test

```bash
# Backend: List venues
curl <http://localhost:8000/venues> | python3 -m json.tool

# Backend: Get recommendations
curl "<http://localhost:8000/recommendations?user_id=user_1>" | python3 -m json.tool

# Backend: Express interest
curl -X POST <http://localhost:8000/interests> \\
  -H "Content-Type: application/json" \\
  -d '{"user_id":"user_1","venue_id":"venue_1"}'

```

---

## 🛠️ Technology Stack

### iOS App (No External Dependencies)

- **SwiftUI** (iOS 17.0+) - User interface framework
- **Combine** - Reactive data flow
- **Foundation** - Core utilities and networking
- **URLSession** - Native networking (async/await)

**Why no external packages?**

- Lightweight and fast
- No dependency management complexity
- Leverages Apple's robust frameworks

### Backend

- **FastAPI** (0.104.1) - Modern async web framework
- **Uvicorn** (0.24.0) - ASGI server with hot reload
- **Pydantic** (2.5.0) - Data validation

**Install:**

```bash
pip install -r Luna-Backend/requirements.txt

```

---

## 🎨 Design Decisions

### MVVM Architecture (iOS)

**Chosen:** MVVM over MVC/VIPER/Redux. **Why:** Separation of concerns, testability, works seamlessly with SwiftUI's @Published. **Trade-off:** More files, better maintainability.

### FastAPI (Backend)

**Chosen:** FastAPI over Django/Flask. **Why:** Built-in async, type safety with Pydantic, auto-generated docs, modern Python. **Trade-off:** Newer framework, excellent docs.

### SQLite (Database)

**Chosen:** SQLite with SQLAlchemy async ORM over PostgreSQL/MongoDB. **Why:** No separate server, file-based persistence, easy migration path. **Trade-off:** Single-server only, perfect for prototype.

### Zero iOS Dependencies

**Chosen:** Native frameworks only (SwiftUI, Combine, Foundation) over Alamofire/Kingfisher. **Why:** Lightweight, simple, Apple-supported, URLSession sufficient. **Trade-off:** More boilerplate, simpler overall.

### Hardcoded Authentication

**Chosen:** Hardcoded `user_1` for demo. **Why:** Focus on core features, simplifies demo, faster testing. **Trade-off:** Not production-ready, sufficient for prototype.

## 📊 Project Statistics

| Metric | Value |
| --- | --- |
| Development Time | 72 hours (3 days) |
| iOS Views | 5 screens + 6 components |
| API Endpoints | 8 fully functional |
| Database Models | 6 SQLAlchemy models |
| Test Data | 8 users, 12 venues, 28 friendships |
| Dependencies (iOS) | 0 (native only) |
| Dependencies (Backend) | 6 (FastAPI, Uvicorn, Pydantic, SQLAlchemy, etc.) |

---

## 📄 License

This project is a portfolio/assessment application demonstrating full-stack iOS development skills. It is not licensed for commercial use.

**Built for:** Luna Community Take-Home Assessment

**Purpose:** Showcase modern iOS development with SwiftUI, FastAPI, MVVM architecture, and production-ready code quality

---

## 🙏 Acknowledgments

**Built with ❤️ by Krutin Rathod**

**Tech Stack:** Swift 5.9 • SwiftUI • Python 3.10 • FastAPI • SQLAlchemy • SQLite

**Status:** ✅ Production-Ready • Zero Critical Bugs • Fully Documented

**Special Thanks:**

- GitHub Copilot and Claude AI for accelerating development
- Luna Community for the thoughtful assessment prompt
- Apple for world-class development tools

---

🎉 **Ready to explore venues? Start the backend server and launch the app!**