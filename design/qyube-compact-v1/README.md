# qyube — Compact white UI prototypes

Date: 2026-10-02. Branch: `codex/qyube-compact-prototypes`.

Status: Home direction approved; seven additional screens are proposals for user review. These generated images describe visual direction and content hierarchy, not implemented UI or pixel-perfect specifications. Image generation used the built-in image_gen tool; see [PROMPTS.md](PROMPTS.md).

## Screens

| Image | Purpose |
|---|---|
| [01 — Home empty](01-home-empty.png) | Today summary, fishing penguin, empty history, New session. |
| [02 — Home history](02-home-history.png) | Real-duration summary with completed and interrupted rows. |
| [03 — New Session](03-new-session.png) | Optional task, mode, conditional app selection, duration, Start. |
| [04 — Home active](04-home-active.png) | Current session and Show timer, alongside previous sessions. |
| [05 — Fishing Report](05-fishing-report.png) | Completed session, catch totals, discoveries, highlights, next session. |
| [06 — Catalog](06-catalog.png) | Small adaptive grid, discovered counts, dark undiscovered silhouettes, selected-item detail. |
| [07 — Insight Day](07-insight-day.png) | Individual polaroid catches, focus metrics, distribution, sessions, daily catch summary. |
| [08 — Insight Week](08-insight-week.png) | Period metrics/chart, five-column catch thumbnails and aggregate counts. Pattern also serves Month/Year. |
| [09 — Settings](09-settings.png) | Compact settings content with the gear menu open. |

## Visual contract

- Pure neutral white `#FFFFFF` application surface; charcoal approximately `#222222` for primary text/buttons; neutral grays for secondary text and controls. No cream wash, decorative gradient, or blue UI accent. Colorful collectible art and genuine app icons are allowed.
- One compact main window, no sidebar. Target starting width 420 pt, height about 700 pt; keep resizing and scrolling available. Image pixel dimensions are not point dimensions.
- Header: close, qyube, Insight, Catalog, gear. Back navigates to Home from internal pages. Gear opens Settings, Manage subscription, Sign out, Help, Give feedback, Quit.
- Use space for grouping. Borders are functional and sparse: fields, selection, collection cells and a few separators. Avoid wrapping every section in cards.
- Keep the watercolor/charcoal no-glasses penguin identity. Inside Home/setup/report it has no ice, bucket, water or ground shadow. Reuse registered poses from the existing asset set for actual animation.
- Keep timer and desktop companion as two separate floating surfaces during a session. This main-window redesign does not remove them or change desktop companion props.
- No daily goal, tag UI, automatic break, Aquarium, catch-buy/sell controls, or return to freemium packaging.

## Agent implementation notes and image limitations

1. Preserve business rules in the current task plan. Images use illustrative content and are not database fixtures. Catalog species/colors are provisional art, not a final content roster.
2. New Session's generated duration control resembles a stepped slider and repeats the value in a selector. Implement one ruler with 180 first, then every minute from 10 through 60, default 10. Do not copy the apparent ten-minute-only increments or duplicate input.
3. Home active's 1h20m illustrates 72 finished minutes plus 8 active minutes. Reconcile this live summary without persisting or counting the active session twice. Show timer is the main footer action; the duplicate inline action may be omitted for simplicity.
4. Report is a completed-state proposal. Interrupted sessions use a calmer compact report; below five active minutes explain catch return, at/after five preserve banked catches. Completion never gates rare/legendary eligibility. Highlight items are a subset, not the total ledger.
5. Catalog example has 12 discovered cells out of 25. Each entry maps to a stable species ID; counts come from banked catches. The total roster is not fixed at 25. A selected detail can be an inline region or accessible sheet after user review.
6. Insight Day is an extended scroll-content preview, with its lower edge cropped. Do not create an excessively tall fixed window to fit it. Header/period controls remain reachable. Latest catch cards keep duplicates; daily summary groups counts. View all expands the collection without a hard data cap; render lazily.
7. Week is the shared period pattern: Month uses days/weeks as appropriate and Year uses months. Use 5 or more columns when space permits and fewer at narrower widths. Week artwork repeats more submarines than the sample aggregate count; chart bars and catch quantities across prototypes are illustrative and must be derived from consistent data in code.
8. Settings menu is intentionally shown open. In the generated correction it appears to push the Sound group lower: actual popover must overlay content without relayout. Session sound/Soft bell and Volume/slider each form one row. Launch at login is a proposed row, not evidence it has been implemented. Route billing/account actions only to configured flows; do not invent working endpoints.
9. Control sizes, contrast, keyboard focus, icon tooltips/VoiceOver labels, scroll restoration and Reduce Motion require native verification. The generated typography and spacing are directional; enforce readable sizes at actual 420 pt width.

## Review and scope

All nine images were visually inspected. Catalog total and Settings labels were corrected with targeted image edits. No Swift application code was changed for this prototype batch. Existing uncommitted code and earlier design deletions were carried onto the new branch without modification. Previous prototype folders and documentation remain historical references.

See [task_plan.md §12](../../task_plan.md) and [ART_DIRECTION.md §14](../qyube-floating/ART_DIRECTION.md) for the dated precedence rules.

## Native implementation follow-up — 2026-10-03

The user approved the compact interaction recommendations, except for the proposed 420 × 700 pt dimensions. The native build on `codex/qyube-compact-ui` starts at 360 × 610 pt, matching the narrow prototype proportions; scrolling handles longer pages. Settings is a route in the same main window and supports ⌘,. Earlier sizing/proposal text above is retained as history.

All collectible surfaces temporarily share the existing watercolor `CompanionFish` illustration, including the penguin's desktop catch sprite. Counts/identities remain backed by the actual ledger. Desktop floating panels continue to follow `qyube-active-session-v1`. See task_plan §13 for implementation mapping, checks and remaining production work.
