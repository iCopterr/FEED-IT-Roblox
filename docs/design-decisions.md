# Prototype redesign — approved 2026-09-22

The user approved all three changes below and confirmed there are no real-player
saves requiring refunds. These newer instructions supersede the corresponding
Farm, Protection, currency and permanent-loss rules in GDD v0.5.

## Agreed direction: failure preserves the pet

- Explosion loses Feed growth, not the pet: keep identity/rarity/lock and reset
  to base Feed level 0. Failed Food remains consumed.
- Reframe Revive as an immediate Rescue opportunity after failure, not an
  anytime restoration. Offer Restore Growth or Keep at Level 0.
- Test window: 15 seconds after the configured failure presentation; tuning value,
  not final balance. Block pet
  movement/feeding during the pending choice. Decline/expiry returns the base-level
  pet to inventory; the offer cannot be reused. Disconnect must not restart expiry.
- Rescue remains free and Studio-only for prototype testing. No paid receipt or
  production recovery product has been introduced.

## Money-based food shop instead of AFK farm

- Merchant food purchases replace AFK farm Food production and farm upgrades.
- Shop periodically restocks different foods, inspired by a seed-shop restock loop.
- Food types differ in how much they reduce Feed failure/explosion chance.
- Money is the only shop currency. Token drops, Token HUD and consumable
  Protection actions are removed from active gameplay. Legacy data/config/modules
  remain for reference, but the old farm services/controllers do not start.
- Restock every 30 minutes: Basic always available, two weighted distinct special
  offers, each purchasable once per player per restock. One player's purchases
  never empty another player's stock.
- One serving per Feed. Basic: 5 for $100, no reduction. Hearty: 5 for $2.5K,
  15% relative reduction. Gourmet: 3 for $25K, 30%. Royal: 2 for $250K, 45%.
  All are prototype tuning values in FoodConfig, not final balance.
- Final explosion risk = original risk × plate multiplier × food multiplier.
  Plate upgrades stay; foods cannot make a positive base risk zero. Explosion,
  Miracle Save and Critical order is unchanged.
- Food HUD sums all servings. Feed UI cycles types and shows the selected type's
  quantity and final risk. UI remains authored StarterGui assets.
- Game direction is pet farming/tending, not a straight tier-progression tycoon.

## Test data

- DataConfig.MemoryOnly=true disables remote DataStore access in every environment.
  Data lasts only within the running server; a new Play/server starts fresh.
- Save/lease infrastructure is retained for later, not deleted. No remote data
  was erased. Same-server reconnect uses its original recovery timestamp.
- Schema v9 adds Foods for special servings; Food holds Basic servings. Old token
  and farm fields are inactive compatibility data. Do not enable production saves
  until the new economy and migration policy have been reviewed.

## Verification

- FoodShopVerification covers the new merchant, selected-food Feed, immediate
  Rescue, duplicate requests, and real-time automatic level-zero recovery.
- Older Farm/Merchant/Protection verification scripts describe the previous
  design and are not a current acceptance suite. They remain opt-in only.
