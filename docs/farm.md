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
Upgrade purchasing/UI is not implemented in this change.

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
