# Active prototype farm

Each plot contains an editable Farm station in Workspace, stored in
PlayerPlots.rbxmx. No runtime geometry is generated. Walk within five studs of
your own WorkPoint to enter automatically. The server moves and anchors the
character at the work position. Only Jump exits (Space, touch jump or gamepad
jump); WASD/stick movement keeps farming. Exit restores anchoring/rotation and moves
the player to ExitPoint. Move outside the rearm radius before entering again.

Per the user's 2026-09-16 instruction, Food is produced **only while farming**,
overriding the GDD's passive-production direction. Level one produces
2 Food/sec. Rates use GDD 19.1's candidate curve times persisted FarmPower.
Farm upgrades are purchased with Money from an editable sign beside each farm.
The sign shows current level, current/next Food/sec, and the Buy Upgrade price.
The GDD 19.1 curve is centralized in FarmConfig.UpgradeCost, keyed by TARGET
level: level 2 costs 5K Money and raises base production from 2 to 6 Food/sec;
level 15 is the maximum. Prices/rates remain candidate balance for playtesting.

FarmUpgradeSigns.rbxmx is mapped to Workspace.FarmUpgradeSigns. Its six model
names match the six PlayerPlots names. Geometry is authored in Studio and never
generated at runtime. Re-export editor geometry/UI changes before Rojo resync.
The controller clones each authored SurfaceGui into PlayerGui, adorning its
board, because Roblox requires PlayerGui parenting for interactive SurfaceGui
buttons: https://create.roblox.com/docs/reference/engine/classes/SurfaceGuiBase/Adornee
Only the nearby owner can buy (14 studs); others can read but not purchase.

FarmUpgradeService validates live character, loaded data, plot ownership,
distance, affordability, cooldown and expected CURRENT level. The expected
level prevents stale/double clicks buying a second upgrade. Money and FarmLevel
change without yielding and persist together through existing DataService.
Further purchases are blocked until save confirmation; failures retry without
refund/rebuy. FarmPower and active-only production are preserved. An active
farmer can upgrade without leaving; the next tick uses the upgraded rate.
FarmUpgradeChanged immediately updates the Money HUD. Signs reset on departure.

FarmService owns sessions, proximity checks, life/plot validation and elapsed
server time. Clients can only request their own exit, never an amount or entry.
Duplicate calls cannot accelerate payouts. Death, respawn, leaving, lost data,
lost station and displacement cancel farming. No offline or catch-up rewards.
Held pets are unequipped without deleting inventory data; equipping while
farming is blocked. Existing Food persistence is reused without schema changes.

Food payouts push the HUD immediately, with FoodAt stale-snapshot protection.
FarmConfig.RunAnimationId is intentionally empty; add an owned animation ID
later. FarmController loops it during farming and stops it on exit.

FarmVerification is an opt-in two-player Studio memory test:
StudioTestService:ExecuteMultiplayerTestAsync(2, "FarmVerification").
Keyboard/touch input and the visual experience still require client playtesting.
The clean server test passed 27 checks. Eleven isolated input-handler checks
also passed; these simulate controller signals, not actual keyboard hardware.

FarmUpgradeVerification is a separate opt-in two-player memory test:
StudioTestService:ExecuteMultiplayerTestAsync(2, "FarmUpgradeVerification").
All 27 purchase/production/persistence/ownership/lifecycle checks passed.
Ten isolated sign-view checks and twelve geometry/input-property checks pass.
Actual mouse/touch/gamepad feel and live DataStore outage/rejoin remain unverified.
Large balances use the existing double-precision Money schema; individual units
are not exactly representable above 2^53. This feature does not redesign currency.
