# Money food merchant

Hold E at the merchant interaction pad to browse food. Stock refreshes on shared
5-minute boundaries. Basic Food is always offered but is no longer infinite:
each player can buy its five-serving bundle at most five times per restock. Two
distinct special food offers can each be purchased once per player per restock.

The standard risk-reduction lineup is Basic (0%), Fresh (8%), Hearty (15%),
Fortified (22%), Gourmet (30%), Enchanted (38%) and Royal (45%). Royal remains
the strongest. Only two of the six weighted special foods appear each restock;
the Feed UI keeps all seven authored cards in its scrolling food bar.

Prices, quantities and risk reductions live in FoodConfig. MerchantConfig
controls stock selection, refresh timing and request validation. Purchases spend
Money and add the selected food. No farm drops or Token currency remain.

The server validates player proximity, personal remaining stock, affordability,
restock ID, sequence and transaction lock. Per-restock purchase markers use the
existing boolean save map, so no data-version migration is needed. Replays do
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
