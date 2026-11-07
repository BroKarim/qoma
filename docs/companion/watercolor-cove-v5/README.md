# Watercolor ice cove trial v5

Branch: `codex/watercolor-ice-cove-trial`. Previous branch saved at `b30867e`.

The new transparent environment was generated with built-in imagegen from `output/imagegen/penguin-diorama-drafts/draft-b-ice-cove-small-feet.png`. Exact prompt: `environment-prompt.txt`.

Runtime assets are grouped under `Qoma/Assets.xcassets/Companion/WatercolorCoveV5/`. The environment is newly painted; the character/rod twelve-drawing catch, cast, deposit and ice-hop atlases, bucket and fish are copies of the existing watercolor assets. This trial retains the proven full-cycle timing and whole-drawing animation rather than regenerating every pose. The reference's smaller feet have not yet been propagated across those legacy drawings.

The stage is 164 × 180 pt. A shared actor offset preserves the existing line-tip, bucket and catch-path calibration while placing the character on the cove. Three translucent fish move independently on shallow elliptical routes inside the lagoon. Pause freezes their clock; Reduce Motion holds their positions. Fish are decorative and do not affect catches or rewards.

The ice-hop distraction is the primary trial reaction. Existing light/snow reactions remain functional. Generate actual SpriteKit preview frames and clips with the Debug app's `--companion-snapshots <directory>` argument.

Validation: Debug compilation and 33 focused tests across CompanionPlaybackTests, DistractionIntegrationTests and DistractionMotionTests passed. Tests include fish movement, pause, Reduce Motion, hidden-state cleanup and fixed-island positioning. Test host and test bundle required consistent ad-hoc signing (`CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO`) for this local test run; project signing settings were not modified. Actual SpriteKit fishing and hop frames were visually inspected. Full fishing cycle (180 frames/30 fps) and hop preview are saved in `previews/`. `git diff --check` passed. No manual long-session or multimonitor QA.
