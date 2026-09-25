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
  Protection actions are removed from active gameplay. Legacy save fields remain
  readable; retired configs, modules and sign assets were deleted on 2026-09-23.
- Restock every 30 minutes: Basic is always offered with five personal purchases;
  two weighted distinct special offers are each purchasable once per player per
  restock. One player's purchases never empty another player's stock.
- One serving per Feed. Standard relative-risk tiers are Basic 0%, Fresh 8%,
  Hearty 15%, Fortified 22%, Gourmet 30%, Enchanted 38% and Royal 45%. Basic's
  purchase remains a five-serving $100 bundle. All are prototype tuning values
  in FoodConfig, not final balance.
- Final explosion risk = original risk × food multiplier. Plate upgrades were
  removed by user request on 2026-09-23; foods cannot make a positive base risk zero. Explosion,
  Miracle Save and Critical order is unchanged.
- Food HUD removed. Inventory has a separate Food tab; Feed UI uses selectable
  food cards and a rotating pet preview. UI remains authored StarterGui assets.
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
- Superseded farm/plate/Token-merchant tests were removed. FeedVerification now
  covers the current RNG and migrations; FoodShopVerification covers transactions.

## Deferred food effects — 2026-09-23 (not implementation approval)

- Additional standard food tiers were later approved and implemented on
  2026-09-25. The special gameplay effects below remain deferred.
- Lucky Treat proposal: total Critical chance 6% -> 12%, conditional on survival;
  no food-based risk reduction. The later removal of plate upgrades also applies.
- Growth Feast proposal: +1 additional level on successful Feed, capped at 40.
- Mystic Meal proposal: 45% relative risk reduction normally, 30% stronger for
  Mystic pets (45% x 1.30 = 58.5%, not 75%).
- These are discussion candidates only. Current four foods and odds stay unchanged.
- Suggested next prototype priority: a fresh-player start and short onboarding
  path through egg purchase/hatch, placement, earning, food purchase and feeding.
  No onboarding implementation was authorized in this discussion.
