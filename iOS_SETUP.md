# iOS App Setup Instructions

## Quick Start Guide

### 1. Backend is Already Running ✅

The FastAPI backend is currently running on http://localhost:8000

To verify it's running:
```bash
curl http://localhost:8000/venues
```

If it's not running, start it with:
```bash
cd Luna-Backend
venv/bin/python3 -m uvicorn main:app --reload --port 8000
```

### 2. Open Xcode Project

```bash
cd /Users/krutinrahtod/Desktop/Desktop/WEB/webCodes/latestCodee/name/name
open name.xcodeproj
```

### 3. Add Files to Xcode Target

**IMPORTANT:** You need to add all the new files to the Xcode project target.

#### Files to Add:

**Models folder:**
- User.swift
- Venue.swift
- Interest.swift
- APIModels.swift

**Services folder:**
- APIService.swift

**ViewModels folder:**
- VenueFeedViewModel.swift
- VenueDetailViewModel.swift

**Views folder:**
- VenueFeedView.swift
- VenueCardView.swift
- VenueDetailView.swift
- ProfileView.swift

**Root folder:**
- Info.plist

#### How to Add Files:

1. In Xcode, select `File` → `Add Files to "name"...`
2. Navigate to each folder and select the files
3. Make sure these options are checked:
   - ✅ "Copy items if needed" (optional, files are already in place)
   - ✅ "Create groups"
   - ✅ "name" target is checked
4. Click "Add"

**OR** you can drag and drop folders from Finder into Xcode's Project Navigator.

### 4. Configure Info.plist

The `Info.plist` file has already been created with proper network settings.

**Add it to Xcode:**
1. Drag `Info.plist` from the `name/name/name/` folder into Xcode
2. Make sure "name" target is checked

**Configure Target to Use Info.plist:**
1. Select the project in Project Navigator
2. Select "name" target
3. Go to "Build Settings"
4. Search for "Info.plist"
5. Set "Info.plist File" to: `name/Info.plist`

### 5. Build and Run

1. Select a simulator (iPhone 15 Pro recommended)
2. Press ⌘R or click the Run button
3. Wait for build to complete
4. App should launch in simulator

### 6. Expected Behavior

✅ App launches with TabView
✅ "Discover" tab shows loading indicator briefly
✅ 12 venue cards appear in a scrollable list
✅ Each card shows:
   - Venue image from picsum.photos
   - Venue name
   - Colored category badge
   - Interested count (e.g., "4 people interested")
   - Heart icon (not functional yet)
✅ Pull down to refresh reloads venues
✅ "Profile" tab shows placeholder

### 7. Troubleshooting

#### Build Errors

**Error: "No such module 'Combine'"**
- Combine is built-in, no action needed
- Clean build folder: ⌘⇧K
- Rebuild: ⌘B

**Error: "Use of undeclared type 'User'"**
- Make sure all Model files are added to the target
- Check File Inspector → Target Membership → "name" is checked

**Error: "Cannot find 'APIService' in scope"**
- Make sure Services/APIService.swift is added to target
- Clean and rebuild

#### Runtime Errors

**Error: "The resource could not be loaded"**
- Backend is not running
- Start backend: `cd Luna-Backend && venv/bin/python3 -m uvicorn main:app --reload --port 8000`

**Error: "Failed to decode response"**
- Check backend is returning correct JSON
- Test: `curl http://localhost:8000/venues | python3 -m json.tool`

**Images don't load**
- This is normal - picsum.photos may be slow
- Images will appear after a delay
- Gray placeholder shows while loading

**Error: "Could not connect to the server"**
- iOS Simulator uses `localhost` or `127.0.0.1`
- Make sure backend is running on port 8000
- Check APIService base URL is "http://localhost:8000"

### 8. Testing Checklist

Run through these tests:

- [ ] App builds without errors
- [ ] App launches without crashing
- [ ] Venue list loads (12 venues)
- [ ] Images appear (may take a few seconds)
- [ ] Category badges show correct colors:
  - Blue for Coffee Shop
  - Orange for Restaurant
  - Purple for Bar
  - Green for Cultural
- [ ] Interested counts show (e.g., "4 people interested")
- [ ] Pull-to-refresh works
- [ ] Profile tab shows placeholder
- [ ] No errors in Xcode console (warnings are OK)

### 9. File Structure Verification

After adding files, your Xcode Project Navigator should look like:

```
name/
├── name/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Venue.swift
│   │   ├── Interest.swift
│   │   └── APIModels.swift
│   ├── Services/
│   │   └── APIService.swift
│   ├── ViewModels/
│   │   ├── VenueFeedViewModel.swift
│   │   └── VenueDetailViewModel.swift
│   ├── Views/
│   │   ├── VenueFeedView.swift
│   │   ├── VenueCardView.swift
│   │   ├── VenueDetailView.swift
│   │   └── ProfileView.swift
│   ├── nameApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── Assets.xcassets/
├── nameTests/
└── nameUITests/
```

### 10. Next Steps

Once Phase 2 is working:
- [ ] Verify all 12 venues display
- [ ] Test pull-to-refresh
- [ ] Check that categories are color-coded
- [ ] Confirm no build errors or warnings
- [ ] Take a screenshot of working app

Ready for Phase 3! 🚀

---

## Quick Reference

**Start Backend:**
```bash
cd Luna-Backend
venv/bin/python3 -m uvicorn main:app --reload --port 8000
```

**Open Xcode:**
```bash
open name.xcodeproj
```

**Test Backend:**
```bash
curl http://localhost:8000/venues
```

**Clean Build:**
In Xcode: ⌘⇧K (Clean Build Folder)

**Build & Run:**
In Xcode: ⌘R (Run)
