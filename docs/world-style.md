# World Floor Style

All current walkable world floors use the same authored lime grid/stud language:

- lime base: RGB `124, 255, 31`;
- Plastic material with the classic Studs top surface;
- a top-facing `FloorGrid` Texture using
  `rbxasset://textures/grid16.png`;
- 32-by-32-stud texture tiling at 55% transparency.

Coverage is 21 authored parts: the SkyIsland Meadow and Promenade, six plot
Grounds, six Pen Floors, six EntrancePaths, and the Money merchant Base. The
conveyor, foundations, trims, roofs and other machinery are intentionally not
treated as floors. Walls are reserved for a future style pass.

Every Texture is stored directly under its floor in the RBXMX world asset; no
runtime script constructs the look. Plot Ground and Pen Floor textures remain
children of the resized parts, so their 32-stud tiling continues automatically
through capacity-expansion milestones.

Verification: `PlotVerification` checks the authored style on all current floor
categories, while `PlotUpgradeVerification` confirms Ground/Pen tiling survives
every capacity expansion from five through ten slots.

Global light, shadow and post-processing settings are documented separately in
`docs/lighting.md`.

## Environment depth

`Workspace.WorldDecor` is a separate Rojo-authored world asset. It adds the
non-gameplay terrain silhouette without changing plot, conveyor or placement
geometry:

- three descending island-core layers and four darker cliff faces;
- three underside rock masses and six distant floating rocks;
- six perimeter tree clusters kept outside the player plots;
- two merchant-side garden beds and four shrubs.

The cliff and floating-rock shapes are decorative, while the outer tree trunks
and garden beds are the only new collidable dressing. All foliage remains
non-colliding. The decor uses authored Parts rather than a runtime map generator,
so Rojo reconnects reproduce the same scene.
