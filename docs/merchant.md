# Mystery Merchant prototype

The static merchant stall is at the end of the central conveyor (Z = 112).
Approach its gold interaction pad and hold E to browse three random offers.
Stock refreshes on shared 30-minute wall-clock boundaries, not 30 minutes after joining.
Each account can buy each displayed slot once per restock. Bought slots persist
across rejoining; the stock is deterministic across servers running the same config.

## Tokens and rewards

- While continuously working in the farm, every 60 seconds the server rolls a
  10% chance to award one Token. Leaving resets the current minute's progress.
- No offline drops, entry bonus, catch-up rolls, or client-controlled RNG.
- Tokens are separate from Protection Tokens. New profiles start with zero
  merchant Tokens; the cap is 9,999. The HUD uses K/M/B/T formatting.
- Food Pouch: 1 Token for 500 Food.
- Food Crate: 3 Tokens for 5K Food.
- Food Vault: 7 Tokens for 25K Food.
- Guardian Charm: 5 Tokens for one Protection Token, respecting its cap of 10.
- Studio memory-only Debug has a + TOKEN button for testing without grinding.

All stock, weights, prices, drop odds and timing are in
`src/shared/Config/MerchantConfig.luau`. These are provisional balance values.
The drop rate averages one Token per ten uninterrupted farming minutes, but
there is no guaranteed drop or pity timer. Monitor long dry streaks and AFK
incentives during playtests. This explicitly requested prototype shop is the
current earned Protection source, not the GDD's proposed quest/event system.

## Safety and verification

Schema v8 adds Tokens, MerchantRestockId and MerchantPurchases without resetting
existing pets, currency or Protection. Server purchases validate range, living
character, current stock, balance, reward cap, sequence and shared transaction
lock. Charging, reward and slot marker mutate together without yielding, then
save through DataService. Save uncertainty keeps mutations locked until a
confirmed save; it does not refund an ambiguously saved purchase.

MerchantVerification runs only in explicit Studio memory tests. It covers
migration, stock boundaries/determinism, invalid and distant requests, insufficient
funds, replay, per-player slot limits, memory persistence, farm rolls and caps.
Live DataStore reconnect/lease testing and manual touch/gamepad/visual review
remain separate from these automated checks.
