# Qyube Uncommon collectibles — batch v1

## Scope
36 draft fish illustrations across six 3 × 2 sheets. The roster was written to `manifest.json` before generation. Names describe stylized fish-inspired concepts; they are not verified species identifications. Production game IDs remain unset pending roster approval.

This batch follows `../common-collectibles-v1/WORKFLOW.md` and uses `design/qyube-collectibles-v5-fish/02-fish-collection-sheet-no-eyes.png` as STYLE REFERENCE ONLY. Exact prompts and reference paths are recorded in `prompts.json`.

## Style
Handmade watercolor, fine irregular charcoal contours, softly textured painted interiors, muted natural polar colors, cozy simplified rounded fish silhouettes. No eyes, replacement dots, rings or sockets. No text, scenery, ground, shadows, gold, magic or glow. Pale paint stays inside each silhouette; exported backgrounds have real alpha.

## Files and export
- `uncommon-sheet-01.png` through `uncommon-sheet-06.png`: selected original generated sheets, copied from Codex generated_images without removing originals.
- `fish/`: 36 transparent 512 × 512 PNG exports.
- `manifest.json`: stable art ID, draft name, concept, rarity, category, sheet, cell, crop, alpha bounds and export path.
- `prompts.json`: exact built-in imagegen prompts and reference path.
- `contact-sheet-light.jpg` and `contact-sheet-dark.jpg`: review composites, not game sprites.
- `export_assets.py`: repeatable deterministic crop, trim, resize and review composition using Pillow. No artwork is drawn by the script.

Grid cells establish reading order. Equal grid crops included neighboring fin fragments where fish exceeded their nominal cells, so final per-item source boxes follow the main connected silhouette (alpha >= 32, 3px padding), without changing any painted pixels. Actual source-pixel boxes are saved in the manifest and reused by the export script. Alpha is preserved, trimmed to the object's bounds, proportionally fitted within 440 × 440 and centered on a transparent 512 × 512 canvas. Upscaling harmonizes UI footprint and adds no real painted detail.

Run from the repository root:
```sh
python3 output/imagegen/uncommon-collectibles-v1/export_assets.py
```

## Generation method
Built-in imagegen, transparent background enabled, one call per six-object sheet. Python/Pillow is used only for workflow-authorized deterministic export and review composites. No CLI/API generation. Source prompts and concepts are draft; game integration waits for roster approval.

## Validation result
36 RGBA exports passed size/transparency checks: 512 × 512, real transparent margins, at least 36px clear space along every edge. Both contact sheets were visually inspected after the crop correction: no neighboring fragments, clipped fins or visible cast shadows. White and cream paint remains visible against the dark review background. Some silhouettes are close relatives by design; final names and species mapping remain draft. `validation.json` records export dimensions, alpha ranges and bounds. `sources.json` records original generated file paths.
