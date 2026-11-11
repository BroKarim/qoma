# Living cove — 11 November 2026

## Stage 1 — codex/living-cove-atmosphere

Actors scale 0.45 (previously 0.78), preserving the seated world position. Removed procedural rotation/stretch on top of painted poses to avoid double motion. Swimming fish retain existing bounded lagoon routes and pause behavior. Added subtle float ripples, session-random light snow and an Appearance atmosphere picker. Auto uses local Mac time; light transitions take four seconds. No changes to catch odds or persistence.

Debug build succeeded. Added a pose stability test; visual QA and test execution follow below. Existing project warnings remain.

## Stage 2 — codex/cove-visitors

Small pixel gull/seal visitors, one at a time, every 8–15 minutes of active focus. Arrivals wait until idle fishing, duration 10–20 seconds. Pause freezes scheduling. No rewards or collection writes. Pixel silhouettes are drawn with SpriteKit pixel nodes; production art polish remains a visual-review item. Submarine deferred as agreed.

## Stage 3 — codex/cove-interactive-bucket

Bucket click opens a transient live session popover, with counts by species, discoveries compared with banked catches in other sessions, provisional notice and Open Catalog. Uses indexed account/session query including both banked and provisional events. Existing shared catch artwork remains until its pixel replacement. Companion accessibility press and Space/Return open catches; clicking elsewhere still opens timer, dragging still moves the panel. Popover closes with panel/session removal; existing completion flow continues to hide the companion.

38 focused companion/visitor tests passed before the final discovery-label update. Final Debug build succeeded and the actual renderer exported contact-sheet, fishing and hop frame sequences under /tmp/qyube-living-cove-preview. Smaller body and fixed feet inspected on contact sheet. Pending: manual bucket click/keyboard QA, long visits, time-of-day transition, pixel source silhouette cleanup (existing watercolor-derived alpha mattes may still clip individual drawings).

Final focused test run passed (40 cases), including bucket query account/session isolation and provisional/banked rows. Source snippets and PNG contact sheet are saved in previews/living-cove. No production account or focus session was started.
