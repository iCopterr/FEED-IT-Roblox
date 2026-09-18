# Feed configuration

FeedConfig is now consumed by FeedService, MoneyService and Feed presentation.

- BaseFoodCost and ExplosionChance use the target level (current + 1), 1–40.
- Multiplier uses current/resulting level, 0–40. Fractional rarity Food costs are preserved.
- Explosion rolls first. An explosion gets a separate 5% Miracle Save roll;
  Miracle keeps the old level, spends Food, and skips Critical.
- Otherwise Critical rolls 94% +1, 5% +2, 0.9% +3, 0.1% +5.
  Skipped levels do not roll intermediate explosions.
- Owner decision: all gains stop at 40. An Insane result at 38 grants only +2.
  Level 40 cannot attempt another Feed; costs/odds are not extrapolated.
- Presentation config controls rise, accelerating spin, landing, burst and banners.
- GetScale is a conservative prototype curve: +6% original size per level,
  capped at 3.4x to fit the current plate/Pen. It is presentation balance, not
  a change to the GDD income multipliers. Carried models remain normalized.

Player schema v3 adds PendingRecovery[PetId] with Pet (full pre-failure record),
AttemptId, ExplodedAt and FoodSpent. Recovery pets are outside Inventory and
cannot earn, equip, place or be removed. No automatic expiry or deletion;
Revive/Protection/purchases are not implemented.

Food and outcome mutate without yielding and save together through DataService.
A retry returns the same cached attempt. Feed/pickup/removal are locked during
presentation and until save confirmation. Failed/ambiguous saves retry without
refunding, rerolling or restoring the pet. Leave/shutdown save the same profile.
Production DataStore outages/session transfer still require live verification.
