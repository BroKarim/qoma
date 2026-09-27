# Dzenn — Release 1 Product Specification

**Status:** Approved product baseline
**Platforms:** macOS 14+, iOS 17+
**Target:** Release 1 within four months
**Working product name:** Dzenn

## 1. Product definition

Dzenn is an offline-first focus-session app where completed focus time creates a calm fishing-and-collection loop. It is **not** a conventional Pomodoro app: there is no default 25/5 cycle and no automatic break mode.

The user starts an intentional timer, watches a penguin fish, earns discoveries, and builds a living Aquarium plus a Catalog. Focus is the action; the collection is the gentle feedback loop.

### Product promises

- The timer remains reliable when the app is in the background.
- A focus session is valuable even if it is interrupted after meaningful time has elapsed.
- The collection never disappears because a subscription expires.
- The core product works without an account or internet connection.
- iOS and macOS share collection progress optionally, but never fight over a live timer.

## 2. Terminology

| Term | Meaning |
|---|---|
| **Focus session** | One user-selected timed session. It replaces the old product’s “Pomodoro” concept. |
| **Completed session** | A session whose countdown reaches zero. It increments Completed Sessions. |
| **Interrupted session** | A session stopped before zero. Its real duration still counts as Focus Time. |
| **Provisional catch** | A visual catch made before the session reaches five active minutes; it is not yet saved. |
| **Banked catch** | A saved catch event. It increments Catalog count and can appear in Aquarium. |
| **Catalog** | Collection index that records discovery and total count for each species/item. |
| **Aquarium** | A living top-down visual display that renders one instance of each discovered species/item. |
| **Biome** | A fishing/Aquarium environment and its loot pool. Release 1 has Calm Sea and Deep Sea. |
| **Deep Focus** | Optional iOS Screen Time restriction mode that shields non-allowed apps during a session. |

## 3. Platforms and product surfaces

| Surface | macOS | iOS |
|---|---|---|
| Timer entry | Menu bar and main app | Main app |
| Active-session visual | Floating always-on-top penguin-fishing panel | Full session screen; app may background; later Live Activity/Dynamic Island support |
| App/tab analytics | Yes, local-only and permission-based | No |
| Catalog | Yes | Yes |
| Aquarium | Yes | Yes; iPhone portrait is primary layout |
| Deep Focus | No in Release 1 | Yes, subject to entitlement approval |
| Cloud sync | Optional collection/session sync | Optional collection/session sync |

## 4. Focus session rules

### 4.1 Timer selection

- Default selection is **10 minutes**.
- The timer picker is a ruler-like iOS control for normal **10–60 minute** choices.
- **180 minutes** is a separate first/special choice before the regular ruler range.
- There is no automatic break timer and no default Pomodoro cycle.
- A user can choose or create a tag before a session. The first onboarding tag is `Work`, but all tags are user-defined.
- A user may add a short description of what they are doing before or during the session.

### 4.2 Session state contract

```text
idle → active → completed
             └→ interrupted
```

- Actual elapsed active time is always stored as Focus Time.
- Only `completed` increments the Completed Sessions metric.
- If a tag changes mid-session, the **last selected tag applies to the whole session**. This is intentional: it lets a user correct a forgotten/wrong tag.
- The active timer is device-local. It is not synced through iCloud.

### 4.3 End-of-session presentation

| Outcome | Result |
|---|---|
| Countdown reaches zero | Full celebratory Fishing Report: total catch count, new discoveries, rare/legendary highlights, and Aquarium action. |
| Stopped at or after five active minutes | Compact Fishing Report labelled `Interrupted`; banked catches remain visible. |
| Stopped before five active minutes | Gentle message that the provisional catches return to the sea; no collection report. |

## 5. Fishing and reward loop

### 5.1 Visible animation cadence

Each fishing cycle uses this rhythm:

1. Wait for a randomized **6–10 seconds**.
2. A bite triggers a visual cue and a **2–6 second** reel/pull sequence.
3. The catch enters the bucket; a short deposit beat completes the loop.
4. The penguin returns to idle fishing.

The typical end-to-end loop is about **8–16 seconds**. Small fish tend to reel faster; larger catches can take longer. The game feel should resemble a frequent, rewarding fishing loop rather than a sparse productivity reward.

### 5.2 Banking threshold

- Every catch is animated from the first seconds of a session.
- Until five active minutes, all catches are provisional.
- At five active minutes, previously provisional catches bank immediately.
- After five active minutes, every deposited catch banks immediately.
- Stopping before five minutes removes all provisional catches from the session and does not change Catalog/Aquarium.
- Rare, legendary, and non-fish items may appear before five minutes. Their rarity does **not** depend on a session finishing.

### 5.3 Catch transaction rules

- The reward is rolled when the reel phase begins.
- It becomes a banked event only when the catch is deposited in the bucket and the session is eligible to bank it.
- Ending the session or terminating the scene during a reel does not grant that in-flight catch.
- The pity counter only advances from banked catches, never provisional ones.

