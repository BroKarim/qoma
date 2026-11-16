# Illustrated distraction effects

Integrated on the current `codex/companion-watercolor-animation` branch. Existing uncommitted fishing-companion and popover changes are preserved.

- Lights: code-drawn black veil, 85% peak opacity (80% fixed with Reduce Motion), clipped to the detected window and excluding occluding regions. Existing click-through window tracking remains in use.
- Ice flowers: approved illustrated sprites replace procedural branches. Capacity follows window area (one per 5,000 square points, minimum 24, maximum 180); starts at 25% and adds batches every ten seconds, full by 50 seconds. A 900 × 650 point window grows from 30 to 117; 600 × 400 grows from 12 to 48. Stable seeded layout, varied scale/rotation, close spacing and overlaps. Reduced Motion holds the initial arrangement.
- Snowstorm: 18–30 illustrated snow clumps, at most two wind illustrations, proportionally tiled bottom snowbank. No physics, blur, or new dependency. Uses the existing 30 Hz overlay clock, stops when the target loses focus or the session stops. Reduced Motion shows a static arrangement. No wind sound was supplied; this effect is silent.
- Penguin: twelve complete illustrated drawings for each of lights, annoyed hopping and blowing, following smooth-catch-v3. All share the overlay episode clock; registered body/floor anchors preserve placement. The existing floe and cup remain independent. Normal fishing resumes through the existing playback model. The separate-body rig trial was rejected and removed.

`prepare-distraction-assets.py` reproducibly extracts, registers, and downsizes the original imagegen sheets with Pillow. It does not redraw illustrations. Runtime assets live in `Qoma/Assets.xcassets/Distraction` and the three `CompanionDistraction*V3` image sets. The source PNGs, exact prompts and per-frame registration metadata remain in `penguin-drawn-v3/`. Runtime effect/character PNGs total about 3.1 MB.

Verification uses focused Swift Testing suites (`DistractionMotionTests`, `DistractionIntegrationTests`, `CompanionPlaybackTests`) and the existing debug flags `--distraction-snapshots` / `--companion-snapshots`. Snapshots are saved under `integration-check/`. Tests cover illustrated resources, bounded density, window resizing, pixel clipping through occlusion holes, dark/clear frames, sounds, episode preservation, synchronized penguin frames and Reduce Motion.

The debug overlay snapshot runner also reports mean CPU drawing time for 120 storm frames at 900 × 650 points. This fixture does not measure total application CPU/GPU usage, battery drain, or performance on other Macs. End-to-end manual QA across other applications, fullscreen, multiple monitors and continuous live resizing is still needed.

Final verification: Debug test build succeeded, 24 tests passed (28 cases including parameterized effects), zero failures. `git diff --check` passed. The measured AppKit CPU draw/capture fixture averaged 7.71 ms/frame over 120 frames on this MacBook Air. Final overlay snapshots confirm 117 flowers, 30 snow clumps, 0.85 dark opacity, correct overlay ordering and click-through. Companion contact sheet was inspected on light and dark backgrounds.

Subsequent polish: fixed the bright rectangular patch by removing own-panel rectangular holes and compositing floating panels above the veil. A continuous shoulder/body rig replaces the stepped light-switch poses. Follow-up verification passes 29 tests / 35 cases; combined preview and details live in `penguin-rig-v2/README.md` and `polish-check/polish/`.

Current revision supersedes that rig trial: all three distraction animations use twelve whole drawings, with active previews and notes in `docs/companion/smooth-distraction-v3.md`. The rig and old six-drawing runtime sets were removed, while source drawings remain archived. Final verification passes 32 tests / 38 cases, including full drawing order and no body-part rig nodes. The rectangular-cutout fix is preserved.
