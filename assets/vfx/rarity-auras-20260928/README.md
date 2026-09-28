# Progressive rarity auras

Presentation-only, client-local effects for tagged `PetVisual` models. No BaseParts, rig changes, economy changes or model-template edits.

| Rarity | Total particles/second | Appearance | Light brightness |
|---|---:|---|---:|
| Epic | 3 | Sparse purple sparks above silhouette | 0 |
| Legendary | 7 | Golden sparks and gentle light | .25 |
| Mythic | 12 | Main and side sparkles | .45 |
| Fabled | 20 | Denser sparkles and soft aura | .7 |
| Divine | 34 | Soft aura, side sparkles and crown stars | 1 |
| Celestial | 52 | Largest, densest sparkles, aura and crown stars | 1.5 |

Rates are the full-detail totals across all continuous emitters. Shiny/Rainbow/Celestial variants retain their tint and establish a minimum effect tier (Legendary/Mythic/Divine); they never downgrade a stronger rarity. Rainbow tint cycles. All effects follow the pet and resize after feeding growth.

## Budgets

- At most 18 nearest pet auras within 100 studs.
- Beyond 55 studs, rates drop to 40%.
- At most six unshadowed local PointLights, within 45 studs, range capped at 12.
- Particle size/growth extent capped to prevent giant pets filling the screen.
- Hidden feeding presentation pets, distant pets and removed pets clean up their effects.
- Existing eight-burst cap and cleanup retained.

The highest tier uses five emitters and up to one light; zero physical parts. These limits are verified, but FPS improvements are not claimed.

## Verification

`VFXVerification` passed 58 checks in Studio Play, including strictly increasing tier rates, low-rarity exclusion, variant minimums, growth, no added model parts, effect duplication, distance/hidden cleanup, aura/light caps, lower distant rate and burst cleanup. Rojo build and diff checks passed.

Studio screenshots compare the same Ice Dragon geometry at all six rarities. In `overview.png`, screen left is Celestial and screen right is Epic. `epic.png` shows the refined emission point above the silhouette; `celestial.png` shows the richer body/crown treatment. Editor review is a seeded still sample; particle positions vary during Play. Source: `docs/studio/review-rarity-auras.luau`. Review clones are removed after inspection; installed templates are untouched.
