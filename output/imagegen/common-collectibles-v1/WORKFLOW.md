# Qyube collectible asset workflow — 22 October 2026

## Deliverables and scope
Built-in imagegen was used for background extraction and generation; Python/Pillow was used only for the user-requested deterministic crop, trim, resize and review contact sheet. No CLI/API generation was used.

- `fish-sheet-transparent-v1.png`: transparent extraction of all 32 fish from `design/qyube-collectibles-v5-fish/02-fish-collection-sheet-no-eyes.png`.
- `fish/fish-source-01.png` through `fish-source-32.png`: 32 individual fish in original reading order.
- `common-ocean-finds-sheet-v1.png`: six new Common non-fish objects in a 3 × 2 grid.
- `ocean-finds/`: sea pebble, clam shell, spiral shell, driftwood, shell shard and sea glass, each exported separately.
- `manifest.json`: IDs, proposed rarity, category, sheet, cell, crop coordinates and export filename.
- `contact-sheet.jpg`: review image on porcelain background, not a game sprite.
- `crop_assets.py`: repeatable crop/export script; requires Pillow.

This is the first asset batch, not a completed 60-item Common roster. The source fish remain rarity-unassigned in the manifest: the previous design places recognizable fish in Uncommon, and the source includes tropical species as well as ocean fish. Do not assume they are Antarctic species or assign every source fish to Common. New ocean finds are Common candidates. These artwork IDs have not been mapped into the game's existing stable collectible IDs, and assets have not been wired into the app.

## Style lock
Read `design/qyube-collectibles-v5-fish/PROMPT-NO-EYES.md` and inspect its accompanying PNG before every batch. The reference Markdown is an eye-removal edit prompt: its ivory paper background is NOT a requirement for exported sprites.

Preserve handmade watercolor, fine irregular charcoal contours, natural-history silhouettes, softly textured painted interiors and natural colors. Fish have absolutely no eyes, eye rings, sockets, eyelashes or replacement dots. Preserve decorative body spots that are not eyes. Non-fish objects have no faces. Use genuine transparent alpha; no paper backdrop, ground, cast shadows, labels, frames or scenery. Keep texture inside the object.

## Reusable generation method
1. Write a manifest before generation: stable art ID, category, rarity, precise concept, sheet and cell. Map art IDs to production game IDs only after roster approval.
2. Attach the original fish sheet as STYLE REFERENCE ONLY for new objects.
3. Generate Common/Uncommon in six-object 3 × 2 sheets; Rare in four-object 2 × 2 sheets; Legendary in one- or two-object sheets. These are starting batch sizes, not hard requirements.
4. Ask for each object in the middle 65% of its cell, with transparent gutters and no overlapping fins/effects.
5. Inspect the complete sheet. Verify actual alpha, then composite over light AND dark backgrounds to check halos, holes in pale bodies and accidental shadows.
6. Copy selected outputs from Codex generated_images into the workspace. Keep the original generation; never overwrite approved assets.
7. Crop each cell, trim to alpha bounds, fit proportionally inside 440 × 440 and center on transparent 512 × 512. This gives 36px minimum margin along the longest axis.
8. Inspect all crops on a contact sheet at catalog scale. Check clipped fins, neighboring fragments, edge artifacts and visual size. If a cell fails, regenerate only that item.
9. Keep one color PNG per item. The app can produce the locked black silhouette from its alpha; do not generate a second silhouette image.
10. Save the exact prompt, reference path, source sheet and manifest with every batch.

The source sheet is 1774 × 887 and its fish are not perfectly aligned to equal grid divisions. Its manual x boundaries are 0,242,458,680,895,1114,1330,1550,1774; y boundaries 0,230,450,648,887. Do not reuse these boundaries for a different sheet. The new 1536 × 1024 Common sheet uses equal thirds and halves. Cropping script records source-pixel boxes in the manifest.

Original fish have about 200px painted detail. 512px exports enlarge them for consistent UI footprint; this does not add real detail. Regenerate individually if larger detailed art is needed.

Run:
```sh
python3 output/imagegen/common-collectibles-v1/crop_assets.py
```

## Exact generation prompt — Common batch 01
```text
Use case: stylized-concept. Asset type: qyube Common ocean-find collectible sprite sheet. Input image is STYLE REFERENCE ONLY, not an edit target. Create exactly SIX non-fish objects in a precise 3-column by 2-row grid on a genuinely TRANSPARENT background. Same handmade watercolor and fine irregular charcoal outlines as the reference fish, gently textured painted interiors, soft natural Arctic ocean colors, clear simple silhouettes, charming tactile illustrated natural-history objects. Row 1 left: one smooth rounded blue-gray sea pebble. Row 1 center: one small closed cream ribbed clam shell. Row 1 right: one muted sandy spiral sea-snail shell, empty. Row 2 left: one small weathered pale driftwood twig. Row 2 center: one single broken curved shell shard with chalky ivory inside and muted pink-beige outer edge. Row 2 right: one rounded frosted pale sea-green sea-glass piece. Each cell contains ONE isolated object centered comfortably, no extra debris or sparkles. Object fits within middle 65% of its cell with generous transparent margins. Equal visual size, entire object visible, no overlap. Common ordinary objects, no gold, magic, aurora, faces, eyes, monsters, lettering or labels, no borders, no background paper texture, no scenery, no ground, no cast shadow. Texture remains INSIDE objects only. Match reference painterly craftsmanship; do not turn into glossy 3D or flat vector.
```

## Background extraction prompt — fish source
Edit target: the supplied 32-fish sheet, 8 columns × 4 rows. Remove only the warm ivory paper backdrop and replace it with real transparency. Preserve all fish, original positions and canvas aspect ratio, watercolor colors, interior textures, charcoal contours, patterns and proportions. Preserve white painted body areas. Keep all fish eyeless; no eye marks or sockets. No new objects, text, shadows or rearrangement. Return the complete transparent sheet.

## Validation
38 individual RGBA exports were checked for alpha transparency and reviewed on a contact sheet. The generated sheets were also composited over porcelain to inspect pale paint and outlines. Assets are draft artwork pending user approval and final species/rarity mapping.

