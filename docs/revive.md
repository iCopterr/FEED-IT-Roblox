# Pet Repair Station

Failed Feed leaves the pet in inventory with `Broken=true` and a stable
`BreakId`. It keeps its level and can be held, placed, picked up and fed again.
Successful Feed increases its level normally. Repeated failures retain the
damage ID and never stack penalties or reset progress.

`PetIncome` applies `ReviveConfig.BrokenIncomeMultiplier` (0.5) to the normal
rate at the pet's current level. Only pets placed in a pen earn Money;
stored, carried and feeding-plate pets do not bypass pen capacity. Eligible
x2 Money applies afterwards. No expiry, offline income or automatic reset.
Pet labels, inventory, pen remote and Feed UI show the broken state.

At the Pet Repair Station, one Repair Charm clears Broken/BreakId in place.
100 Repair Shards exchange for one Repair Charm. Robux food purchases still
award the same guaranteed shards by rarity. The existing 149-Robux direct
product repairs the selected pet; the 79-Robux charm and Welcome Pack retain
their IDs and quantities. All repair/shard art reuses the existing assets.

Schema v13 migrates every v12 PendingRecovery pet into normal inventory with
its saved Feed level, identity, traits, lock and original attempt ID. Conflicting
inventory identities fail migration instead of overwriting. Charms, shards,
commerce reservations and receipts remain intact. PendingRecovery remains an
empty compatibility field. Internal Revive names/remote paths/product keys stay
stable for compatibility; player-facing language is Repair throughout.

Server handlers validate ownership, proximity, damage episode ID and the shared
transaction lock. Paid reservations block charm repair or permanent removal of
the target but allow normal placement and upgrading between transactions.
Receipt fulfillment repairs the latest pet state, never an old growth snapshot.
Damage and charm consumption save together; receipt IDs prevent double grants.

`docs/studio/test-broken-pet-recovery.luau` exercises v12 migration, conflicts,
actual Feed/replay, permanent damage, further upgrades, non-stacking failures,
placed income/x2, save/reload, shard exchange, charm repair and stale/new damage
IDs. In Studio it also checks the actual controller's list, preview and tabs.
The local PowerShell runner runs the economic checks without Studio rendering.
Commerce tests cover all products plus repair after upgrades and legacy receipts.
