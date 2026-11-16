# Qyube snow demo v1

Status: completed with local Python/Pillow + FFmpeg compositing. No HeyGen generation used.

Branch: codex/qyube-snow-demo.

Assets:
- assets/qyube-cap-1.mp4 — original source, copied without modification; 1080 × 1184, 30 fps, 16.733333 s.
- assets/blue-sage.png — selected generated background, copied without modification.
- prompt.md — reusable brief, approved direction, timeline and execution constraints.
- assets/island-mask.png — exterior black matte removal, preserving the dark cave and penguin.
- assets/bird-sprite.png — original procedural pixel bird; both wing poses are defined in render.py.
- render.py — complete reproducible composition, including seeded snow and water ripples.
- preview-03s.png, preview-09s.png, preview-15s.png — review stills.
- qyube-snow-demo-v1.mp4 — final H.264 video with original AAC audio copied unchanged.

## Reproduce

Requires Python 3, Pillow, numpy, ffmpeg and ffprobe. Run `python3 render.py` from this folder, or run the script by its path. This overwrites the final render and generated preview assets, leaving source assets intact.

## Validation and scope

Revision: island reduced by 15% to 680 × 529 at (500, 457); outside matte contracted by 4 source pixels with a soft half-pixel edge to remove the dark exterior border. Ground shadow and ripple positions adjusted to match. Duration and other effects unchanged. Re-render verified at 502 frames / 16.733333 seconds and decoded without errors.

Output: 1308 × 1200, 30 fps, 502 frames, 16.733333 seconds, matching source video duration. Background's last row/column cropped to make dimensions even for H.264. Verified frame count and duration with ffprobe; decoded entire output with FFmpeg without errors; visually reviewed the 9-second still. Camera and island position are static; original fish/fishing motion and audio retained. Added a 0.45-second island fade-in, subtle ground shadow, 48 seeded snow particles, four gentle ripple events, and a two-pose pixel bird crossing at 8–11 seconds. No added music or voice.

The fixed silhouette mask is tailored to this stationary source; use per-frame matting if replacing it with moving scenery. Full real-time playback was not manually reviewed.
