# FilamentVault-iOS — Project Documentation

A SwiftUI iOS port of the Android FilamentVault app: a fully offline 3D-printing
filament inventory manager with a bundled 291-entry catalog of manufacturer print
settings covering 46 brands.

_Last audited: 2026-10-10 against main @ aa2f336. Review round 2026-10-11: sources
type-checked._

## Overview / Purpose
FilamentVault lets a maker catalog the filament spools they own and look up recommended
print settings from a built-in catalog. Each spool records material, color, brand,
diameter, print settings, quantity, notes, and a cropped spool photo. When you add a spool,
the app fills in print parameters with a cascading lookup: user override first, then the
built-in catalog, matched by material + brand + modifier. The inventory is shown as a
color-wheel-sorted list of cards, each with a stylized 3D "spool" swatch drawn in the
filament's color. The UI is dark-mode only (`.preferredColorScheme(.dark)`).

Everything is stored locally on the device (SwiftData, which uses SQLite). Backup is a
plain JSON file exported and imported through the iOS Files picker.

## Status
**Does not compile as committed:** one error in `SettingsView.swift:59` (`.fileExporter` is
missing `isPresented:`). The fix is one line (see Known Issues). Apart from that error, the
code is feature-complete for its initial release (v2.1.1) and has been dormant since.
Evidence:
- Two commits on `main`: `6f7a0f3` (2026-04-23, "Initial release v2.1.1 (iOS)") and
  `aa2f336` (2026-06-27, documentation only). No git tags. `origin` has only `main`, which
  matches the checked-out branch.
- The in-app About text says "FilamentVault v2.1.1 (iOS)" (`Views/Settings/SettingsView.swift`).
  The README states feature parity with Android v2.1.1 as of April 2026. One exception: the
  Android app can take photos with the camera and this port cannot (see Known Issues).
- The Swift sources contain no `TODO`, `FIXME`, or stub code. Models, services, and views
  are complete and cross-referenced.
- **Type-checked, not run.** On 2026-10-11, `swiftc -typecheck` over
  `FilamentVault/**/*.swift` (iOS 17.0 Simulator target, Swift 5 language mode, Xcode 27
  toolchain) reported exactly one error:
  `SettingsView.swift:60:13: error: missing argument for parameter 'isPresented' in call`.
  With the one-line fix applied to a scratch copy, the module type-checks with one
  warning (`SpoolCropperView.swift:139`, see Technical Requirements). Nothing was built into
  an app bundle or run on a device or the Simulator. The repo has no CI.
- **Source files only:** no `*.xcodeproj` and no XcodeGen spec are committed. Building
  needs the manual "create an Xcode project and add the files" setup below, plus the
  one-line source fix.

## Technical Requirements
- **Language**: Swift 5.9+. The code uses the `@Model` and `#Preview` macros.
  - Build in **Swift 5 language mode** (`SWIFT_VERSION = 5`; Build Settings → Swift
    Language Version). Swift 6 mode turns `SpoolCropperView.swift:139` into an error: it
    calls the main-actor `renderCrop` from `Task.detached` without `await`, which Swift 5
    mode reports only as a warning.
- **UI**: SwiftUI.
- **Persistence**: SwiftData (needs iOS 17).
- **Minimum deployment target**: iOS 17.0. Besides SwiftData, the code uses other iOS 17
  SwiftUI APIs, such as the two-parameter `onChange` and `.topBarTrailing` toolbar
  placement.
- **Tooling**: macOS with Xcode. The README recommends Xcode 15.2 or newer; Xcode 15 is the
  minimum for Swift 5.9 macros and the iOS 17 SDK.
- **Hardware**: an iPhone running iOS 17+ or the iOS Simulator. The layout is written for
  iPhone; iPad behavior is unverified. The app never connects to a 3D printer or to any
  network service.
- **Accounts/keys**: an Apple ID for code signing. TestFlight or App Store distribution
  needs the paid Apple Developer Program. No API keys, backend accounts, or third-party
  credentials are needed.

## Dependencies
Apple first-party frameworks only. There is no SwiftPM manifest, Podfile, or Carthage
file, and no vendored library.

