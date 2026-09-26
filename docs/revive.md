# Timed Rescue after failed feeding

An exploded pet enters PendingRecovery with its original identity and growth.
During the offer it cannot earn, equip, place or feed. Restore Growth restores its
pre-failure level by consuming one owned Revive Charm; Keep at Level 0 returns the same pet at base level.
Decline or timeout also returns it at level 0. Failed food stays consumed.

The offer expires after the configured feed presentation plus the Rescue window
in ReviveConfig. Closing the UI or reconnecting does not restart that clock.
Rescue requires a charm in both Studio and published servers. Buy a rare charm
at the Money merchant before risking a pet. No Robux receipt product is involved.
Missing charms reject restoration without consuming the pending offer. Closing,
declining, expiry and rejected/replayed requests do not spend charms. The charm
deduction and restored pet are saved atomically in the same profile.
KeepBase and automatic expiry remain free in normal servers.

PrototypeRevive validates ownership, pet/attempt IDs, expiry, cooldown and the
shared transaction lock. Save retries retain the same resolved state.
FoodShopVerification covers timed expiry and current feeding; ReviveVerification
covers legacy recovery identity, request validation and persistence.
