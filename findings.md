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

## qyube macOS Pivot — 2026-09-29

- The product is renamed **qyube**. Its identity is a cute glasses-wearing penguin in a cozy Antarctic world: snow white first, ice/igloo blue second, penguin gray as an accent.
- The core loop stays intact: the penguin fishes throughout the focus session; catches follow the existing provisional and five-minute banking rules; the Fishing Report reveals the haul when the user chooses Done.
- The macOS session now begins from a main-app New Session flow: name one task, choose duration, then choose only the applications necessary for that task.
- Once active, the main app yields to a separate remaining-time timer panel and a transparent penguin companion panel. Closing the timer does not dismiss the penguin; the menu-bar time restores the timer.
- An application outside the allow-list stays usable. qyube provides click-through visual friction, with a growing fish interruption as the first concept, instead of blocking access.
- Catalog and Insight remain first-class macOS surfaces. Aquarium is deferred from the first pivot phase.
- Kiki validates the single-task and allowed-app interaction pattern, but qyube must retain its own illustrated Antarctic language, non-blocking response model, and fishing collection loop.
- NSWorkspace can identify the frontmost macOS application. A qyube overlay can be mouse-transparent. Accurate positioning against another app's window may need Accessibility access; App Sandbox compatibility must be proven before making it a shipping commitment.

## qyube Floating Companion Art Direction — 2026-09-30

- Current floating artwork direction follows the user's latest sleeping-penguin reference: watercolor/charcoal penguin with no glasses, white/charcoal/warm-gray palette, and a restrained terracotta accent. Do not carry the earlier blue palette into the latest floating concept.
- The prominent concentric ripple was removed from the active fishing concept because it looked too strong at widget size. The first floating animation can omit a shared ripple layer.
- The Kiki reference screenshot is 2940 × 1912 px. Approximate timer bounds are 420 × 285 screenshot px and penguin art bounds around 235 × 235 screenshot px. Assuming 2× Retina, target about 210 × 143 pt for timer and 118 × 118 pt for art, with a roughly 140 pt transparent character canvas. These remain estimates to validate on the target Mac.
- Ice floe and bucket are canonical fixed layers, reused at identical canvas coordinates in every state. Current generated active/sleep images are conceptually matched only; production should not use their separately regenerated floes as state backgrounds.
- App activation and session events update logical state immediately. Animation can ease over a short span, but there is no timer/debounce before a reaction begins.
- If app-monitoring permission is denied during setup, retain the New Session draft and return to that form with retry/Open System Settings or Timer only options. If revoked during an active session, preserve timer and fishing while disabling app-aware behavior.
- Implementation-facing specification: design/qyube-floating/ART_DIRECTION.md.
