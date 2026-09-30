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

The timer and penguin are separate floating windows. Closing the timer hides only the timer. Its menu-bar item can restore it. The penguin companion stays visible while the session is active.

## 4. Visual direction and fixed scene

### Palette and medium

Use the current qyube floating reference:

- warm white and snow white;
- charcoal black;
- graphite and warm gray;
- very restrained muted terracotta for a small event accent.

Do not introduce blue into this floating companion artwork. Keep the hand-painted charcoal/watercolor texture, soft irregular edges, and small, friendly penguin proportions. The latest approved sleeping reference has no glasses; do not add glasses unless the art direction is deliberately revised.

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
| `catchCelebration` | A newly discovered or rare catch is deposited in the bucket | Penguin raises/presents the fish with a proud expression; hold briefly, then place it in the bucket. | Catch presentation completes, then `fishing`. |
| `sessionAlmostFinished` | Session enters its configured final interval | Keep fishing. Use one restrained cue such as a tiny bucket highlight or eye glance; no new pose and no repeated alerts. | Session reaches zero, is extended, or is stopped. |
| `sessionCompleted` | Timer reaches zero | Stop the fishing loop, bring the rod in, stand/turn toward the bucket, and look satisfied. | User selects Continue or Done. |
| `continue` | User selects Continue | Small upbeat reaction, cast the line again, and resume the same focus session according to the session contract. | Cast settles, then `fishing`. |
| `done` | User selects Done | Penguin pulls the bucket slightly closer or lifts it; hand off to Fishing Report. | Fishing Report is presented and the main app returns. |
| `stoppedBeforeBanking` | User ends session before five active minutes | Gently return provisional catches to the water; calm, non-punitive expression. | Session ends and the main app returns. |
| `pausedSleeping` | User pauses the session | Stop fishing; curl up and sleep on the fixed floe. Show small `z z z` marks from the mouth. | Resume returns to `fishing`; stop/completion follows its normal flow. |
| `distractedReaction` | A foreground app violates the selected mode's policy | Interrupt the current penguin action immediately; short flipper/foot hops and annoyed-but-gentle expression. | User returns to a permitted app or mode policy no longer triggers; recover to `fishing`. |
| `permissionUnavailable` | Required monitoring permission is denied or unavailable | No special character pose. Fishing and timer continue if the user chooses Timer only. | Permission is granted later or session setup changes. This is a capability/fallback state, not an art state. |

### State precedence

1. Session termination and `done` take precedence over catch celebration.
2. Pausing cancels active character motion and enters sleep.
3. A distraction event interrupts the current pose immediately. An in-flight catch that has not reached the bucket is not granted, consistent with the existing catch transaction rule.
4. `catchCelebration` only begins after deposit and banking eligibility are satisfied.
5. `sessionAlmostFinished` is a low-priority modifier; it must not override sleep, distraction, a catch sequence, or completion.

## 7. Timing guidance

The fishing cadence already defined for qyube remains authoritative: wait a randomized **6–10 seconds** for a bite; the reel/pull beat takes approximately **2–6 seconds**, followed by deposit. Keep the catch roll and banking transaction rules from the product plan unchanged.

The values below are starting animation timings for prototype review, not product invariants. Tune them against the small floating size:

| Motion | Suggested time | Direction |
|---|---:|---|
| Idle breathing cycle | 3–5 s | Small vertical body scale/offset; seamless loop. |
| Head glance / micro-look | 0.25–0.45 s | Soft ease, then relaxed hold. |
| Session-start hop | 0.45–0.75 s | One compact hop and settle. |
| Bite reaction | 0.12–0.25 s | Immediate snap/lean; begins on the event frame. |
| Reeling body lean | 0.25–0.5 s | Strong readable lean with feet braced; rod bends. |
| Fish reveal / celebration | 1.0–1.8 s | Lift fish; hold proud expression about 0.5–0.9 s. |
| Deposit into bucket | 0.35–0.6 s | Fish arcs into bucket; deposit event fires on landing. |
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
- [ ] Character sheet with locked proportions and neutral, fishing, curled sleeping, pulling, and presenting-catch poses.
- [ ] Separated character layers with documented pivot points for head, torso, flippers, feet, eyes, and beak.
- [ ] Rod and line as separate controllable layers.
- [ ] One small fish asset and one deposit effect.
- [ ] Sleep `z z z` marks as a separate layer.
- [ ] Distraction hop pose and a non-animated annoyed resting pose.
- [ ] Reduce Motion static variants or supported transitions.
- [ ] Alpha, canvas bounds, scale, pivot, and anchor metadata for every asset.

Existing generated concepts are visual references, not final production layers. In particular, generated sleeping and active illustrations are only approximately matched. Production animation must composite the same fixed floe and bucket master layers under every penguin pose.

## 12. Acceptance criteria for the animation spike

- [ ] Timer panel target is approximately 210 × 143 pt on the reference Retina assumption; character artwork approximately 118 × 118 pt with a transparent canvas around it.
- [ ] Floe and bucket remain pixel-registered while switching among all implemented states.
- [ ] No prominent concentric water rings appear in the initial floating companion.
- [ ] Idle has subtle continuous breathing and at least one head/rod micro-movement without distracting loops.
- [ ] App-policy and session-state triggers begin their visual response on the first rendered frame after event delivery.
- [ ] Catch is awarded only after deposit; interruption before deposit does not grant it.
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
