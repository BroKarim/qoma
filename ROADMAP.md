# Dzenn — Four-Month Release-1 Roadmap

**Planning horizon:** 16 weeks
**Scope authority:** `PRODUCT_SPEC.md`
**Current state:** documentation and architecture planning; implementation has not started.

## Delivery principle

Build the reliable session/data spine before the illustration-heavy surfaces. Deep Focus is isolated behind a feature boundary so an external entitlement delay never holds the release hostage.

## Milestone overview

| Milestone | Weeks | Outcome |
|---|---:|---|
| M0 — Product freeze and technical foundation | 1–2 | Brand/data/architecture decisions are executable; old Qoma assumptions are isolated. |
| M1 — Reliable session and collection engine | 3–5 | Timer, tags, banking, catch events, Catalog data, and tests work without final art. |
| M2 — macOS experience | 6–8 | Penguin floating panel, Catalog, Aquarium, and core Mac analytics integrate with the engine. |
| M3 — iOS companion | 9–11 | Native iOS session app, collection, analytics, background behavior, and Store foundation work. |
| M4 — Premium, sync, and Deep Focus | 12–13 | Purchase gating, CloudKit sync, and Deep Focus readiness/contingency are resolved. |
| M5 — Polish, balance, and release | 14–16 | Content balance, accessibility, QA, signing/store preparation, and release candidate. |

## Week-by-week plan

### Week 1 — Freeze product contract and audit migration

- Adopt `PRODUCT_SPEC.md` as the new source of truth; archive/mark older conflicting Qoma TODO/release claims.
- Decide final Dzenn bundle identifiers, app-group/iCloud container naming, and data migration policy from existing Qoma JSON.
- Establish the Mac App Store as the primary Release-1 channel required for Universal Purchase; assess whether the old direct-DMG/Sparkle channel is retired or retained as a separately licensed channel later.
- Validate whether the retained macOS app/activity analytics can meet App Sandbox and App Review requirements.
- Map current dependencies: `FocusSessionManager`, `TimerService`, `WindowManager`, analytics stores, settings panes, tests, Sparkle.
- Create a new domain model boundary rather than adding the game loop directly to current global-singleton code.

**Exit gate:** a migration design exists and no ambiguous old Pomodoro/break requirement remains in active work.

### Week 2 — Project structure and design system

- Add shared platform/domain modules or targets as appropriate for macOS+iOS.
- Define SwiftData schemas and migration strategy.
- Define semantic design tokens, localization keys (English/Bahasa Indonesia), illustration naming, sound/haptic assets, and accessibility requirements.
- Prototype Canvas scene and Metal water effect in isolation; benchmark on baseline hardware.
- Submit/prepare Family Controls entitlement request immediately. This is a parallel external risk, not a dependency for week 3.

**Exit gate:** domain data compiles, animation spike meets the 30-FPS target, entitlement submission is documented.

### Week 3 — Session state machine

- Replace break-cycle assumptions with the user-selected timer model: 10-minute default, 10–60 ruler, special 180-minute choice.
- Implement absolute-end-time timer, background/relaunch handling, active/completed/interrupted state, and actual-focus-time accounting.
- Implement tag and description editing, including last-tag-wins behavior.
- Add unit tests for start, stop, completion, interruption, relaunch recovery, and time calculations.

**Exit gate:** the session engine is deterministic and test-covered without any fishing UI.

### Week 4 — Catch events, five-minute banking, and Catalog domain

- Implement fishing-cycle scheduler, provisional catch state, reel/deposit transaction, five-minute bank transition, and interrupted-session rules.
- Implement rarity tables and hidden pity bookkeeping as configurable balance data.
- Implement Catalog discovery/count aggregation from catch events.
- Add tests for pre-five-minute cancellation, banking transition, duplicate counts, legendary/pity boundaries, and in-flight cancellation.

**Exit gate:** reward logic is correct in tests and inspectable without final art.

### Week 5 — Data migration and analytics foundation

- Complete SwiftData persistence and recoverable session snapshots.
- Define session/catch/tag queries for Day/Week/Month/Year analytics.
- Port only safe/useful existing macOS analytics; preserve app/tab analytics as a separate local-only concern.
- Add fixture data and performance tests for long histories.

**Exit gate:** offline data survives relaunch and analytics data queries are fast with a year of simulated catch events.

### Week 6 — macOS floating fishing scene

- Replace the timer-only floating panel with penguin, ice floe, fishing loop, bite/reel/deposit states, and optional timer presentation.
- Preserve panel dragging, Spaces/full-screen behavior, and device-local panel state.
- Connect scene animation to the session/catch engine; stop animation when hidden.
- Implement audio/haptic equivalents appropriate for macOS and preference toggles.

**Exit gate:** a Mac focus session visibly completes the full fishing loop and survives normal panel/window interactions.

### Week 7 — macOS Catalog, Aquarium, and Fishing Report

- Build Catalog with counts, locked Pro silhouettes, and detail screens.
- Build Aquarium with one visual entity per discovered item, Canvas paths, water shader, tap-to-detail, and Reduce Motion behavior.
- Build completion/interruption Fishing Reports.
- Validate rendering memory/CPU with all 48 launch entities.

**Exit gate:** the core Dzenn collection loop is usable end-to-end on macOS.

### Week 8 — macOS analytics and migration review

- Build Day Latest Haul with expandable full list, daily summary, and Week/Month/Year grids.
- Integrate focus/tag metrics and preserve macOS-only app/domain analytics with clearer permission/privacy controls.
- Validate existing Qoma data migration or explicitly choose a clean-start migration with user-facing release notes.
- Internal macOS alpha.

**Exit gate:** macOS alpha has timer, collection, analytics, and stable persistence.

