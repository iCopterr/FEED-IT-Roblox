# Pet model optimization — editor trials

Optimize one pet at a time, starting with the heaviest template. Never replace
the installed template until appearance, rig, saved/reloaded mesh assets and
carry/place/feed behavior have passed verification. No runtime mesh generation.

## Bone Dragon (first trial, not installed)

### Upload follow-up (port 58742)

All 10 authorized uploads succeeded; the old API-beta restriction is resolved.
However, loading every uploaded ID returns an identical 768-face, 1x1x1
checkerboard cube. Expected section face counts range from 122 to 2,884.
The saved URI references survive reload, but that does **not** establish that
the correct geometry survived. Visual verification failed. Original template
remains installed and unchanged. Asset metadata confirms the expected names
and owner for the sampled torso/skull, not approval or geometry correctness.

Run `docs/studio/audit-bone-dragon-meshes.luau` in edit mode for a read-only
recheck; it records the existing IDs so no duplicate uploads are needed.
Check asset moderation/processing status in Creator Dashboard. The cause is
not confirmed; do not assume it is merely an upload delay or install cubes.

| Metric | Original | Thin-wedge mesh trial |
| --- | ---: | ---: |
| BaseParts | 4,979 | 35 |
| WeldConstraints | 4,968 | 24 |
| Motor6Ds | 10 | 10 |
| Mesh sections | 0 | 10 |
| Wedge surface triangles | ~39,632 including prism thickness | 4,954 double-sided |

The trial keeps 25 original Parts, including invisible rig anchors and visible
box details. Triangle figures exclude those Parts and are not an FPS benchmark.
Double-sided rendering and remaining effects still have rendering costs.

`docs/studio/mesh-pet-candidate.luau` is an editor-only conversion recipe. Select
a disposable clone under Workspace, set `OptimizationCandidate=true`, and run
the recipe through Studio MCP. It accepts only thin opaque WedgeParts welded
to uniquely named rig anchors, groups by anchor/material, retains face colors,
and centers mesh vertices before creating each MeshPart. Do not run on an
installed template. Failed trials can be discarded and recreated from original.

Visual review: front and oblique comparisons preserve the skeletal silhouette,
wing membranes and colors. Primitive Studs surface detail is removed by this
conversion, giving smooth faceted surfaces. Rig offsets/references, disabled
collision/touch/query flags, and 2x scaling passed edit-mode checks. Runtime
carry/place/feed checks and saved-asset visual review remain pending.

### Persistence blocker

EditableMesh-backed MeshParts do not retain their editable geometry when these
trial models are serialized/deserialized through SerializationService. The
mesh content reloaded as None in the test. A local RBXM of this trial is **not**
a durable optimized asset. Upload real meshes, then use asset-backed MeshParts,
verify reload, and add a durable asset mapping that preserves other templates.
Owner approved mesh uploads. The first attempt was rejected before any upload:
`CreateAssetAsync and CreateAssetVersionAsync are not available yet`. Enable
Studio **File > Beta Features > CreateAssetAsync Luau API**, restart and reconnect
MCP, then regenerate the trial and retry uploads. Roblox's official
[API announcement](https://devforum.roblox.com/t/beta-lua-asset-creation-for-creator-tooling-with-createassetasync/3294134)
documents this beta requirement and the local-plugin context restriction.
No game publication or installed-template replacement has been performed.

### Rejected experiment

CSG union batching produced 76 parts but increased the measured triangle count
to 64,134 and serialized model size to ~2.34 MB versus ~354 KB original. It was
not installed. Part-count reduction alone is not evidence of an improvement.

## Queue (measured live templates, descending parts)

Bone Dragon 4,979; Hydra 4,105; Astral Kitsune 3,665; Kitsune 3,395;
Basilisk 3,333; Chimera 3,331; Cerberus 3,107; Minotaur 3,105;
Seraph Beast 2,884; Kraken 2,724; World Serpent 2,673; Behemoth 2,420;
Celestial Dragon 2,265; Ember Drake 2,116; Manticore 2,108; Ice Dragon 1,870;
Eclipse Griffin 1,770; Frost Wolf 1,729; Ancient Wyvern 1,683;
Storm Griffin 1,678; Lava Golem 1,508; Phoenix 1,252; Thunder Serpent 1,018;
Void Leviathan 740; Black Wolf 71; Baby Griffin 67; Boar 54;
Horned Bunny 46; Fox 44; Chicken 35.

Total 59,775 BaseParts across 30 templates. These are template counts, not
simultaneously visible live pets. Profile representative mobile gameplay after
durable replacement before claiming a frame-rate improvement.
