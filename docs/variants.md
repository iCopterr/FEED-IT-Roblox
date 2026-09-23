# Hatch variants

Every newly purchased conveyor egg reserves one server-rolled variant,
independent of the species/rarity result. Existing eggs and pets are not rerolled.
The result stays hidden until hatch. Debug-spawned pets remain Normal.

| Variant | Chance | Income multiplier |
|---|---:|---:|
| Normal | 99.889% | 1x |
| Shiny | 0.1% (1/1,000) | 2x |
| Rainbow | 0.01% (1/10,000) | 5x |
| Celestial | 0.001% (1/100,000) | 10x |

Values live in src/shared/Config/VariantConfig.luau. One integer ticket is
drawn from 100,000 tickets; variants are mutually exclusive. No pity or luck
boost is applied. These odds are intentionally extremely rare for initial testing.

PetIncome is shared by authoritative payouts and displayed income. BaseIncome
is unchanged; the variant multiplier applies alongside the Feed multiplier.
Food cost, explosion risk and critical odds are unchanged. Existing schema
already stores Variant and preserves it in pending recovery and egg records.

Names in inventory/hotbar, Feed, Rescue and hatch results identify the variant.
This first pass reuses the existing models; special skins/VFX are not included.
