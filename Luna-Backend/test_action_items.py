#!/usr/bin/env python3
"""
Quick test script to verify action items functionality.
Tests the new action item creation and management endpoints.
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_action_items():
    print("🧪 Testing Action Items Feature")
    print("=" * 50)
    
    # Test 1: Express interest for 4 users to trigger action item
    print("\n1️⃣ Testing action item creation with 4 users...")
    users = ["user_1", "user_2", "user_3", "user_4"]
    venue_id = "venue_1"
    
    for user in users:
        response = requests.post(
            f"{BASE_URL}/interests",
            json={"user_id": user, "venue_id": venue_id}
        )
        print(f"   User {user} expressed interest: {response.status_code}")
        
        if user == users[-1]:  # Last user should trigger action item
            data = response.json()
            if data.get("action_item"):
                print(f"   ✅ Action item created!")
                print(f"   📋 Description: {data['action_item'].get('description')}")
                print(f"   🔑 Action code: {data['action_item'].get('action_code')}")
                action_item_id = data['action_item'].get('action_item_id')
            else:
                print(f"   ❌ No action item created (threshold not met)")
                action_item_id = None
    
    # Test 2: Check user profile for action items
    print("\n2️⃣ Testing user profile action items...")
    response = requests.get(f"{BASE_URL}/users/user_1")
    data = response.json()
    action_items = data.get("action_items", [])
    print(f"   Found {len(action_items)} action item(s) in profile")
    
    if action_items:
        item = action_items[0]
        print(f"   📋 Action item: {item.get('description')}")
        print(f"   🏢 Venue: {item.get('venue', {}).get('name')}")
        print(f"   👥 Interested: {len(item.get('interested_user_ids', []))} users")
    
    # Test 3: Complete action item (if exists)
    if action_item_id:
        print("\n3️⃣ Testing action item completion...")
        response = requests.post(
            f"{BASE_URL}/action-items/{action_item_id}/complete",
            json={"user_id": "user_1"}
        )
        if response.status_code == 200:
            print(f"   ✅ Action item marked as completed")
        else:
            print(f"   ❌ Failed to complete: {response.status_code}")
    
    # Test 4: Remove interests to clean up
    print("\n4️⃣ Cleaning up test data...")
    for user in users:
        response = requests.post(
            f"{BASE_URL}/interests",
            json={"user_id": user, "venue_id": venue_id}
        )
        print(f"   User {user} removed interest: {response.status_code}")
    
    print("\n" + "=" * 50)
    print("✅ Action Items test completed!")

if __name__ == "__main__":
    try:
        # Check if server is running
        response = requests.get(BASE_URL)
        if response.status_code == 200:
            test_action_items()
        else:
            print("❌ Server not responding correctly")
    except requests.exceptions.ConnectionError:
        print("❌ Backend server not running at localhost:8000")
        print("   Start the server with: cd Luna-Backend && uvicorn main:app --reload --port 8000")
