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
