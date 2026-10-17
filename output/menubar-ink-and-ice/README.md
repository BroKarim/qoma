# Ink & Ice — implementation review

Actual SwiftUI/AppKit renders at 2×, produced with isolated fixture preferences and session repositories. Fish and selected apps in these screenshots are fixtures, not personal session records.

- `01-idle-timer.png`: timer-only idle.
- `02-idle-allowing.png`: idle with app summary and five daily catches.
- `03-active.png`: locked duration/mode, Pause and Stop in a 4:1 ratio.
- `04-paused.png`: Resume and Stop.
- `05-allow-list.png`, `06-block-list.png`: separate app editor surfaces.

The watercolor penguin uses the existing JournalArcticPenguin asset with subtle movement that respects the system and app Reduce Motion settings. Surfaces use flat colors and drawn borders, with no background image.

Validation: Debug macOS build, session/reset/live rule tests, daily catch tests, menu-bar timer tests, and temporary render checks passed. The temporary render harness was removed after inspection. Native mouse/keyboard routing, search typing, and NSOpenPanel interaction have not been manually retested in this redesign.