| Framework | Used for | License |
|---|---|---|
| SwiftUI | All UI | Apple SDK (Xcode and Apple SDKs Agreement) |
| SwiftData | Persistence (`@Model`, `ModelContainer`, `@Query`) | Apple SDK |
| Foundation | JSON coding, file I/O | Apple SDK |
| UIKit | `UIImage`, `UIColor`, `UIGraphicsImageRenderer` | Apple SDK |
| PhotosUI | `PhotosPicker` | Apple SDK |
| UniformTypeIdentifiers | `.json` content type for export/import | Apple SDK |

The repo has no external open-source dependencies, so there are no third-party
dependency licenses to track.

## Setup Instructions
This repo contains source files only. To build, create a host Xcode project and add the
files to it. The steps below are the corrected version of the README's procedure. They
were not re-run during this audit.

1. Install Xcode 15.2+ and sign in with an Apple ID (Xcode → Settings → Accounts).
2. Clone:
   ```bash
   git clone https://github.com/SexualMoose/FilamentVault-iOS.git
   cd FilamentVault-iOS
   ```
3. In Xcode, choose File → New → Project → iOS → App.
   - Product Name: `FilamentVault`
   - Organization Identifier: your reverse-DNS (the README uses `com.sexualmoose`)
   - Interface: SwiftUI · Language: Swift · Storage: None (SwiftData is set up in code)
   - Save the project in a **separate location** (for example a sibling folder). Do not let
     Xcode replace the repo's `FilamentVault/` folder: that deletes the sources. Recover
     them with `git checkout -- FilamentVault` if it happens.
4. Delete the template's own `ContentView.swift` and `FilamentVaultApp.swift` (Delete →
   Move to Trash). The repo provides both, and two `@main` types will not compile.
5. Drag the contents of the repo's `FilamentVault/` folder onto the project's
   `FilamentVault` group: `Models/`, `Services/`, `Views/`, `Resources/`,
   `FilamentVaultApp.swift`, and `ContentView.swift`. Choose "Create groups" and add them to
   the `FilamentVault` target.
   - Leave "Copy items if needed" unchecked so you keep editing the git clone in place.
   - Xcode 16 and later show different options in this dialog: choose **Action: Reference
     files in place** and **Groups: Create groups**.
   - Confirm that `Resources/defaults.json` is under Build Phases → Copy Bundle Resources.
     Without it, seeding fails: the app logs `defaults.json missing from app bundle` and
     the Database tab stays empty.
6. Configure the target:
   - General → Minimum Deployments → iOS 17.0.
   - Signing & Capabilities → select your Team and make sure the Bundle ID is unique.
   - Version: optionally set it to `2.1.1` to match the hard-coded About text (Xcode's
     template default is 1.0).
   - Info (privacy usage strings): the code only uses `PhotosPicker`. It runs out of
     process and needs no photo-library permission, so no usage description is strictly
     required. Adding `NSPhotoLibraryUsageDescription` is a harmless precaution.
     `NSCameraUsageDescription` and `NSPhotoLibraryAddUsageDescription` are not used by
     the current code.
   - Build Settings → Swift Language Version → **Swift 5** (see Technical Requirements).
7. Apply the one-line fix to `Views/Settings/SettingsView.swift` described under Known
   Issues ("Does not compile as committed"). Without it the build fails.

## Build & Run
- **Simulator**: pick an iOS 17+ simulator as the run destination and press ⌘R.
- **Device**: connect the iPhone and turn on Developer Mode (Settings → Privacy & Security
  → Developer Mode). Pick the device as the destination and press ⌘R. On first install,
  trust the developer certificate under Settings → General → VPN & Device Management.
- **Free Apple ID builds expire after 7 days.** Re-run ⌘R to re-sign. The paid Apple
  Developer Program removes the expiry and enables TestFlight and the App Store (Product
  → Archive → Distribute App).
- **No command-line build:** the repo has no project or scheme, so there is no
  `xcodebuild` invocation until you create the project yourself. The repo also has no ship
  or TestFlight script.
- **First launch** seeds the 291-entry catalog from `defaults.json`. Later launches skip
  seeding unless the bundled entry count changes.

