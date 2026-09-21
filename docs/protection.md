# Prototype Feed Protection

Protection is an account-bound, single-attempt risk reduction. It does not
guarantee survival. New and migrated prototype profiles receive three tokens so
the decision can be playtested before quest rewards or Developer Products exist.

On the Feed panel:

- FEED uses the current plate-adjusted explosion risk.
- PROTECT shows tokens remaining and the exact protected risk.
- Protection becomes available for target Feed Level 6 and higher.
- Food cost is unchanged.
- An accepted Protected Feed consumes exactly one token whether it succeeds,
  Miracle Saves, or explodes. Invalid, unaffordable, stale, or busy requests do
  not consume Food or a token.

`FeedConfig.ProtectedRisk` contains the GDD v0.5 §22 candidate target risks.
`GetProtectedRisk` preserves the current Feed Plate's relative reduction, so
plate upgrades and Protection both matter while risk remains above zero.

The server owns token count, applied risk, RNG, Food deduction and outcome.
Sequence replay returns the original attempt without consuming another token.
Food, token count and outcome are one in-memory transaction followed by the
existing confirmed-save retry lock. Schema v7 persists `ProtectionTokens`.

The Mystery Merchant now sells a Guardian Charm for five farm-earned merchant
Tokens, granting one Protection Token (cap 10). These are two separate balances.
See `merchant.md`. No quest/event source or Robux receipt path exists yet.
Earned and paid tokens must use this same strength when paid sources are added.
