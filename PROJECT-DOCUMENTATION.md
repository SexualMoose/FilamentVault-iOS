# FilamentVault — iOS

A SwiftUI iOS port of the Android FilamentVault app: a fully offline 3D-printing
filament inventory manager with a bundled 291-entry catalog of manufacturer print
settings spanning 47 brands.

## Overview / Purpose
FilamentVault lets a maker catalog the filament spools they own (material, color,
brand, diameter, print settings, quantity, notes, and a cropped spool photo) and
look up recommended print settings from a built-in catalog. When you add a spool,
the app auto-populates print parameters via a cascading lookup (user override →
built-in catalog, matched by material + brand + modifier). The inventory is
displayed as a color-wheel-sorted grid of stylized "spool" swatches. Everything
is stored locally on device (SwiftData/SQLite); backup is a plain JSON file
exported/imported through the iOS Files app.

## Status
Working / feature-complete for the stated scope. Evidence:
- Tagged "Initial release v2.1.1 (iOS)" in the README and commit message; README
  states "feature parity with Android v2.1.1 as of April 2026."
- All 23 source files compile-coherent: models, services, and views are
  cross-referenced and complete (no `TODO`/`FIXME`/`NotImplemented`/stub code
  found anywhere in the Swift sources).
- Single commit, single `main` branch, clean working tree.
- One caveat: this repo intentionally ships **source files only, no Xcode
  project** (`*.xcodeproj`). The README documents a manual "create a new Xcode
  project and drag the files in" workflow, so the repo is not turnkey-buildable
  from a clone — it requires the documented ~10-minute manual setup.

## Technical Requirements
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Persistence**: SwiftData (requires iOS 17.0+; built on SQLite)
- **Min deployment target**: iOS 17.0
- **Tooling**: Xcode 15.2 or newer (README), macOS to run it
- **Hardware**: a physical iPhone or the iOS Simulator; a 3D printer is the
  subject matter but is NOT required or connected — the app never talks to any
  printer or network service
- **Accounts/keys**: an Apple ID for code signing. No API keys, no backend
  accounts, no third-party service credentials of any kind.

## Dependencies
None beyond Apple's first-party frameworks. There is no SwiftPM manifest, no
Podfile, no Carthage, no vendored libraries. Imports used:
- `SwiftUI`, `SwiftData`, `Foundation`, `UIKit`, `UniformTypeIdentifiers`,
  `PhotosUI` (PhotosPicker).
All are part of the iOS SDK (Apple platform license). There are zero external
open-source dependencies, so there is no third-party dependency-license surface.

## Setup Instructions
This repo contains source files only. To build you create a host Xcode project
and add these files to it (verbatim from README, condensed):

1. Install Xcode 15.2+ and sign into an Apple ID (Xcode → Settings → Accounts).
2. Clone:
   ```bash
   git clone https://github.com/SexualMoose/FilamentVault-iOS.git
   cd FilamentVault-iOS
   ```
3. In Xcode: File → New → Project → iOS → App.
   - Product Name: `FilamentVault`
   - Organization Identifier: your reverse-DNS (README uses `com.sexualmoose`)
   - Interface: SwiftUI, Language: Swift, Storage: None (SwiftData is added in code)
4. Add the source files: drag the repo's `FilamentVault/` subfolders
   (`Models/`, `Services/`, `Views/`, `Resources/`) plus `FilamentVaultApp.swift`
   and `ContentView.swift` onto the project's `FilamentVault` group. Let them
   replace Xcode's auto-generated `ContentView.swift` / `FilamentVaultApp.swift`.
   Ensure `Resources/defaults.json` is added to the app target (Copy Bundle
   Resources).
5. Target config:
   - General → Deployment Info → iOS 17.0
   - Signing & Capabilities → select your Team, ensure a unique Bundle ID
   - Info → add `NSPhotoLibraryUsageDescription` (required for the photo picker).
     The README also lists `NSCameraUsageDescription` and
     `NSPhotoLibraryAddUsageDescription`; the camera one is not actually needed
     because the code only uses `PhotosPicker` (photo library), never the camera
     — see Known Issues.

## Build & Run
- Connect an iPhone (enable Developer Mode in iOS Settings → Privacy & Security).
- Pick the device as the run destination and press ⌘R, or run on the Simulator.
- Free Apple ID builds expire after 7 days; re-run ⌘R to re-sign. A paid Apple
  Developer Program ($99/yr) removes that and enables TestFlight/App Store.
- First launch seeds the 291-entry catalog from `defaults.json`; subsequent
  launches are instant.

## Usage
- **Inventory tab**: color-wheel-sorted grid of owned spools; tap to view/edit;
  add a spool and the form auto-fills print settings from the catalog; attach a
  photo and crop it (pan/zoom/rotate) into a spool silhouette.
- **Database tab**: search the built-in catalog; entries badge as Modified or
  Custom; edit an entry to create a user override or save-as-new; reset to original.
- **Settings tab**: export/import a JSON backup via the Files app; reset-all.

