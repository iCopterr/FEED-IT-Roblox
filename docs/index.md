# Pet Index

The blue stud-style INDEX book button sits at the left-middle of the screen,
opposite the egg and pen remote controls. It opens the authored
`StarterGui.IndexUI` ScreenGui. Categories show the six configured egg models
and their discovery counts. Each category displays its six configured pets.

Every pet card discloses its configured hatch percentage, name and rarity,
including before discovery. Selecting a discovered pet also shows normal level-0
income from PetConfig.BaseIncome; this value intentionally excludes feed growth
and variants. Undiscovered species keep the black model silhouette and hidden
income, while the selected detail discloses the pet chance and the independent
Normal, Shiny, Rainbow and Celestial percentages. Percentages are calculated
from EggConfig and VariantConfig at render time rather than copied UI constants.
Viewport tinting preserves the original templates.

Discovery uses the existing saved PetIndex species flags, set by server pet
creation and completed hatches. Buying or placing an egg does not discover its
reserved result. Removing, placing, or resetting a pet does not erase its
discovery. No schema migration is needed.

The read-only IndexSnapshot action on PrototypeUI.Request returns only the
caller's copied discovery map, with a separate request throttle. It accepts no
unlock commands and never returns reserved hatch results. The client refreshes
while the page is open. Other modal pages and travel close the Index; its modal
flag suppresses world placement, upgrade, and conveyor actions underneath it.

All UI layout is saved in src/ui/IndexUI.rbxmx. Runtime code binds authored
buttons and viewports, and clones only preview models/cameras. Preview models
are released when the page closes. Buttons do not capture WASD navigation.

## Preview performance

Only the current egg's six pet cards and selected detail are cloned, not all
thirty-six pets. Repeated discovery refreshes reuse unchanged previews. Closing
the page releases both models and cameras. The shared ItemPreview helper strips
joints, constraints, Humanoids and animation controllers from its anchored UI
copies, with collision/touch/query disabled. Original pet templates and their
rigs are untouched; all visible geometry and textures remain.

Measured in Studio: Bone Dragon has 4,979 BaseParts and 9,959 descendants;
its static preview retains all 4,979 BaseParts with only 4,979 descendants.
This reduces retained instance overhead, NOT polygon count or a measured FPS
cost. Hydra has 4,105 parts and several other pets have over 3,000. Rendering
six complex pets plus the detail is still expensive. Inventory and hotbar
also use these detailed previews and need the same longer-term asset solution.

Recommended next step: bake each pet/egg to an uploaded thumbnail image, use
authored ImageLabels for cards/categories/hotbar, and tint those images black
for locked silhouettes. Keep just the selected detail as a 3D viewport. For
world/held pets and the detail, convert the many-part originals to optimized
MeshParts while preserving rig animation boundaries. Keep original models as
editable backups. Do not mass-union or delete detail blindly. Profile on a
low-end client before choosing triangle/texture budgets. No thumbnail assets,
model conversion, world changes or claimed FPS improvement are part of this
Index implementation.

Reference: [Roblox performance guidance](https://create.roblox.com/docs/performance-optimization/improve).

Verification: defer ExecuteMultiplayerTestAsync(2, "IndexVerification") from an
idle Studio MCP command, following the launch pattern in merchant.md. The suite
uses memory profiles, checks server hatch/discovery isolation and save behavior,
and exercises the six categories, all thirty-six previews, odds, silhouettes, selection,
and modal close behavior on two clients.
