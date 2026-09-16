# Prototype pet income

Placed pets automatically pay into their owner's Money balance every second.
The per-second formula is BaseIncome x FeedMultiplier (GDD sections 14 and 43.6).
Common level 0 earns 10/s; Rare earns 500/s; Mythic earns 45,000/s.
Locked placed pets earn normally. Stored and carried pets earn zero.

MoneyService reads authoritative Inventory and PlacedPetIds from a loaded,
validated profile with an owned plot. Each fixed tick adds one second of income;
no remote accepts an amount, duration, or client-calculated rate. Picking up a
pet stops its contribution on the next tick. There is no offline/catch-up income
or partial-second accrual. Server stalls do not replay missed ticks.

FeedConfig centralizes the GDD's multiplier curve for levels 0-40. Above-40
levels are unbalanced and contribute zero until explicitly configured. Variant,
Trait and global bonus multipliers are outside this prototype income scope.
This does not implement feeding or any new pet levels itself.

The existing Money field and DataService autosave/leave/shutdown flow persist
earned income; no schema changes are needed. HUD snapshots include the current
IncomePerSecond and show it next to the balance. PetIncome pushes each authoritative
payout balance every second; the HUD buffers the latest value and redraws
once per second. Polling remains a fallback.
Server timestamps prevent an older snapshot overwriting a newer pushed balance.

Each payout includes a batch of PetId/Amount entries sent only to the owner.
IncomeEffectsController clones the editable ReplicatedStorage.PetIncomePopup
BillboardGui template above each earning pet once per second with that payout's
amount, then floats/fades it over 0.65s. HUD updates
also display once per second; a continuously placed Common shows +10 per popup, not +2.5.
The template is authored in Studio and stored in src/ui/PetIncomePopup.rbxmx.
Fractional amounts are retained when needed; earning rates are
unchanged. Popups are presentation only and never award money. Missing/unloaded
visuals skip the popup without affecting the already-authorized payout.

MoneyVerification is an opt-in Studio memory-mode two-player test, invoked via
StudioTestService:ExecuteMultiplayerTestAsync(2, "MoneyVerification"). It verifies
stored/held/placed/locked states, exact ticks, summed and Feed-scaled rates,
ownership, the automatic loop, pickup stopping income, and memory saving.
Published DataStore verification remains separate.