## Architecture
SwiftUI + SwiftData, MVVM-lite (views read `@Environment(\.modelContext)`; no DI
framework). Three SwiftData `@Model` entities:
- `Filament` — a user-owned inventory row (Models/Filament.swift).
- `DefaultSetting` — a built-in catalog row, seeded from JSON (Models/DefaultSetting.swift).
- `DefaultOverride` — user edits / custom catalog entries (Models/DefaultOverride.swift).

Supporting models: `Enums.swift` (MaterialType, FillType-as-"Modifier"),
`FilterCriteria.swift`.

Services:
- `DefaultsPopulator` — seeds `DefaultSetting` from bundled `defaults.json` on
  first launch and re-seeds when the JSON entry count differs from the DB
  (preserves user data); implements the 4-tier cascading lookup
  (exact → material+brand → material+modifier → material), overrides first.
- `ColorWheelSort` — HSV-based ordering (hue ×360 from UIColor.getHue), plus
  hex→UIColor/Color initializers.
- `ImageStorage` — JPEG file I/O under app documents `filament_images/`.
- `BackupService` — Codable DTOs + JSON encode/decode and SwiftData import/export.

Views: Inventory (List/Card/Detail/FilterSheet/SpoolCropper), Database
(List/Editor), Settings, and Common (ColorSwatchSpool Canvas drawing,
BrandAutocomplete).

Data flow: `FilamentVaultApp` builds the `ModelContainer` and on appear calls
`DefaultsPopulator.seedIfNeeded`. `ContentView` is a 3-tab `TabView`. Views
fetch/insert via the shared model context; the detail form calls
`DefaultsPopulator.lookupDefaults` to prefill settings; backup round-trips
through `BackupService` DTOs and the Files app.

## Integrations & Interconnects
- **Sibling repo**: the Android original at
  `https://github.com/SexualMoose/FilamentVault` (this is the SwiftUI port of it;
  shares the same `defaults.json` catalog and 3-table data model).
- **iOS Files app**: backup JSON is read/written through `.fileExporter` /
  `.fileImporter`, which surfaces iCloud Drive, Google Drive, OneDrive, Dropbox,
  and local storage — but the app itself integrates with none of those services
  directly; it only hands a document to the system picker.
- **No network, no cloud, no hardware, no analytics, no backend.** The app is
  entirely offline and self-contained.

## Configuration & Secrets
None. There are no API keys, tokens, endpoints, `.env`, service-account files,
keystores, or signing material in the repo. The only configuration is the Xcode
project the developer creates (bundle ID, signing team, Info.plist usage strings).
`.gitignore` already excludes signing artifacts (`*.mobileprovision`, `*.p12`,
`*.cer`, `GoogleService-Info.plist`).

## Testing
No automated tests exist (no XCTest target, no test files). The README explicitly
suggests unchecking "Include Tests." Verification today is manual on device/simulator.

## Known Issues / TODO
- **Not turnkey-buildable**: no `.xcodeproj` is committed; building requires the
  manual project-creation workflow in the README.
- **README mentions `NSCameraUsageDescription`**, but the code never uses the
  camera (only `PhotosPicker` against the photo library). The camera usage string
  is unnecessary; only `NSPhotoLibraryUsageDescription` is relevant.
- **Brand `Colorfabb`/`ColorFabb` appear as two distinct casings** in
  `defaults.json`, which will fragment brand grouping/autocomplete for that brand.
- Minor: a SwiftUI binding workaround in `FilamentDetailView.swift:88`
  (`photoPickerItem != nil && false`) — harmless but odd.
- No unit/UI tests.

## Third-party & Licensing notes
- **No LICENSE file.** README states "Personal project. All rights reserved."
  This means it is proprietary/all-rights-reserved by default; no reuse rights
  are granted to others.
- **No third-party code** is vendored or copied; no foreign copyright headers,
  no "adapted from"/"based on" notices. The entire codebase appears original.
- **No external dependencies** to license-audit (Apple SDK only).
- **Trademarks**: `defaults.json` lists 47 manufacturer brand names (Bambu Lab,
  Prusament, Polymaker, Hatchbox, eSUN, Creality, Elegoo, BASF, Amazon Basics,
  etc.) and `Enums.swift` includes `PEI/ULTEM` (ULTEM is a SABIC trademark).
  These are used descriptively/nominatively as catalog labels for compatible
  consumables, not in the app name, bundle ID, icon, or in a way implying
  affiliation/endorsement — standard nominative use, low IP risk. The app name
  "FilamentVault" and bundle id `com.sexualmoose.FilamentVault` are original.

## Security notes
- No secrets, keys, tokens, passwords, or credentials anywhere in the working
  tree or git history (single commit; history == tree).
- No network code at all (no `URLSession`/`WKWebView`/HTTP/sockets), so no TLS,
  injection, CORS, or remote-content attack surface.
- No `eval`/`exec`/shell execution; no raw SQL (SwiftData only).
- Two `print()` calls log error objects (not user data) — negligible.
- Data is local to the app sandbox (documents directory + SwiftData store);
  backups are user-initiated plain JSON the user chooses where to place.
- Overall: clean. No security findings.
