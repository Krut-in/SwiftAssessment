# Luna Backend API - Quick Start Guide

## 🚀 Quick Start

### Installation

1. **Create and activate virtual environment:**
   ```bash
   cd Luna-Backend
   python3 -m venv venv
   source venv/bin/activate  # On macOS/Linux
   # OR on Windows: venv\Scripts\activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

### Start Server
```bash
uvicorn main:app --reload --port 8000
```

**Server will be available at:**
- API Root: http://localhost:8000
- Interactive Docs: http://localhost:8000/docs
- OpenAPI JSON: http://localhost:8000/openapi.json

## 🧪 Test All Endpoints

### Test Script
For automated testing, run:
```bash
./test_booking_agent.sh
```

### Manual Testing

```bash
# 1. List all venues (GET /venues)
curl http://localhost:8000/venues | python3 -m json.tool

# 2. Get venue detail (GET /venues/{id})
curl http://localhost:8000/venues/venue_1 | python3 -m json.tool

# 3. Express interest (POST /interests)
curl -X POST http://localhost:8000/interests \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user_1","venue_id":"venue_5"}' | python3 -m json.tool

# 4. Get user profile (GET /users/{id})
curl http://localhost:8000/users/user_1 | python3 -m json.tool

# 5. Get recommendations (GET /recommendations?user_id={id})
curl "http://localhost:8000/recommendations?user_id=user_1" | python3 -m json.tool
```

## 📖 API Documentation

**Interactive Swagger UI:**
Browse interactive docs at: http://localhost:8000/docs

**Features:**
- Try out endpoints directly in browser
- View request/response schemas
- See all available endpoints
- Automatic validation

## 📂 Project Structure
```
Luna-Backend/
├── main.py              # All 5 API endpoints + recommendation logic
├── models.py            # Pydantic models (User, Venue, Interest)
├── data.py              # Synthetic test data (8 users, 12 venues)
├── agent.py             # Mock booking agent
├── requirements.txt     # Python dependencies (FastAPI, Uvicorn, Pydantic)
├── setup.sh             # Automated setup script
├── test_booking_agent.sh # Booking agent test script
├── API_TESTING.md       # Complete testing guide
└── README.md            # This file
```

## 🤖 Booking Agent

The mock booking agent automatically triggers when 3+ users express interest in a venue.

### Agent Behavior
- **Threshold:** 3 users interested
- **Action:** Simulates automated table reservation
- **Response:** Returns reservation code in format `LUNA-{venue_id}-{4_digits}`

### Example Response (Agent Triggered)
```json
{
  "success": true,
  "agent_triggered": true,
  "message": "Mock booking agent: Reserved table for 3 at Blue Bottle Coffee",
  "reservation_code": "LUNA-venue_1-4521"
}
```

### Example Response (Below Threshold)
```json
{
  "success": true,
  "agent_triggered": false,
  "message": "Interest recorded successfully",
  "reservation_code": null
}
```

### Production Integration
This is a **mock implementation** for demonstration purposes. In production, this would integrate with:
- **OpenTable API** (https://www.opentable.com/developers) - Real-time table availability and reservations
- **Resy API** (https://resy.com/api) - Restaurant booking platform integration
- Real-time notifications to users when reservations are confirmed
- Payment processing and confirmation emails

---

## ✅ Implementation Status

**All Features Complete:**
- ✅ 5 REST API endpoints implemented
- ✅ Recommendation engine with 3-factor scoring
- ✅ Mock booking agent with threshold triggering
- ✅ Pydantic validation on all inputs
- ✅ Comprehensive error handling
- ✅ Auto-generated API documentation
- ✅ CORS enabled for web integration

**Production-Ready Features:**
- ✅ User-friendly error messages
- ✅ Input validation with Pydantic
- ✅ Request/response logging
- ✅ Proper HTTP status codes
- ✅ Type hints throughout

---

## 🔧 Dependencies

```txt
fastapi==0.104.1        # Modern web framework with auto docs
uvicorn[standard]==0.24.0  # ASGI server with hot reload
pydantic==2.5.0         # Data validation and serialization
```

**Install:**
```bash
pip install -r requirements.txt
```

---

## 📊 Data Models

**Users (8 total):**
- Alex Chen, Jordan Kim, Sam Rivera, Taylor Lee
- Morgan Park, Casey Wu, Riley Brooks, Quinn Davis

**Venues (12 total):**
- 3 Coffee Shops (Blue Bottle, Stumptown, La Colombe)
- 3 Restaurants (The Spotted Pig, Carbone, ABC Kitchen)
- 3 Bars (Dead Rabbit, Employees Only, Angel's Share)
- 3 Museums (MoMA, Met Museum, Guggenheim)

**Interests:**
- 25+ pre-seeded interest relationships
- Dynamically updated via API

---

## 🚀 Next Steps

1. **Test the API**: Visit http://localhost:8000/docs
2. **Run iOS App**: Open `name.xcodeproj` and press Cmd+R
3. **Test Integration**: Express interest from iOS app, watch backend logs

---

**Built with Python 3.10+ • FastAPI • Pydantic**
