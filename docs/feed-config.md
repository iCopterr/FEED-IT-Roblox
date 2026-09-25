# Feed configuration

FeedConfig contains explosion chances, Critical outcomes, income multipliers,
growth and presentation timing. FoodConfig contains food prices, servings and
risk reductions. Each accepted attempt consumes one selected serving.

The seven standard foods reduce risk by 0%, 8%, 15%, 22%, 30%, 38% and 45%.
They are Basic, Fresh, Hearty, Fortified, Gourmet, Enchanted and Royal. These are
plain relative-risk tiers; rarity-specific bonuses, Critical bonuses and extra
Feed-level gains remain deferred.

Explosion chance uses the target level (current + 1); food applies a relative
reduction to that chance. Explosion rolls first, followed by a 5% Miracle Save
roll on failure. Survival rolls Critical: 94% +1, 5% +2, 0.9% +3, 0.1% +5.
Skipped levels do not roll intermediate failures, and all gains stop at 40.

Visual growth adds 10% of the original model size per Feed level. Level 0 is
1x and level 40 is 5x; every configured level is visibly larger than the one
before it. The same curve drives Pen, feed plate, Feed effects and carry visuals.

There are no protection tokens, plate upgrades or rarity-based food costs.
On failure, the pet enters PendingRecovery with its original identity and level.
The timed Rescue offer restores growth in Studio; decline/expiry returns the same
pet at level 0. Failed food stays consumed. See design-decisions.md.

Food/outcome mutate together without yielding, then save through DataService.
Request replay returns the same result. Feed and pickup remain locked through
presentation and save confirmation. FeedVerification covers RNG and migrations;
FoodShopVerification covers food transactions, failure, Rescue and expiry.
