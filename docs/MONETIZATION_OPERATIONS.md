# Monetization implementation — 2026-09-30

## Fulfillment

MonetizationService owns the single MarketplaceService.ProcessReceipt callback.
It grants on a detached, schema-validated profile copy, writes reward plus
PurchaseId marker together, then acknowledges only after DataService.Save.
DataService's existing UpdateAsync session lock is the cross-server guard.
Failed/ambiguous saves retain the in-memory reward/marker and retry while
gameplay mutation is locked. Duplicate callbacks never re-grant. No reward is
granted by a client or PromptProductPurchaseFinished.

CommerceState stores a versioned JSON object in Settings.CommerceV1. This is
server-only despite its location: SetSetting uses an unrelated fixed allowlist.
Existing schema cloning, migration and profile saving preserve this scalar.
Never delete receipt markers or reset CommerceV1 on a live account. New prompts
are stopped at 10,000 receipts; a ledger archival design is needed before that
limit. This is prototype storage, not an unlimited purchase-history solution.

## Context and stock

One saved pending intent per player binds the prompt to the server-selected
product, food slot, egg list, or PetId + explosion AttemptId. Save precedes
prompting. Cancellation from the server Marketplace event clears only the
matching prompt token. No cancellation timeout discards a potentially paid
purchase. Prompt closure with success does NOT grant anything.

Food reserves one existing shop slot against Money purchases while payment is
pending. Paid delivery after rotation still grants the purchased food, without
overwriting newer stock history. Personal restock replaces only that player's
stock and returns to normal stock at the next five-minute boundary.

Grow Now finishes the selected egg's timer (not hatch/reward animation).
Already-ready/collected eggs are successful no-ops, per owner instruction.
Grow All snapshots the currently placed growing eggs for a flat 199 Robux.

Revive intent must start within 24 hours at the machine. Its exact recovery
record is protected from expiry and manual charm/base recovery until payment
resolves. A receipt restores that same pet with pre-failure level, no food
refund and no automatic feeding. Cancelled payment restores normal expiry.

The permanent x2 pass is checked by the server and multiplies placed-pet income
and income payout effects, not money packs. Welcome is prompted only once;
a second distinct externally bought Welcome receipt remains unresolved rather
than acknowledging payment for no reward.

## Deployment and support limitations

- Keep food, Grow Now/All, Restock and direct Revive products off external-store
  sales: they require in-game context. Keep Welcome off external sales to enforce
  its once-per-player rule. Only unrestricted money packs support context-free
  external receipt delivery.
- An interrupted/ambiguous prompt can leave a saved pending intent with no
  confirmed cancellation or receipt. New product prompts are blocked and the
  player sees a pending-purchase notice. Do not clear it blindly: verify payment
  history with support first. No automatic credit/refund economy was added.
- Memory-only Studio rejects purchases. Published servers use the existing
  production DataStore. Studio DataStore opt-in is intentionally unchanged.
- Ordinary callback tests use mocks and detached profiles, never real payment
  or live account data. No real Robux purchases were made.
- Live client/payment end-to-end testing is still required: MCP reported Play
  started but runtime targets timed out; later edit inspection reported not
  running. No successful live payment test or production publication claimed.

## Verification

Run docs/studio/test-commerce.luau through environment-mcp.ps1 in edit mode.
It tests the actual service source with payment/data mocks, all 24 product
handlers, repeat receipts, simulated rejoin, failed-save retry, cancellation,
Welcome once, pass entitlement, shared food reservation and old-stock delivery,
Grow no-op and timer schema, protected expired Revive and personal Restock.
Rojo build, Luau syntax checks and git diff checks pass.

Roblox API reference checked:
https://create.roblox.com/docs/reference/engine/classes/MarketplaceService
