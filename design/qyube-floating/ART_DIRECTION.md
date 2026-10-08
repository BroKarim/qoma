# qyube Floating Companion: Art Direction and Animation Contract

**Status:** Ready for implementation planning
**Scope:** macOS floating penguin companion and timer sizing; initial animation behavior
**Audience:** implementation agents, animation/art agents, reviewers
**Product:** qyube
**Platform focus:** macOS first; iOS is explicitly out of scope for this document

## 1. Purpose

Build a small, transparent floating companion for active focus sessions. The penguin should feel alive through articulated 2D movement while preserving one recognizable character and one fixed ice-floe scene across every state.

The animation should support the focus loop without pulling attention away from the user's work. State changes caused by session events or foreground-app changes start immediately. No artificial waiting period is added before the character reacts.

## 2. Normative rules

- **MUST** keep the ice floe geometry, scale, canvas position, texture, and shading identical across all character states.
- **MUST** keep the bucket geometry, scale, and location identical across all character states.
- **MUST** preserve the same penguin identity, proportions, palette, face, and illustration style across all states.
- **MUST** keep the companion window transparent outside the foreground artwork.
- **MUST** begin a reaction on the first rendered frame after its triggering event is received.
- **MUST NOT** add an arbitrary timer or debounce before reacting to an app-activation or session-state event.
- **MUST NOT** change the ice floe, bucket, or overall companion layout to express a character state.
- **MUST NOT** count a catch before it has been deposited in the bucket.
- **MUST** move each reeled catch straight into the bucket, then immediately begin casting/fishing again. No reveal, proud hold, celebration, or post-deposit delay is added, including for new or rare catches.
- **MUST** use one generic fish appearance for fish catches and one tree-shaped visual proxy for non-fish catches in the floating scene. Actual collectible identity remains separate from this rendering choice.
- **MUST NOT** add a penguin cast-shadow layer.
- **SHOULD** keep idle motion quiet and low-amplitude.
- **SHOULD** prefer articulated watercolor/charcoal layers and property animation over full-canvas frame replacement.
- **MAY** use a small number of authored image poses for expressive moments that do not deform well as a rig.

## 3. Reference size analysis

The supplied macOS desktop screenshot is **2940 × 1912 pixels**. The floating timer is approximately **420 × 285 screenshot pixels**. The penguin artwork near the lower-right is approximately **235 × 235 screenshot pixels**.

Assuming this screenshot is a 2× Retina capture, use these initial logical-size targets:

| Surface | Screenshot estimate | Initial logical target | Notes |
|---|---:|---:|---|
| Timer panel | 420 × 285 px | **210 × 143 pt** | Match Kiki's approximate footprint. qyube's timer visual stays in qyube's approved style. |
| Penguin artwork | 235 × 235 px | **118 × 118 pt** | Transparent illustration only; do not add a visible card or background. |
| Penguin window canvas | — | **about 140 × 140 pt** | Allows a small transparent margin around the artwork and supports shadow-free edges. |

These are measurements from the user's screenshot, not official Kiki specifications. The Retina scale is an assumption. Recheck the point size on the target Mac before finalizing production dimensions.

The reference places the timer near the desktop's upper-left and the character near the lower-right. Treat these as initial placement cues only; persist each window's user-adjusted position and avoid covering the Dock, menu bar, or active controls.

The timer and penguin are separate floating windows. Closing the timer hides only the timer. The penguin companion stays visible while the session is active.

### Menu-bar timer interaction (confirmed)

- The qyube menu-bar item displays remaining time only, with no logo, clock icon, penguin icon, status dot, or app name.
- Clicking the time when the floating timer is closed restores that same timer at its saved position with the current remaining time.
- Clicking the time when the floating timer is already open does nothing. Do not toggle visibility, open a menu, activate the main app, move the panel, or restart the countdown.
- Closing the floating timer does not pause/end the session or hide the penguin. Both time displays use the same session clock.
- [Active-session visual drafts](../qyube-active-session-v1/README.md) show the open and closed states. These are awaiting user review.

## 4. Visual direction and fixed scene

### Palette and medium

Use the current qyube floating reference:

- warm white and snow white;
- charcoal black;
- graphite and warm gray;
- very restrained muted terracotta for a small event accent.

