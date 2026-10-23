# Analytics calendar UI — 22 October 2026

Component renders using synthetic QA data, not user history. These images exercise the calendar, sessions, Top Apps and catch grid; they are not captures of the full running app shell. The actual dashboard additionally includes its eyebrow header and selected-day focus summary.

- `compact-310.png`: 310pt width, long session title, durations below/above an hour, duplicates, multiple rarities.
- `wide-500.png`: 500pt width, adaptive catch grid.
- `empty-six-week-month.png`: empty state and August 2026 with six calendar rows in the test locale.

App build and temporary ImageRenderer QA harness passed. Harness removed after visual inspection. Existing Analytics repositories, tracking, heatmap/domain calculations and rarity configuration were not changed. Website UI stays hidden; legacy Heatmap and Breakdown components remain available elsewhere in source.
