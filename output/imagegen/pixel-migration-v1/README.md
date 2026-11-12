# Full pixel migration — 11 November 2026

Branch: codex/all-pixel-art. User authorizes replacing all app illustrations/icons and historical collectible artwork with pixel art, preserving identity, silhouette, pose and colors, keeping eyeless creatures eyeless. Remove old app illustration files after replacement. Existing pixel cove remains the style anchor.

Inventory: manifest.json deduplicates 196 nonpixel PNGs across app assets and individual collectible manifests, with 291 target paths. Existing Pixel assets are excluded. Historical UI concept sheets are reference archives, not runtime art.

Outstanding work:
- Generate pixel replacements with built-in imagegen using each existing illustration as edit target.
- Inspect outputs and preserve alpha, animation atlas layouts and source dimensions.
- Replace production images and historical collectible exports, remove unused old companion art after tracing callers.
- Replace raster menu/settings/distraction art and native symbol icons.
- Check catalog references, app icon, sprite atlases and build. Record all generation prompts and source paths.

Keep source control as recovery for replaced PNGs. Never delete original Codex generated images.
