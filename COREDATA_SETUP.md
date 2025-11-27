# CoreData Model Setup Instructions

## Overview
The `VenueEntity.xcdatamodeld` file must be created manually in Xcode as it's a special XML-based file format that requires Xcode's Data Model editor.

## Steps to Create CoreData Model

### 1. Create Data Model File
1. In Xcode, right-click on `name/Models` folder
2. Select **New File** → **Data Model**
3. Name it `VenueEntity` (Xcode will add `.xcdatamodeld` automatically)
4. Click **Create**

### 2. Add VenueEntity
1. Open `VenueEntity.xcdatamodeld` in Xcode
2. Click the **Add Entity** button at the bottom
3. Name the entity `VenueEntity`
4. Add the following attributes:

| Attribute Name | Type | Optional | Default |
|---|---|---|---|
| id | String | No | - |
| name | String | No | - |
| category | String | No | - |
| image | String | No | - |
| interested_count | Integer 32 | No | 0 |
| distance_km | Double | Yes | - |
| cached_at | Date | No | - |

### 3. Add InterestEntity
1. Click **Add Entity** again
2. Name the entity `InterestEntity`
3. Add the following attributes:

| Attribute Name | Type | Optional | Default |
|---|---|---|---|
| venue_id | String | No | - |
| is_interested | Boolean | No | false |
| synced | Boolean | No | false |

### 4. Configure Entity Properties
For **VenueEntity**:
- Select the entity in the left panel
- In the **Data Model Inspector** (right panel):
  - Class: `VenueEntity`
  - Codegen: `Class Definition`

For **InterestEntity**:
- Select the entity in the left panel
- In the **Data Model Inspector**:
  - Class: `InterestEntity`
  - Codegen: `Class Definition`

### 5. Verify Setup
1. Build the project (⌘+B)
2. Xcode will automatically generate the CoreData entity classes
3. The `PersistenceController` will now be able to use these entities

## Alternative: Manual Entity Classes

If you prefer manual control, you can set Codegen to "Manual/None" and create the entity classes manually:

```swift
// VenueEntity+CoreDataProperties.swift
import Foundation
import CoreData

extension VenueEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<VenueEntity> {
        return NSFetchRequest<VenueEntity>(entityName: "VenueEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var category: String?
    @NSManaged public var image: String?
    @NSManaged public var interested_count: Int32
    @NSManaged public var distance_km: Double
    @NSManaged public var cached_at: Date?
}

// InterestEntity+CoreDataProperties.swift
import Foundation
import CoreData

extension InterestEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InterestEntity> {
        return NSFetchRequest<InterestEntity>(entityName: "InterestEntity")
    }

    @NSManaged public var venue_id: String?
    @NSManaged public var is_interested: Bool
    @NSManaged public var synced: Bool
}
```

## Testing CoreData Setup

After creating the model, test with this code in a view:

```swift
let persistence = PersistenceController.shared
print("CoreData container loaded: \(persistence.container.name)")

// Test saving
let testVenues = [
    VenueListItem(id: "test_1", name: "Test Venue", category: "Café", image: "", interested_count: 5, distance_km: 1.2)
]
persistence.saveVenues(testVenues)

// Test fetching
let cached = persistence.fetchCachedVenues()
print("Cached \(cached.count) venues")
```

## Troubleshooting

**Error: "No NSEntityDescriptions in any model claim the NSManagedObject subclass 'VenueEntity'"**
- Solution: Ensure Codegen is set to "Class Definition" or create manual classes

**Error: "Failed to load persistent stores"**
- Solution: Check that the model name matches the container name in `PersistenceController`
- The container is initialized with `NSPersistentContainer(name: "VenueEntity")`

**Error: "Unresolved identifier 'VenueEntity'"**
- Solution: Build the project to generate CoreData classes
- Ensure the Data Model file is included in the target

## Next Steps

Once CoreData is set up:
1. Integrate `PersistenceController` into `VenueFeedViewModel`
2. Test offline mode by toggling Airplane mode
3. Verify sync queue works when re-enabling network
