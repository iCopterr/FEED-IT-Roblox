# Money food merchant

Hold E at the merchant interaction pad to browse food. Stock refreshes on shared
5-minute boundaries. Basic Food is always offered but is no longer infinite:
each player can buy one serving at a time, at most five servings per restock. Two
distinct special offers can each be purchased once per player per restock.
Every purchase grants exactly one food or one charm. Existing owned food is not reduced.

The 39-Robux **Refill Stock** restores the exact three offers currently shown,
clears their personal purchase limits, and starts a fresh five-minute personal
window. It does not reroll the selection. The source selection, personal expiry,
purchase intent and receipt remain server-authoritative and persisted.

The standard risk-reduction lineup is Basic (0%), Fresh (8%), Hearty (15%),
Fortified (22%), Gourmet (30%), Enchanted (38%) and Royal (45%). The rare exception
is Blessed Food: $10M, zero explosion risk for one Feed, ordinary critical odds,
and level-40 cap. Its stock weight is 0.25. Revive Charm costs $5M, weight 0.5,
and restores pre-failure growth only within the existing timed Rescue offer.
Both have one personal purchase per restock if offered. Their Money purchases do
not grant Revive Shards; only fulfilled Robux food receipts do.
Across 100,000 seeded restocks (IDs 1–100,000), Blessed appeared in 0.22% and
Revive in 0.504%; these are measured samples, not exact configured probabilities.
Only two weighted specials appear each restock; Feed has eight authored food
cards. Charms are shown in the Food/consumables inventory tab, never the feed selector.

Prices, quantities and risk reductions live in FoodConfig. MerchantConfig
controls stock selection, refresh timing and request validation. Purchases spend
Money and add the selected food or charm. ReviveConfig.Shop contains charm tuning.
No farm drops or Token currency remain.

The server validates player proximity, personal remaining stock, affordability,
restock ID, sequence and transaction lock. Per-restock purchase markers use the
existing boolean save map. Schema v10 added ReviveCharges, and schema v12 adds
ReviveShards with a zero migration for existing profiles
without changing balances, food, pets, recovery deadlines or tutorial state. Replays do
not charge twice. FoodShopVerification covers all food definitions, Basic's
five-purchase limit, special limits, feeding and client startup.

## Shop presentation

`StarterGui.MerchantUI` owns the complete authored shop hierarchy. The compact
scrolling list follows the configured food progression order even when the two
special offers were randomly selected in a different order. Each row keeps its
original server stock slot for purchase validation and shows image-ready art
(emoji fallback), food name, bundle/remaining stock, formatted Money price and
Feed-risk reduction. Sold-out rows remain visible but disabled. No shop UI is
constructed at runtime.

## Studio verification

Run the two-client suite from an idle Studio MCP edit context. Schedule the
yielding test outside the command callback, then poll the result attribute from
a later command. Studio data stays in memory with the default DataConfig.

```lua
game:SetAttribute("MerchantReviewResult", nil)
task.defer(function()
	local ok, result = pcall(function()
		return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "FoodShopVerification")
	end)
	game:SetAttribute("MerchantReviewResult", game:GetService("HttpService"):JSONEncode({ok=ok, result=result}))
end)
```

Read with `print(game:GetAttribute("MerchantReviewResult"))`. A non-nil result
means the run ended; inspect both `ok` and `result.passed`. The snapshot contract
includes `Amount` so cards can show servings without inferring purchase rewards.

The one-item/rare-consumables update passed 78 FoodShopVerification checks and
46 TutorialVerification checks in memory-only multiplayer tests. The idle-edit
`docs/studio/verify-rare-merchant.luau` harness passed 18 additional checks using
actual MerchantService source with isolated profile, stock-clock and saver
dependencies: both rare grants/prices, insufficient Money, validation rollback,
duplicate request, save lock and personal stock. This is not a live DataStore test.
