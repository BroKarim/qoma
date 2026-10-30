# Catch motion trial v3

A three-second clip of idle → bite → anticipation → pull → held reward, rendered by the actual SpriteKit companion on light and dark backgrounds.

- Preview: `smooth-catch-v3.gif` (looping) and `smooth-catch-v3.mp4` (30 FPS render).
- Artwork: `Qoma/Assets.xcassets/Companion/CompanionCatchFramesV3.imageset/CompanionCatchFramesV3.png`.
- Generation: built-in imagegen, reference `CompanionPosesV2`. Exact prompts are in `smooth-catch-prompt.txt` and `smooth-catch-layout-prompt.txt`.
- Twelve drawings replace the former large pose jumps during the bite and pull. The drawn action advances at roughly 12 drawings per second, while breathing, the line and the catch move continuously.
- Per-frame feet anchors compensate for generated cell margins. Rod tips follow the corresponding painted frames.
- Default pulling duration is 1.4–1.6 seconds, including a held reward beat. Reduce Motion holds a single drawing and retains catch feedback.
- Reproduce by running the Debug app with `--companion-snapshots <directory>`. The `catch-clip` subfolder contains 90 PNG frames at 30 FPS.

The clip intentionally stops before deposit. The bucket transition and the other animation states still use the preceding artwork and need a separate pass if this motion direction is accepted. Drawn-frame texture and silhouette consistency still need human feel review at normal speed; adding more frames alone does not establish final animation quality.

Validation: build succeeded; CompanionPlaybackTests and DistractionIntegrationTests passed, including drawing order, feet stability through Reduce Motion, distraction reset, and reward accounting. PNG frames were visually inspected for foot contact, rod/line attachment and catch visibility on both backgrounds.
