# Task Plan: qyube macOS Pivot and Prototype

## Goal

Define the macOS-first product direction and prototype scope for **qyube**: a cozy, Antarctic focus companion where a watercolor penguin fishes through a focus session, while gentle visual friction discourages unplanned app switching.

This document replaces the previous Dzenn documentation plan for the macOS work. The iOS product plan is intentionally unchanged and will be revisited later.

## Current Phase

Ready for prototype iteration — the macOS pivot contract is recorded below.

## Product Direction

qyube is a focused-work companion, not a conventional Pomodoro app. A user names one concrete task, selects the apps they need, chooses a duration, and starts. The main app then gives way to two independent desktop companions:

- a compact floating timer panel that shows remaining time only;
- a transparent penguin fishing panel that remains on screen throughout the session.

The penguin continuously fishes during a session. This fishing loop, the catch banking rules, and the post-session Fishing Report remain a defining part of qyube. They are not replaced by the app-selection pivot.

The home UI and floating companion now use a calm neutral palette: white, charcoal, warm gray, and a small terracotta accent. Do not add blue to the latest floating companion artwork. The UI should have illustrated warmth and small tactile details rather than an austere minimalist productivity look.

The current approved home and New Session visual baseline is [01-home-floating-form.png](design/qyube-concepts-v3/01-home-floating-form.png): a warm-white workspace, compact left navigation, centered fishing illustration, and elevated New Session card on the right. Its palette and hierarchy should carry through the remaining macOS prototype screens.

The floating companion's character states, art constraints, screenshot-derived size estimates, event timing, permission fallback, and the boundary between home artwork and transparent companion artwork are specified in [design/qyube-floating/ART_DIRECTION.md](design/qyube-floating/ART_DIRECTION.md). That document is the implementation-facing source of truth for the companion renderer.

## macOS Session Flow

```text
Main app
  → New Session
  → Configure task, duration, and allowed apps
  → Start
  → Active focus session
      ├─ floating timer panel
      ├─ transparent penguin fishing companion
      └─ gentle distraction response for unallowed apps
  → Session end
      ├─ Continue
      └─ Done → Fishing Report → Main app
```

### 1. Main app

- The main app is the only place to create a new session.
- Its primary action is `New Session`.
- It retains the two supporting product surfaces: **Insight** and **Catalog**.
- Aquarium is deferred from the first macOS phase. Catalog replaces it as the collection surface and shows illustrated cards for every collectible.
- During an active session, the user reaches the main app by ending that session. The main app does not stay open as a third active-session panel.

### 2. New Session setup

The setup page collects three required choices before `Start`:

1. A clear task name or intention.
2. A duration. The current product baseline remains a default 10-minute session, normal choices from 10 to 60 minutes, and a distinct 180-minute option.
3. The applications needed for that task. This is an allow-list, not a list of apps to block.

Tags and a longer optional note may remain available if they support the setup without competing with the three primary choices.

### 3. Active focus session

- Starting a session hides the setup and creates two independent floating surfaces.
- The **timer panel** shows only the remaining time in qyube styling. It can be closed by the user.
- The remaining time also appears in the menu bar as text only, without a qyube logo or any accompanying icon. Clicking it restores the timer panel after it is closed. If the floating timer is already open, clicking the menu-bar time does nothing; it must not toggle, open a menu, or activate the main app.
- The **penguin panel** remains visible even when the timer panel is closed. It has no rectangular background or window card; the penguin, fishing rod, bucket, ice floe, and animation are the visible content.
- Both surfaces must be usable as lightweight desktop companions, including over other apps and across Spaces where macOS permits it.
- Use the screenshot-derived starting footprints: timer about 210 × 143 pt; penguin artwork about 118 × 118 pt with a transparent companion canvas. These are estimates assuming a 2× Retina screenshot and must be checked on a target Mac.

### 4. Allowed apps and visual friction

- qyube observes when the frontmost application changes during a focus session and compares it with the session allow-list.
- An allowed app receives no distraction effect.
- An unallowed app remains usable. qyube must not block launch, hide its controls, capture its keyboard input, prevent clicks, or force the user to stop the session.
- qyube responds with a temporary, click-through visual interruption above that app. The first prototype should explore an increasing school of fish that partially crosses the app window while leaving the user able to read and interact with it.
- A secondary visual response can be tested, such as a brief dimming or an animated light change, only if it does not cause flicker, visual strain, or obscure important content.
- The penguin can react with brief contextual animation. Its personality should be warm and playful, never shaming or hostile.
- The reaction begins on the first rendered frame after a foreground-app event. Do not add a debounce or artificial waiting interval.
- The response is intentional friction: it makes an unplanned detour less pleasant to linger in while preserving an emergency escape hatch for messaging, calls, and work exceptions.

