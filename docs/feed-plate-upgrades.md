# Feed plate upgrades

Each plot has a purple upgrade sign beside its feed plate. Nearby owners buy
with Money. Ten levels use the current farm upgrade prices (20K through 1000T),
copied into a separate FeedPlateConfig so future balancing is independent.

Level 1 has no reduction; every upgrade adds 5% relative reduction, reaching
45% at level 10. Effective risk = base explosion chance × (1 - reduction).
For example, 20% becomes 11%; 88% becomes 48.4%. This does not subtract
percentage points or guarantee safety. Miracle/Critical ordering and level 40
cap remain unchanged. Studio debug forced outcomes intentionally override RNG.

Player schema v4 saves FeedPlateLevel. v3 saves migrate to level 1, preserving
other progress and recovery records. No DataStore key/store change.
The server validates owner, distance, life, expected level, cooldown, funds,
and Feed/Revive lock. Money and level change without yielding, then save with
retries. Ambiguous save failures never refund/rebuy. Feed stays blocked until
the upgrade save confirms. Leaving/shutdown uses the existing DataService.

World signs are authored Instances in FeedPlateUpgradeSigns.rbxmx. The client
clones their SurfaceGui into PlayerGui for clickable buttons; it does not build
world geometry. Feed UI displays base risk, actual risk and plate reduction.

Verification: run StudioTestService ExecuteMultiplayerTestAsync with two clients
and argument FeedPlateUpgradeVerification. It is Studio/memory gated.
58 checks cover migration, prices, relative RNG, purchase validation, duplicates,
level cap, real Feed integration, save/reload and unchanged other-player progress.
Physical input/visual review and production DataStore testing remain separate.
