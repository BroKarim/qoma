# Whole-drawing distraction animation v3

Follows the accepted `smooth-catch-v3.md` approach: twelve complete watercolor/pencil penguin drawings per action, connected in-betweens at approximately twelve drawings per second, and small continuous whole-sprite breathing/travel. No detached-body rig, joint animation, or whole-character crossfade.

Previews from the actual SpriteKit companion, on light/dark backgrounds:

- `distraction-lights-v3.gif`: three seconds / 90 rendered frames; reach, press and retract. Drawing 6 lands on each existing switch-sound beat, including faster dim cycles.
- `distraction-ice-v3.gif`: three seconds / 90 rendered frames; anticipation, takeoff, apex, descent, squash and recovery. A whole-drawing jump arc preserves smooth travel while the painted body changes naturally.
- `distraction-snow-v3.gif`: four seconds / 120 rendered frames; inhale, puffed-cheek exhale hold, deflation and return.

All three use twelve unique drawings. Runtime SpriteKit remains at its existing 60fps cadence; these GIF previews are captured at 30fps. Reduce Motion holds the first whole drawing and removes breathing/jump travel.

Source art and exact built-in imagegen prompts are preserved under `design/qyube-distraction-v1/penguin-drawn-v3/`. User-supplied six-pose illustrations served as identity/style references. `prepare-distraction-assets.py` cuts at measured transparent gutters, aligns the painted feet on 256px canvases, and uses a single scale per action to preserve painted squash/extension. It checks that source artwork is not clipped. Runtime atlases are `CompanionDistractionLightsV3`, `CompanionDistractionIceV3`, and `CompanionDistractionSnowV3`, each a 1024×768 atlas of twelve 256px square cells. Registration metadata is stored beside the sources.

The rejected light-switch body/flipper rig and its four runtime image sets were removed. Prior rig source art remains archived for provenance only. The window-compositing fix remains: floating app panels sit above the veil, with actual sprite alpha determining their visible silhouette; transparent panel corners do not punch rectangular holes into the dimmed application.

Validation: Debug test build succeeded; 32 tests / 38 expanded cases passed, zero failures. Tests cover all twelve drawing indices and their order, switch-sound synchronization, no body-part child nodes, hop/Reduce Motion behavior, distraction reset, existing fishing/catch accounting, and transparent panel corners at window levels 0/3/8. Every preview exporter confirms all twelve drawings were rendered; representative drawn poses were inspected on both backgrounds. `git diff --check` passed. Source consistency and subjective animation feel still benefit from normal-speed review, as in the catch-v3 trial. Manual fullscreen/multimonitor/other-app QA was not performed in this pass.

Reproduce with a Debug build and `--companion-snapshots <directory>`. The `distraction-clips` subfolder contains the three GIFs and twelve representative PNGs per effect.