### 5. Fishing, catches, and ending a session

- Fishing continues during the entire active session, independent of whether the user opens an allowed or unallowed app.
- Preserve the approved loop: randomized idle wait, bite cue, reel/pull, deposit into bucket, then return to idle fishing.
- Catch visuals use one generic fish and one tree-shaped proxy for non-fish catches. After reeling, each goes directly into the bucket; no reveal, celebration, or post-deposit pause. Immediately resume casting/fishing, including for new or rare catches. Actual collectible art and identity appear in Catalog and Fishing Report; the proxy does not alter catch probabilities or banking rules.
- Minimum artwork batch: [eight poses with and without glasses plus shared props](design/qyube-minimum-assets-v1/README.md). Both variants follow the watercolor charcoal reference and omit penguin shadows; final variant selection is pending review.
- Preserve the five-minute banking threshold. Catches are visible from the start but remain provisional until five active minutes. Stopping earlier removes provisional catches; eligible deposited catches bank as already specified.
- At the time limit, present the user with `Continue` or `Done`.
- `Done` leads to the Fishing Report, which shows the session’s catch result, discoveries, and relevant highlights, then returns the user to the main app.
- The exact behavior of `Continue` (additional duration choice and how the result groups in the report) is a prototype question. It must preserve the existing banking and count rules.

## Core Product Surfaces

| Surface | Purpose in the macOS pivot |
|---|---|
| Main app | Start a session; view Insight and Catalog when no session is active. |
| New Session | Name one task, choose duration, select allowed apps, then start. |
| Timer panel | Show remaining time only; close and restore from the menu bar. |
| Penguin panel | Transparent always-present fishing companion and catch animation. |
| Distraction overlay | Click-through fish-based visual friction over an unallowed foreground app. |
| Fishing Report | Reveal session catches when the user finishes. |
| Catalog | Illustrated collectible cards; discovery state, rarity, details, and counts. |
| Insight | Session history, focus time, completion/interruption data, task/tag distribution, and unallowed-app detours where permission and platform constraints allow. |

## Collection Contract

- Catalog is the phase-one collection experience.
- It displays all available collectibles as illustrated cards. Undiscovered entries may use silhouettes; discovered entries show art, name, rarity, and total count.
- The Catalog count increases only from banked deposited catches.
- Existing collection content remains safe when a session is interrupted after the five-minute threshold.
- Aquarium, manual decoration, and biome presentation are deferred from this macOS prototype and should not determine its navigation or core layout.

## Insight Contract

- Insight is supportive evidence of focus, never a punitive scorecard.
- It records focus time, completed and interrupted sessions, session task, duration, and catch summaries.
- It may record unallowed foreground-app detours only after the user gives the appropriate macOS permission and understands what is recorded.
- For the first prototype, use representative data and focus on whether a user can understand their session outcome at a glance.

## Technical Prototype Constraints

- Ask for app-monitoring permission in context, only when a selected mode needs it. If permission is denied during setup, return to the same New Session form with task, duration, and selections preserved; offer retry/Open System Settings or switch to Timer only. Do not start a partial session or show an error pose.
- If permission is revoked during a session, keep the timer and fishing alive, stop app-aware behavior immediately, and show a small non-modal status message. Do not discard the session.
- If permission is unavailable, qyube still runs focus sessions, fishing, timer, Catalog, and Insight without app-aware visual friction.
- qyube can detect the frontmost app through macOS workspace notifications. Accurate window-relative overlay placement may require Accessibility access and must be proven in a small technical spike.
- The overlay must be qyube-owned and mouse-transparent, so the foreground app keeps receiving normal input.
- macOS App Sandbox restricts the use of Accessibility APIs. Before committing to a Mac App Store delivery promise for window-following effects, validate the exact capability and distribution path with a sandboxed build.
- The prototype must provide Reduce Motion support: replace fish swarms and reactive motion with a restrained static cue.

## Prototype Deliverables

1. **Main app / New Session** — a high-fidelity flow from `New Session` to task, duration, and allowed-app selection.
2. **Active-session companions** — timer-open, timer-closed, and menu-bar restoration states, with the transparent penguin panel unchanged across them.
3. **Distraction response** — a visual state showing an allowed app uninterrupted and an unallowed app receiving click-through fish interference.
4. **Session end** — `Continue`, `Done`, Fishing Report, and return to the main app.
5. **Catalog and Insight** — enough screens and sample states to test their place in the home experience.
6. **Technical spike** — a minimal macOS proof of frontmost-app detection, click-through overlay behavior, and permission fallback.
7. **Floating art/animation contract** — fixed-scene rules, character identity, screenshot-derived window sizes, state table, timing guidance, and permission fallback in `design/qyube-floating/ART_DIRECTION.md`.

