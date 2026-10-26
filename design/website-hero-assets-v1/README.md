# qyube hero — watercolor assets v1

Created 26 October 2026 with built-in imagegen. All 11 newly generated PNGs have real RGBA transparency (alpha range 0–255). Four existing fish PNGs were copied without modification. Original sources remain intact.

## Character

Same charcoal/white watercolor penguin with opaque red–cyan cinema 3D glasses covering its eyes. Colors of the glasses are the deliberate small accent.

| File | Use |
| --- | --- |
| [penguin-fishing.png](penguin-fishing.png) | Before start and quiet fishing wait; flippers ready to grip rod |
| [penguin-casting.png](penguin-casting.png) | Casting anticipation, flippers lifted |
| [penguin-pulling.png](penguin-pulling.png) | Pull/reel, body leaning back |
| [penguin-deposit.png](penguin-deposit.png) | Direct deposit toward bucket at scene left |
| [penguin-sleeping.png](penguin-sleeping.png) | Paused state |
| [penguin-completed.png](penguin-completed.png) | Entry/completed standing pose |

Pose concepts adapted from ../qyube-minimum-assets-v1/PROMPTS.md. Hop omitted because this website demo has no distraction enforcement state. The six poses are individual static cutouts, not a continuous frame sequence or registered rig. Different silhouettes, camera details, body scales and empty margins require per-pose registration when assembling the hero. Do not assume equal image rectangles give matching feet/grip anchors. White belly and face stay opaque.

## Shared layers

[antarctic-background.png](antarctic-background.png) adds an optional opaque white watercolor environment behind all foreground layers: distant mountains left/right, quiet sea and open center. See [BACKGROUND-PROMPT.md](BACKGROUND-PROMPT.md). The foreground cutouts below remain transparent.

| File | Use |
| --- | --- |
| [ice-floe.png](ice-floe.png) | Single fixed platform reused in every state |
| [bucket-empty.png](bucket-empty.png) | Single fixed bucket at penguin's left |
| [fishing-rod.png](fishing-rod.png) | Separate rod, pointed up-right |
| [water-wash.png](water-wash.png) | Wide isolated watercolor water texture |
| [water-splash.png](water-splash.png) | Catch splash keyframe |

No opaque page background is baked into these layers. There are no mountains, UI labels, or scenery plates.

## Existing fish reused

Copies of fish-source-01, 10, 22 and 25 are in fish/. Original source: ../../output/imagegen/common-collectibles-v1/fish/. These preserve the existing fish colors and 512 × 512 transparent canvases. The full source collection remains available; these four form a small initial demo pool. The source manifest labels this art draft-art.

## Assembly notes for the next implementation

Layer order: water wash → moving reflection → ice floe → penguin → rod/line/catch → bucket foreground occlusion → splash/droplets as needed. Keep bucket and ice fixed while the penguin changes pose. Choose a shared scene coordinate system and record feet and rod-grip anchors per pose before animating. The rod grip must meet the flippers; do not bake a second rod into character art.

Draw a fine SVG line from rod tip to water/catch at runtime. Ripple ellipses, individual droplets, the little bite cue, and reflection distortion are code-drawn effects rather than additional generated bitmaps. Adjust the rod curve dynamically for reel tension; this raster rod is a material/reference asset and a simple rigid fallback.

Catch sequence: cast → wait → bite → pull → fish travels directly into bucket → cast again. Award count only on bucket landing. No held-up trophy pose. Pause uses sleeping pose. Session completion uses standing pose. Timing and catch frequency remain implementation decisions.

For fish entering the bucket, add a foreground rim/body occlusion mask in the renderer; the empty bucket PNG alone is not a layered bucket rig. The splash is one keyframe, not a fluid simulation. Continuous water movement, pose alignment, responsive layout, asset compression and browser validation are still pending.

## Metadata and prompts

[asset-manifest.json](asset-manifest.json) records actual dimensions and alpha bounds; faint pigment near edges can make raw alpha bounds larger than the visible subject. [PROMPTS.md](PROMPTS.md) contains the exact generation prompts. Generated files are source artwork; create optimized deployment derivatives during website integration.
