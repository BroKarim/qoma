# qyube active-session prototype v1

Status: visual draft for user review. These are static mockups, not an implemented macOS session or animation.

## Screens

- [01-timer-open.png](01-timer-open.png): the compact timer is at upper-left; the transparent fishing companion is at lower-right. The main app is hidden. The qyube menu-bar item displays only `08:42`, matching the floating timer.
- [02-timer-closed.png](02-timer-closed.png): only the floating timer is hidden. The menu-bar time and fishing companion remain visible.

The warm neutral desktop is presentation context, not a background painted by the companion window. The character window must be transparent outside the art in implementation.

## Confirmed interaction

| Current state | Action | Result |
|---|---|---|
| Floating timer visible | Click its close control | Hide timer only; keep session and penguin active. |
| Floating timer hidden | Click menu-bar time | Restore timer at saved position, displaying current remaining time. |
| Floating timer visible | Click menu-bar time | No action; no toggle, menu, focus change, countdown reset, or window movement. |

Restoring the timer returns to the first composition. Time continues while the panel is closed; the repeated `08:42` in these static images is only a visual placeholder.

## Visual review notes

Generated with the built-in imagegen tool, using the approved home prototype for UI styling and the existing no-ripple companion for character reference. The timer contains only time plus a small close control. No app logo accompanies the menu-bar time; ordinary macOS system icons are separate.

The generated artwork and panel dimensions remain approximate. The draft currently renders the timer about 275 px wide and the companion about 200 px wide on a 1536 px canvas, larger than the footprint target. The implementation targets in ART_DIRECTION.md remain authoritative: about 210 × 143 pt for the timer and 118 pt for visible companion art, assuming the reference Retina scale. Verify actual size in a native prototype before approval. Generation can introduce slight texture or silhouette differences; production states must reuse the same master artwork.

## References

- [Approved home prototype](../qyube-concepts-v3/01-home-floating-form.png)
- [Existing active companion art](../qyube-floating-prototype/01-active-fishing-no-ripple.png)
- [Art direction and behavior contract](../qyube-floating/ART_DIRECTION.md)
- [Generation prompts](PROMPTS.md)
