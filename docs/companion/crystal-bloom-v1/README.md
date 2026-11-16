# Crystal Bloom v1 — 13 November 2026

Built-in imagegen generated six transparent pixel crystal blossoms from the approved Crystal Bloom A direction. Full prompt: `prompt.txt`; original sheet: `sources/crystal-bloom-sheet.png`. `prepare-assets.py` packages six cells with nearest-neighbor scaling and preserves their generated alpha.

Runtime uses `CrystalBloom1` through `CrystalBloom6`. The six replaced `DistractionIceFlower` image sets were removed. `DistractionEffectView` keeps drawing at the existing controller's 30 fps while the effect is active. Each blossom turns linearly, with alternating directions and 48/60/72-second periods. An 8-second opacity shimmer stays within 94–100%. Existing growth batches and positions remain stable. Reduce Motion removes rotation and shimmer. Returning to an allowed app immediately clears the overlay through the existing controller.

`previews/crystal-bloom.gif` is a ten-second sample of the actual AppKit renderer at 20 fps; its preview loop resets after ten seconds, while runtime rotation continues. The background is a synthetic dark reading fixture, not another app's screenshot.

Debug export: `Qoma --crystal-bloom-snapshots <writable-directory>`. For a sandboxed build, use the app container's tmp directory. Build and focused DistractionMotionTests / DistractionIntegrationTests passed. Two historical tests were updated to the previously changed light-switch timing without changing the lamp implementation. Manual blocked-app/fullscreen/multimonitor QA and battery profiling were not performed.