## Usage
- **Inventory tab** (`FilamentListView`):
  - Spool cards appear in color-wheel order: saturated colors by hue first, then
    low-saturation colors (grays, black, white) by brightness.
  - The filter sheet filters by material, brand, diameter (1.75 / 2.85 mm), and nozzle
    Min/Max temperatures, each of which must fall within the spool's nozzle range. The
    brands offered are those in your inventory.
  - **+** adds a spool, tapping a card edits it, and long-press → Delete removes it along
    with its photo files.
- **Add/Edit form** (`FilamentDetailView`):
  - **Fields:** Material (16 types), Modifier (18 options), Brand (autocompletes from
    inventory, catalog, and overrides), color hex with a live spool swatch, color name,
    diameter, quantity stepper, temperatures, speeds and cooling,
    retraction/flow/layer, density and drying, notes, and photo.
  - **Auto-fill:** changing material, modifier, or brand fills settings from the
    catalog. Brand changes are debounced 0.5 s. Fields that count as edited are not
    overwritten, and in practice that includes values filled by an earlier auto-fill or
    loaded from a saved spool (see Known Issues).
  - **Duplicate check:** a new entry with the same material, color hex, diameter, brand,
    and modifier as an existing spool offers "Add Spool (+1)" instead.
- **Photo**: pick an image with `PhotosPicker`. A cropper sheet opens (drag, pinch to
  zoom 0.3×–6×, rotate ±90° / ±15°) and masks the image to a capsule "spool" outline. The
  result is saved as a JPEG under the app's `Documents/filament_images/`. You can re-crop
  from the stored original or remove the photo. Remove and Change Photo delete the old
  image files right away, not on Save (see Known Issues).
- **Database tab** (`DefaultsListView` / `DefaultsEditorView`):
  - The list merges built-in entries with your overrides. The header shows
    `N entries · N modified · N custom`.
  - You can search by material, brand, or modifier. Entries carry **Modified** or
    **Custom** badges, and built-ins with no brand or modifier are labeled
    "Generic fallback".
  - **+** creates a custom default.
  - Editing a built-in offers Save (stores an override and keeps the original), Save as
    new entry, and Reset to original. Custom entries offer Save changes, Duplicate as new
    entry, and Delete.
- **Settings tab** (`SettingsView`):
  - **Export backup** writes a JSON file through the Files export picker. The default
    name is `filamentvault_backup_<yyyyMMdd_HHmmss>`.
  - **Import backup** asks whether to **Merge** (append; nothing is de-duplicated, and
    see Known Issues for a crash case) or
    **Replace everything** (deletes current inventory, its photo files, and all
    overrides first).
  - **Reset all default edits** deletes every override, including user-created custom
    entries. Inventory is not affected.
  - **About** shows the hard-coded version string.

## Architecture
SwiftUI + SwiftData, MVVM-lite: views use `@Environment(\.modelContext)` and `@Query`,
with no DI framework. There are three SwiftData `@Model` entities in one persistent (not
in-memory) `ModelContainer`:
- `Filament`: a user-owned inventory row (`Models/Filament.swift`). Photo paths are stored
  as filenames relative to `Documents/filament_images/`.
- `DefaultSetting`: a built-in catalog row, seeded from JSON (`Models/DefaultSetting.swift`).
- `DefaultOverride`: a user edit of a built-in entry, or a user-created custom entry
  (`Models/DefaultOverride.swift`).
  - An edit records the built-in entry's material, brand, and modifier strings in
    `baseMaterial`, `baseBrand`, and `baseFillType`. Because the link is by strings, not
    by row ID, overrides survive a catalog re-seed.
  - `baseMaterial == nil` marks a custom entry.

Supporting models: `Enums.swift` (`MaterialType`, 16 cases; `FillType`, 18 cases, shown
as "Modifier") and `FilterCriteria.swift`.

Services:
- `DefaultsPopulator`:
  - Seeding: on launch, it compares the number of entries in the bundled `defaults.json`
    with the number of `DefaultSetting` rows. If they differ, it deletes and re-inserts
    the catalog. User filaments and overrides are untouched.
  - Lookup: it implements the 4-tier cascading lookup (exact → material+brand →
    material+modifier → material), checking overrides before the catalog.
- `ColorWheelSort`: HSV-based ordering. Hue comes from `UIColor.getHue` (0…1, multiplied
  by 360), and colors with saturation below 0.12 count as gray. The file also defines the
  hex → `UIColor` / `Color` initializers.
