# Findings

User screenshot shows a rectangular undimmed patch behind transparent portions of the companion panel. User also reports stiff light-switch animation. Need regressions at controller/surface and actual scene-render seams.

Red feedback loop executed: xcodebuild test -project qoma.xcodeproj -scheme Qoma -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/qyube-companion-build -only-testing:QomaTests/DistractionIntegrationTests CODE_SIGNING_ALLOWED=NO. Both new regressions failed: transparentCompanionPanelDoesNotPunchABrightRectangle at levels 0/3/8; lightSwitchMovementContinuesBetweenDrawnPoses. Existing suite passes.

Ranked predictions: (1) rectangular own-panel exclusions cause undimmed transparent pixels; removing these holes should leave the veil intact. (2) panel stacking must remain above the veil, especially for elevated target windows; test levels 0/3/8 and restore original levels on hide. (3) current pose selection has unchanged transforms between steps; continuous body/arm motion should change adjacent rendered frames without crossfading whole characters.

Confirmed: protectedPanels was converted into rectangular occludedRegions, punching holes through the veil. Original screenshots only rendered companion and veil independently, missing the composition bug. A controller/surface integration regression now checks a transparent corner behind a real floating NSPanel. Float levels are raised only where needed and restored on hide; WindowServer handles sprite alpha.

Motion fix uses a separate illustrated shoulder-pivot flipper with stable body textures. Continuous reach/press/settle transforms replace the old dimBright frame-index stepping in the actual scene. Both sound beats remain clock-synchronized. New model tests verify continuity over 110 seconds of accelerated cycles, plus real scene tests for frame-to-frame movement and Reduce Motion.