Do not introduce blue into this floating companion artwork. Keep the hand-painted charcoal/watercolor texture, soft irregular edges, and small, friendly penguin proportions from [the no-ripple master reference](../qyube-floating-prototype/01-active-fishing-no-ripple.png). The user selected the **no-glasses variant** as the primary candidate for the native prototype. Keep the glasses sheet as an alternative reference. Do not add a separate penguin shadow.

The first [minimum asset batch](../qyube-minimum-assets-v1/README.md) contains eight poses per variant and one shared property/effect sheet. The [native companion UI prototype](../qyube-companion-animation/README.md) now extracts the selected sheet into registered poses and articulated layers, renders a continuous fishing loop in SpriteKit, and connects it to the existing menu-bar session controls.

### Approved home and New Session prototype

Use [01-home-floating-form.png](../qyube-concepts-v3/01-home-floating-form.png) as the approved visual baseline for the macOS home screen and New Session setup. It is the current reference for the app's system design, composition, and palette; later prototype screens should feel like part of this same product.

- **Composition:** a narrow left sidebar; a large, warm-white work area; the penguin fishing illustration centered in the open area; and a distinct New Session card floating on the right. Keep generous breathing room while giving the form enough visual weight to read as the primary action.
- **Navigation:** Focus, Catalog, and Insight in the sidebar, with Settings anchored at the bottom. Aquarium remains deferred.
- **Form hierarchy:** task name, focus mode, relevant app selection, duration, then one clear Start session action. The app list is conditional on the selected mode; Timer only does not need app selection.
- **Palette order:** warm/off-white is dominant, charcoal is used for text and primary controls, warm gray supports surfaces and secondary text, and muted terracotta is a small action accent. Do not add blue to this approved direction.
- **Surface treatment:** use restrained macOS window chrome, fine neutral borders, softly elevated white cards, and rounded controls. Add warmth through illustration texture and small tactile details rather than decorative background imagery.
- **Artwork boundary:** this home-screen illustration is a compositional reference. Its visible splash/ripple belongs to the home artwork only; it does not override the floating companion rule below, where the initial shared scene has no prominent ripple layer. Keep the floating companion transparent outside its foreground artwork.

Treat the screenshot as the selected prototype baseline, not a pixel-perfect production spec. Preserve its visual hierarchy and theme while refining spacing, accessibility, and macOS-native interaction details in later prototype passes.

### Fixed scene layer

The following scene elements are shared by all states and must use the same source assets and anchor coordinates:

1. Ice floe.
2. Bucket.

The prominent concentric water rings were removed from the latest active fishing asset because they were too strong at floating size. The initial shared scene therefore has **no water-ripple layer**. If a water cue is added later, it must remain subtle, use one fixed anchor, and must not alter the floe or scene layout.

The fishing rod, line, fish, splash, and sleep marks are state or effect layers. They can move, appear, or disappear without changing the fixed scene.

### Penguin identity lock

Keep a canonical character sheet and rig with consistent:

- head-to-body ratio;
- cheek/face and belly shapes;
- charcoal cap and back;
- eye and beak placement;
- flipper and foot size;
- brush density, outline weight, and watercolor texture;
- scale and ground-contact anchor relative to the floe.

The penguin's body anchor stays registered to the floe. Do not resize or recenter the character between states to fit a pose.

## 5. Recommended 2D construction

Use a small articulated 2D rig for continuous motion. Keep painterly surfaces as transparent raster layers; vector paths are useful for simple lines and geometry but should not replace the watercolor character art.

Suggested scene tree:

```text
CompanionScene
├── FixedScene
│   ├── IceFloe
│   └── Bucket
├── PenguinRig
│   ├── Body
│   ├── Head
│   ├── LeftFlipper
│   ├── RightFlipper
│   ├── Feet
│   ├── Eyes
│   └── Beak
├── FishingRig
│   ├── Rod
│   └── Line
├── CatchEffect
└── StateController
```

For an initial native macOS spike, SpriteKit is a good fit: it supports 2D scenes, image textures, nodes, actions, and shared texture atlases on macOS and iOS. SwiftUI can host the surrounding application and floating-window controls. Keep the companion scene isolated behind a small state-and-event interface so the renderer can be swapped if needed.

