# Bone Dragon — Blender remodel draft

Owner requested Higgsfield/Blender remodeling of high-part-count pets only.
This is the first pilot, NOT a replacement installed in Roblox.

- Project: https://higgsfield.ai/3d-jutsu/8eb244c9-3fbf-4bfc-86d4-dd5f2f29e4f7
- Committed Higgsfield revision: 1
- Blender 5.2 source: BoneDragon.blend
- Portable export: BoneDragon.glb
- Reproducible build: docs/blender/bone_dragon_remodel.py
- Geometry: 5,012 triangles, 2,744 vertices, one skinned mesh object.
- Ten rigid skin bones, five used materials; GLB exports five material primitives.
  One Blender object does not guarantee one Roblox MeshPart or draw call.
- Structural checks: finite vertex positions, every vertex has one rigid weight,
  rest-pose bones and unit scale. Major joint overlap assertions passed.
- Design: warm ivory skeleton, stronger skull/horns, turquoise eyes, open ribs,
  broad dark wing membranes. Geometry is Z-up, forward -Y, about 5.28m long.

## Verification still required

The Eevee render was generated but its signed URL could not be opened through
the image-inspection tools. The interactive viewer is for owner review, not
evidence of an agent visual pass. Do not claim appearance complete.

No Roblox import, size calibration, pet placement/holding/feed test or Studio
visual review has occurred. Original production template remains unchanged.
Current MCP tools do not expose the Studio local-file 3D Importer; computer use
remains prohibited by owner. Import the GLB manually as a separate review model
(never overwrite PetsModel), or export FBX from the Blend if the importer rejects
GLB. Report importer errors rather than retrying the failed EditableMesh upload.

Only continue mass remodeling after the pilot looks cohesive from multiple
angles and survives the standard Roblox import pipeline.
