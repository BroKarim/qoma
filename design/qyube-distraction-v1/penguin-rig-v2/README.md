# Continuous light-switch rig

**Archived / rejected:** the user requested whole illustrated in-between frames instead. All four rig runtime image sets and the rig renderer were removed. See `docs/companion/smooth-distraction-v3.md` for the active implementation. This folder preserves generation provenance only; the notes below describe the superseded trial.

Generated with built-in imagegen, transparent_background=true, using the approved `../penguin-frames-v1/penguin-lights-v1.png` as character/style reference. Original source: `lights-rig-source.png`. Full verbatim prompt: `prompt.txt`.

`../prepare-distraction-assets.py` extracts four runtime assets without redrawing them:

- `Qoma/Assets.xcassets/Companion/CompanionLightsBody.imageset`: stable body with active flipper removed.
- `Qoma/Assets.xcassets/Companion/CompanionLightsBlink.imageset`: registered closed-eye expression.
- `Qoma/Assets.xcassets/Companion/CompanionLightsArm.imageset`: detached shoulder-pivot flipper.
- `Qoma/Assets.xcassets/Companion/CompanionLightsSwitch.imageset`: stationary switch prop.

The body uses the same 256px canvas and floor registration as the other distraction sprites. SpriteKit draws continuous shoulder rotation, body lean, press squash and settling on its existing 60fps view. A smoothstep reach envelope begins 650ms before each click and settles over 550ms afterward; click times are synchronized to the existing quarter/three-quarter dim-cycle sound beats even when cycles accelerate. Breathing and brief blinks add idle motion. Reduce Motion holds a static pose. The whole character is not crossfaded between unrelated silhouettes.

Compositing fix: `DistractionOverlayController` no longer adds rectangular own-panel exclusions. Floating app panels that need it are temporarily raised above the veil, then returned to their original levels on hide. WindowServer uses the illustration's actual alpha, so transparent corners and gaps stay dim without requiring a changing silhouette mask or per-frame screen capture.

Verification: red regressions reproduced both the bright rectangle (target levels 0/3/8) and unchanged transforms between light-switch poses. The focused suites subsequently passed: 29 tests / 35 cases, zero failures. Final debug preview build passed. `../polish-check/polish/lights-smooth-preview.gif` contains 240 frames at a 30fps export cadence; runtime motion is driven by the existing 60fps SpriteKit view. PNG stills at press/dark phases show the gaps remaining dim. No live App Store/fullscreen/multimonitor manual QA was performed in this fix.
