# Lighting Style

The active map lighting is authored in `src/lighting/Lighting.rbxmx` and mapped
directly to the `Lighting` service by Rojo.

The current look keeps the colorful simulator palette while adding depth:

- Realistic lighting style with global shadows;
- 3:12 PM sun angle for readable directional shadows;
- 0.35 shadow softness for clean but non-harsh edges;
- darker ambient light and balanced outdoor fill for contact shadows;
- restrained Bloom and SunRays instead of a washed-out glow;
- mild warm ColorCorrection;
- light Atmosphere haze that preserves the cloud sky;
- DepthOfField disabled so gameplay and UI stay sharp.

Legacy post-processing objects previously parented under Workspace were removed.
Post effects belong under Lighting (or a camera); the Rojo asset is now the only
source of truth for the global look.

When tuning, keep the lime floor readable and check fences, signs, pets, the
merchant and conveyor from both normal player height and an island overview.
Avoid heavy blur, strong bloom or dense Atmosphere because they reduce gameplay
clarity and flatten the checker/stud surface.