### 5.4 Rarity and anti-frustration model

- Legendary may appear on the first catch.
- Base legendary probability is approximately **1 / 2,000** eligible catches.
- If no new legendary has appeared after **1,200 banked catches**, its chance rises gradually.
- A not-yet-discovered legendary is guaranteed by **2,500 banked catches** without one.
- The pity system is hidden. There is no visible meter, countdown, or “guaranteed soon” UI.
- Exact probabilities remain balance values to be adjusted through playtesting, but the structure above is a product invariant.

## 6. Collection design

### 6.1 Launch content

- Release 1 ships with a minimum of **48 collectibles**:
  - 24 Free
  - 24 Pro/Lifetime
  - at least 3 Legendary items
- Types include ordinary fish, unusual fish/creatures, marine plants, trash, and sea objects such as a submarine.
- More content may be added only if it does not dilute art, animation, or testing quality.

### 6.2 Catalog

- First discovery opens the item’s Catalog entry.
- Each later catch increments its count, for example `Clownfish ×42`.
- Free users can see silhouettes for all Pro items, including rare and legendary content. Locked entries clearly state the required Pro biome/access.
- Catalog visibility is never time-gated. Only the ability to catch Pro content requires Pro/Lifetime.
- Catalog is the authoritative display for counts, discovery state, rarity, and item details.

### 6.3 Aquarium

- Every discovered species/item appears **once** in Aquarium regardless of its Catalog count.
- Aquarium is a self-organizing, living visual display. Users do not manually place, decorate, or rearrange objects in Release 1.
- Tapping an Aquarium entity opens its Catalog detail.
- Fish move in a top-down view with procedural body trails. Plants and objects use suitable slow/static behaviors.
- The Aquarium is an artful representation of the collection, not a literal inventory of every individual catch.

### 6.4 Biomes

| Biome | Access | Purpose |
|---|---|---|
| Calm Sea | Free | Default fishing and Aquarium environment; Free loot pool. |
| Deep Sea | Pro/Lifetime | Premium environment and premium loot pool. |

Release 1 deliberately excludes manual decoration, user placement, breeding, trading, and multiplayer mechanics.

## 7. Analytics

Analytics are about focus and collection progress, not pressure.

### 7.1 Periods

- **Day:** calendar day in local device time.
- **Week:** Monday through Sunday.
- **Month:** calendar month.
- **Year:** calendar year.

### 7.2 Day view

1. **Latest Haul** at the top displays every catch from the latest session as a Polaroid-style card. Repeats remain repeated: ten clownfish create ten cards.
2. The section initially previews, then expands to the full, uncapped session result through upward drag, grabber/chevron, or a small `View all` button. Dragging downward collapses it.
3. **Daily Summary** below aggregates all sessions that day by species/item, focus-time distribution, comparison with yesterday, tag distribution, and special-catch counts.

### 7.3 Week, month, and year views

- Retain the latest-haul concept but render compact bordered thumbnails in a responsive grid (roughly five or more columns depending on device width), not Polaroid cards.
- Use virtualization/lazy grids so long histories do not load every image at once.
- Preserve the same focus, tag, completed/interrupted, and special-discovery summaries at the selected period granularity.

### 7.4 macOS activity analytics

- Existing app/domain analytics stays macOS-only, permission-based, and local-only.
- It is not synced to iCloud.
- iOS intentionally does not show “which apps were opened during focus.”

## 8. Deep Focus (iOS)

### 8.1 Access model

| Tier | Capability |
|---|---|
| Free | Default Deep Focus allow-list; user cannot customize it. |
| Pro/Lifetime | Custom Deep Focus allow-list selected before the session. |

The Free default allow-list contains Phone, Messages, Maps, Camera, Wallet, Settings, and necessary system services. It excludes browsers, social apps, mail, games, and other discretionary apps.

### 8.2 Behavior

- Deep Focus is enabled before a focus session begins and uses Screen Time authorization.
- Release 1 Custom Deep Focus selects **applications only**. There is no per-domain website control; Safari is either allowed as an app or blocked as an app.
- The allow-list is locked while a session is active.
- Opening a blocked app displays an iOS system shield styled with Dzenn’s icon, title, subtitle, colors, and action label. Its layout remains system-owned.
- Shield copy:

  ```text
  Deep Focus
  Sorry, this app isn’t allowed while your focus session is running.
  Leave
  ```

- Tapping `Leave` ends the session as interrupted, releases the shield, and returns the user to Home. The standard five-minute banking rules still apply.
- If authorization is declined, timer sessions still work without Deep Focus.

### 8.3 Release contingency

Family Controls distribution entitlement approval is a dependency outside the project. If it is not approved in time, Deep Focus is omitted from the Release-1 UI and the rest of the product ships. It is never represented by a fake/disabled “coming soon” button.

## 9. Monetization

### 9.1 Prices and access

