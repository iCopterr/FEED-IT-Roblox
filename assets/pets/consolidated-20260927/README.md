# Consolidated Advanced, Elite, Master and Supreme pets

The 24 existing pet designs were consolidated into native Roblox UnionOperations
per rigid rig section. These are the old silhouettes and palettes, not redesigns.
The six Basic pets are outside this batch.

## Contents and locations

- `originals/`: serialized copies of all 24 original models, before any changes.
- `optimized/`: serialized consolidated models, retaining their template names.
- `verification.json`: counts and save/restore verification results.
- `manifest.json`: SHA-256 hashes and byte sizes of the RBXM files.
- Active Studio templates: `ReplicatedStorage.PetsModel`.
- Original Studio instances: `ServerStorage.PetModelBackups_20260927` after installation.
- `Workspace.PetOptimizationPreview`: one World Serpent review copy.

To restore an original, move its installed optimized template aside, then move
the same-named model from the backup folder into `ReplicatedStorage.PetsModel`.
Do not keep two same-named templates in that folder.

## Verification and constraints

Initial budget: at most 100 BaseParts per pet, including invisible rig anchors.
Final batch: **59,458 → 691 BaseParts (98.8% fewer), 14–50 per pet**.

Checked every candidate against its original: template attributes, primary part,
motor count and endpoints, joint offsets, connected rig graph, actual wedge
geometry extents, pivot, and unchanged retained-part physics. Each model was
serialized and deserialized; part counts, union triangle counts, bounds and
2× growth scaling were checked again. Every design was inspected alongside its
original from front and rear three-quarter views in Studio.

The anchored display-template convention is retained. Gameplay source,
animations, species IDs, and the Basic templates were not changed.

This is **instance consolidation, not a proven rendering-speed improvement**.
Native CSG has 976,120 union triangles across the batch (excluding remaining
primitives), and the optimized files are larger than the originals. No FPS,
full Studio close/reopen, or gameplay Play-test claim is made.

CSG shows the legacy stud finish more prominently at a distance than the tiny
source wedges. It also changes texture projection on Ice Dragon's consolidated
wing panels. Shapes, palettes and rigging are retained, but the surface rendering
is not pixel-identical. Originals remain available for comparison and rollback.

## Tooling

- `docs/studio/consolidate-pet-template.luau`: one-template builder; edit mode only.
- `docs/studio/verify-consolidated-pets.luau`: complete-batch verification.
- `docs/studio/install-consolidated-pets.luau`: guarded swap with original-instance backup.
- `docs/studio/export-consolidated-pets.ps1`: native RBXM serialization over local MCP.

No uploaded or session-only EditableMesh geometry is required.

## Part counts

| Pet | Original | Consolidated | Union triangles |
|---|---:|---:|---:|
| Ancient Wyvern | 1683 | 23 | 28362 |
| Astral Kitsune | 3665 | 45 | 59250 |
| Basilisk | 3333 | 25 | 55926 |
| Behemoth | 2420 | 25 | 37250 |
| Bone Dragon | 4979 | 43 | 65536 |
| Celestial Dragon | 2265 | 28 | 39344 |
| Cerberus | 3107 | 32 | 49812 |
| Chimera | 3331 | 36 | 53220 |
| Eclipse Griffin | 1770 | 24 | 29830 |
| Ember Drake | 2116 | 27 | 33958 |
| Frost Wolf | 1729 | 26 | 29150 |
| Hydra | 4105 | 48 | 68052 |
| Ice Dragon | 1870 | 35 | 27402 |
| Kitsune | 3395 | 50 | 55768 |
| Kraken | 2724 | 29 | 58344 |
| Lava Golem | 1508 | 18 | 24194 |
| Manticore | 2108 | 27 | 35006 |
| Minotaur | 3105 | 26 | 47088 |
| Phoenix | 1252 | 17 | 21524 |
| Seraph Beast | 2884 | 34 | 53578 |
| Storm Griffin | 1678 | 22 | 27806 |
| Thunder Serpent | 1018 | 14 | 16374 |
| Void Leviathan | 740 | 17 | 14220 |
| World Serpent | 2673 | 20 | 45126 |
