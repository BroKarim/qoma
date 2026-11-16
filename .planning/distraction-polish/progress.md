# Progress

- Began investigating reported light-switch motion and rectangular cutout in current branch.
- Ran red regression suite: rectangular hole fails at window levels 0/3/8; light-switch continuous movement fails. Initial per-function Xcode filter ran zero Swift Testing tests, so reran the whole integration suite to verify actual failures.
- Removed own-panel rectangular exclusions and elevated floating app panels over the veil where required; original levels restore on hide. All panel/alpha regressions now pass.
- Generated a matching body/blink/flipper/switch puppet sheet via built-in imagegen, preserved source and prompt, extracted small runtime sprites. Light-switch animation now uses continuous shoulder rotation, body anticipation/press/settling, breathing and blink timing; no whole-character crossfade. Existing SKView renders at 60 fps.
- Focused tests passed after runtime changes, including both new regressions and continuity through accelerated cycles. Building debug preview fixture for visual verification.
- Final verification: 29 tests / 35 expanded cases passed (xcresult Test-Qoma-2026.10.28_12-04-24-+0700). Preview-only build passed after adding a deterministic combined overlay/SpriteKit fixture. The first preview build ended with signal 15 during package resolution; retry with cached package resolution succeeded.
- Exported and inspected press/dark PNGs and 240-frame GIF under design/qyube-distraction-v1/polish-check/polish. Log confirms noRectangularCutouts=true. Native layer order/click-through check passes. Real App Store/fullscreen/multi-monitor QA not performed.
