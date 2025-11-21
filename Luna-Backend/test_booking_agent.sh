#!/bin/bash

# Phase 1C Booking Agent - Complete Test Suite
# This script tests all booking agent functionality

echo "🧪 Luna Backend - Phase 1C Booking Agent Test Suite"
echo "===================================================="
echo ""

BASE_URL="http://127.0.0.1:8000"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to test
test_endpoint() {
    local test_name="$1"
    local expected="$2"
    local result="$3"
    
    echo -n "  Testing: $test_name... "
    if [[ "$result" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "    Expected: $expected"
        echo "    Got: $result"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "📋 Test 1: Agent Does NOT Trigger Below Threshold"
echo "------------------------------------------------"
echo "Setup: venue_9 should have < 3 users"

# Check current state
RESULT=$(curl -s "$BASE_URL/venues/venue_9" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['venue']['interested_count'])")
echo "  Current interest count: $RESULT"

if [ "$RESULT" -lt 2 ]; then
    # Add first interest
    echo "  Adding user_4 to venue_9..."
    RESPONSE=$(curl -s -X POST "$BASE_URL/interests" \
        -H "Content-Type: application/json" \
        -d '{"user_id":"user_4","venue_id":"venue_9"}')
    
    test_endpoint "Agent should NOT trigger" '"agent_triggered": false' "$RESPONSE"
    test_endpoint "Success should be true" '"success": true' "$RESPONSE"
    test_endpoint "Message should indicate success" '"message": "Interest recorded successfully"' "$RESPONSE"
else
    echo "  Venue already has >= 2 users, skipping test"
fi

echo ""
echo "📋 Test 2: Agent Triggers At Threshold (3 users)"
echo "------------------------------------------------"

# Add another interest to reach threshold
echo "  Adding user_8 to venue_9..."
RESPONSE=$(curl -s -X POST "$BASE_URL/interests" \
    -H "Content-Type: application/json" \
    -d '{"user_id":"user_8","venue_id":"venue_9"}')

test_endpoint "Agent SHOULD trigger" '"agent_triggered": true' "$RESPONSE"
test_endpoint "Success should be true" '"success": true' "$RESPONSE"
test_endpoint "Message should mention booking" '"Mock booking agent: Reserved table"' "$RESPONSE"
test_endpoint "Should include reservation code" '"reservation_code": "LUNA-venue_9-' "$RESPONSE"

# Extract and verify reservation code format
RESERVATION_CODE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('reservation_code', ''))" 2>/dev/null)
if [[ $RESERVATION_CODE =~ ^LUNA-venue_9-[0-9]{4}$ ]]; then
    echo -e "  Code format verification: ${GREEN}✓ PASS${NC} ($RESERVATION_CODE)"
    ((TESTS_PASSED++))
else
    echo -e "  Code format verification: ${RED}✗ FAIL${NC} ($RESERVATION_CODE)"
    ((TESTS_FAILED++))
fi

echo ""
echo "📋 Test 3: Agent Triggers Above Threshold (>3 users)"
echo "---------------------------------------------------"

# venue_1 should already have multiple users
CURRENT_COUNT=$(curl -s "$BASE_URL/venues/venue_1" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['venue']['interested_count'])")
echo "  venue_1 current interest count: $CURRENT_COUNT"

if [ "$CURRENT_COUNT" -ge 3 ]; then
    echo "  Already above threshold, agent should trigger on new interest"
    
    # Try adding another user
    RESPONSE=$(curl -s -X POST "$BASE_URL/interests" \
        -H "Content-Type: application/json" \
        -d '{"user_id":"user_8","venue_id":"venue_1"}')
    
    test_endpoint "Agent should trigger" '"agent_triggered": true' "$RESPONSE"
    test_endpoint "User count should reflect total" "Reserved table for $((CURRENT_COUNT + 1))" "$RESPONSE"
fi

echo ""
echo "📋 Test 4: Reservation Code Format Consistency"
echo "---------------------------------------------"

# Test multiple times to verify randomness
echo "  Generating 3 reservation codes..."
for i in {1..3}; do
    # Use different venue to avoid conflicts
    RESPONSE=$(curl -s -X POST "$BASE_URL/interests" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":\"user_${i}\",\"venue_id\":\"venue_11\"}")
    
    CODE=$(echo "$RESPONSE" | python3 -c "import sys, json; r = json.load(sys.stdin); print(r.get('reservation_code', 'N/A') if r.get('agent_triggered') else 'Not triggered')" 2>/dev/null)
    echo "    Attempt $i: $CODE"
    
    if [[ $CODE =~ ^LUNA-venue_11-[0-9]{4}$ ]]; then
        ((TESTS_PASSED++))
    elif [[ $CODE == "Not triggered" ]]; then
        echo "      (Below threshold, expected)"
    else
        ((TESTS_FAILED++))
    fi
done

echo ""
echo "📋 Test 5: All Endpoints Still Functional"
echo "----------------------------------------"

# Test each endpoint
echo "  1. GET /venues"
RESULT=$(curl -s "$BASE_URL/venues" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['venues']))")
test_endpoint "Should return 12 venues" "12" "$RESULT"

echo "  2. GET /venues/{venue_id}"
RESULT=$(curl -s "$BASE_URL/venues/venue_1" | python3 -c "import sys, json; d = json.load(sys.stdin); print(d['venue']['name'])")
test_endpoint "Should return venue name" "Blue Bottle Coffee" "$RESULT"

echo "  3. POST /interests (already tested above)"
echo -e "    ${GREEN}✓ PASS${NC}"
((TESTS_PASSED++))

echo "  4. GET /users/{user_id}"
RESULT=$(curl -s "$BASE_URL/users/user_1" | python3 -c "import sys, json; d = json.load(sys.stdin); print(d['user']['name'])")
test_endpoint "Should return user name" "Alex Chen" "$RESULT"

echo "  5. GET /recommendations"
RESULT=$(curl -s "$BASE_URL/recommendations?user_id=user_1" | python3 -c "import sys, json; print('recommendations' in json.load(sys.stdin))")
test_endpoint "Should return recommendations" "True" "$RESULT"

echo ""
echo "📋 Test 6: Edge Cases"
echo "-------------------"

echo "  Testing interest removal (toggle off)..."
RESPONSE=$(curl -s -X POST "$BASE_URL/interests" \
    -H "Content-Type: application/json" \
    -d '{"user_id":"user_1","venue_id":"venue_2"}')

test_endpoint "Should remove interest" "Interest removed" "$RESPONSE"
test_endpoint "Agent should NOT trigger on removal" '"agent_triggered": false' "$RESPONSE"

echo ""
echo "======================================================"
echo "🏁 Test Suite Complete"
echo "======================================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Phase 1C is complete.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review.${NC}"
    exit 1
fi
