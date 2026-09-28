# Divine / Cosmic pet expansion

Six new pets for the revised Supreme and Ultimate pools. Existing 30 templates were retained.

| Pet | Final BaseParts | Union triangles |
|---|---:|---:|
| Divine Phoenix | 17 | 17,730 |
| Heavenly Kirin | 19 | 24,082 |
| Godly Behemoth | 24 | 31,406 |
| Galaxy Dragon | 32 | 40,032 |
| Cosmic Hydra | 48 | 74,064 |
| World Eater | 15 | 16,884 |

155 BaseParts total, including invisible anchors. Initial budget: <=100 per pet. Native CSG preserves the established faceted construction and per-anchor rig. Triangles remain substantial; no FPS claim.

## Saved assets

- `optimized/*.rbxm`: final installed templates; import under `ReplicatedStorage.PetsModel` using the exact spaced filename/model name.
- `originals/*.rbxm`: pre-consolidation source geometry. Keep outside replicated storage/gameplay.
- `report.json`: original/final counts, union triangle counts, joints, serialized size, bounds delta.
- `sha256.json`: exact saved RBXM hashes.
- `prior-template-attributes.json`: pre-reclassification attributes for existing templates (and initial attributes for the six new templates).
- `review/*.png`: front/rear Studio reviews after refinement.
- `verification.json`: passing edit-mode roster/migration checks and explicit test limitations.

`boundsDelta` compares primitive bounding boxes, whose unused wedge corners inflate bounds; optimizer separately asserts actual wedge-vertex bounds against consolidated geometry, native serialization/deserialize fidelity, rig connectivity/alignment and 2x scaling.

## Reproduction and recovery

1. Run `docs/studio/build-divine-cosmic-expansion.luau`, replacing `__PET_NAME__` for one of the six names. It archives source models in `ServerStorage.DivineCosmicSources_20260927` and guards against duplicate execution.
2. Run the existing `docs/studio/consolidate-pet-template.luau` with the pet name and replace its source folder `PetModelBackups_20260927` with `DivineCosmicSources_20260927`.
3. Run `docs/studio/review-expansion-pet.luau` with name and angle; inspect front/rear before installation. The installation script records visual approval, so run it only after reviewing all six.
4. Run `docs/studio/install-divine-cosmic-expansion.luau` to install reviewed new candidates and update template metadata from PetConfig. It does not replace an existing same-named template.
5. Optional display: `docs/studio/show-divine-cosmic-expansion.luau` creates `Workspace.DivineCosmicShowcase`.

The old 24 original models remain in `ServerStorage.PetModelBackups_20260927` and `assets/pets/consolidated-20260927/originals`. No old model was deleted. This directory’s six native RBXM templates are the durable new art deliverables; they are not currently mapped through Rojo, matching the existing pet-template workflow. Rojo manages configs, scripts, IndexUI and EggTemplates.

## Verification

All six received individual front/rear visual inspection. Phoenix, Kirin and Galaxy Dragon were refined and rechecked. Rig connectivity/alignment, native serialize/deserialize, bounds and 2x scaling passed. The models retained their exact counts after Studio restart.

Studio's stalled test state was resolved by the owner restarting Studio on 2026-09-28. All requested regression runs then passed:

- RosterVerification: 184 checks, including all pools, installed templates and v10-to-v11 migration.
- ConveyorVerification: 177 checks with two players, including Ultimate purchase, placement, incubation, hatch/carry, save/load, concurrent purchases and replay protection.
- IndexVerification: 18 server checks with both client reports passing; each client renders all 36 pets across six pools, checks discovered/locked states and interactions.
- VFXVerification: 24 checks, including Fabled/Divine/Celestial aura support and bounded effects.
- Final Ultimate Index screenshot inspected: six tabs fit, names/rarities/incomes readable.
- Rojo build and staged diff checks passed.

Play tests use isolated memory; no production DataStore or published-server test was performed. Low instance counts do not establish a runtime FPS improvement. The initial failed-launch limitation in the previous handoff is resolved.
