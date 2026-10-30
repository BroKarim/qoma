# Watercolor companion v2

Branch: `codex/companion-watercolor-animation`, created from `codex/settings-menu-popover`.
Generated with the built-in imagegen tool. Existing artwork remains available; runtime now uses two new transparent PNG atlases:

- `Qoma/Assets.xcassets/Companion/CompanionPosesV2.imageset/CompanionPosesV2.png`: 1536 × 1024, six whole-body poses (idle, tug, pull, celebrate, deposit, sleep).
- `Qoma/Assets.xcassets/Companion/CompanionCatchesV2.imageset/CompanionCatchesV2.png`: four columns (eyeless fish, boot, shell, bottle).

`CompanionScene` slices textures without rewriting the source pixels. Pose rectangles and rod-tip coordinates are explicit because generated artwork is not perfectly aligned to a uniform grid. The deposit rod extends slightly into the next nominal cell. Continuous position, rotation and breathing transforms animate between narrative beats. These are six key poses, not twenty individually drawn in-between frames.

Visual catches rotate independently of catalog rewards. They never create persistent catches or change their rarity. A session's real catch count still changes only through `recordCatch(kindID:)`. Reduce Motion suppresses bounces, sway and travel while retaining visible state changes and catch feedback.

## Generation prompts

Initial pose prompt: Production sprite atlas, single transparent PNG, exactly 3 equal columns and 2 equal rows, six square equal cells, no grid lines, no labels, no text, no background. Use reference penguin's hand-drawn watercolor design and paper texture. Each cell contains one full seated plump black and cream penguin holding a wooden fishing rod, consistent size and baseline. No mouth, beak or nose. Eyes only two simple curved black strokes or squeezed angle strokes, never circles, dots, pupils or eye whites. Continuous whole body. No fish, line, ice, bucket or water: these are separate runtime layers. Poses: calm idle; leaning forward at tug; strong pull leaning back; proud joyful catch; guiding catch to right; resting without rod.

Final pose revision prompt (verbatim):

> Correct this production atlas layout and alpha. Keep all SIX exact penguin poses, watercolor artwork and stroke-only eyes, no mouths. Exact 3 columns x 2 rows of equal square cells. CRITICAL shrink each complete character WITH its rod so the entire artwork fits inside its own cell with 12% transparent margin ON EVERY SIDE. Especially bottom left rod must be wholly below horizontal midpoint of image, middle-right-facing pose rod must not extend into bottom-right cell. All characters feet on same 85% baseline within their own cell. Keep size consistent. Remove ALL brown glow, gradients, paper backdrop, shadows outside characters. Background must be entirely alpha-transparent, absolutely no painted backdrop. No labels or lines. Deliver one neatly aligned six-pose sprite sheet.

Catch prompt (verbatim):

> Use case: stylized-concept. Production watercolor sprite atlas, exactly 4 equal columns in one horizontal row on true transparent background. Four isolated collectible objects: cell1 small silvery blue fish with fins and tail but absolutely NO eyes, NO mouth, NO facial marks; cell2 small worn brown ankle boot; cell3 curled pale peach seashell; cell4 little green glass bottle with cork. Hand-drawn dark organic pencil outlines and mottled watercolor paper texture matching a cozy black-and-cream watercolor penguin fishing game. Every object centered within its own cell, fit inside middle 65% cell width and height, generous transparent margins, similar visual size. No scenery, no ground, no shadows, no glow, no text, no grid, no numbers, no anthropomorphic faces on any object. These will be tiny fishing rewards in a desktop companion.

## Combined ice and water base

`Qoma/Assets.xcassets/Companion/CompanionIceWaterV2.imageset/CompanionIceWaterV2.png` is the single transparent environment image generated with built-in imagegen. Ice and water are painted together. The penguin and bucket remain separate so breathing, pulling, bouncing and deposit poses do not stretch the scenery. The base renders at 140 × 46 pt; the whole-body character renders at 100 pt high, with its feet at the ice contact level. The fishing line and splash use the left water ripple as their shared endpoint. See `ice-water-v2-prompt.txt` for the exact generation prompt and `ice-water-runtime.png` for the in-app composition.

Runtime integration uses `CompanionScene` through the existing `CompanionWindowController` for active and paused sessions; the panel takes its size from the scene. Decorative catch rotation comes from `CompanionPlayback.completedVisualCatches` so it remains consistent when an update crosses multiple animation phases. Persisted catch events update only the session reward count. The focused companion test suite, including frame-interval independence, passed after integration.
