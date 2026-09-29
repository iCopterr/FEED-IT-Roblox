# Rectangular egg set

## Particle detail pass — 2026-09-29

All eggs now include themed authored emitters: pollen/fireflies, frost/embers,
enchanted wisps, ancient soul embers, divine stardust, and cosmic stars/nebula.
Each layer uses short lifetimes, rotation, size and transparency curves. Emitters
stay attached to moving shells. Supreme and Ultimate add soft shadowless lights.
No BaseParts added. Rates per Basic through Ultimate: 5, 14, 16, 18, 22, 31/sec;
2–6 emitters per egg, lifetime <=2.2 seconds. Built-in textures require no upload.

Saved asset budget/sequence checks, Rojo build and live Studio assertions pass.
After reconnecting to localhost:58742, inspected all six emitting review models
in entry/premium views. Increased non-Basic sparkle sizes by 50% for readability
without increasing rates. Shell silhouettes remain clear. Evidence is saved in
particles-entry.png, particles-premium.png and particle-live-audit.json.
This verifies Edit-mode appearance; fresh Play interactions and FPS profiling
were not performed.

Six stepped, studded cuboid shells with original tier-specific decorations.
Authored source: `src/world/EggTemplates.rbxmx`; rebuild recipe:
`python docs/studio/build-rectangular-eggs.py`.

| Egg | Design | BaseParts |
|---|---|---:|
| Basic | Sandstone/cream shell, seed seal, little green sprout | 12 |
| Advanced | Deep teal, paired ice crystals, amber vents, cyan core | 14 |
| Elite | Violet, ivory horns, golden mythical crest | 15 |
| Master | Moss stone, fossil mask, tusks and dorsal plates | 19 |
| Supreme | Ivory/gold, feathered wings, rectangular luminous halo | 24 |
| Ultimate | Indigo, violet crown, stars and tilted square cyan orbit | 18 |

Budget was under 40 BaseParts per egg. Stud surfaces add no separate stud parts.
No external meshes, textures, scripts or animated rigs are required. These are
static templates: conveyor/placement anchor them; existing carry code welds every
part to the hand. A Shell PrimaryPart preserves a stable pivot across clones.

Original asset preserved in `backups/EggTemplates-original.rbxmx`; live originals
also copied into `ServerStorage.EggModelBackups.OriginalRoundEggs` before Rojo
updated the templates. Template IDs are unchanged, so egg pools, inventory,
conveyor, carry and incubation continue resolving their existing models.

Verified saved Rojo asset build, six live template names, rectangular Shell
shapes, PrimaryParts, anchored/noncollidable geometry, <=40 part counts, and
clone/ScaleTo(.65)/PivotTo behavior. Front overview, entry/premium close views
and rear view inspected. Corrected disconnected orbital corners and crystal
joins after the first review, then rebuilt and inspected again.

Fresh Play hatch/conveyor/carry interaction testing was not performed; the
previous StudioTestService stale-session blocker remains unresolved. Prices,
odds, incubation times, UI artwork and pet models are unchanged. Review copies
are in `Workspace.RectangularEggReview`, away from the playable island.
