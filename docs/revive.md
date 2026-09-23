# Timed Rescue after failed feeding

An exploded pet enters PendingRecovery with its original identity and growth.
During the offer it cannot earn, equip, place or feed. Restore Growth restores its
pre-failure level in Studio; Keep at Level 0 returns the same pet at base level.
Decline or timeout also returns it at level 0. Failed food stays consumed.

The offer expires after the configured feed presentation plus the Rescue window
in ReviveConfig. Closing the UI or reconnecting does not restart that clock.
Rescue is free and Studio-only; paid restoration is not implemented.
KeepBase and automatic expiry work in normal servers.

PrototypeRevive validates ownership, pet/attempt IDs, expiry, cooldown and the
shared transaction lock. Save retries retain the same resolved state.
FoodShopVerification covers timed expiry and current feeding; ReviveVerification
covers legacy recovery identity, request validation and persistence.