- `ImageStorage`: JPEG file I/O (quality 0.9) under app `Documents/filament_images/`.
- `BackupService`: Codable DTOs, JSON encode/decode, and SwiftData import/export.
  - Backup format: `{ version: 1, createdAt, filaments: [...], defaultOverrides: [...] }`.
  - Dates are ISO-8601; output is pretty-printed with sorted keys.
  - Photos and photo filenames are not included.
  - `BackupFile` (`FileDocument` + `Transferable`, in `SettingsView.swift`) wraps the data
    for `.fileExporter`.

Views: Inventory (List / Card / Detail / FilterSheet / SpoolCropper), Database
(List / Editor), Settings, and Common (`ColorSwatchSpool` Canvas drawing,
`BrandAutocomplete`).

Data flow:
1. `FilamentVaultApp` builds the `ModelContainer` (it calls `fatalError` if that fails).
2. When the root view appears, a `Task` runs `DefaultsPopulator.seedIfNeeded`.
3. `ContentView` is a 3-tab `TabView`, with a `NavigationStack` per tab.
4. Views fetch and insert through the shared model context.
5. The detail form calls `DefaultsPopulator.lookupDefaults` to prefill settings.
6. Backups round-trip through the `BackupService` DTOs and the Files picker.

Repository layout:
```
FilamentVault/
├── FilamentVaultApp.swift, ContentView.swift
├── Models/      Filament, DefaultSetting, DefaultOverride, Enums, FilterCriteria
├── Services/    DefaultsPopulator, ColorWheelSort, ImageStorage, BackupService
├── Views/       Inventory/, Database/, Settings/, Common/
└── Resources/   defaults.json  (291 entries)
```

