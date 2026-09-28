# Species base sizes — 2026-09-28

Historical first pass, superseded by `../creature-scale-20260928/README.md`.
The 40-stud shared cap described below is no longer active.

World size is derived from each species' `BaseFootprint`: the horizontal bounding-box diagonal in studs at Feed Level 0. Chicken keeps its original authored size at a 6.3-stud footprint and 4.85-stud height. The roster grows from that baseline to 18-stud Hydra and 22-stud World Eater footprints.

Feed growth still uses `FeedConfig.GetScale`. Growth is capped only when a model reaches a 40-stud footprint, leaving clearance inside the pen's 44-stud narrow dimension. Small pets can therefore use the full 5x growth curve while already-large monsters stop growing when they fill the pen safely.

Carry retains its 0.65 display multiplier. Placement, feeding pedestal updates, carry, and client feed animations all call `PetModels.GetScale`. Uniform scaling preserves model silhouettes, rigs, and part counts. No save data, income, feed odds, or template geometry changed.

| Egg | Species footprints (studs) |
|---|---|
| Basic | Chicken 6.3; Boar 7.1; Horned Bunny 6; Fox 8; Black Wolf 9; Baby Griffin 8.5 |
| Advanced | Ember Drake 13; Frost Wolf 9; Storm Griffin 13.5; Lava Golem 11; Thunder Serpent 12; Ice Dragon 15 |
| Elite | Kitsune 10; Minotaur 11.5; Basilisk 11; Manticore 13; Chimera 13.5; Cerberus 14 |
| Master | Hydra 18; Phoenix 14.5; Kraken 18; Ancient Wyvern 17; Bone Dragon 17; Behemoth 18 |
| Supreme / Ultimate | Astral Kitsune 12; Eclipse Griffin 16; Void Leviathan 19; Celestial Dragon 18; Seraph Beast 16; World Serpent 20; Divine Phoenix 16; Heavenly Kirin 13; Godly Behemoth 20; Galaxy Dragon 19; Cosmic Hydra 21; World Eater 22 |

## Verification

- Studio edit-mode geometry audit validates all 36 base footprints, level-10/40 capped growth, motor alignment, unchanged templates and part counts, and pen-compatible maximum footprints.
- Visual lineup inspected in Studio: Chicken 4.85 studs tall, Ice Dragon 5.97, Hydra 12.44, and Godly Behemoth 11.29. Hydra is over 2.5 times Chicken's height and clearly reads as a large monster.
- Earlier runtime integration passes remain valid for the shared scale path: CarryVerification 38, DebugVerification 47, and WanderingVerification 21.
- `revised-size-comparison.png` records the inspected Studio view.
