# qyube floating companion — revised states

Built-in imagegen. Both PNGs have transparent alpha.

- `01-active-fishing-no-ripple.png`: revised active state with the prominent concentric ripple removed.
- `02-paused-sleeping.png`: sleeping pose with small z letters from the mouth.

The generated floe is visually matched for concept review. Production animation should reuse one literal fixed floe layer and bucket layer across all states.

## Active revision prompt

Use case: precise-object-edit.
Edit target image 1 is the existing qyube active fishing floating companion PNG. Make exactly one visual change: completely remove the large dark concentric water ripple/rings below and left of the ice floe. Replace that area with genuinely transparent alpha, clean edges, no residual gray circles, no halo, no splash. The fishing line may end subtly at an invisible water point near the floe; do not add new water art.
Preserve every other feature as closely as possible: same exact ice floe shape, size, orientation, watercolor texture and position; same penguin face/body/pose/size/brush style; same fishing rod and thin line; same bucket shape and position; same overall transparent canvas dimensions and foreground alignment. No background or opaque canvas. No blue. Do not crop. This is the revised active state to become the fixed-base reference for a sleeping state.

## Sleeping prompt

Use case: precise-object-edit.
Image 1 is the EDIT TARGET and canonical qyube floating companion active-state art after removal of water ripple. Image 2 is ONLY a pose reference: a curled up sleeping penguin with tucked feet, charcoal watercolor, no background. Create ONE sleeping/paused state from image 1.
ABSOLUTE fixed-scene invariants: preserve image 1's precise small ice floe outline, size, position, angle, pale gray-white watercolor surface, and shadowing; preserve the same metal bucket in the same exact place at the right edge of the floe. Keep the canvas and transparent background. No water ripple or rings, no splash, no background of any kind. Do not redesign the floe or bucket. The subject must be visibly the SAME penguin character as in image 1: same head cap, white face/belly, charcoal gray back, tiny black feet/flippers, loose ink-and-watercolor brush texture, overall size relative to ice.
Change only the penguin's pose and small accessories to show PAUSE / SLEEPING: penguin is lying curled on its side atop the same ice, similar to image 2, gently tucked flippers and feet, closed relaxed eyes, beak/mouth visible oriented toward the upper-right, calm and cozy. The fishing rod is laid neatly on the ice, low and unobtrusive, with no long vertical hanging line. No fish being caught. Add exactly three small handwritten pale graphite “z” letters emerging clearly from the penguin's mouth/beak, drifting diagonally upward; first z smallest close to mouth, others slightly larger farther away. They must appear to come from the MOUTH, not from an arbitrary point above its head. No other text or symbols.
Compact desktop companion asset, entirely within canvas, comfortable transparent margins. Original 2D charcoal and warm-gray watercolor look. No blue, no glasses, no UI frame, no timer, no window chrome, no extra props or characters. Genuinely transparent alpha outside the foreground art, not an opaque white or checkerboard background.

