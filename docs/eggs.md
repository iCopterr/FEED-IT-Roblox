# Prototype eggs and incubation

Eggs replace the alpha direct-pet conveyor offers. Hold E near an offer to buy;
purchase starts incubation immediately. Open MY EGGS for odds/countdown, then
press HATCH when ready. The pet goes to MY PETS, not automatically to the Pen.

Balance is in src/shared/Config/EggConfig.luau:

- One prototype_egg, 5K Money, 10-second incubation.
- Results: Common 40%, Uncommon 25%, Rare 18%, Epic 10%, Legendary 5%, Mythic 2%.
- One incubation slot, independent of the five active pet slots.
- These are test-friendly prototype values, not production hatch odds.
- Price, HatchSeconds and weighted SpeciesId result pool are per egg.
- ConveyorConfig controls which egg types appear, their spawn weights and motion.
  PetConfig remains the species/rarity/base-income source.

Schema v5 adds IncubatingEggs[EggUid] with EggId, StartedAt, ReadyAt, PricePaid,
and a full reserved Pet record. v4 migrates to an empty egg map without touching
existing money, pets, recovery, farm or plate levels. Pet schema remains v2.

The server rolls/reserves the result at purchase, charges and saves atomically.
Snapshots do not reveal that result. ReadyAt is an absolute server timestamp:
incubation continues while disconnected; no offline Money or Food is awarded.
Hatch cannot bypass the timer and moves the same reserved PetId into Inventory,
consuming its egg and updating PetIndex without yielding. No reroll at claim.
Saved timers/results remain valid if config is changed after purchase.

Purchase/hatch use shared Feed locks through confirmed saving, retry ambiguous
failures without refunding/rerolling, and reject stale/foreign/malformed requests.
Replay of the latest purchase/hatch returns the original response; consumed
eggs cannot create another pet after reconnect. No purchase remote accepts
client price, result, time or species. The conveyor validates range/alive/plot/
offer expiry before calling the server-only purchase method.

Actual authored assets: Workspace.EggTemplates and StarterGui.EggUI, exported
to .rbxmx for Rojo. Runtime clones only those templates and the existing label.
No runtime world/UI geometry generator, new pet species or paid hatch skips.
The existing PetConveyor and ConveyorPetLabel names remain for asset stability.

Verification: ConveyorVerification.server.luau now supports EggVerification
and ConveyorVerification test arguments with two Studio clients in memory mode.
43 integration checks pass. Nine isolated actual-controller checks and seven
actual-service save-failure/retry checks pass. Regressions: 72 Feed and 22 legacy
Revive checks pass with schema v5 (153 total checks this session).
Live DataStore rejoin/outages and
physical desktop/touch/gamepad presentation need a separate playtest.

Fresh production profiles still start at 0 Money without a starter pet; this
pre-existing onboarding gap is not changed here. Use Studio debug grants for
prototype testing. No farm/feed price or income balancing was changed.
