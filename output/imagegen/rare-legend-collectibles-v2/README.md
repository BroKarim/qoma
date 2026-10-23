# Rare & Legendary — 30 new illustrations each

Additional batch following `../rare-legend-collectibles-v1/README.md` and the shared Common workflow. Existing approved images and production game mappings are preserved.

## Scope
30 new Rare and 30 new Legendary draft art IDs, distinct from the six v1 concepts. These are artwork candidates; productionGameID remains null pending roster selection. This asset batch does not change game pool sizes, odds or weights.

Rare keeps a recognizable source fish, invertebrate, plant or ocean find with one dominant magical mutation. Legendary uses distinct polar-myth creatures and ancient artifacts. Both retain cozy watercolor, softly mottled paint, fine irregular charcoal contours and zero eyes or sockets. Objects and plants have no faces. Fantasy effects stay attached to the subject or enclosed inside it, keeping a readable collectible silhouette.

## Generation
Built-in imagegen with real transparent-background requests. Original eyeless fish sheet is STYLE REFERENCE ONLY:
`design/qyube-collectibles-v5-fish/02-fish-collection-sheet-no-eyes.png`.

Concepts and stable art IDs were written to `manifest.json` before generation. Exact generation prompts and sheet layouts were saved to `batches.json` before any tool call. Rare uses seven 2 × 2 sheets plus one 2 × 1 sheet; Legendary uses fifteen 2 × 1 sheets. Originals remain in Codex generated_images and selected sheets are copied here.

## Files
- `rare-batch-*-v2.png`, `legendary-batch-*-v2.png`: selected original sheets.
- `rare/`, `legendary/`: transparent 512 × 512 color PNGs, proportionally fitted within 440 × 440 and centered with at least 36px margin.
- `manifest.json`: art ID, draft name, category, concept, sheet/cell, crop box, export path and roster status.
- `batches.json`: exact prompt set and reference path.
- `sources.json`: original generated file paths.
- `rare-contact-light.jpg`, `rare-contact-dark.jpg`, `legendary-contact-light.jpg`, `legendary-contact-dark.jpg`: review composites, not sprites.
- `validation.json`: per-item export size, alpha range and alpha bounds.
- `export_assets.py`: deterministic crop/trim/resize/review with Pillow; no artwork generation or repainting.

Re-export:
```sh
python3 output/imagegen/rare-legend-collectibles-v2/export_assets.py
```

Crop boxes are specific to each sheet. Initial equal cells may be adjusted after inspecting complete objects to avoid clipped tips and neighboring fragments. Final recorded source boxes take precedence on re-export. One color asset per item; app silhouettes can be produced from alpha.


## Completed review
All 60 individual RGBA exports are present: 30 Rare and 30 Legendary. Size, alpha bounds and at least 36px transparent margins were checked during export. Both rarities were visually inspected on light and dark contact sheets after refining source crop boxes. Neighboring fragments from nominal grid cells were excluded through crop selection; entire fish tails, wings, tentacles and artifact parts remain within the final boxes. No eye marks or face features are present in the selected creatures. Pale painted interiors remain visible over dark backgrounds.

`--refine-crops` computes source crop proposals from the largest connected silhouettes (alpha >= 32, 3px padding); final boxes are recorded in the manifest. Plain re-export uses the recorded boxes. This operation only selects rectangular source regions and resizes them, without repainting artwork.

The v1 batch remains separate. Across v1 and v2 there are 34 Rare and 32 Legendary artwork candidates; the current production selections and reserved drafts are listed below.


## Production integration — 23 October 2026

Forty-seven v2 illustrations are used by the 150-item collection: 19 Rare (`rare-06`–`rare-24`), 27 new Legendary slots (`legendary-04`–`legendary-30`), and `legendary-spirit-narwhal` replacing the legacy Narwhal illustration. The Narwhal keeps its persisted game ID `narwhal`; artwork names and Indonesian display names are linked through `CatalogDefinitions.artworkID`. Catch IDs, weights, rarity odds, pity thresholds and pool sizes remain unchanged. Asset sets are in `Qoma/Assets.xcassets/Collectible-<art-id>.imageset`.

The remaining 14 Rare and two Legendary drafts stay in this batch with `productionGameID: null` and status `reserved-art-no-pool-slot`. Glacier Leviathan and Ice Kraken concepts were kept intact; the v2 Spirit Narwhal replaces the legacy Narwhal image, while Cathedral Skate and Wreck Hermit remain reserved. The 27 selected Legendary entries retain a mix of creatures and artifacts.
