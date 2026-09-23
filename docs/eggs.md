# Prototype eggs and incubation

Eggs replace the alpha direct-pet conveyor offers. Hold E near an offer to buy;
purchase holds the egg if hands are free, otherwise stores it in Inventory.
Players may own and buy any number of eggs without hatching earlier purchases.
Equip an egg from Inventory, then click/tap inside your own fenced Pen.
Placement starts incubation. Once ready, stand beside the egg and press E
(single press, not hold; gamepad X / touch prompt also supported).
The right-side Growing Eggs panel lists placed eggs and allows remote claiming;
manual E hatching remains available.
Hatching validates ownership, a living character, readiness and 10-stud range.
The pet returns to inventory and is held after saving if hands are free; it
never automatically enters the Pen. PUT AWAY EGG stores an unplaced held egg.
Placed eggs remain incubating until claimed (egg repositioning is not included).

Balance is in src/shared/Config/EggConfig.luau:

- Five configured egg tiers with six individually weighted pets per tier.
- There is no ownership/incubation-slot cap; active pet slots remain separate.
- These are test-friendly prototype values, not production hatch odds.
- Price, HatchSeconds and weighted SpeciesId result pool are per egg.
- ConveyorConfig controls which egg types appear, their spawn weights and motion.
  PetConfig remains the species/rarity/base-income source.

Schema v6 stores IncubatingEggs[EggUid] with EggId, StartedAt, ReadyAt, PricePaid,
HatchSeconds, optional plot-local PenPosition, and a full private reserved Pet.
New eggs use zero timestamps until placed. v5 migration preserves existing
paid timers/results; those eggs must be placed, but their countdown never resets.
v4 still migrates through an empty egg map without resetting progress.
Pet schema remains v2. Saved local positions restore into the owner's next plot.

The server rolls/reserves the result at purchase, charges and saves atomically.
Snapshots do not reveal that result. ReadyAt is an absolute server timestamp:
incubation continues while disconnected; no offline Money or Food is awarded.
Hatch cannot bypass the timer and moves the same reserved PetId into Inventory,
consuming its egg and updating PetIndex without yielding. No reroll at claim.
Saved timers/results remain valid if config is changed after purchase.

Purchase/placement/hatch use shared Feed locks through confirmed saving, retry ambiguous
failures without refunding/rerolling, and reject stale/foreign/malformed requests.
Replay of the latest purchase/hatch returns the original response; consumed
eggs cannot create another pet after reconnect. No purchase remote accepts
client price, result, time or species. The conveyor validates range/alive/plot/
offer expiry before calling the server-only purchase method.

Actual authored assets: Workspace.EggTemplates, StarterGui.FeedYourPetUI and
StarterGui.PenManagerUI, exported to .rbxmx for Rojo. The old MY EGGS ScreenGui
was removed. Runtime clones only egg/pet item rows, not complete interfaces.
No runtime world/UI geometry generator, new pet species or paid hatch skips.
The existing PetConveyor and ConveyorPetLabel names remain for asset stability.

Verification: ConveyorVerification.server.luau now supports EggVerification
and ConveyorVerification test arguments with two Studio clients in memory mode.
The expanded carry/place suite passes all 64 checks through two-client Studio
memory testing on MCP port 58743 (2026-09-20). All 76 synced sources compile;
Rojo build and diff checks pass. Includes ready E prompt configuration and
server hatch/range checks; physical E/touch input still needs review.
Previous v5 implementation: 43 integration checks passed. Nine isolated actual-controller checks and seven
actual-service save-failure/retry checks pass. Regressions: 72 Feed and 22 legacy
Revive checks passed with schema v5 (153 checks; not a verification of v6).
Live DataStore rejoin/outages and
physical desktop/touch/gamepad presentation need a separate playtest.

Fresh production profiles still start at 0 Money without a starter pet; this
pre-existing onboarding gap is not changed here. Use Studio debug grants for
prototype testing. No farm/feed price or income balancing was changed.
