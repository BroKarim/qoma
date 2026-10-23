# Uncommon artwork integration — 22 October 2026

36 generated fish assets are available. 34 are integrated into existing game slots `uncommon-03` through `uncommon-36`. Slots 01–02 retain legacy Trout and Seashell. This preserves the 36-item Uncommon pool, existing catch IDs, item weights, base odds and rarity simulation.

The manifest records `productionGameID`, separate from the artwork `id`. The app uses `Collectible-<artwork id>` image sets; no randomizer changes are needed. Uncommon Silverfish Garis Tembaga (`uncommon-silverfish-stripe`) and Lanternfish Bulat (`uncommon-lanternfish-round`) remain reserved without pool slots. They were not discarded.

Existing catches with numbered IDs now resolve to the new names and artwork. Further generation should fill unmapped slots in other tiers or explicitly revisit pool size before adding Uncommon items. Keep the decoder fixes documented in `task_plan.md`.