### Week 9 — iOS app shell and timer

- Add iOS target/app shell and navigation for Session, Analytics, Aquarium, Catalog, and Settings.
- Implement iPhone portrait session UI, timer picker, session background behavior, local completion notification, and restore on relaunch.
- Keep iOS free of macOS app/tab tracking.

**Exit gate:** iPhone can complete and interrupt sessions reliably with local collection persistence.

### Week 10 — iOS collection and analytics

- Port Canvas Aquarium, Catalog, Fishing Report, and Day/period analytics interactions to iOS.
- Implement gestures plus grabber/chevron/`View all` accessibility affordances.
- Test Dynamic Type, VoiceOver labels, Reduce Motion, Low Power Mode, and small iPhone layouts.

**Exit gate:** iOS reaches feature parity for the core focus/collection loop.

### Week 11 — Asset and content production pass

- Produce, integrate, and review the 48-collectible minimum: Catalog art, Aquarium entity art, session icons, rarity metadata, and localized names/descriptions.
- Build Calm Sea/Deep Sea content tables and original visual themes.
- Add seeded debug/test tools for deterministic rarity and collection QA; exclude debug tooling from release.
- Run design review for visual consistency and legibility.

**Exit gate:** complete launch content is playable and no placeholder is required for core experience.

### Week 12 — StoreKit and entitlement-independent premium gating

- Implement Universal Purchase StoreKit products, entitlement state, Restore Purchases, and Free/Pro/Lifetime gating.
- Verify expiration behavior: existing items stay visible; only future Pro catching/biome access and Custom Deep Focus stop.
- Ensure upgrade prompts never interrupt an active focus session.
- Begin sandbox purchase testing on both platforms.

**Exit gate:** purchase states behave correctly without requiring Deep Focus to exist.

### Week 13 — Cloud sync and Deep Focus decision gate

- Implement optional private iCloud/CloudKit sync for append-only completed/interrupted eligible sessions and banked catches.
- Verify offline merge, duplicate avoidance, and active-timer isolation on two physical devices.
- **Decision gate:**
  - If Family Controls entitlement is approved: implement/validate Free default allow-list, Pro custom app list, Dzenn shield copy, and `Leave` behavior.
  - If approval is pending/denied: omit all Deep Focus UI from Release 1 and log the feature for the next release.

**Exit gate:** sync works; Deep Focus is either tested end-to-end or cleanly absent with no release impact.

### Week 14 — Balance, polish, and robustness

- Playtest catch cadence, legendary probability, pity thresholds, report pacing, and premium visibility.
- Tune no more than data/config values unless a real defect is found.
- Fix state recovery, performance, memory, animation, sound, and edge-case defects.
- Verify a large local history and all 48 Aquarium entities on supported devices.

**Exit gate:** Release Candidate 1 is feature complete.

### Week 15 — QA and store/release preparation

- Run unit, integration, migration, purchase, sync, accessibility, and manual device QA.
- Mandatory physical-iPhone Deep Focus tests if included: Screen Time authorization, Free defaults, Pro custom list, block shield, `Leave`, backgrounding, airplane mode, and expiry.
- Prepare App Store metadata, screenshots, privacy nutrition labels, subscription terms, support links, release notes, macOS signing/notarization and/or App Store distribution path.
- Update README, release process, and marketing copy to Dzenn; remove stale Qoma/break claims.

**Exit gate:** Release Candidate 2 passes the launch checklist with no unresolved P0/P1 defect.

### Week 16 — Release candidate and launch

- Final device regression and data-migration verification.
- Submit/release iOS and macOS according to the selected distribution strategy.
- Monitor crash reports, purchase restoration, sync health, and early player feedback.
- Create post-launch backlog: iPad-specific Aquarium, per-domain controls, manual decoration, new biomes, and any Deep Focus work deferred by entitlement.

**Exit gate:** Release 1 is live, or in review with a tested release candidate and clear release operations.

## Critical path and risk controls

| Risk | Control | Release impact |
|---|---|---|
| Family Controls entitlement approval is late | Request in week 2; isolate feature; omit UI if unavailable by week 13 | Does not block release. |
| Current Qoma JSON/singleton architecture resists feature work | Establish new session/data domain before UI work | Avoids accumulating redesign debt. |
| 48-item art scope expands | Lock minimum at 48; share behavior classes; do not add assets late without replacing none | Protects quality and QA time. |
| Cross-device conflicts | Sync only banked, completed/interrupted append-only records; never sync active timers | Preserves correctness. |
| Animation battery/performance | Canvas/Metal prototype in week 2; pause off-screen, cap at 30 FPS, honor Reduce Motion/Low Power Mode | Prevents late rendering rewrite. |
| Subscription trust concerns | Lifetime includes all future premium content; never revoke earned items | Maintains a clear customer promise. |
| Universal Purchase conflicts with legacy direct-DMG distribution | Make Mac App Store the Release-1 primary channel; do not promise shared purchases on DMG builds | Keeps the sales promise technically true. |

## Definition of done

Release 1 is complete when all acceptance criteria in `PRODUCT_SPEC.md` pass, plus:

- Automated tests cover the session and banking domain rules.
- Manual QA covers Mac and physical iPhone behavior.
- Release documentation, privacy copy, subscriptions, artwork credits/licenses, and distribution signing are internally consistent.
- No stale Qoma/Pomodoro/break claim remains in user-facing Release-1 documentation.

## Explicit non-goals for the four-month window

- A design system redesign unrelated to Dzenn.
- Manual aquarium decoration/placement.
- Per-site browser filtering.
- iPad-specific layout design.
- An online account/backend/social feature.
- Any delay to the core release solely to wait for Deep Focus entitlement approval.