## Phases

### Phase 1: Freeze macOS Pivot Contract

- [x] Rename the product direction to qyube and establish its Antarctic visual identity.
- [x] Retain fishing, catch banking, Fishing Report, Insight, and Catalog.
- [x] Defer Aquarium from phase one.
- [x] Define the single-task, allowed-app session setup.
- [x] Define the independent timer and penguin companion behavior.
- [x] Define visual friction instead of total app blocking.
- [x] Record floating companion art and animation requirements in `design/qyube-floating/ART_DIRECTION.md`.
- **Status:** complete

### Phase 2: Prototype the Session Journey

- Active-session open/closed visual drafts: [design/qyube-active-session-v1/README.md](design/qyube-active-session-v1/README.md). Generated for review; approval is pending.
- [ ] Create and review the New Session experience.
- [ ] Create and review active companion states.
- [ ] Create and review the unallowed-app visual interruption.
- [ ] Create and review completion, Continue, Done, and Fishing Report states.
- **Status:** in progress

### Phase 3: Validate macOS Interaction Feasibility

- [ ] Prove foreground-app detection and no-permission fallback.
- [ ] Prove a mouse-transparent qyube overlay does not interfere with the underlying app.
- [ ] Determine whether a window-relative overlay can ship under the intended sandbox/distribution constraints.
- [ ] Record performance, accessibility, multi-display, full-screen, and Space behavior.
- **Status:** pending

### Phase 4: Turn the Accepted Prototype into an Implementation Plan

- [ ] Update the macOS architecture and data plan from the accepted prototype.
- [ ] Define the product state machine and persistence boundaries.
- [ ] Sequence implementation milestones and validation gates.
- **Status:** pending

### Phase 5: Revisit iOS Separately

- [ ] Review iOS only after the macOS prototype and implementation approach are accepted.
- **Status:** deferred

## Decisions Made

| Decision | Rationale |
|---|---|
| Product name is qyube | The name derives from “cube” and supports a cute Antarctic penguin identity. |
| macOS pivots toward a single-task, allowed-app workflow | It gives the focus session a clearer intention and a useful desktop intervention point. |
| Unallowed apps remain usable | Visual friction preserves access for legitimate exceptions and emergencies. |
| Fish interference is the first distraction response | It fits the fishing collection world and can become gradually more distracting without blocking work. |
| Penguin fishing remains the central reward loop | The animated catch and post-session result are qyube’s principal distinction from Kiki. |
| Timer and penguin are separate surfaces | The user can remove the time panel without losing the companion. |
| Floating dimensions use the screenshot as a starting reference | The estimated 210 × 143 pt timer and 118 pt penguin preserve Kiki's approximate desktop footprint without treating it as a published specification. |
| Every state reuses the fixed floe and bucket | Stable scene geometry keeps the penguin's states visually registered. |
| App and session triggers change logical state immediately | The required zero-delay reaction stays responsive; a short animation transition is visual motion, not reaction delay. |
| Permission denial keeps the New Session draft and offers Timer only | Graceful degradation lets the user complete focus without app monitoring and avoids losing setup input. |
| Catalog replaces Aquarium in phase one | It retains collection value while reducing visual-system scope. |
| iOS is deferred | The current design work and technical uncertainty are specific to macOS. |

## Open Prototype Questions

1. What exact additional-duration interaction follows `Continue`?
2. Does qyube show the fish effect around the whole app window, along its edge, or in a small companion cluster near the active area?
3. How quickly should the interruption escalate before it becomes distracting enough to redirect attention but remains safe and accessible?
4. How should a user temporarily mark an unallowed app as necessary without turning the allow-list into a loophole?
5. Which Insight metrics are valuable enough to show on the main app without making the product feel like surveillance?

## Errors Encountered

| Error | Attempt | Resolution |
|---|---:|---|
| `codex/` branch prefix could not be created | 1 | The local Git reference layout rejected the nested branch name; created `qyube-macos-pivot-plan` instead. |
| Sandbox could not write Git refs | 1 | Created the requested branch with approved Git access. |

## Notes

- This plan governs macOS prototype and planning work. It does not authorize broad implementation changes yet.
- Existing working-tree changes are user-owned and remain outside this documentation commit.
- Floating animation implementation details live in `design/qyube-floating/ART_DIRECTION.md`.
