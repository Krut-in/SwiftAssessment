# Quick Start Guide - Luna Backend

## Start Server
```bash
cd Luna-Backend
source venv/bin/activate
uvicorn main:app --reload --port 8000
```

## Test All Endpoints
```bash
# 1. List all venues
curl http://127.0.0.1:8000/venues | python3 -m json.tool

# 2. Get venue detail
curl http://127.0.0.1:8000/venues/venue_1 | python3 -m json.tool

# 3. Express interest
curl -X POST http://127.0.0.1:8000/interests \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user_1","venue_id":"venue_5"}' | python3 -m json.tool

# 4. Get user profile
curl http://127.0.0.1:8000/users/user_1 | python3 -m json.tool

# 5. Get recommendations
curl "http://127.0.0.1:8000/recommendations?user_id=user_1" | python3 -m json.tool
```

## API Documentation
Browse interactive docs at: http://127.0.0.1:8000/docs

## Project Structure
```
Luna-Backend/
├── main.py              # All 5 API endpoints + recommendation logic
├── models.py            # Pydantic models (User, Venue, Interest)
├── data.py              # Synthetic test data (8 users, 12 venues)
├── agent.py             # Mock booking agent (Phase 1C)
├── requirements.txt     # Python dependencies
├── API_TESTING.md       # Complete testing guide
└── PHASE_1B_SUMMARY.md  # Implementation verification
```

## Booking Agent (Phase 1C)
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

## Phase 1C Status: ✅ COMPLETE
- Mock booking agent implemented in `agent.py`
- Agent integrated with POST `/interests` endpoint
- Threshold-based triggering (3+ users)
- Reservation code generation working
- All 5 endpoints still functioning correctly
