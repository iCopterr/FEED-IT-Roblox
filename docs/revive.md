# Pet Repair Station

Failed Feed leaves the pet in inventory with `Broken=true` and a stable
`BreakId`. It keeps its level and can be held, placed in the pen and picked up.
As of the owner's 2026-10-06 update, explosion immediately clears the feeding
plate and returns the same pet to inventory/hotbar. Broken pets cannot be put
on the feeding plate or fed (including forged requests) until repaired.
The animation never restores a broken model to the plate. Failed Food is spent.

`PetIncome` applies `ReviveConfig.BrokenIncomeMultiplier` (0.1, 90% less) to the normal
rate at the pet's current level. Only pets placed in a pen earn Money;
stored, carried and feeding-plate pets do not bypass pen capacity. Eligible
x2 Money applies afterwards. No expiry, offline income or automatic reset.
Pet labels, inventory, hotbar, pen remote and repair previews show damage.
Shared BrokenPetVisual applies reversible soot colors and an orange rim;
world pets also emit light smoke. Premium variant auras resume after repair.

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
the target but allow normal pen placement between transactions.
Receipt fulfillment repairs the latest pet state, never an old growth snapshot.
Damage and charm consumption save together; receipt IDs prevent double grants.

Repair startup binds the existing `PrototypeRevive` RemoteFunction instead of
creating a competing duplicate. An old authored Studio remote was causing
intermittent hangs/empty lists when clients selected its unhandled copy. Startup
is idempotent and binds all pre-existing same-name RemoteFunctions for compatibility.
The controller invalidates stale empty lists on the owner's explosion and retries
throttled opening snapshots promptly.

`docs/studio/test-broken-pet-recovery.luau` exercises v12 migration, conflicts,
actual Feed/replay, permanent damage, blocked feeding, retained legacy progress,
placed income/x2, save/reload, shard exchange, charm repair and stale/new damage
IDs. In Studio it also checks the actual controller's list, preview and tabs.
The local PowerShell runner runs the economic checks without Studio rendering.
Commerce tests cover all products plus repair after upgrades and legacy receipts.
Live ReviveVerification now forces an actual Feed explosion, verifies immediate
plate cleanup, inventory/hotbar return and repair previews, and checks both
forged Feed and plate placement rejection before repair. Broken appearance
restoration/rig preservation has its own detached visual invariant suite.
