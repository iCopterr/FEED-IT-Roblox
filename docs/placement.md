# Pet placement and pickup

Select an owned pet in MY PETS, then choose PLACE PET or PICK UP. Placement
chooses the first free slot on the caller's plot, up to five pets. Pickup returns
the same pet to inventory; it is not physical carrying. Locked pets support both
actions. There is no hatch flow or automatic pet grant yet.

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
placement with the whole player profile; no schema version change is needed.

## Verification

The opt-in PlacementVerification.server.luau requires Studio memory mode and
two disposable players. Run StudioTestService:ExecuteMultiplayerTestAsync(2,
"PlacementVerification") from an Edit-side task and collect its EndTest result.
It covers ownership, malformed IDs, capacity, identity, locks, repeat actions,
visual repair, template failures, memory saving/migration, Remote handler
validation/throttling, departure cleanup and plot reuse.

Published DataStore rejoin/cross-server tests and actual button input on
touch/gamepad remain separate checks. No production data is modified by tests.