| Offering | Price | Access |
|---|---:|---|
| Free | $0 | Full core timer, Calm Sea, Free collectibles, Catalog/Aquarium/analytics basics, default Deep Focus when available. |
| Monthly Pro | $0.99/month | Pro content and Custom Deep Focus while subscription remains active. |
| Yearly Pro | $9.99/year | Same Pro access while subscription remains active. |
| Lifetime | $20 one time | Every Pro feature and all present/future premium content permanently. |

- Universal Purchase means the same Apple ID unlocks eligible iOS and macOS access with one purchase.
- There is no separate free trial: the Free tier is the trial experience.
- Restore Purchases is always available.

### 9.2 Distribution constraint for Universal Purchase

Universal Purchase requires the iOS and macOS builds to participate in the same App Store product configuration. Therefore, the **Mac App Store build is the primary Release-1 distribution path** for the shared Monthly, Yearly, and Lifetime entitlement.

- The legacy direct-DMG/Sparkle channel cannot read or share an App Store subscription/Lifetime receipt.
- If a direct Mac build is retained later, it must be treated as a separate distribution policy; it must not promise the shared Universal Purchase without an additional account/entitlement system.
- Existing macOS app/activity tracking must be validated under App Sandbox, signing, and App Review requirements early in the roadmap.

### 9.3 Subscription expiration

When Pro subscription expires:

- Never delete, hide, or disable already discovered collection entries.
- Continue displaying all previously earned items in Catalog and Aquarium.
- Remove access only to catching new Pro items, using premium biomes, and Custom Deep Focus.

### 9.4 Upgrade UX

- Never interrupt an active session with an upgrade prompt.
- Offer upgrade only from a locked Catalog silhouette, a Pro biome choice, or Custom Deep Focus.
- There are no paid random draws, consumables, or gacha purchases.

## 10. Data, sync, privacy, and reliability

### 10.1 Local data

- Use SwiftData for Release-1 session, catch, catalog, tag, and preference domain data.
- Catch records store lightweight identifiers and metadata; illustrations are bundled/referenced once, never duplicated per catch.
- The app must remain fully usable offline.

### 10.2 Optional iCloud sync

- iCloud Sync is presented in onboarding and defaults to **off**.
- It syncs banked catch events, catalog/discovery state derived from them, and completed/interrupted eligible sessions.
- It does not sync active timers, transient provisional catches, floating-panel position, macOS permissions, or macOS app/tab analytics.
- Sync uses append-only records with unique session/catch IDs. Counts derive from the merged catch events rather than syncing mutable aggregate counters.

### 10.3 Privacy

- No mandatory account.
- No server is required for core timer/collection behavior.
- macOS productivity analytics needs explicit permissions and remains local unless the user separately enables an unrelated export feature in a future release.
- Any analytics/telemetry added later must be opt-in and documented separately.

## 11. Visual, audio, accessibility, and performance

### 11.1 Rendering

- Use original 2D illustrated assets; reference material informs interaction rhythm, not copied visual art.
- Use SwiftUI Canvas for 2D drawing and a restrained Metal shader for water ripples/caustics.
- Fish movement uses deterministic procedural paths and follow-the-leader/spine-trail segments.
- The fishing panel and Aquarium animate at 30 FPS while visible.
- Off-screen scenes stop animating. Low Power Mode and Reduce Motion lower or simplify the visual workload.

### 11.2 Audio and accessibility

- Catch sound, ambient sound, and haptics are independently configurable.
- Sound defaults to off on first launch.
- Reduce Motion preserves the reward loop but simplifies trails, ripples, and nonessential motion.
- Latest Haul has visible controls in addition to gestures so it remains discoverable and VoiceOver-accessible.
- Release 1 ships in English and Bahasa Indonesia.

## 12. Explicitly deferred beyond Release 1

- Automatic breaks and Pomodoro cycles.
- Manual Aquarium placement/decorating.
- Per-domain Deep Focus web blocking.
- iPad-specific Aquarium layout.
- Live cross-device active timer synchronization.
- Trading, multiplayer, breeding, social feeds, and paid random draws.
- New visual biomes/content beyond the first two, except where safely added before launch.

## 13. Release-1 acceptance criteria

Release 1 is ready only when:

1. A 10–60/180-minute focus session is reliable on both platforms, including background behavior.
2. Fishing cadence, five-minute banking, interrupted-session handling, Catalog counts, and one-per-species Aquarium rendering work deterministically.
3. Offline data survives relaunch and iCloud sync merges eligible data without duplicates when enabled.
4. Analytics accurately distinguishes focus time, completed sessions, interrupted sessions, tags, and latest haul periods.
5. Pro/Lifetime state gates only future premium access and never removes earned collection data.
6. Deep Focus, if included, is validated on physical iPhones for authorization, shielding, `Leave`, backgrounding, purchase gating, and accessibility.
7. If Deep Focus entitlement is not approved, its release removal does not block any other criterion.
