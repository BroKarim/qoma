# Findings & Decisions

## Requirements

- Preserve the existing macOS focus utility as the base, but replace the floating timer visual with a penguin fishing on an ice floe.
- Add Catalog and Aquarium as first-class product surfaces on macOS and iOS.
- Release a companion iOS app with different platform behavior: no macOS-style floating panel and no app/tab-usage analytics.
- Make all core product behavior work offline; make iCloud collection/session sync opt-in.
- Ship a large Release 1 in approximately four months without allowing Deep Focus entitlement approval to block release.

## Research Findings

- The existing source project is a macOS Swift/SwiftUI menu-bar app with an `NSPanel` floating timer, local JSON persistence, analytics based on Accessibility/AppleScript, and Sparkle update support. The source target remains branded Qoma and needs a deliberate rebrand/migration plan.
- The supplied fishing reference communicates a readable loop: penguin idles, reacts to a bite, reels a catch, deposits it in a bucket, and the bucket opens collection results.
- The supplied aquarium reference is a top-down, rounded blue tank with small fish and decor moving through open water.
- Apple Universal Purchase supports one App Store product across platforms when its configuration is shared correctly.
- A shared App Store purchase does not extend to the legacy direct-DMG/Sparkle distribution channel. Release 1 must use the Mac App Store as its primary cross-platform purchase channel.
- Apple Managed Settings UI provides a system-owned shield that can be customized with an icon, title, subtitle, colors, and action labels. It is not an arbitrary full-screen SwiftUI view.
- Forest demonstrates a relevant model: all users can use a default Deep Focus allow-list while custom allow-lists are a paid capability.

## Technical Decisions

| Decision | Rationale |
|---|---|
| SwiftData becomes the local source of truth for new Release-1 product data | The present JSON store will not scale comfortably to session events, catalog counts, analytics, and iCloud sync. |
| Completed session and catch-event records are immutable/append-only | Counts can be derived and sync can deduplicate by UUID. |
| Use 2D Canvas with a small Metal shader layer, not 3D/video playback | Matches the intended top-down illustration style while remaining offline and battery-conscious. |
| Use procedural fish trails and shared behavior classes | Gives fish natural motion without authoring a frame-by-frame animation for every collectible. |
| iCloud sync is opt-in and excludes active timers and Mac permission/panel state | Avoids cross-device timer conflicts and preserves device-local behavior. |
| Deep Focus is iOS-only in Release 1 | It depends on iOS Screen Time APIs; macOS keeps its existing productivity/analytics direction. |
| Mac App Store is the primary Release-1 distribution path | It is required for the approved Universal Purchase promise; direct DMG receipt sharing is not available. |

## Issues Encountered

| Issue | Resolution |
|---|---|
| Apple Screen Time shielding is system-owned, not a fully custom app page | Design the Dzenn shield within Apple’s supported icon/title/subtitle/button customization model. |
| Family Controls entitlement can delay distribution | Treat Deep Focus as a release contingency, not a hard dependency. |
| Large visual collection could affect performance | Store identifiers rather than images per catch; render one aquarium entity per discovered species/item; pause off-screen animation. |
| Current Mac app tracking may face App Sandbox/App Review constraints | Validate this in week 1 before treating it as a release guarantee. |

## Resources

- Existing product analysis: `CONTEXT.md`
- Apple Universal Purchase: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms
- Apple iCloud/CloudKit: https://developer.apple.com/icloud/cloudkit/
- Apple Canvas: https://developer.apple.com/documentation/swiftui/canvas
- Apple SwiftUI shader library: https://developer.apple.com/documentation/swiftui/shaderlibrary
- Apple Managed Settings UI shield configuration: https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration
- Apple Family Controls entitlement: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
- Apple blocked applications setting: https://developer.apple.com/documentation/managedsettings/applicationsettings/blockedapplications-swift.property
- Apple Live Activities: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- Forest iOS listing: https://apps.apple.com/us/app/forest-focus-for-productivity/id866450515

## Visual Findings

- Fishing should prioritize the readable catch sequence over visual complexity: idle fishing, bite cue, pull/reel, deposit, reset.
- Aquarium should feel like a living display, not a placement game: top-down fish movement, gentle surface movement, and static/slow decor.
- The user wants a cozy illustrated aesthetic, with original Dzenn assets rather than copied reference art.
