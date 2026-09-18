# Broken pets and Studio Revive

Explosion retains the existing PendingRecovery record. Broken pets are not in
usable inventory: they cannot earn income, equip, place or Feed. There is no
level-one reset, permanent deletion, decline action or recovery expiry in this
prototype. This follows the user's newer broken-state choice rather than the
GDD's eventual decline/expiry deletion flow.

The authored StarterGui.ReviveUI shows BROKEN PETS when recovery exists. The
panel opens after Feed animation/save completes, including for recovery loaded
from a save. It shows name, rarity, pre-explosion level/income and spent Food.
Previous/Next browse multiple records. KEEP PLAYING closes the panel without
deleting anything; BROKEN PETS reopens it. No public revive count/history.

REVIVE FREE (STUDIO) is enabled only when the server reports Studio eligibility.
ReviveService independently requires RunService:IsStudio for every mutation;
client flags cannot enable it in published servers. Published players can view
their broken pets, but paid recovery/products/receipts are not implemented.

PrototypeRevive accepts Snapshot or Revive(PetId, AttemptId). Ownership comes
only from the caller's profile. Type/length, cooldown, profile validity, exact
explosion identity and shared Feed lock checks precede mutation. Snapshot data
is caller-only and detached from persisted pet records.

Revive moves a clone of the original pet from PendingRecovery into Inventory
without yielding. It retains PetId, FeedLevel, Species, Rarity, Variant, Traits,
Locked, CreatedAt and BaseIncome. It does not create a fresh pet, grant currency,
refund Food, reroll Feed, equip or place the pet. Use MY PETS to equip it again.
An already-consumed recovery cannot restore twice, including after reload. An
old AttemptId cannot recover a newer explosion of the same PetId.

The inventory/recovery transition saves atomically in the existing profile.
Shared FeedLocks keeps new Feed/placement/pickup blocked until save confirmation.
Failures retry without rollback or a second reward; existing leave/shutdown saves
include the transition. No schema migration or Farm/Feed/economy balance edits.
ReviveConfig contains only timing values; free Studio recovery is not a balance
toggle. Real production outage/rejoin behavior still needs separate testing.

Verification: 22 real two-player Studio memory assertions via
ExecuteMultiplayerTestAsync(2, "ReviveVerification"); six isolated actual-service
checks with mocked production/save-failure dependencies; eight isolated actual
controller checks with the authored UI and mocked input/transport. All pass.
Build, synced Luau compilation and diff checks pass. Physical mouse/touch and
visual layout review remain unverified. No Computer Use or live data writes.
