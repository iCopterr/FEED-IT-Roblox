# Prototype plots and capacity upgrades

Six authored plots remain arranged three per side of the central egg conveyor.
Each ground is 80x80 studs (previously 60x60); each fenced pen is 60x44
(previously 45x33). Centers: X=-66/+66 and Z=-96/0/96.
Open wood rails, capped posts, stone foundations, entrance paths and shrubs
are editable Workspace instances, not generated at runtime.

SkyIsland.rbxmx provides a 236x320-stud grass platform with two smaller rock
layers beneath it and a central promenade. The old 2048x2048 Baseplate is
removed from Workspace (retained in Studio ServerStorage for recovery).
The island floats over the empty sky/void.

Each player starts with FIVE active pet slots. The matching world sign buys
one additional slot per purchase, up to TEN for this prototype. Prices by
target capacity: 6=20K, 7=100K, 8=500K, 9=2.5M, 10=10M Money.
Tune src/shared/Config/PlotUpgradeConfig.luau; these are initial test prices.
Upgrades increase capacity, not the physical size of the already-expanded pen.
Food still comes from the merchant. No AFK farm or feed-plate risk bonus returns.

PlotUpgradeService validates ownership, distance, living character, expected
capacity, affordability, cooldown and transaction locks. Money/capacity commit
together without yielding; the save lock remains until confirmed. A stale
capacity token cannot purchase the next tier accidentally. MaxPetSlots already
exists in versioned player data, so no new schema field is needed.

Ten invisible slot markers provide fallback positions only; click-to-place
anywhere inside the pen remains supported. PlotService caps usable slots by
the player's purchased capacity. Signs and inventory display that capacity.
Leaving releases the world plot; upgrade progress belongs to player data,
not to the plot. MemoryOnly remains enabled: progress lasts only this server.

Static assets: PlayerPlots.rbxmx, PlotUpgradeSigns.rbxmx, SkyIsland.rbxmx.
Export Studio edits back to these files before resync; Rojo is not reverse sync.
The SurfaceGui sign is authored; its controller clones it into PlayerGui for
clickable world buttons. No runtime UI layout/geometry builders.

Set the place's Maximum Players to 6 in Creator Dashboard. The script's
six-plot ownership limit is not the platform matchmaking setting.

## Verification

Opt-in Studio multiplayer tests:

- PlotUpgradeVerification: prices, ownership, distance, malformed requests,
  save/Feed locks, stale/repeated purchases, 5→10 placement capacity, maximum,
  save/reload and unchanged other-player/Food state.
- PlotVerification: ownership, spawn/respawn, departing player and plot reuse.
- FoodShopVerification: food shop, Feed, Rescue and UI regression.

Launch using StudioTestService:ExecuteMultiplayerTestAsync(2, testName) from
the edit context in task.spawn. These tests require memory-only data.
