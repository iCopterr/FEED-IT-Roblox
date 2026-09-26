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
at the Money merchant. The adjacent Robux button is visibly disabled (SOON):
the owner confirmed no Developer Product exists yet. No purchase prompt or
receipt handler is active; future payment integration requires a real product
and idempotent receipt processing before enabling that button.
Missing charms reject restoration without consuming the pending offer. Closing,
declining, expiry and rejected/replayed requests do not spend charms. The charm
deduction and restored pet are saved atomically in the same profile.
KeepBase and automatic expiry remain free in normal servers.

PrototypeRevive validates ownership, pet/attempt IDs, expiry, cooldown and the
shared transaction lock. Save retries retain the same resolved state.
FoodShopVerification covers timed expiry and current feeding; ReviveVerification
covers legacy recovery identity, request validation and persistence.
