# Pet placement and pickup

Select an owned pet in MY PETS, then choose EQUIP PET. The pet appears attached
to the character's right hand. Walk into your Pen and hold E for one second to
place it in the first free slot, up to five pets. Select a placed pet and use
PICK UP while within ten studs to hold it again. UNEQUIP returns it to inventory.
Locked pets support these actions. The developer's empty Studio memory profile
receives one test pet; there is no production starter reward or hatch flow yet.

CarryService keeps transient carry state separate from persisted placement.
It prepares the hand model before removing a placed pet, checks server distance,
ownership, life/character state and elapsed hold time, and uses PlacementService
for the final transaction. Walking away cancels a hold. Full Pens keep the pet
held; death/respawn/leave clear only the held visual. No schema change is needed.
The UI's old direct PlacePet/PickupPet requests are no longer accepted.
CarryController hides other players' Pen prompts; this is presentation only.
The server independently validates even forged prompt events.

CarryVerification runs with StudioTestService:ExecuteMultiplayerTestAsync(2,
"CarryVerification") using memory data. It exercises server carry/hold logic;
actual keyboard/touch/gamepad input and hand pose still need visual playtesting.

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
