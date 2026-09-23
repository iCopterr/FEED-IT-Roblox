# Feed plate (prototype staging)

Each plot has one authored FeedPlate model, saved in PlayerPlots.rbxmx.
Equip a stored pet (or hold E to pick up a Pen pet), walk near your plate,
then click/tap its surface. Hold E for one second near the staged pet to
open Feed UI, then use Pick Up Pet to carry it again. Only one pet fits;
an occupied plate never replaces it.

CarryService validates the held identity, PedestalService validates the owned
plot, live character, distance, profile and visual template before transfer.
Placement UI requests share the existing cooldown. Plate pickup goes through
the Feed UI with server ownership, pet-ID, range and cooldown validation.
Inventory equip cannot bypass plate pickup. Other pets can still be equipped
without replacing the staged pet. Pen pickup still uses server-timed holds.

Staging is transient: the original inventory record remains stored (no income,
no Pen slot). Respawn/leaving clears the visual, not the pet. Save/rejoin safely
returns it to inventory, preserving its ID, lock and Feed Level. No schema change.

Feed RNG, selected food and timed Rescue are implemented. Consumable Protection
and plate upgrades are retired; see feed-config.md and revive.md.

Opt-in Studio memory test:
StudioTestService:ExecuteMultiplayerTestAsync(2, "PedestalVerification").
All 23 checks passed. The six static plate bounds/uniqueness checks and Rojo
build also passed. Actual mouse/touch interaction still needs visual playtesting.
