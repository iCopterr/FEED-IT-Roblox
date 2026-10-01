# Revive Machine — 24-hour recovery

An exploded pet enters PendingRecovery with its original identity and growth.
During recovery it cannot earn, equip, place or feed. Visit the Revive Machine
beside the merchant and hold E. Select a broken pet from the scrollable list to
preview it and restore its pre-failure growth with one owned Revive Charm.
The window is exactly 24 hours from the saved ExplodedAt timestamp, including
offline time. Expiry returns the same pet to inventory at level 0, never deletes
it. Failed food stays consumed. There is no automatic Rescue popup anymore.

ReviveConfig controls the window and machine interaction distance. Closing the
UI or reconnecting does not restart the clock. Existing pending records use
their original explosion timestamp with the new 24-hour window.
Rescue requires a charm in both Studio and published servers. Buy a rare charm
at the Money merchant or use the configured 149-Robux direct Revive product for
the selected recovery. Receipt processing remains the only authority for paid
restoration and is idempotent.
Missing charms reject restoration without consuming the pending offer. Closing,
declining, expiry and rejected/replayed requests do not spend charms. The charm
deduction and restored pet are saved atomically in the same profile.
KeepBase and automatic expiry remain free in normal servers.

## Revive Shards

The Revive Machine has separate **Broken Pets** and **Shard Exchange** tabs.
Every successfully received Robux food purchase grants a guaranteed shard amount
based on that food's configured rarity: Common 1, Uncommon 2, Rare 5, Epic 10,
Legendary 20, Mythic 35, Fabled 60 and Celestial 100. Money purchases grant no
shards. The Welcome Treat Pack, purchased Revive Charm, direct pet Revive, Money
packs, Grow and Restock also grant no shards, preventing discounted reward loops.

One hundred shards exchange for one owned Revive Charm. ReviveShards is a
server-authoritative persisted integer introduced in schema v12. Paid shards use
the existing durable receipt ledger, so a duplicate receipt cannot duplicate the
reward. Machine exchange requires proximity and the shared transaction lock;
sequence replay returns the prior result without spending twice. Shards and the
new charm are validated and saved together.

PrototypeRevive validates ownership, pet/attempt IDs, expiry, cooldown and the
shared transaction lock. Save retries retain the same resolved state.
FoodShopVerification covers timed expiry and current feeding; ReviveVerification
covers legacy recovery identity, request validation, shard exchange and
persistence. The edit-mode commerce and revive-shard harnesses cover every paid
food reward, duplicate receipts, distance, insufficient balance and replay.
