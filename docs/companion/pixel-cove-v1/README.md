# Pixel art cove comparison

Branch: `codex/pixel-art-cove-trial`, forked from watercolor commit `bf2a998`.

Built-in imagegen generated the environment, five animation sheets (54 drawings) and an eight-item prop kit, using `output/imagegen/penguin-diorama-drafts/draft-b-ice-cove-pixel-art.png` as the style reference. Source images, common style prompt and prop prompt are preserved here. `prepare-assets.py` exports the pixel runtime assets under `Qoma/Assets.xcassets/Companion/PixelCoveV1/`. Registered watercolor silhouettes are used only as alpha mattes to reject generator backgrounds and preserve cell alignment.

The fishing state machine, twelve-drawing action timing, cast/catch/deposit path calibration, small 0.78 actor scale, distraction timing, swimming paths, pause, interruptions, decorative catch accounting and Reduce Motion behavior are inherited from the watercolor version. This comparison changes only artwork and texture filtering to nearest-neighbor. No animation dependency was added.

Motion purpose: state indication for fishing/distraction and the requested ambient fish behavior. SpriteKit remains at 60 FPS with complete drawn poses and the existing smooth travel between states. Preview clips use 30 FPS. The pixel counterpart is a generated adaptation of the reference, rather than a pixel-for-pixel reproduction of every frame.

Both branches remain available for selection. This branch does not change the saved watercolor branch. Previews are captured from the actual SpriteKit renderer.

Validation: Debug build succeeded; 34 focused companion/distraction tests passed. Preparation checks all 54 character cells are present. Final fishing, deposit and hop were inspected using actual SpriteKit renders. Full-cycle preview contains 180 frames at 30 FPS; hop preview verifies all twelve drawings. The final island-only cleanup was followed by another successful build and fresh preview export. `git diff --check` passed. Long-session/multimonitor manual QA was not performed.
