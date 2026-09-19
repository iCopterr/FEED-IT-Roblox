# Failed-feed recovery: Revive or keep at base level

After Explosion (when Miracle Save fails), the existing PendingRecovery record
preserves the pre-failure pet while the owner chooses. Pending pets cannot earn,
equip, place or Feed. Revive restores the old level; KeepBase returns the same
pet at FeedConfig.ExplosionResetLevel (0). Both consume the offer permanently.
Food stays spent either way. No deletion or automatic expiry. This supersedes
the older broken-only choice and GDD loss-on-decline flow.

The authored StarterGui.ReviveUI shows PET RECOVERY when recovery exists. The
panel opens after Feed animation/save completes, including for recovery loaded
from a save. It shows name, rarity, pre-explosion level/income and spent Food.
Previous/Next browse multiple records. KEEP AT LEVEL 0 returns the pet to MY PETS
and closes that offer, NOT merely the window. Disconnecting or hiding the window
without a choice preserves the offer across saves. No public revive count/history.

REVIVE FREE (STUDIO) is enabled only when the server reports Studio eligibility.
ReviveService independently requires RunService:IsStudio for every mutation;
client flags cannot enable it in published servers. Published players can view
their recovery and choose KEEP AT LEVEL 0 for free; paid recovery/products/receipts
are not implemented. KeepBase is server-validated but not Studio-restricted.

PrototypeRevive accepts Snapshot, Revive(PetId, AttemptId), or
KeepBase(PetId, AttemptId). Ownership comes
only from the caller's profile. Type/length, cooldown, profile validity, exact
explosion identity and shared Feed lock checks precede mutation. Snapshot data
is caller-only and detached from persisted pet records.

Revive moves a clone of the original pet from PendingRecovery into Inventory
without yielding. It retains PetId, FeedLevel, Species, Rarity, Variant, Traits,
Locked, CreatedAt and BaseIncome. It does not create a fresh pet, grant currency,
refund Food, reroll Feed, equip or place the pet. Use MY PETS to equip it again.
KeepBase uses the same atomic transition with only FeedLevel changed to 0.
An already-consumed recovery cannot restore twice or undo an accepted reset,
including after reload. An old AttemptId cannot recover a newer failure.

The inventory/recovery transition saves atomically in the existing profile.
Shared FeedLocks keeps new Feed/placement/pickup blocked until save confirmation.
Failures retry without rollback or a second reward; existing leave/shutdown saves
include the transition. Schema stays v4; existing recovery records support both
choices. Farm prices, feeding costs, risk, criticals and income multipliers stay
unchanged. Only the failure decision and its base-level outcome changed.
ReviveConfig contains only timing values; free Studio recovery is not a balance
toggle. Real production outage/rejoin behavior still needs separate testing.

Historical verification (before the new KeepBase choice): 22 real two-player Studio memory assertions via
ExecuteMultiplayerTestAsync(2, "ReviveVerification"); six isolated actual-service
checks with mocked production/save-failure dependencies; eight isolated actual
controller checks with the authored UI and mocked input/transport. All pass.
Build, synced Luau compilation and diff checks pass. Physical mouse/touch and
visual layout review remain unverified. No Computer Use or live data writes.

Current choice-flow verification: 72 FeedVerification multiplayer assertions and
47 DebugVerification assertions pass, including actual explosions, both choices,
Food retention, base-size regrowth, stale requests and memory save/reload.
The legacy ReviveVerification subsequently passed all 22 checks during egg/schema-v5
regression. Its fixture now waits out the request cooldown before testing a stale
attempt ID. New isolated recovery-client and public-server/save-failure checks remain pending.