A continuous fishing scene should combine small property movements (body breathing, head tilt, flipper/rod rotation, line curvature) with a few authored poses for catch and sleep. Avoid animating every body pixel as a new full-screen image each frame.

## 6. State model

The animation is driven by explicit state events. The state controller changes state immediately when the relevant event arrives. Animation duration describes how the new pose is drawn; it is not a delay before reacting.

| State | Entry event | Character action | Exit event |
|---|---|---|---|
| `sessionStarting` | User starts a valid session | Penguin hops onto the fixed floe with rod and bucket props; settles into fishing. | Setup animation completes, then `fishing`. |
| `fishing` | Session active; allowed app active; no catch beat in progress | Quiet breathing and head/rod micro-movement. Run the existing fishing cadence. | Bite, pause, unallowed-app event, session completion, or stop. |
| `catchDeposit` | Reeling brings a generic fish or tree proxy out of the water | Guide the catch directly into the bucket with a continuous arc, without holding/presenting it. | On landing, apply existing catch eligibility rules and immediately resume casting/fishing. |
| `sessionAlmostFinished` | Session enters its configured final interval | Keep fishing. Use one restrained cue such as a tiny bucket highlight or eye glance; no new pose and no repeated alerts. | Session reaches zero, is extended, or is stopped. |
| `sessionCompleted` | Timer reaches zero | Stop the fishing loop, bring the rod in, stand/turn toward the bucket, and look satisfied. | User selects Continue or Done. |
| `continue` | User selects Continue | Small upbeat reaction, cast the line again, and resume the same focus session according to the session contract. | Cast settles, then `fishing`. |
| `done` | User selects Done | Penguin pulls the bucket slightly closer or lifts it; hand off to Fishing Report. | Fishing Report is presented and the main app returns. |
| `stoppedBeforeBanking` | User ends session before five active minutes | Gently return provisional catches to the water; calm, non-punitive expression. | Session ends and the main app returns. |
| `pausedSleeping` | User pauses the session | Stop fishing; curl up and sleep on the fixed floe. Show small `z z z` marks from the mouth. | Resume returns to `fishing`; stop/completion follows its normal flow. |
| `distractedReaction` | A foreground app violates the selected mode's policy | Interrupt the current penguin action immediately; short flipper/foot hops and annoyed-but-gentle expression. | User returns to a permitted app or mode policy no longer triggers; recover to `fishing`. |
| `permissionUnavailable` | Required monitoring permission is denied or unavailable | No special character pose. Fishing and timer continue if the user chooses Timer only. | Permission is granted later or session setup changes. This is a capability/fallback state, not an art state. |

### State precedence

1. Session termination and `done` take precedence over a catch sequence.
2. Pausing cancels active character motion and enters sleep.
3. A distraction event interrupts the current pose immediately. An in-flight catch that has not reached the bucket is not granted, consistent with the existing catch transaction rule.
4. `catchDeposit` grants the catch only at bucket landing. New/rare catches have no separate celebration or hold; their actual identity is shown in Catalog and Fishing Report.
5. `sessionAlmostFinished` is a low-priority modifier; it must not override sleep, distraction, a catch sequence, or completion.

## 7. Timing guidance

The fishing cadence already defined for qyube remains authoritative: wait a randomized **6–10 seconds** for a bite; the reel/pull beat takes approximately **0.9–1.5 seconds**, followed by deposit. Keep the catch roll and banking transaction rules from the product plan unchanged.

The user's no-pause requirement removes the reveal/celebration and post-deposit wait. Immediately start the next cast/fishing action when the item lands; the ordinary in-water wait for the next bite still applies. Fish and tree proxies follow the same path and timing. A tree proxy does not create a new collectible type or alter the catch roll.

The values below are starting animation timings for prototype review, not product invariants. Tune them against the small floating size:

