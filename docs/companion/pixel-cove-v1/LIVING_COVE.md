# Living cove — 11 November 2026

## Stage 1 — codex/living-cove-atmosphere

Actors scale 0.45 (previously 0.78), preserving the seated world position. Removed procedural rotation/stretch on top of painted poses to avoid double motion. Swimming fish retain existing bounded lagoon routes and pause behavior. Added subtle float ripples, session-random light snow and an Appearance atmosphere picker. Auto uses local Mac time; light transitions take four seconds. No changes to catch odds or persistence.

Debug build succeeded. Added a pose stability test; visual QA and test execution follow below. Existing project warnings remain.

## Stage 2 — codex/cove-visitors

Small pixel gull/seal visitors, one at a time, every 8–15 minutes of active focus. Arrivals wait until idle fishing, duration 10–20 seconds. Pause freezes scheduling. No rewards or collection writes. Pixel silhouettes are drawn with SpriteKit pixel nodes; production art polish remains a visual-review item. Submarine deferred as agreed.
