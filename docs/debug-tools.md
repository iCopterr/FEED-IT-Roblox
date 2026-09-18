# Studio debug panel

Start a fresh Studio Play session using the default memory data mode, then click
STUDIO DEBUG. The authored DebugUI is disabled by default, and its controller
enables it only in Studio when the server supplies PrototypeDebug.

- Enter a positive whole amount and click + MONEY or + FOOD. Scientific notation
  such as 1e12 is accepted. Maximum grant is 1e15; resulting balance cap is 4e15.
- Click the rarity button to cycle Common/Uncommon/Rare/Epic/Legendary/Mythic,
  then SPAWN PET. It enters inventory with a unique PetId. Debug spawning stops
  at 200 inventory pets; this is not a general game inventory-cap change.
- Click the target-pet button to cycle your pets (short PetId distinguishes
  duplicates). Enter 0–40 and SET PET LEVEL. Pick up a placed pet first; held,
  stored or plate pets can be edited. Plate model growth updates immediately.
- Enter 1–10 and SET FARM LEVEL. This edits only your memory profile, not the
  FarmConfig prices/rates. Existing farm sign and production read the new level.
- Cycle Success / Critical / Mega / Insane / Explosion / Clear and ARM NEXT FEED.
  The target PetId is fixed when armed. Close DEBUG, put that pet on the feed
  plate and Feed normally. Critical gains use existing +2/+3/+5 configuration
  and stop at 40. Explosion deliberately bypasses natural zero-risk levels and
  Miracle Save for testing; it still uses the actual broken/recovery transaction.

Overrides are consumed only after an accepted, validated Feed transaction.
Insufficient Food, wrong plate, max level and other rejected requests leave the
override armed. Another pet/player is unaffected. Clear removes the override;
leaving the server clears it as well. No permanent probability changes occur.

Debug writes are rejected during Feed/Revive locks. The panel suppresses world
carry/Feed/conveyor interactions while open. Money/Food/inventory HUD updates
through its existing polling; debug does not change production payout timing.

Safety: both server handlers and override resolution require IsStudio AND the
memory adapter. No debug remote exists in published games or persistent Studio
sessions. The client hides the panel outside Studio. Requests validate profile,
ownership, bounded finite integers, species/mode, cooldown and sequence. Cached
replays return the same result without another currency grant or pet; altered
payloads with an old sequence are rejected. Lost replies trigger a snapshot,
not an automatic second grant. No targeting another player, data reset,
permanent odds editing or production DataStore writes are supported.

Files: DebugService, DebugFeedOverrides, DebugController, DebugConfig and the
authored DebugUI.rbxmx. FeedService checks the independent override module after
normal eligibility/cost validation and consumes it after successful validation.
No schema or Farm/Feed balance configuration changes.

Verification: 47 two-player memory Studio assertions via
ExecuteMultiplayerTestAsync(2, "DebugVerification"), 12 isolated actual-service
access-gate checks with mocked environment flags, and 10 isolated controller
checks using the authored GUI with mocked input/transport. All pass. Build,
synced compilation and diff checks pass. Physical input and visual layout review
remain separate. No Computer Use or live data writes.