| Motion | Suggested time | Direction |
|---|---:|---|
| Idle breathing cycle | 3–5 s | Small vertical body scale/offset; seamless loop. |
| Head glance / micro-look | 0.25–0.45 s | Soft ease, then relaxed hold. |
| Session-start hop | 0.45–0.75 s | One compact hop and settle. |
| Bite reaction | 0.12–0.25 s | Immediate snap/lean; begins on the event frame. |
| Reeling body lean | 0.25–0.5 s | Strong readable lean with feet braced; rod bends. |
| Catch transfer into bucket | 0.35–0.6 s | Continuous arc from the reel directly to the bucket; no reveal hold. Deposit event fires on landing. |
| Post-deposit pause | 0 s | Immediately start the next cast/fishing action for either catch proxy. |
| Sleep transition | 0.6–1.0 s | Stop rod, yawn/curl, settle. |
| Wake transition | 0.4–0.7 s | Open eyes, stretch, take up rod. |
| Distraction reaction | 0.15–0.3 s to begin | Start immediately; hop burst lasts 0.8–1.5 s, then a quiet annoyed idle. |
| Completed-session settle | 0.5–0.9 s | Bring rod in and look at bucket before controls appear. |
| Done / bucket gesture | 0.45–0.8 s | Small lift or pull, then open Fishing Report. |

No state transition waits for a minimum dwell time. If events arrive during an animation, the state controller applies precedence and begins the next compatible pose on the next render frame. Do not queue stale distraction events.

## 8. Immediate app-policy transitions

The foreground-app event triggers the policy check synchronously with the event handling:

- If the active app is permitted by the selected focus mode, maintain or resume `fishing`.
- If it violates the selected mode, enter `distractedReaction` immediately; do not wait several seconds before the penguin reacts.
- The timer continues unless the user explicitly pauses or ends the session.
- The visual response must not take keyboard focus or intercept clicks intended for the foreground application.
- When the user returns to a permitted app, stop the hop burst and resume fishing promptly.
- If the event occurs during reeling and the fish has not been deposited, interrupt that catch sequence; do not grant that catch.
- Apply the Allowing, Block, and Timer only mode semantics defined by the current product/session contract. Do not infer a different enforcement policy in the animation renderer.

## 9. Permission denial and graceful fallback

Ask for monitoring permission only when the user chooses a session mode that needs app monitoring, with a short in-context explanation before the macOS system prompt.

When the user denies permission during New Session setup:

1. Return to the same New Session form.
2. Preserve task name, duration, selected apps, and other entered values.
3. Show a concise inline explanation that app-aware behavior is unavailable.
4. Offer **Try Again / Open System Settings** and **Switch to Timer Only**.
5. Start nothing in the background until the user explicitly starts a valid mode.
6. Do not show an error pose on the penguin.

This follows the usual permission pattern: ask in context, preserve the user's work, explain the feature affected, and let them retry or continue with a reduced capability.

If permission is revoked during a session, keep the timer and fishing session alive, stop app-aware reactions and tracking immediately, and show a small non-modal notice in the timer/menu-bar surface. Do not discard the session or eject the user to setup mid-session. Offer to reopen permission settings after the session.

## 10. Accessibility and rendering behavior

- Respect Reduce Motion. Replace hops, rapid movement, and moving catch effects with short fades, restrained pose changes, or static cues.
- Do not use flashing or rapid luminance changes.
- Preserve the immediate logical state change even when Reduce Motion is on; only the visual transition changes.
- Pause unnecessary per-frame work when the companion is hidden or the system requests reduced rendering.
- Keep all text and session controls out of the transparent character artwork; accessible timer and stop controls remain in their own UI surfaces.
- Maintain readable silhouette and catch action at the target ~118 pt character size.

## 11. Initial asset checklist

Required to prototype the first state loop:

- [ ] Fixed ice floe master asset (transparent PNG).
- [ ] Fixed bucket master asset (transparent PNG).
- [ ] Character sheet with locked proportions and neutral, fishing, casting, curled sleeping, pulling, direct-deposit, distraction-hop, and completed poses; compare glasses and no-glasses variants.
- [ ] Separated character layers with documented pivot points for head, torso, flippers, feet, eyes, and beak.
- [ ] Rod and line as separate controllable layers.
- [ ] One generic fish asset, one tree-shaped non-fish proxy, and one small splash/deposit effect.
- [ ] Sleep `z z z` marks as a separate layer.
- [ ] Distraction hop pose and a non-animated annoyed resting pose.
- [ ] Reduce Motion static variants or supported transitions.
- [ ] Alpha, canvas bounds, scale, pivot, and anchor metadata for every asset.

