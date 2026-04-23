# FilamentVault — iOS

SwiftUI port of the Android [FilamentVault](https://github.com/SexualMoose/FilamentVault) app.
3D printing filament inventory manager with a built-in 291-entry database of
manufacturer print settings across 46+ brands.

- **Language**: Swift 5.9+ / SwiftUI
- **Min iOS**: 17.0 (for SwiftData)
- **Storage**: SwiftData (built on SQLite)
- **Backup**: JSON export/import via iOS Files app (iCloud Drive, Google Drive, OneDrive, etc.)
- **Data model**: Feature-parity with the Android release, same defaults.json catalog

---

## Quick start (first time, on the Mac)

You'll create a fresh Xcode project, drag the source files in, and build. Total
time ~10 minutes.

### 1. Install prerequisites
- **Xcode 15.2 or newer** (free from the Mac App Store)
- **Apple ID** signed into Xcode (Xcode → Settings → Accounts → `+`)
  - Free account = 7-day app expiration, 3-device limit
  - $99/yr Apple Developer Program = unlimited devices + TestFlight + App Store

### 2. Clone this repo
```bash
cd ~/Developer   # or wherever you keep projects
git clone https://github.com/SexualMoose/FilamentVault-iOS.git
cd FilamentVault-iOS
```

### 3. Create a new Xcode project
1. **File → New → Project**
2. Choose **iOS → App**, click Next
3. Fill in:
   - Product Name: `FilamentVault`
   - Organization Identifier: `com.sexualmoose` (or your own reverse-DNS)
   - Bundle Identifier: `com.sexualmoose.FilamentVault` (auto-fills)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we'll add SwiftData via code)
   - **Uncheck** "Include Tests" unless you want them
4. Save it **inside the cloned `FilamentVault-iOS` folder**, overwriting the existing `FilamentVault` subfolder (or pick a sibling location and merge — see step 4)

### 4. Drop the source files in
In Finder, open the cloned repo's `FilamentVault/` folder. You'll see these
subfolders of source code:

- `Models/`
- `Services/`
- `Views/`
- `Resources/` (contains `defaults.json`)
- `FilamentVaultApp.swift`
- `ContentView.swift`

**Drag all of these** onto your Xcode project's `FilamentVault` group in the
left sidebar. When the dialog appears:
- ✅ **Copy items if needed** (only if Xcode created your project in a different location)
- ✅ **Create groups**
- ✅ Add to target: `FilamentVault`

Xcode will replace its auto-generated `ContentView.swift` and `FilamentVaultApp.swift`.

### 5. Configure the target

Select the project at the top of the Xcode sidebar → select the **FilamentVault**
target.

**General tab:**
- Deployment Info → **iOS 17.0**
- Orientations → iPhone: Portrait only (or whatever you prefer)

**Signing & Capabilities tab:**
- Team: select your Apple ID team (personal team or Developer Program)
- Signing Certificate: Apple Development (auto)
- Bundle Identifier: make sure it's unique (e.g. add your name: `com.sexualmoose.yourname.FilamentVault`)

**Info tab:** add these privacy usage descriptions (required or your app crashes when accessing):
- `NSCameraUsageDescription` → `FilamentVault uses the camera to photograph filament spools.`
- `NSPhotoLibraryUsageDescription` → `FilamentVault reads photos you attach to filaments.`
- `NSPhotoLibraryAddUsageDescription` → `FilamentVault can save cropped spool photos.` *(optional)*

### 6. Build & run
- Connect your iPhone via USB (first time only; wireless works after)
- On the iPhone: **Settings → Privacy & Security → Developer Mode** → toggle on, reboot when prompted
- In Xcode's top toolbar, pick your iPhone as the run destination (dropdown next to the scheme)
- **⌘R** (or the ▶️ play button) to build, install, and launch

First launch quirk: iOS refuses to run apps from "untrusted developers." On the phone:
**Settings → General → VPN & Device Management → `Apple Development: your@email.com` → Trust**.

### 7. Seeding note
On first launch, the app parses `defaults.json` from the bundle and seeds
SwiftData with 291 filament defaults. This happens once; subsequent launches
are instant.

---

## 7-day re-sign dance (free Apple ID only)

If you're using a free Apple ID, apps signed this way **expire after 7 days**.
To re-install: plug in the iPhone, open the project in Xcode, hit ⌘R again.
The 7-day timer resets. No re-building from scratch, just re-signing.

To escape this: pay **$99/yr** for the Apple Developer Program. That gives you:
- Unlimited devices, no expiration
- TestFlight (install via shared link, 90-day expiration, easier for "a few devices")
- App Store submission path

---

## Distributing to "a few devices" (personal)

### Option A: TestFlight (recommended for multiple devices)
Requires Apple Developer Program ($99/yr).

1. In Xcode: **Product → Archive** (builds a release IPA)
2. In Organizer (auto-opens): **Distribute App → App Store Connect → Upload**
3. On [App Store Connect](https://appstoreconnect.apple.com):
   - Create app record (first time)
   - My Apps → FilamentVault → TestFlight → Internal Testing
   - Add testers by Apple ID email (up to 100 internal testers, 10,000 external)
4. Testers install the **TestFlight** app from the App Store, accept your invite → install FilamentVault
5. Each TestFlight build expires after **90 days**; re-archive and upload to refresh

### Option B: Direct sideload via Xcode
Plug each iPhone into your Mac once, hit ⌘R. Free Apple ID = 7-day expiration,
Developer Program = unlimited.

### Option C: App Store (if you ever pursue broader distribution)
Same archive workflow, but submit for review instead of TestFlight. Adds:
- Privacy policy URL (required)
- App Store screenshots (6.7" iPhone required)
- App description + keywords
- Review takes 24–72 hours typically

---

## Architecture notes (if you want to modify)

```
FilamentVault/
├── FilamentVaultApp.swift        Entry point, builds SwiftData ModelContainer
├── ContentView.swift             TabView shell: Inventory / Database / Settings
├── Models/
│   ├── Filament.swift            @Model — user inventory row
│   ├── DefaultSetting.swift      @Model — built-in catalog row (seeded from JSON)
│   ├── DefaultOverride.swift     @Model — user edits + custom defaults
│   ├── Enums.swift               MaterialType, FillType (displayed as "Modifier")
│   └── FilterCriteria.swift      Filter logic for list
├── Services/
│   ├── DefaultsPopulator.swift   Seeds DefaultSetting on first launch, runs
│   │                             cascading lookup (override → base catalog)
│   ├── ColorWheelSort.swift      HSV-based sort, plus UIColor/Color hex init
│   ├── ImageStorage.swift        File I/O in app documents/filament_images/
│   └── BackupService.swift       JSON encode/decode + SwiftData import/export
├── Views/
│   ├── Inventory/
│   │   ├── FilamentListView.swift     Color-wheel-sorted grid
│   │   ├── FilamentCardView.swift     Single row with spool swatch
│   │   ├── FilamentDetailView.swift   Add/edit form with auto-populate
│   │   ├── FilterSheet.swift          Material/brand/temp/diameter filters
│   │   └── SpoolCropperView.swift     Pan/zoom/rotate cropper with mask
│   ├── Database/
│   │   ├── DefaultsListView.swift     Search + badges (Modified/Custom)
│   │   └── DefaultsEditorView.swift   Edit/save-as-new/reset-to-original
│   ├── Settings/
│   │   └── SettingsView.swift         Backup/restore + reset all
│   └── Common/
│       ├── ColorSwatchSpool.swift     3D angled spool in SwiftUI Canvas
│       └── BrandAutocomplete.swift    Type-ahead brand field
└── Resources/
    └── defaults.json                  291-entry filament database
```

### Key design choices vs Android version
- **SwiftData** instead of Room. Same 3-table structure (inventory / built-in catalog / user overrides), and same cascading lookup behavior.
- **No DI framework**. SwiftUI's `@Environment(\.modelContext)` replaces Hilt.
- **TabView** instead of BottomNavigationBar. Same 3 tabs, same deep-linking hierarchy.
- **`.fileExporter` / `.fileImporter`** replace Android's Storage Access Framework — same "pick any cloud location" behavior via iOS Files.
- **`PhotosPicker`** replaces PickVisualMedia.
- **`MagnificationGesture` + `DragGesture`** replace `detectTransformGestures` on Android for the pan/zoom cropper.
- **Cropper includes rotation** (fixed 90° buttons + 15° fine buttons) — addresses the common problem of EXIF-rotated camera photos displaying sideways after crop.

### Differences to watch out for
- SwiftData performs automatic schema migration for additive changes (new fields). For destructive changes you'll need `VersionedSchema`.
- iOS doesn't have Android's auto-camera-permission crash; Photos/Camera usage descriptions in Info.plist are still required or your app is terminated.
- `UIColor.getHue` returns hue in 0…1 (not degrees). ColorWheelSort multiplies by 360.

---

## Version

**v2.1.1** — feature parity with Android v2.1.1 as of April 2026.

---

## License

Personal project. All rights reserved.
