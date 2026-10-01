# Native companion animation prototype

Status: implemented for macOS Debug review. Candidate: no glasses. This milestone replaces the old floating timer content with the penguin; the existing MenuBarView remains the temporary session controller. The final home screen, two-window timer design, menu-bar restore semantics, app policy enforcement, Catalog persistence and Fishing Report are not implemented by this milestone.

## Run and review

Open `qoma.xcodeproj`, select scheme **Qoma**, choose **My Mac**, and Run the Debug configuration.

1. Open the existing menu-bar popover, select a duration, and press **start**. A transparent 140 × 140 pt panel appears near the lower-right; the ice artwork occupies 118 pt horizontally.
2. The penguin enters, casts, waits 6–10 seconds, reacts to a bite, reels for 0.9–1.5 seconds, and transfers the catch directly into the bucket in 0.48 seconds. The next cast begins immediately after landing.
3. **pause** puts the penguin to sleep; **resume** begins casting again.
4. **cancel** before five active minutes returns a representative catch to the water and clears the temporary visual count. If no catch has landed, no returned fish is invented. At/after five minutes, the panel dismisses without the return effect. No Catalog writes occur in this UI prototype.
5. When the real timer expires, the companion keeps its completed stance and the existing popover returns. The legacy session/break flow otherwise remains in place.
6. Drag the artwork to move the nonactivating panel. Its position is remembered and clamped to the available display on the next opening.

For isolated testing without a real session, use **… → Companion preview** in a Debug build. This menu is disabled during an actual session. It offers Start fishing loop, Catch now (only during idle fishing), Sleep, Resume fishing, Distraction hop, Session completed, Stop before five minutes, Actual size, Inspect at 2× size, and Dismiss companion.

Distraction is a manual UI trigger in this milestone; changing foreground apps does not trigger it. It interrupts fishing immediately, performs one small hop burst, then rests. Resume clears the simulated distraction. After Completed/Stopped, use Start fishing loop to begin another preview.

The isolated launch command is:

```sh
open -n build/qyube-companion/Qoma.app --args --companion-preview
```

`build/qyube-companion/Qoma.app` is a local generated Debug artifact (ignored by Git). It uses the existing Qoma product name. Rebuild it from Xcode after later code changes.

## Asset pipeline

- Source: `design/qyube-minimum-assets-v1/01-poses-no-glasses.png` and `03-shared-props.png`.
- Reproducible literal extraction: `swift tools/export-companion-assets.swift` from repository root.
- Output: 22 transparent images in `Qoma/Assets.xcassets/Companion/` plus [asset-manifest.json](../qyube-minimum-assets-v1/asset-manifest.json).
- Eight pose images share a 512 × 512 pixel canvas with ground anchor `(256, 450)` measured from the top-left. The corresponding SpriteKit normalized anchor is `(0.5, 62/512)`.
- Head, torso, both flippers, and feet are separate texture pieces for the live rig. The rod is separately rotated; its line is a continuously redrawn curved path.
- The live fishing loop interpolates body lean, head tilt, flipper/rod rotation, breathing, and catch travel. It does not play the eight pose images as a flipbook. Sleep/hop/completed use registered authored silhouettes with restrained continuous motion.
- Exactly one floe and one bucket sprite are used for every state. Neither is regenerated or moved during character-state changes.
- One generic fish and one tree proxy are used. For visual testing, every fifth catch is the tree proxy; this is a sample sequence, not production loot probability. The stop effect uses one fish as a visual summary of the returned provisional catches.

The source is flattened generated artwork. Rig seams and transitions between authored silhouettes remain prototype quality; further animation polish may be needed after review. Pose reference images containing rods are retained for future art work; the live rig uses the standalone rod and line, avoiding duplicates.

## Runtime boundaries

- `CompanionPlayback`: deterministic event/state progression with injectable wait durations; only bucket landing increments an in-memory visual count. Pause, distraction, completion, or stop cancels an in-flight catch.
- `CompanionScene`: SpriteKit rendering at 30 fps, separate pose/prop/effect layers, transparent stage, Reduce Motion alternatives.
- `FloatingCompanionView`: AppKit hosting bridge that owns no session state and reads the SwiftUI Reduce Motion environment.
- `WindowManager`: owns the scene/panel lifecycle and receives session events. Dismissal detaches the renderer and clears callbacks; a stale stop callback cannot dismiss a newer scene.
- `FocusSessionManager`: forwards pause/resume/stop/completion to the companion. Intentional stop sets its completion guard before publishing zero time, preventing a false timer-completed callback.

The companion does not implement production rewards, probability, app blocking, or permissions. Existing session analytics remain governed by the existing app settings. The isolated preview starts no actual session and skips the startup monitoring-permission request.

## Validation

- Debug app built successfully via `xcodebuild` using the macos-build skill, with code signing disabled for this local build.
- Nine focused tests in `CompanionPlaybackTests` passed: landing-only grants, no cooldown, distraction cancellation, pause precedence, early-stop return, five-minute boundary, completion/restart, no invented early catch, fixed scene anchors, and Reduce Motion. Some tests cover multiple assertions.
- Actual SpriteKit renders were inspected on light and dark backgrounds, including the 118 pt floe width; see [render-check.png](render-check.png).
- The Debug app was launched in isolated preview mode and its live transparent companion was inspected on the desktop.

Reproduce the focused test run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project qoma.xcodeproj -scheme Qoma -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:QomaTests/CompanionPlaybackTests \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_ALLOWED=NO
```

An optional Debug-only render check accepts `--companion-snapshots <directory>` and exits after writing eight PNGs and a contact sheet. It uses the actual bundled textures and scene; it skips menu/session startup and monitoring requests.