Existing generated concepts are visual references, not final production layers. In particular, generated sleeping and active illustrations are only approximately matched. Production animation must composite the same fixed floe and bucket master layers under every penguin pose.

## 12. Acceptance criteria for the animation spike

- [ ] Menu-bar item contains only remaining time; clicking restores a closed timer and is a no-op when the timer is open.
- [ ] Timer panel target is approximately 210 × 143 pt on the reference Retina assumption; character artwork approximately 118 × 118 pt with a transparent canvas around it.
- [ ] Floe and bucket remain pixel-registered while switching among all implemented states.
- [ ] No prominent concentric water rings appear in the initial floating companion.
- [ ] Idle has subtle continuous breathing and at least one head/rod micro-movement without distracting loops.
- [ ] App-policy and session-state triggers begin their visual response on the first rendered frame after event delivery.
- [ ] Catch is awarded only after deposit; interruption before deposit does not grant it.
- [ ] Both catch proxies travel directly to the bucket, then fishing resumes immediately; no catch-celebration hold or cooldown.
- [ ] Pause enters sleep; resume returns to fishing on the same fixed scene.
- [ ] Permission denial preserves the New Session form and offers retry or Timer only.
- [ ] Permission denial does not disable timer/fishing behavior when the user chooses Timer only.
- [ ] Reduce Motion preserves state meaning without rapid or large movement.
- [ ] State transitions do not move or resize the companion window.

## 13. References

