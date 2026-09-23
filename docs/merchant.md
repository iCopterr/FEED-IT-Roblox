# Money food merchant

Hold E at the merchant interaction pad to browse food. Stock refreshes on shared
30-minute boundaries. Basic Food is always available and repeatable; two distinct
special food offers can each be purchased once per player per restock.

Prices, quantities and risk reductions live in FoodConfig. MerchantConfig
controls stock selection, refresh timing and request validation. Purchases spend
Money and add the selected food. No farm drops or Token currency remain.

The server validates player proximity, ownership of stock, affordability,
restock ID, sequence and transaction lock. Replays do not charge twice.
FoodShopVerification covers purchases, stock limits, feeding and client startup.
