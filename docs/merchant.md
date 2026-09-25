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

## World presentation

The merchant is an authored market landmark rather than the earlier box stall.
Its 42-by-30-stud platform keeps the original `InteractionPoint` at
`(0, 0.4, 147.5)`, so proximity, travel and purchase validation are unchanged.
The structure includes a stepped purple-and-gold canopy, open counter, corner
posts, display shelves, six colored food props and adjacent garden beds.

`SellerRig` is a large R6-style NPC rig with a Humanoid, Animator, anchored
HumanoidRootPart, six Motor6D body joints, apron and hat welds. It is ready for a
future idle animation without converting the merchant into runtime-generated
geometry. The existing merchant SurfaceGui hierarchy and screen UI assets were
not changed during this world-art pass.
