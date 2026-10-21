# Findings & Decisions

## Current macOS implementation-planning findings — 2026-10-01

This section records the latest user decisions. Older Dzenn/Universal Purchase/Aquarium and earlier qyube notes below are historical where they conflict with this section; `task_plan.md` is being updated as the implementation authority.

- macOS-first technical implementation is requested as a detailed handoff for another AI agent; no application code should be changed in this planning session.
- The core interaction borrows Kiki's task/duration/three-mode session setup, but **Allowing** and **Blocking** create click-through visual friction, not an OS-level block. Timer Only has no app/site policy reaction.
- Allowing a whole browser such as Chrome allows every site within that browser. Explicit domain rules remain optional advanced controls; browser-level choice takes precedence.
- Tags are removed. The freeform session task is the sole work context; Insight may aggregate exact task titles without automatically merging similar names.
- Two distinct floating windows: closeable timer and persistent transparent penguin during an active session. Menu-bar time restores a closed timer. Penguin click may also restore timer. A completed timer goes to Fishing Report and a repeat-session action; no break and no Continue extension.
- Login is mandatory through a website using only Google or Apple identity providers. The seven-day trial requires card entry through Stripe before access; no trial charge up front. Expired access shows a subscription gate before the main app, instead of a read-only Catalog/Insight shell. Monthly/yearly/lifetime offerings remain planned, details later.
- Aquarium is canceled. Catalog alone shows all collectible types including undiscovered entries. Daily focus goal is removed.
- The approved home concept has a warm-white three-part composition: narrow sidebar, central penguin illustration, raised New Session form on the right. The active-state drafts show timer near upper left, penguin near lower right; closed-timer state leaves penguin visible. These are layout references, not production measurements.
- The existing `WindowManager` manages only one companion `NSPanel`; `MenuBarController` still hosts `MenuBarView` with session controls. `FocusSessionManager` still has break-state logic and persists analytics only behind an analytics-enabled flag. A new session architecture must split these responsibilities.
- Apple App Review Guidelines currently say unlocking app functionality requires IAP for App Store apps, with storefront/entitlement-specific external-purchase exceptions; multiplatform purchases made elsewhere generally must also be available as IAP in the app. A Stripe-only card-first flow must not be assumed shippable on iOS or Mac App Store without a distribution decision. Sources: https://developer.apple.com/app-store/review/guidelines/ and https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/ .
- Stripe documentation supports trial subscriptions with payment-method collection via Checkout. Source: https://docs.stripe.com/payments/checkout/pricing-table .
- `Qoma/Managers/AppDelegate.swift` currently launches as an accessory menu-bar app and requests analytics/automation permissions at startup. The new login gate and context-specific permissions require changing this launch sequence.
- `Qoma/Services/TimerService.swift` uses an absolute end time in memory but has no persisted snapshot/relaunch restore. `FocusSessionManager` still routes completion to a short break and opens the old menu-bar popover.
- `Qoma/Services/ActivityTracker.swift` already observes foreground app changes, but its lifecycle is tied to analytics records; policy evaluation must become independent of the analytics-enabled flag. `BrowserActivityResolver` currently supports more browsers for analytics, though the new product can limit policy semantics to Chrome/Safari.
- `Qoma/Models/SessionState.swift` encodes quickSession/taskPlan and break phases; replace with idle/active/paused/completed/interrupted and a separate policy mode enum. Existing `FocusSessionRecord` has a title field but no policy snapshot/catch IDs/status enum.
- Current companion `CompanionPlayback` is a UI-only animation with deterministic demo fish/tree proxies; its counters must not be treated as durable Catalog events. Its current pause/distraction logic cancels in-flight catches, which may conflict with the user-approved rule that fishing continues during unallowed-app visual friction; resolve by decoupling policy reaction from catch transaction.
- `Qoma/UI/SettingsView.swift` exposes a standalone Aquarium page and legacy dark settings shell; both must be removed/replaced during implementation, while retaining reusable settings logic as appropriate. The Xcode project uses file-system-synchronized source groups, easing new Swift files, but has an existing app deployment target of macOS 11.5; reconcile the new minimum explicitly rather than assuming macOS 14+ already set.
- The selected no-ripple floating artwork is transparent, with a fixed floe and bucket, no glasses, charcoal watercolor penguin. The implementation contact sheet shows fishing, bite, pull, deposit, sleep, distraction, completion, and release poses at large and small scale. Preserve existing prototype as visual starting material, not production reward logic.
- `design/qyube-active-session-v1/README.md` explicitly marks its timer-open/closed screenshots as draft mockups. It defines menu-bar restore as a no-op when the timer is already visible. `design/qyube-minimum-assets-v1/README.md` confirms generic fish/tree proxies; actual collectible identity belongs to Catalog/Fishing Report.

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

## 2026-10-02 — Compact white main UI revision

- User selected compact Kiki-style navigation with no sidebar, followed by a pure-white/minimal visual refinement. Earlier warm-white sidebar mockups remain historical; latest main-UI direction is in task_plan §12 and ART_DIRECTION §14.
- Main-page fishing penguin omits ice/bucket/water; this does not revise desktop companion props. Two session panels remain required.
- Nine prototype PNGs are now local to `design/qyube-compact-v1/`: two prior Home images plus seven new page proposals. Built-in image_gen was used, with prompts and image limitations recorded next to the assets.
- Native implementation must correct illustrative discrepancies: continuous minute ruler, fixed-size viewport with scroll for Insight, computed graph/count values, and overlay-only Settings menu. See the package README for full details.
- Seven new screens await user review. No runtime UI was implemented in this prototype pass.

## 2026-10-17 — Hand-drawn Arctic main UI

- Approved direction: hand-drawn structure with precise native controls and charts; avoid applying a strong irregular border to every row.
- Canonical palette is `output/imagegen/arctic-palette/qyube-arctic-palette-v1.png` and `prompt-v1.md`: Snow `#FBFAF8`, Frost `#F3F3F0`, Paper `#FFFFFF`, Ink `#212121`, Fjord `#527386`, Ice `#DCE8ED`, Divider `#E0E0E0`, Interrupted `#AB665C`.
- Existing `SettingsSurfaceCard` is the highest-leverage seam: it is shared by Settings, Analytics, About, General, Appearance, timeline, and empty states.
- Existing `QyubeInkBorder` deliberately varies its path but its top control point can put a 1.3 pt stroke too close to clipping. The shared replacement must inset the path safely.
- Settings exists in two surfaces: standalone `Qoma/UI/SettingsView.swift` and in-app `QyubeJournalSettingsView`; both already reuse shared navigation/card components.

## 20 Oktober 2026 — roadmap compact

- Rencana lama memuat keputusan yang sudah digantikan (goal, nama tugas, menu bar, break); konteks compact terbaru menjadi acuan redesign.
- Start/Pause/Resume/Stop, repository lokal, catches, analytics, preferences dan Sparkle memiliki fondasi existing: integrasikan sesudah UI, sebelum membangun layanan baru.
- Atlas imagegen adalah inventaris, bukan ukuran/font presisi atau otorisasi fitur tambahan. Detail sesi terbaru memakai form + catches di bawah Mode + Start; Catalog lima kolom hanya artwork dengan latar empat rarity.
- Rincian pekerjaan dan syarat selesai disimpan di `design/qyube-compact-roadmap.md`.
