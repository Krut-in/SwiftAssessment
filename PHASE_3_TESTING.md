# Phase 3: Testing Guide

## Prerequisites

1. **Backend Server Running:**
   ```bash
   cd Luna-Backend
   source venv/bin/activate
   uvicorn main:app --reload --port 8000
   ```
   
   Server should be running at: http://127.0.0.1:8000

2. **Xcode Project Open:**
   - Project: `name.xcodeproj`
   - Scheme: `name`

## Testing Checklist

### Backend Verification

Test all endpoints are working:

```bash
# 1. Test venues list
curl http://127.0.0.1:8000/venues

# 2. Test venue detail
curl http://127.0.0.1:8000/venues/venue_1

# 3. Test user profile
curl http://127.0.0.1:8000/users/user_1

# 4. Test recommendations
curl http://127.0.0.1:8000/recommendations?user_id=user_1

# 5. Test interest toggle
curl -X POST http://127.0.0.1:8000/interests \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user_1", "venue_id": "venue_1"}'
```

### iOS App Testing

#### 1. Initial Launch
- [ ] App launches without crashes
- [ ] Venue feed loads and displays venues
- [ ] Images load correctly
- [ ] Category badges show correct colors

#### 2. Venue Feed (Discover Tab)
- [ ] Scroll through venue list
- [ ] Tap heart button on any venue
- [ ] Heart fills with red color and animates
- [ ] Heart button toggles on/off correctly
- [ ] Pull down to refresh
- [ ] Loading indicator shows during refresh

#### 3. Venue Detail View
- [ ] Tap any venue card to navigate
- [ ] Hero image displays at top
- [ ] Custom back button appears (top-left)
- [ ] Venue name, category, address display
- [ ] Interested count shows correct number
- [ ] "I'm Interested" button shows correct state
- [ ] Tap interest button - see loading spinner
- [ ] Button changes from "I'm Interested" to "Interested"
- [ ] Button color changes from blue to red
- [ ] "People Who Want to Go" section appears
- [ ] User avatars scroll horizontally
- [ ] About section shows description
- [ ] Tap back button to return

#### 4. Booking Agent Testing
**Important:** Need 3+ users interested to trigger agent

To test booking agent:
1. Use curl to add interests for multiple users:
   ```bash
   curl -X POST http://127.0.0.1:8000/interests \
     -H "Content-Type: application/json" \
     -d '{"user_id": "user_2", "venue_id": "venue_10"}'
   
   curl -X POST http://127.0.0.1:8000/interests \
     -H "Content-Type: application/json" \
     -d '{"user_id": "user_3", "venue_id": "venue_10"}'
   ```

2. In app, navigate to venue_10 and tap interest button
3. Alert should appear: "Booking Confirmed! 🎉"
4. Message shows reservation details
5. Tap "OK" to dismiss

#### 5. Profile View
- [ ] Tap Profile tab
- [ ] User avatar loads
- [ ] User name displays: "Alex Chen"
- [ ] "X places saved" count is correct
- [ ] User bio displays
- [ ] Interest badges show (coffee, food)
- [ ] Saved venues grid displays with 2 columns
- [ ] Tap any saved venue to navigate to detail
- [ ] Pull down to refresh
- [ ] Empty state shows when no saved venues

#### 6. Cross-View State Synchronization
Test that interest state syncs across views:

1. Go to Feed
2. Save a venue (tap heart)
3. Go to Profile - venue should appear in saved list
4. Go back to Feed - heart should still be filled
5. Open venue detail - button should show "Interested"
6. Tap to unsave
7. Go to Profile - venue should disappear
8. Go back to Feed - heart should be empty

#### 7. Navigation Flow
- [ ] Feed → Detail (tap card)
- [ ] Detail → Back to Feed (back button)
- [ ] Profile → Detail (tap saved venue)
- [ ] Detail → Back to Profile (back button)
- [ ] Switch tabs while on detail view
- [ ] Navigation state maintains correctly

#### 8. Error Handling
Test error scenarios:

1. **No Network:**
   - Turn off backend server
   - Pull to refresh
   - Error message appears
   - Retry button works
   - Turn backend back on
   - Retry succeeds

2. **Invalid Venue:**
   - Manually test with invalid venue ID
   - Error message displays
   - Can navigate back

#### 9. Loading States
Verify loading indicators appear:
- [ ] Initial venue feed load
- [ ] Pull to refresh
- [ ] Venue detail load
- [ ] Interest button toggle
- [ ] Profile load

#### 10. Empty States
- [ ] New user profile shows "No Saved Places"
- [ ] Message: "Explore venues and tap the heart to save them"
- [ ] Heart slash icon displays

## Expected Behavior Summary

### Interest Toggle Flow
1. Tap heart → Animates, API call starts
2. Optimistic update: heart fills immediately
3. API returns → Success or error
4. On success: state persists
5. On error: revert to previous state
6. Profile auto-refreshes with new saved venue

### Booking Agent Flow
1. 3 users interested → threshold met
2. 4th user taps interest
3. API processes booking
4. Alert appears: "Booking Confirmed! 🎉"
5. Message shows reservation details
6. User dismisses alert

### Navigation Flow
```
TabView
├── Discover Tab
│   └── NavigationStack
│       ├── VenueFeedView
│       └── VenueDetailView (pushed)
└── Profile Tab
    └── NavigationStack
        ├── ProfileView
        └── VenueDetailView (pushed)
```

## Known Issues / Limitations

1. **User ID Hardcoded:** Current user is always "user_1"
2. **No Authentication:** No login system
3. **Simulator Only:** Testing on simulator (localhost API)
4. **No Real-time:** Changes require pull-to-refresh
5. **Limited Error Recovery:** Some errors require app restart

## Performance Notes

- Images load asynchronously with placeholders
- API calls use async/await (non-blocking)
- Optimistic updates provide instant feedback
- Debounced profile refresh (500ms) prevents spam
- LazyVStack/LazyVGrid for efficient scrolling

## Debugging Tips

If issues occur:

1. **Check Backend:**
   ```bash
   curl http://127.0.0.1:8000/venues
   ```

2. **Check Xcode Console:**
   - Look for API errors
   - Check for SwiftUI warnings
   - Verify network requests

3. **Reset App State:**
   - Stop app
   - Clean build folder (Cmd+Shift+K)
   - Rebuild and run

4. **Reset Backend Data:**
   - Restart backend server
   - Data resets to initial state

## Success Criteria

✅ All venues display correctly
✅ Interest functionality works across all views
✅ Navigation flows work in both directions
✅ Booking agent triggers correctly
✅ Profile displays saved venues
✅ State synchronizes across views
✅ Error handling works gracefully
✅ Loading states display appropriately
✅ No crashes or freezes
✅ UI is responsive and smooth

## Video Demo Checklist

For Phase 3 demo video, show:

1. ✅ App launch and venue feed
2. ✅ Scroll through venues
3. ✅ Tap heart to save venue (animation)
4. ✅ Tap venue to view details
5. ✅ Show all sections: hero, info, interested users, about
6. ✅ Toggle interest button
7. ✅ Demonstrate booking agent alert (if possible)
8. ✅ Navigate back to feed
9. ✅ Switch to Profile tab
10. ✅ Show saved venues grid
11. ✅ Tap saved venue to view details
12. ✅ Navigate back to profile
13. ✅ Pull to refresh on both screens
14. ✅ Explain state synchronization

---

**Testing Status:** Ready for comprehensive testing
**Next Phase:** Phase 4 - Recommendations Integration
