# Feed configuration

FeedConfig extends the existing income multiplier module. No gameplay behavior
is switched on by this change: FeedService still consumes 1 Food without RNG.

- BaseFoodCost and ExplosionChance are indexed by **target level**, 1–40.
- Multiplier remains indexed by resulting/current level, 0–40; unchanged.
- GetFoodCost(targetLevel, rarity) applies the GDD rarity multiplier, preserving
  fractional costs. Unknown levels/rarities return nil; never extrapolate.
- CriticalResults uses 94% +1, 5% +2, 0.9% +3, 0.1% +5.
- Explosion is rolled first. On explosion, roll 5% Miracle Save; it preserves
  pre-attempt level and spent Food, and skips Critical. Without explosion,
  roll Critical; skipped levels do not roll extra explosions.

Level 40 is the end of configured balance, not a newly imposed gameplay cap.
The future transaction must explicitly resolve critical overshoot past 40
before enabling progression; this config does not invent a clamp or extra curve.

Presentation contains tunable defaults for closing UI on accepted Feed, rising
four studs, accelerating spin from 45 to 1080 degrees/sec, success return/flash,
explosion burst/fade and result banners. These are settings only: no effects,
banner Instances or animation code are added yet. Miracle Save has separate copy
so it cannot be mislabeled as a successful level gain or a permanently lost pet.

Next: implement the safe server transaction/pending recovery, then make client
effects show its authoritative outcome. Never delete a pet solely for an effect.
