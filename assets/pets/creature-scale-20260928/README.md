# Creature scale, using Chicken as the baseline

Owner requested much larger, creature-appropriate proportions across all 36 pets.
Chicken keeps its authored height of 4.85 studs. These are art-direction sizes
for fantasy creatures, not claims of literal biological dimensions.

Base horizontal diagonals range from 6 studs (Horned Bunny) through 120 (World
Eater). Boar is 8.98 studs tall, Black Wolf 9.64, Ice Dragon 22.27, Hydra 35.94,
and World Serpent 73.41. Kraken stands 30.87 studs tall and spans 56.57 by 56.57.
Complete measured heights, footprints and unchanged part counts are in
`size-audit.json`; all pet models remain at 14–71 BaseParts.

## Growth and interaction

The shared 40-stud cap is removed. The existing Feed multiplier drives growth,
with an extra-footprint budget of 48 studs at level 40. Small creatures retain
their 5x curve; larger creatures add up to 48 studs to their base diagonal.
Every level grows and large species remain larger at the same Feed level.
World Eater reaches a 168-stud diagonal; Kraken reaches 128.

Giant silhouettes deliberately overhang the existing prototype pens. Production
wandering settles oversized models at the pen center; smaller models continue
to wander inside the fences. Multiple giant pets can overlap, and large carried
or pedestal pets can obstruct the camera. The map and carry multiplier were not
redesigned in this size pass. Scale does not add parts or establish an FPS claim.

Pickup prompts now sit two studs above the model's ground plane and server
distance validation uses that point. Feed prompts remain close to the dish after
growth. Placement raycasts exclude active pets so large wings/tentacles do not
intercept floor clicks. Pet identities, ownership, saved data and economy remain
unchanged. Template geometry and backups are untouched.

## Verification

- All six egg groups visually inspected in Studio with Chicken alongside them;
  screenshots are named basic, advanced, elite, master, supreme and ultimate.
- 4,705 edit-mode assertions on the actual PetModels module: all 36 species,
  levels 0–40, continuous/bounded growth, ground pickup points, scaled Motor6Ds,
  original template scale and part counts.
- 14,418 edit-mode assertions exercising the actual WanderingService: grown
  Chicken, Kraken, World Serpent and World Eater on all six rotated pen floors.
  Grounding, finite transforms, giant centering and ordinary-pet containment pass.
- Rojo build and whitespace checks pass.
- Fresh Play integration remains blocked: StudioTestService reports a previous
  test still running despite Edit mode. Ground pickup/feeding and click behavior
  need a normal Play smoke test after Studio is restarted. These edit-mode audits
  do not replace a multiplayer interaction or performance test.
