# Rare & Legendary — batch 01

Created 22 October 2026 using built-in imagegen. Follows [the shared asset workflow](../common-collectibles-v1/WORKFLOW.md).

## Scope
This batch contains **4 Rare and 2 Legendary assets**, not the complete 24 Rare / 30 Legendary roster. All six are integrated into the Catalog and catch pool using existing stable game IDs (Rare slots 02–05, Legendary slots 02–03); artwork IDs remain separate. See `productionGameID` in `manifest.json`. Base odds, pool sizes and weights are unchanged.

## Assets
| Art ID | Concept |
| --- | --- |
| rare-golden-icefish | Golden mutation of an elongated icefish |
| rare-skeletal-fish | Ivory fish skeleton, closed skull without eye sockets |
| rare-frostwing-ray | Ray with crystalline ice wings |
| rare-aurora-shell | Clam shell with aurora mineral bands |
| legendary-glacier-leviathan | Coiled polar sea serpent with glacier plates |
| legendary-ice-kraken | Eyeless polar kraken crowned with ice |

Names in this table are artwork IDs. The manifest records their stable game IDs. The fish category includes marine creatures; no scientific species claim is implied.

## Files
- `rare-batch-01-v1.png`: original generated transparent sheet, 1536 × 1024.
- `legendary-batch-01-v1.png`: original generated transparent sheet, 1774 × 887.
- `rare/` and `legendary/`: six individual RGBA PNGs, 512 × 512, fitted to 440 × 440 with centered padding.
- `batches.json`: exact final prompts, sheet arrangement and concepts recorded before generation.
- `manifest.json`: individual crop boxes, rarity, concept, source, path and draft status.
- `contact-sheet-light-dark.jpg`: review on porcelain and dark ink backgrounds.
- `crop_assets.py`: repeatable deterministic cropping/export; requires Pillow.

## Style and review
Reference image: `design/qyube-collectibles-v5-fish/02-fish-collection-sheet-no-eyes.png`, used as style reference, not edit target. Reference prompt: `design/qyube-collectibles-v5-fish/PROMPT-NO-EYES.md`.

Watercolor interiors, irregular charcoal contours, no eyes or sockets, no text, true alpha transparency. Rare keeps a recognizable source object with a dominant mutation. Legendary uses distinct polar-monster silhouettes. Source sheets and individual crops were inspected on light and dark backgrounds; limbs, fins, tail tips and pale interiors remain visible.

The generator did not maintain the ideal equal-cell grid exactly. Rare crop boundaries were adjusted to x=800 and y=459; Legendary uses x=975. These are specific to these sheets. Preserve the recorded boxes rather than reverting to equal cells, which would clip the ray's wing or Leviathan's tail.

Re-export from the repository root:
```sh
python3 output/imagegen/rare-legend-collectibles-v1/crop_assets.py
```

Use the source sheets for future edits. One color asset per item remains sufficient; the app renders locked silhouettes from alpha. Re-exporting crops recreates the draft manifest: preserve the `productionGameID` mappings when doing so and copy revised PNGs to their matching Xcode asset sets.
