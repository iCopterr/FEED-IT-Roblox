# Egg content

Three conveyor eggs; 18 species total. Existing prototype IDs, odds, price and
timer remain unchanged so old inventory and incubating eggs remain compatible.

| Egg | Price | Incubation | Conveyor chance |
| --- | --- | --- | --- |
| Prototype | 5K | 10 seconds | 70% |
| Advanced | 2M | 2 minutes | 25% |
| Elite | 500M | 12 minutes | 5% |

Advanced: Moss Buddy (Uncommon 25%), Clover Cub (Uncommon 25%), River Sprite
(Rare 25%), Dusk Fox (Epic 15%), Sun Guardian (Legendary 9.5%), Moon Spirit (Mythic 0.5%).

Elite: Crystal Cub (Rare 25%), Prism Buddy (Rare 25%), Amethyst Spirit (Epic 25%),
Solar Phoenix (Legendary 12%), Lunar Guardian (Legendary 12%), Astral Dragon (Mythic 1%).

New tier prices/timers/odds follow GDD section 9.2 candidates. Suggested level
unlock gates are not added. Conveyor spawn weights are prototype tuning values.
Per-rarity base income is unchanged. No save-schema change or increased incubation capacity.

All eggs reuse prototype_egg. Each new pet's authored template is an exact copy
of the existing model of its rarity, saved under its species ID. Carry, placement,
feed effects and inventory previews therefore use the existing model pipeline.
No runtime geometry generation, final art, or additional world areas are introduced.
