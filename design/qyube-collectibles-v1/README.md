# qyube collectible assets — batch 01

Art direction: `../qyube-compact-v1/06-catalog.png`. Created on the existing `codex/distraction-animation-polish` branch.

Open `preview.html` to review the full collection on white, checkerboard, or dark backgrounds. Each card also shows a 48 px thumbnail and a live charcoal silhouette. `asset-manifest.json` records the exact built-in image generation prompt for every master.

## Delivery and verification

All 15 assets were generated with the built-in image generation tool and copied into `assets/`. Each master is a 1254 × 1254 RGBA PNG. Total master size is 16,205,430 bytes (approximately 15.5 MiB).

All files were decoded and verified: 15 unique roster entries, square dimensions, alpha ranging from 0 to 255, and visible artwork bounds inside the canvas at alpha > 24. Each generated image was visually inspected for subject, side orientation, and watercolor treatment. Fine watercolor edges remain soft; use the dark-background preview to review edge appearance before any dark-surface integration.

The HTML review provides 48 px samples and silhouettes; native app integration and native-size rendering validation are still pending. These are resolution-preserving masters, not final compressed app renditions. No Swift code, catch probabilities, or catalog discovery data were changed.

## Production contract

- One isolated collectible per transparent PNG; English display names and stable IDs.
- Watercolor pigment, subtle charcoal contours, restrained colors, no background or cast shadow.
- Centered side view; creatures face right. Preserve the whole silhouette with transparent margins.
- Reuse each master for catalog, catch detail, report, and insight. Render undiscovered artwork as a charcoal alpha template rather than maintaining separate silhouette files.
- Fantasy is an art category, not a rarity or a color variant. No color variants in this batch.
- Preserve source resolution. Runtime renditions can be derived when actual display sizes are finalized.
- This batch supplies artwork; new catalog eligibility and catch probabilities require a separate implementation decision.

## Roster

| ID | English name | Art category | Existing catalog ID |
| --- | --- | --- | --- |
| anchovy | Anchovy | Fish | Yes |
| perch | Perch | Fish | Yes |
| trout | Trout | Fish | Yes |
| salmon | Salmon | Fish | Yes |
| narwhal | Narwhal | Fish | Yes |
| stick | Driftwood Stick | Ocean finds | Yes |
| pebble | Smooth Pebble | Ocean finds | Yes |
| shell | Seashell | Ocean finds | Yes |
| clownfish | Clownfish | Fish | No |
| pufferfish | Pufferfish | Fish | No |
| seahorse | Seahorse | Fish | No |
| seaweed | Seaweed | Ocean finds | No |
| yellow-submarine | Yellow Submarine | Ocean finds | No |
| moonfin | Moonfin | Fantasy | No |
| crystal-coral | Crystal Coral | Fantasy | No |

Narwhal retains the current app's Fish grouping for compatibility; it is biologically a marine mammal.