## Integrations & Interconnects
- **FilamentVault (Android)**, sibling repo `SexualMoose/FilamentVault`. This repo is the
  SwiftUI port of it. There is no shared code.
  - **Catalog:** the bundled `defaults.json` is byte-identical to the Android repo's
    `app/src/main/assets/defaults.json` (checked 2026-10-10).
  - **Backups:** both apps use the same backup field names (`filaments`,
    `defaultOverrides`, …), but **backup files are not interchangeable**. This app writes
    ISO-8601 date strings, while the Android app writes epoch-millisecond numbers (checked
    against the Android repo's backup code on 2026-10-10).
- **iOS system services:** backups go through `.fileExporter` / `.fileImporter`. These
  open the Files picker, which can show iCloud Drive, Google Drive, OneDrive, Dropbox, and
  local storage. The app does not integrate with any of those services directly. Photos
  come from the system `PhotosPicker`.
- **Not a fleet member.** The app has no fleet app key, no health or self-report
  telemetry, no self-update, and no client for any self-hosted server.
- **No network of any kind**: no cloud APIs, no Tailscale, no analytics, no backend. There
  is also no hardware, BLE, or USB integration.

## Configuration & Secrets
None. The code reads no environment variables, no custom Info.plist keys, no
`UserDefaults`/`@AppStorage`, and no keychain items. The repo contains no API keys,
tokens, endpoints, `.env` files, service-account files, keystores, or signing material.

All configuration lives in the Xcode project you create: bundle ID, signing team,
deployment target, version, and optional usage strings. Signing identities stay in
Xcode and your keychain. `.gitignore` excludes signing artifacts (`*.mobileprovision`,
`*.p12`, `*.cer`, `GoogleService-Info.plist`) and Xcode user data.

## Testing
- **No automated tests:** there is no XCTest target and there are no test files. The
  README suggests unchecking "Include Tests" (Testing System: None in Xcode 16 and later).
- **No CI:** there is no `.github/workflows`.
- Verification is manual, on a device or the Simulator. A quick smoke check:
  1. After the first launch, the Database tab header should read
     `291 entries · 0 modified · 0 custom`.
  2. Add a spool and change the material, modifier, or brand. The temperature fields
     should auto-fill.
  3. Run this only on a test install with throwaway data. Replace permanently deletes
     every spool photo (backups do not include photos), and Merge leaves duplicate spools
     you must delete by hand. With no built-in edits (the Database header shows
     `0 modified`), export a backup and import it with Merge. The inventory count should
     double. If you have built-in edits, import with Replace instead (the counts should
     stay the same), because Merge then crashes the Database tab (see Known Issues).

## Known Issues / TODO
- **Does not compile as committed:** `SettingsView.swift:59-63` calls
  `.fileExporter(item: exportURL, contentTypes: [.json], defaultFilename: ...)` without
  `isPresented:`, and every `fileExporter` overload requires it. Fix: insert this line
  before `item: exportURL,`:
  ```swift
  isPresented: Binding(get: { exportURL != nil }, set: { if !$0 { exportURL = nil } }),
  ```
  This is the only compile error (type-checked 2026-10-11, see Status).
- **Not turnkey-buildable:** no `.xcodeproj`, XcodeGen spec, or ship script is committed.
  Building needs the manual setup above.
- **Version is set by hand:** the About string is hard-coded in `SettingsView.swift`, and
  the bundle version is whatever you set in your own Xcode project.
- **Backups exclude photos:** the photo filename fields are not in the backup DTOs, and
  "Replace everything" deletes the existing photo files. Moving to a new device or doing a
  replace-restore loses spool photos.
- **Backups are not cross-platform:** iOS and Android backup files cannot be imported into
  each other because the date encodings differ (see Integrations).
- **Merge import does not de-duplicate:** importing the same backup twice doubles the
  inventory.
- **Merge import can crash the Database tab:** Merge also re-inserts every override in
  the backup (`BackupService.swift:121-126`). If the backup contains an edit to a built-in
  entry that already has an edit on the device, the device now has two overrides with the
  same material + brand + modifier key. `DefaultsListView.swift:29` builds the overrides
  into `Dictionary(uniqueKeysWithValues:)`, which traps on duplicate keys, so the app
  crashes when the Database list renders. Settings → Reset all default edits deletes every
  override (custom entries too) and should clear the duplicates. Not verified on a device.
- **Catalog refresh is keyed on entry count only:** a future `defaults.json` that changes
  values but keeps 291 entries will not re-seed existing installs.
- **Catalog data quality:**
  - `ColorFabb` and `Colorfabb` appear as two brand casings (47 brand strings, 46 brands),
    which splits that brand in autocomplete and filters.
  - 12 entries (8 of them brandless) use modifier strings that are not options in the
    `FillType` picker. The form always sends a picker value, and each lookup tier needs
    either that exact modifier or no modifier (`DefaultsPopulator.swift:121-141`), so no
    lookup tier can ever select these 12 entries. They appear only in the Database tab:
    - `High Speed` (7 entries; the enum uses `High Speed (HS)`)
    - `70A (Very Soft/Gel)`, `85A (Soft Flex)`, `95A (Standard Flex)`
    - `ABS+/Pro`
    - `Lightweight/Foaming (LW-PLA)`
  - 22 duplicate material + brand + modifier keys (54 entries), each with conflicting
    values. For example, TPU / NinjaTek / no modifier has 4 entries with nozzle maxima of
    245, 250, 250, and 230 °C. The lookup returns the first match in an unsorted fetch, so
    auto-fill uses an arbitrary one. Overrides are matched by key
    (`DefaultsListView.swift:59-62`), so editing one of these entries marks every row with
    that key as Modified and shows the edited values on all of them.
- **Auto-fill waits for a change:** it runs only when material, modifier, or brand
  changes. A new entry left on the defaults (PLA / Standard, no brand) shows empty
  settings until one of those fields is changed.
- **Auto-fill only fills once:** each numeric field marks itself as user-edited through
  `.onChange(of:)` (`FilamentDetailView.swift:278, 291`), and that also fires when
  auto-fill (lines 353-372) or loading an existing spool sets the value in code.
  Auto-filled values (and values loaded when editing) are therefore treated as user
  edits, so only the first catalog match fills the on-screen fields. Later material,
  modifier, or brand changes do not update them. Inferred from SwiftUI `onChange`
  semantics; unverified on a device.
- **No in-app camera capture:** unlike the Android app, you can only pick existing photos.
- **Cancel after removing or replacing a saved spool's photo loses it:** when you edit an
  existing spool, Remove deletes the image files immediately
  (`FilamentDetailView.swift:244-250`), and picking a new photo deletes the old cropped
  and original files immediately (lines 527-531). The spool record changes only on Save
  (lines 428-429), and Cancel just dismisses (line 74). Removing or replacing the photo
  of an existing spool and then tapping Cancel therefore permanently loses the saved
  photo, because the files are deleted before Save.
- **Swipe-to-delete probably does nothing:** the inventory rows sit in a
  `ScrollView`/`LazyVStack`, and SwiftUI applies `.swipeActions` only to `List` rows.
  Deleting via the long-press context menu works. Not verified on a device.
- **Orphaned image files:**
  - Re-cropping keeps the previous cropped JPEG.
  - Cancelling a new, unsaved entry after picking a photo leaves its JPEGs in
    `filament_images/`.
  - Change Photo followed by Cancel on an existing spool leaves the newly picked JPEGs
    behind.
- **Dead code:**
  - An always-false `.photosPicker(isPresented:)` workaround in `FilamentDetailView.swift`.
  - The unused `BackupDocument` struct in `BackupService.swift`.
  - The unused `ImportMode` enum and `importMode` state in `SettingsView.swift` (lines 10
    and 16). The Merge/Replace choice goes straight to `performImport(replace:)`.
  - In `ColorSwatchSpool.swift`, the `scaleY` helper (lines 141-143) always returns the
    identity transform, and the `outerSide.addArc` path built at lines 39-47 is
    overwritten on line 49 before it is used.
  - The comment on `DefaultOverride.baseMaterial` describes a persistent-model identifier,
    but the field is a material string. The class doc comment (`DefaultOverride.swift:5`)
    refers to a `baseId` property that does not exist.
- **Wrong UI text:** the Settings text says "share sheet", but export uses the Files export
  picker.
- **No unit or UI tests.**

## Third-party & Licensing
- **No LICENSE file, in a public repository.** No license has been chosen yet, so all
  rights are reserved by default. Others get no reuse rights beyond what GitHub's terms
  allow for public repositories (viewing and forking on GitHub). Choosing a license is an
  owner decision.
- **No third-party code:** nothing is vendored or copied, and there are no foreign license
  headers or "adapted from" notices. The repo bundles no fonts, images, models, or asset
  catalog, so no NOTICE / THIRD-PARTY file is needed.
- **No external dependencies:** Apple SDK only, under Apple's terms. There is no copyleft
  (GPL/LGPL/MPL/AGPL) code.
- **Catalog data:** `defaults.json` holds factual print-setting values. The repo does not
  document their sources (provenance unverified).
- **Trademarks:**
  - The catalog names 46 filament brands (for example Bambu Lab, Prusament, Polymaker,
    Hatchbox, eSUN, Creality, Elegoo, BASF, Amazon Basics), and `Enums.swift` includes
    `PEI/ULTEM` (ULTEM is a SABIC trademark).
  - These names are used nominatively, as catalog labels for compatible consumables. They
    do not appear in the app name, bundle ID, or icon, and nothing implies affiliation or
    endorsement. This is low IP risk.
  - The app name "FilamentVault" and the README's suggested bundle ID
    `com.sexualmoose.FilamentVault` are original.

## Security notes
- **Trust boundary is the app sandbox.**
  - The SwiftData store and photos (`Documents/filament_images/`) live in the app
    container.
  - Data leaves the sandbox only when the user exports a backup to a location they choose.
  - Imports read a single user-chosen file through a security-scoped URL.
  - Device backups include the app container, as is standard on iOS; no backup exclusion
    is configured.
- **Auth model: none.** There are no accounts and no network code (no `URLSession`,
  WebKit, or sockets). The app has no inbound or listening surface and makes no outbound
  connections. There is no shell execution, dynamic code evaluation, or raw SQL
  (persistence is SwiftData only).
- **Secrets: none.** The working tree and the full history (`git log -p`) contain no keys,
  tokens, or credentials (checked 2026-10-11). Signing material stays in Xcode/keychain
  and is excluded by `.gitignore`.
- **Risk categories (high level):**
  - Backup files are unencrypted plaintext JSON, so their exposure depends on where the
    user stores them.
  - Imported backup content is trusted as app data once it decodes.
  - Errors are logged with `print` (error objects only, no user data).
