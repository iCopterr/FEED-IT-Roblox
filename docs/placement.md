# Pet placement and pickup

Select an owned pet in MY PETS, then choose EQUIP PET. The pet appears attached
to the character's right hand. Click/tap your Pen floor to place it at that
horizontal position, up to five pets. Hold E for one second near a placed pet
(within ten studs) to pick it into your hand. UNEQUIP stores it. Clicking a pet
or the inventory button cannot bypass the pickup hold. Touch/gamepad use the
same ProximityPrompt hold interaction.
Locked pets support these actions. The developer's empty Studio memory profile
receives one test pet; there is no production starter reward or hatch flow yet.

CarryService keeps transient carry state separate from persisted placement.
It prepares the hand model before removing a placed pet, checks server distance,
ownership, life/character state and requested floor coordinates, and uses
PlacementService for the final transaction. Full Pens keep the pet held;
death/respawn/leave clear only the held visual.
The UI's old direct PlacePet/PickupPet requests are no longer accepted.
The hold-E prompt is removed. CarryController raycasts clicks/taps, ignores UI
input and the character, and only requests placement on the owned Pen floor.
Server checks reject foreign/outside/air/nonfinite coordinates and requests over
50 studs away. A 1.75-stud inset keeps the current 3-stud placeholder pets inside
the fence. Rejected positions are never silently snapped to a different spot.
Mouse and touch are supported; gamepad cursor placement is not implemented.
Input uses ViewportPointToRay to avoid GUI-inset offsets (see the
[Roblox camera reference](https://create.roblox.com/docs/reference/engine/classes/Camera#ViewportPointToRay)).

CarryVerification runs with StudioTestService:ExecuteMultiplayerTestAsync(2,
"CarryVerification") using memory data. It now exercises click positioning,
pickup, boundary checks, v1 migration, memory saving and coordinate isolation.
This updated suite has not run while Studio MCP is disconnected.

PlacementService owns placement mutations. Inventory records, PlacedPetIds,
Placed and PlotSlot change together without yielding, with schema validation
and rollback. A valid visual is prepared before placement is committed. Repeated
requests are idempotent. UIService validates caller state and throttles requests;
clients cannot supply a plot, slot, pet definition, or economy value.

Workspace.PetTemplates contains six editable, static placeholder models,
authored through Studio MCP and exported to src/world/PetTemplates.rbxmx.
Re-export editor changes before Rojo sync: sync is not reverse export.
Placement clones these authored templates into the owner's Pen.ActivePets;
no runtime geometry constructor is used. They are anchored placeholders, not
wandering pets. Template gallery is outside the plot area at Z=-110.

Reconciliation rebuilds visuals from loaded placement data and repairs missing
models. Departure destroys presentation only. The existing DataService saves
placement with the whole player profile. Player/pet schema v2 adds optional
PenPosition {X,Z} in Pen-floor local space, cloned in snapshots and migration.
V1 records migrate without changing PetIds. Missing PenPosition uses the old
slot location for backwards compatibility; slots now count capacity rather than
restrict player placement. Slot markers remain invisible/non-queryable in the
static asset. Existing DataStore names/record wrapper are intentionally unchanged.

## Verification

The opt-in PlacementVerification.server.luau requires Studio memory mode and
two disposable players. Run StudioTestService:ExecuteMultiplayerTestAsync(2,
"PlacementVerification") from an Edit-side task and collect its EndTest result.
It covers ownership, malformed IDs, capacity, identity, locks, repeat actions,
visual repair, template failures, memory saving/migration, Remote handler
validation/throttling, departure cleanup and plot reuse.

Published DataStore rejoin/cross-server tests and actual button input on
touch/gamepad remain separate checks. No production data is modified by tests.