- [Approved qyube home and New Session prototype](../qyube-concepts-v3/01-home-floating-form.png).
- User-supplied macOS screenshot: Kiki timer and character placement/scale reference (2940 × 1912 px).
- User-supplied qyube active-fishing art and sleeping-penguin pose references.
- [Apple SpriteKit](https://developer.apple.com/documentation/spritekit)
- [Apple SKTextureAtlas](https://developer.apple.com/documentation/spritekit/sktextureatlas)
- [Apple SwiftUI Canvas](https://developer.apple.com/documentation/swiftui/canvas)
- Existing product rules: [task_plan.md](../../task_plan.md) and [PRODUCT_SPEC.md](../../PRODUCT_SPEC.md)

## 14. Compact pure-white main UI revision — 2026-10-02

This dated section preserves all earlier art direction as history. It supersedes the **main-window** composition and palette in §4's approved Home subsection: the user now prefers a small Kiki-like window without a sidebar, then refined it toward neutral white and fewer visible containers. See [compact prototype index](../qyube-compact-v1/README.md).

- Main UI surface: pure white `#FFFFFF`; primary ink/button approximately `#222222`; neutral gray text/control hierarchy. No cream tint or decorative gradient. Existing charcoal/watercolor character texture stays inside the artwork. Colorful collection art and app icons do not become UI accent colors.
- One compact window, initially about 420 × 700 pt, with header icons for Insight, Catalog and gear menu. Home has Today summary and penguin above session history, with New session below. During an active session the main action is Show timer.
- Group primarily through whitespace. Keep borders only where needed for fields, selection or small collection cells. Header/footer framing and vertical Home divider are removed.
- Home/setup/report illustration uses the no-glasses penguin and rod only: **no ice floe, bucket, water, ripple or ground shadow**. Reuse pose identity from `qyube-minimum-assets-v1/01-poses-no-glasses.png`; generated UI images are not new production sprite sources.
- This artwork exception is scoped to the main UI. The separate desktop companion's fixed floe/bucket rules remain unchanged until an explicit desktop-art revision. Two floating panels remain part of session behavior.
- Main UI should use the existing pose vocabulary for fishing/pulling/sleep transitions when appropriate. These PNGs demonstrate static layouts only; they do not prove animation or rig alignment.
- Catalog: small adaptive grid, colored discovered entries with counts and dark undiscovered silhouettes. Catch illustrations in this batch are provisional references, not the final species roster.
- Insight: Day uses individual polaroid-style catch cards, including duplicates; longer periods use small bordered thumbnails, roughly five columns at compact width. Content scrolls; View all expands rather than capping history.
- Settings: small gear menu and compact grouped rows are proposed in image 09. Use native accessible controls; popover overlays without changing the underlying layout. New screens remain pending user review.

The current session/product rules in task_plan override obsolete animation descriptions elsewhere in this historical document: no Continue/Done fork or automatic break; completion opens a report and offers another session. Distraction must not discard ledger catches merely because an old visual-state paragraph says to interrupt an animation. Keep catch accounting in the engine.

For implementation limits, ruler details, responsive layout and illustrative data caveats, read [the prototype notes](../qyube-compact-v1/README.md#agent-implementation-notes-and-image-limitations). Do not erase earlier sections when recording the next revision.

## 15. Native compact implementation — 2026-10-03

User approved the compact direction and corrected the earlier size suggestion: follow Kiki and the compact prototypes. The first native content window is 360 × 610 pt with scrolling, not the 420 × 700 pt recommendation in §14. Settings now uses the same main window. Pure-white surfaces, charcoal controls, sparse borders and header navigation remain the visual contract.

For this stage there is one shared catch illustration: existing `CompanionFish`, also used by the desktop fishing sprite. Repeat this exact art in Catalog, Insight and Fishing Report; keep species IDs/counts distinct. Undiscovered entries use the image's alpha silhouette in charcoal. Do not generate a new illustration per species yet.

Both desktop panels continue to follow `qyube-active-session-v1`: 210 × 143 pt timer, transparent 140 pt character stage with the existing floe/bucket. Main-page penguin remains prop-free except for the rod. Timer task editing is in its small actions menu so the visible face remains focused on the countdown.

## 16. App-window distraction effects — 2026-10-04

User confirmed two alternating distraction variations: ice flowers and dim/bright animation. The affected app stays usable. This section extends the distraction reaction in §§6–8 and is the current authority for overlay scope. Earlier global-screen interpretations are superseded; previous documentation remains as history.

### Trigger and affected area

- **Allowing:** react when the foreground app is absent from the allowed list.
- **Blocking:** react when the foreground app is present in the blocked list.
- **Timer only:** neither effect is active. Policy operates at app level: allowing Chrome permits its sites; these effects do not add domain rules.
- Affect only the currently focused offending application's window. Do not decorate every open window belonging to that app. Clip the effect to that window's visible bounds, including its rounded corners. Follow window movement/resizing and remove the old overlay when the focused window changes.
- Desktop, menu bar, Dock, other app windows, qyube's timer, and the independent penguin companion remain unaffected. Overlay must not cover an unrelated window that occludes the target. A fullscreen target may visually occupy most of a display; it still follows that target window rather than becoming a global display overlay.
- The overlay is click-through and must not steal keyboard focus. The user can click, type, scroll, close, move, and switch applications normally. It does not change physical display brightness.
- Start the penguin reaction immediately on the app-policy event. The timer continues. Returning to a permitted app removes the effect promptly and resumes the appropriate companion state. Pause/end clears the overlay; catch accounting remains governed by the existing session engine.
- If a valid target-window boundary cannot be resolved, hide the overlay and retain the companion reaction; never substitute a full-desktop effect. Native implementation must validate window tracking, occlusion, fullscreen/Spaces, multiple displays, and permission loss before claiming support.

### Variation 1 — Ice flower

Reference: [01-ice-flower.png](../qyube-distraction-v1/01-ice-flower.png).

White and graphite branching frost flowers grow inward from the target window's edges/corners. Increase density as uninterrupted distraction lasts longer, with a bounded maximum and a readable center. Match the existing charcoal/watercolor illustration; avoid introducing a blue UI palette. Penguin performs small angry hops with gray steam puffs above its head. Keep the same fixed floe, bucket, character identity, and stage position; only character/effect layers move. Put the rod aside during the gesture.

### Variation 2 — Dim and bright

Reference: [02-dim-bright.png](../qyube-distraction-v1/02-dim-bright.png).

The paired desktop views are successive moments of one loop, not simultaneous application windows. Standing upright with both flippers raised corresponds to normal brightness. Bowing with both flippers extended straight forward corresponds to a translucent charcoal veil over the target window. Rising restores normal brightness. Drive pose and opacity from the same animation phase so the gesture visibly controls the light. Keep app content discernible at the darkest point; do not turn the window fully black.

### Alternation, escalation, and accessibility

- Show one variation at a time; alternate between them, clearing the previous effect during the transition. Do not stack frost and dimming as escalating punishment. Exact first-variation selection and switching interval are still animation-tuning parameters, not approved numeric requirements.
- Longer continuous distraction increases frost density or dim/bright cadence, with hard caps. Changing variation must not accidentally reset accumulated distraction intensity. Returning to a permitted app ends that episode; start the next episode gently.
- Use smooth brightness transitions, never rapid flashes/strobing. Initial tuning proposal: a full dim/bright cycle gradually moves from about 8 seconds toward a minimum of 3 seconds, and dark opacity caps around 40%. These values require prototype review and are not a safety certification.
- Reduce Motion uses static frost and/or a steady dim veil with a restrained annoyed pose; no hops or pulsing brightness. Preserve immediate policy feedback and access to timer controls.

### Prototype boundaries and next assets

These two PNGs communicate composition and gesture only. Generated browser text/chrome and penguin registration are illustrative. Image 01 places frost mainly around page-content edges; production masking must use the actual target-window bounds described above. Image 02 shows the intended bow direction; final authored poses must make the forward bend and both extended flippers clear at floating size. Do not extract these whole desktop mockups as animation sprites.

Later asset work needs a registered angry hop pose, steam puff layer, flippers-up pose, forward-bow pose, and tileable/instanced frost clusters. Reuse the existing fixed floe and bucket. This revision generates design artifacts only; native overlay behavior has not been implemented or tested by this prototype task. Exact generation prompts are recorded in [PROMPTS.md](../qyube-distraction-v1/PROMPTS.md).

### 2026-10-04 correction — scattered ice flowers (v2)

The user approved the dim/bright prototype, including its penguin poses, and approved the angry hopping penguin in the ice-flower prototype. The continuous frost border in image 01 was rejected. This correction supersedes the edge-growth and connected frost descriptions above.

- Current ice-flower reference: [01-ice-flower-v2.png](../qyube-distraction-v1/01-ice-flower-v2.png). Keep v1 as design history.
- Ice flowers are individual branching snowflake sprites scattered across the entire offending window, including its center and chrome. They are not a frozen border or an opaque frost layer.
- Increase the number of sprites over time, retaining gaps and click-through behavior so the app remains usable. Limit rendering to the target window; other windows and desktop stay unaffected.
- The user's new visual reference uses light icy-blue snowflakes. V2 adopts that color for this effect only; the penguin and main UI retain their existing palette.
- Preserve the approved angry hop and steam puffs, fixed floe and bucket. The dim/bright prototype remains the approved reference for the other variation.
- V2 is a static medium-density example; actual spawn timing and maximum density still need animation tuning. No native behavior is changed by this image revision.

## 17. Native distraction animation and sound polish — 2026-10-04

The user rejected the first native motion quality. Preserve the approved v2 scattered snowflake reference and dim/bright gesture. Native implementation now uses larger, multi-branch light-blue snowflakes distributed across shuffled cells, growing in batches of 6 initially, then four every ten seconds to24. Leave readable gaps. No continuous frost border.

Do not dissolve between complete penguin drawings: that creates a ghosted double silhouette. The light gesture uses the existing watercolor body parts with continuous shoulder/head/torso transforms. Flippers rise above the head, then swing forward while the body bows. The ice reaction retains the approved hop texture with anticipation, lift, landing and soft cloud-shaped steam; fixed floe and bucket do not jump. Keep 60fps companion playback and Reduce Motion alternatives.

One `ice-freezing.mp3` cue accompanies each newly appearing batch, with a short fade-out. One `light-switch.mp3` cue accompanies each bright/dim transition. Tie audio to episode events rather than render frames. Honor the sound toggle and volume, stop immediately when the effect ends, and do not loop switch audio for a static Reduce Motion veil.

The selected variation stays fixed while the offending app remains active. A new activation may draw the same or another variation. This supersedes the old interval-based alternation wording in §16. The effect is confined to the target window, with occluding windows and qyube's floating controls protected. Native review output lives in `../qyube-distraction-v1/native-polish-check/`; these are renderer snapshots rather than new generated illustrations.
