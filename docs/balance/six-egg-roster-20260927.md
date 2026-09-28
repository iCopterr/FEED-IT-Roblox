# Six-egg roster and balance — 2026-09-27

Owner-authorized roster update; supersedes historical egg/pet tables in GDD v0.5. These are initial prototype values, not playtest-proven final balance.

## Progression choices

- Preserve Basic through Master prices, timers and species incomes. Retain their existing result weights while applying the requested rarity labels.
- Separate Divine and Cosmic pools. Supreme and Ultimate both use descending 45 / 28 / 18 / 7 / 1.8 / 0.2 percent results.
- Ultimate costs 500B Money (10× Supreme), incubates for 45 minutes, and occupies 0.1% of conveyor offers. Basic availability becomes 67.9%; the remaining tiers retain 25 / 5 / 1.5 / 0.5%.
- At the configured four-second offer interval, Ultimate appears once per ~66.7 minutes on average, with substantial random variation and no guarantee. It remains an endgame purchase.
- Rarity order: Common → Uncommon → Rare → Epic → Legendary → Mythic → Fabled → Divine → Celestial. Celestial rarity and the existing Celestial variant are separate fields.
- Income is species-specific. Earlier rare pets can outperform later common results; feed/variant multipliers, food prices, explosion risk, and transaction order are unchanged.

## Pools

All incomes below are Money/second at Feed Level 0 with the Normal variant. Odds are conditional on hatching that egg; conveyor availability is separate.

### Basic Egg

Price: **5,000**. Incubation: **0m 10s**. Weighted mean base income: **33.59/s**.

| Pet | Rarity | Hatch odds | Base income/s |
|---|---|---:|---:|
| Chicken | Common | 36% | 10 |
| Boar | Common | 29% | 16 |
| Horned Bunny | Uncommon | 18% | 35 |
| Fox | Uncommon | 11% | 55 |
| Black Wolf | Rare | 5% | 140 |
| Baby Griffin | Epic | 1% | 600 |

### Advanced Egg

Price: **2,000,000**. Incubation: **2m 0s**. Weighted mean base income: **368.50/s**.

| Pet | Rarity | Hatch odds | Base income/s |
|---|---|---:|---:|
| Ember Drake | Uncommon | 35% | 80 |
| Frost Wolf | Uncommon | 27% | 200 |
| Storm Griffin | Rare | 20% | 320 |
| Lava Golem | Rare | 11% | 850 |
| Thunder Serpent | Epic | 6% | 1,400 |
| Ice Dragon | Legendary | 1% | 4,500 |

### Elite Egg

Price: **500,000,000**. Incubation: **12m 0s**. Weighted mean base income: **1,577.50/s**.

| Pet | Rarity | Hatch odds | Base income/s |
|---|---|---:|---:|
| Kitsune | Rare | 34% | 450 |
| Minotaur | Rare | 28% | 700 |
| Basilisk | Epic | 20% | 1,800 |
| Manticore | Epic | 12% | 2,800 |
| Chimera | Legendary | 5.5% | 7,500 |
| Cerberus | Mythic | 0.5% | 24,000 |

### Master Egg

Price: **5,000,000,000**. Incubation: **20m 0s**. Weighted mean base income: **8,445.00/s**.

| Pet | Rarity | Hatch odds | Base income/s |
|---|---|---:|---:|
| Hydra | Epic | 38% | 3,500 |
| Phoenix | Legendary | 30% | 5,500 |
| Kraken | Legendary | 18% | 12,000 |
| Ancient Wyvern | Mythic | 11% | 18,000 |
| Bone Dragon | Mythic | 2.5% | 40,000 |
| Behemoth | Fabled | 0.5% | 65,000 |

### Supreme Egg

Price: **50,000,000,000**. Incubation: **30m 0s**. Weighted mean base income: **80,050.00/s**.

| Pet | Rarity | Hatch odds | Base income/s |
|---|---|---:|---:|
| Divine Phoenix | Legendary | 45% | 35,000 |
| Heavenly Kirin | Mythic | 28% | 65,000 |
| Seraph Beast | Mythic | 18% | 150,000 |
| Godly Behemoth | Fabled | 7% | 200,000 |
| Celestial Dragon | Divine | 1.8% | 250,000 |
| World Serpent | Divine | 0.2% | 300,000 |

### Ultimate Egg

Price: **500,000,000,000**. Incubation: **45m 0s**. Weighted mean base income: **221,000.00/s**.

| Pet | Rarity | Hatch odds | Base income/s |
|---|---|---:|---:|
| Astral Kitsune | Mythic | 45% | 100,000 |
| Eclipse Griffin | Fabled | 28% | 220,000 |
| Void Leviathan | Fabled | 18% | 320,000 |
| Galaxy Dragon | Divine | 7% | 550,000 |
| Cosmic Hydra | Divine | 1.8% | 850,000 |
| World Eater | Celestial | 0.2% | 1,500,000 |

## Balance interpretation

These prices assume a developed pen and feeding, rather than payback from one newborn pet. At Level 15 the existing multiplier is 500×. Five surviving Normal pets at their egg’s weighted mean produce the following illustrative income; this ignores food cost, failed attempts, hatch variance and time to reach that level.

| Tier | Five level-15 pets / second | Time to next egg at that income |
|---|---:|---:|
| Basic Egg | 83,975 | 0.4 min |
| Advanced Egg | 921,250 | 9.0 min |
| Elite Egg | 3,943,750 | 21.1 min |
| Master Egg | 21,112,500 | 39.5 min |
| Supreme Egg | 200,125,000 | 41.6 min |
| Ultimate Egg | 552,500,000 | — |

Supreme’s higher average income and upgraded existing cosmic pets are intentional owner-authorized rebalance changes. Observe actual hatch-to-feed retention, time to afford each egg, and survivor distributions before further adjustments. No rarity-wide income multiplier was added.

## Save compatibility

PlayerData v10 → v11 updates rarity and base income by stable SpeciesId in inventory, pending recovery, and already-purchased eggs. Pet IDs, traits, variants, levels, locks, placement, currencies, discovery and recovery fields survive. Paid eggs retain the exact reserved species, price and incubation schedule; they are not rerolled. Saved EggId records original acquisition, while PetConfig.EggId identifies the current hatch pool. Existing cosmetic template names and all old models remain intact.

## Assets and verification

Six new models use the established sculpted wedge construction, then native CSG grouped by rigid rig anchor. Source drafts and final RBXM files are in `assets/pets/divine-cosmic-20260927`. Final counts include invisible rig anchors: Divine Phoenix 17, Heavenly Kirin 19, Godly Behemoth 24, Galaxy Dragon 32, Cosmic Hydra 48, World Eater 15. Total 155 parts.

All six received front/rear visual inspection, rig graph checks, native serialization roundtrips, bounds checks and 2× scaling. Low instance counts do not prove low rendering cost: the six contain 204,198 union triangles in total. Runtime profiling remains necessary.
