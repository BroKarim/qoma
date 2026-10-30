# Progress

- Confirmed scope and read accepted approach. Will preserve overlay alpha/layer fix and current fishing animation work.
- Generated three 12-drawing full-character sheets with built-in imagegen from user-supplied references. Saved originals and exact prompts under penguin-drawn-v3. Registered each drawing's feet on 256px canvases using actual transparent gutters; source artwork is not redrawn by extraction.
- Removed light body/flipper/switch rig code, model helpers, rig tests and four runtime rig image sets. Replaced six-drawing atlases with three 12-drawing V3 atlases; original design sources remain archived. Preserved current catch/cast/deposit changes and panel compositing fix.
- Playback now advances hand-drawn in-betweens at 12 drawings/s, with rest/exhale holds, shared switch sound clock, whole-drawing breathing/hop and Reduce Motion stills. Added explicit all-12-drawings and no-body-part-node regressions. Test build running.
- Final test build passed: 32 tests / 38 cases, zero failures; result Test-Qoma-2026.10.28_15-06-46-+0700.xcresult. `git diff --check` passed.
- Exported real SpriteKit light/dark previews: 90 frames lights, 90 ice, 120 snow, each verified to render all twelve drawings. Inspected press/apex/exhale PNGs and registered atlases for feet contact, whole-character silhouettes and clipping. Copied final GIFs and documentation to docs/companion. No direct fullscreen/multimonitor/other-app QA in this pass.
