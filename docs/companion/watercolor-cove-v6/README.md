# Watercolor cove v6: proportions and lagoon paths

Branch: `codex/watercolor-cove-proportions-fix`.

Five atlases (54 drawings) were edited using built-in imagegen to match the approved small-foot penguin. Catch, cast, deposit, rest and hop all use the revised feet. Source sheets and the prompt are in `sources/` and `small-feet-prompt.txt`. Run `python3 docs/companion/watercolor-cove-v6/prepare-assets.py` to reproduce atlas sizing and matte preparation; it validates every cell. Prior silhouettes from commit 72edfad are used only as transparency masks to suppress generator halos, not as runtime character artwork.

The existing actor coordinate calibration is preserved under a uniform 0.78 scale around the seating location. This reduces the painted body to roughly 58 pt while keeping line tips, bucket and catch paths in the same coordinate system. The island artwork itself is unchanged.

All three fish now stay in the open lower lagoon: their entire sprite bounds fit within x=39...91 and y=29...50. Slightly different speeds, shallow curved routes, small body tilts and a soft turn replace the previous straight paths and hard flips. Pause and Reduce Motion remain supported. Regression tests sample two minutes of all three routes, including sprite margins.

Runtime assets are under `Qoma/Assets.xcassets/Companion/WatercolorCoveV6/`. Old v2/v3/v4 animation atlases and v5 copies were removed from this branch; they remain recoverable in the prior branches. One new hop atlas supplies distraction character drawings; existing effect-specific timing and lift behavior are preserved. No changes to focus policy, overlay effects or persisted rewards.

Validation: Debug build succeeded; 34 focused tests across CompanionPlaybackTests, DistractionIntegrationTests and DistractionMotionTests passed. Actual renderer fishing, deposit, sleeping and hop images were inspected; the final export contains 180 full-cycle frames and 90 hop frames at 30 FPS. Preview exporters verify all twelve distraction drawings are present. Preview aspect ratio is corrected to match the 164×180 pt stage. Final `git diff --check` passed. No manual long-session or multimonitor QA.
