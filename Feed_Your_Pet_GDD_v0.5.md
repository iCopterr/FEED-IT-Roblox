# Feed Your Pet

## Game Design Document (GDD) v0.5

**Platform:** Roblox\
**Genre:** Idle / Pet Collection / Risk--Reward / Progression\
**Document Purpose:** Production reference for AI coding agents, Roblox
Studio implementation, balancing, and prototype validation.\
**Status:** Pre-Prototype Design\
**Core Hook:** Hatch pets, earn Money, produce Food, and repeatedly Feed
pets to make them larger and dramatically more profitable---while
accepting an increasing chance that the pet explodes. Every explosion has a small built-in **5% Miracle Save** chance; otherwise the pet is lost unless recovered through Revive.

------------------------------------------------------------------------

# 1. Executive Summary

**Feed Your Pet** is a Roblox progression game built around a simple
emotional decision:

> **Do I keep this valuable pet now, or risk feeding it one more time?**

Players hatch pets from Eggs and place them inside their personal Pen.
Placed pets generate **Money per second**. Players spend Money on
additional Eggs and Farm upgrades. The Farm continuously produces
**Food**, which is used at a dedicated **Feeding Pedestal**.

Every successful Feed increases the pet's **Feed Level**, income
multiplier, and visible size. At higher levels, every Feed has an
increasing probability of **Explosion**. When an Explosion occurs, the
server rolls a built-in **5% Miracle Save**. A Miracle Save keeps the pet
alive at its pre-attempt Feed Level, but the Food spent on that attempt
remains consumed. If Miracle Save does not trigger, the pet is lost unless
the player uses **Revive** during the available recovery opportunity.

Players may stop feeding a pet at any time. There is no requirement to
continue risking it.

The intended emotional loop is:

**Acquire → Attach → Improve → Risk → Survive → Greed → Risk Again →
Explode or Become Legendary**

The game is not designed around a conventional hard endgame power cap.
Instead, extreme progression is controlled statistically:

> **We do not cap pet power. We cap how many pets statistically survive
> to extreme Feed Levels.**

The target is for approximately Feed Lv.12 to represent a mature/average
naturally pushed pet, Lv.20 to be highly valuable, Lv.30 to be
legendary, and Lv.35--40 to be exceptionally rare community-level
achievements.

------------------------------------------------------------------------

# 2. Product Vision

The game should be understandable within minutes but capable of
generating long-term collecting, gambling-like suspense without wagering
cash for cash prizes, social flexing, optimization, and trading
interest.

The player should be able to look at another player's Pen and
immediately understand:

-   that player's progression;
-   which pets are rare;
-   which pets have survived unusually high Feed Levels;
-   which pets are exceptionally large;
-   which pets may be God Rolls;
-   which player owns something genuinely unusual.

The strongest emotional asset in the game is not Money itself. It is
**attachment to an increasingly valuable pet that can still be lost**.

------------------------------------------------------------------------

# 3. Design Pillars

## 3.1 Risk Creates Prestige

Feed Level only matters socially if reaching a high level is difficult.

Lv.30 must not simply mean that a player spent enough Food. It should
communicate that the pet survived a sequence of increasingly dangerous
attempts.

## 3.2 The Player Chooses the Risk

The game must never automatically Feed a valuable pet without an
explicit player decision.

At meaningful levels, the player always chooses:

-   keep the pet;
-   Feed normally;
-   buy Protection and Feed;
-   stop and preserve the current pet.

**Auto Feed is not part of the intended core design.**

## 3.3 Progress Must Be Visible

Successful Feed progression should affect:

-   Feed Level;
-   Money/sec;
-   physical pet size;
-   Rank;
-   visual effects at extreme levels;
-   inspect information;
-   leaderboard potential.

## 3.4 Rarity and Feed Are Different Axes

Rarity determines the quality of the pet that was obtained.

Feed Level represents what happened to that individual pet after it was
obtained.

A Mythic Lv.5 can be economically useful, while a Common Lv.30 can still
be socially remarkable.

## 3.5 Extreme Players Must Not Dictate the Normal Economy

The final Egg and Farm upgrade costs must not be balanced around a
one-in-millions God Roll pet.

Extreme outliers are allowed to overpower the standard Money economy.

Their long-term goals should transition toward:

-   rare variants;
-   traits;
-   high Feed;
-   Index completion;
-   leaderboard competition;
-   limited pets;
-   trading;
-   collection prestige.

------------------------------------------------------------------------

# 4. Core Gameplay Loop

``` text
Buy Egg
   ↓
Hatch Pet
   ↓
Store or Place Pet
   ↓
Placed Pet Generates Money
   ↓
Spend Money on Eggs / Farm
   ↓
Farm Generates Food
   ↓
Pick Up Pet
   ↓
Carry Pet to Feeding Pedestal
   ↓
Spend Food
   ↓
Explosion Roll
   ↓
Exploded? ───── No ───→ Critical Feed Roll
   ↓ Yes
5% Miracle Save Roll
   ↓
Miracle? ───── Yes ───→ Pet survives at same Feed Level; Food stays spent
   ↓ No
Revive or Lose Pet
   ↓
Increase Feed Level
   ↓
Increase Size + Income
   ↓
Keep or Risk Another Feed
```

The complete economy should reinforce one connected loop:

> **Egg → Pet → Money → Farm → Food → Feed → Stronger Pet → More Money**

------------------------------------------------------------------------

# 5. Currencies

The core game uses exactly two primary progression currencies.

## 5.1 Money

Generated primarily by placed pets.

Used for:

-   Eggs;
-   Farm upgrades;
-   future progression unlocks;
-   potentially Pen expansion or non-premium slot upgrades.

## 5.2 Food

Generated by the player's Farm.

Used primarily for:

-   Feed attempts.

Food should not become a second generic Money currency. Its identity is
specifically tied to pet progression and risk.

------------------------------------------------------------------------

# 6. Player Plot

Each player owns one personal Plot during the server session.

Minimum Plot components:

1.  Spawn area
2.  Fenced Pet Pen
3.  Egg purchase/hatching area
4.  Farm
5.  One Feeding Pedestal
6.  Future expansion space

## 6.1 Pet Pen

Placed pets wander freely within the Pen.

The Pen functions as:

-   production space;
-   progression display;
-   social flex area;
-   future trading/inspection destination.

## 6.2 Feeding Pedestal

Each player has **exactly one primary Feeding Pedestal**.

Feeding cannot be triggered directly from inventory.

Required interaction:

1.  select pet;
2.  pick up/carry pet;
3.  approach Pedestal;
4.  place pet;
5.  open Feed UI;
6.  choose Feed or Protected Feed;
7.  server resolves result.

This creates physical ceremony around the most important action in the
game.

------------------------------------------------------------------------

# 7. Pet Data Model

Every pet is an individual persistent object.

Suggested conceptual schema:

``` lua
Pet = {
    PetId = "unique-id",
    SpeciesId = "pet_species_id",
    EggId = "source_egg",
    Rarity = "Common",
    Variant = "Normal",
    Traits = {},

    FeedLevel = 0,
    BaseIncome = 10,

    IsLocked = false,
    IsPlaced = false,
    PlotSlot = nil,

    CreatedAt = 0,
    DataVersion = 1
}
```

Derived values such as FinalIncome and visual scale should preferably be
recalculated from authoritative data rather than permanently trusted
from the client.

Every pet must have a unique `PetId`, especially before Trading is
introduced.

------------------------------------------------------------------------

# 8. Rarity and Base Income

Current locked base-income anchors:

  Rarity        Base Income
  ----------- -------------
  Common               10/s
  Uncommon            150/s
  Rare                500/s
  Epic              3,000/s
  Legendary        10,000/s
  Mythic           45,000/s

These values are current balancing anchors.

Exact hatch probabilities are **not locked**.

A possible Mythic probability such as `0.01%` has been discussed as an
example but must not be treated as final until Egg economy simulation is
complete.

------------------------------------------------------------------------

# 9. Egg System

Each Egg has its own:

- price;
- pet pool;
- rarity distribution;
- incubation time;
- visual model;
- unlock requirement.

Not every pet should be obtainable from every Egg. A new Egg tier should improve the expected opportunity set without making every pet from the previous Egg immediately worthless. High rolls from an earlier Egg may remain stronger than low rolls from the next Egg.

## 9.1 Full V1 Content Target

- **3 Eggs**
- **18 pets**
- approximately **6 pets per Egg**

## 9.2 Economy v0.4 Candidate Egg Progression

These values are **balance candidates**, not locked production values.

### Basic Egg

- Price: **5,000 Money**
- Incubation: **10 seconds**
- Early-game, Common-heavy pool

| Pet Slot | Rarity | Candidate Chance |
|---|---|---:|
| #1 | Common | 30% |
| #2 | Common | 30% |
| #3 | Uncommon | 25% |
| #4 | Rare | 10% |
| #5 | Epic | 4.5% |
| #6 | Legendary | 0.5% |

### Advanced Egg

- Price: **2,000,000 Money**
- Incubation: **2 minutes**
- Suggested unlock: **Highest Feed ≥ Lv.5 + Farm Lv.3**

| Pet Slot | Rarity | Candidate Chance |
|---|---|---:|
| #1 | Uncommon | 25% |
| #2 | Uncommon | 25% |
| #3 | Rare | 25% |
| #4 | Epic | 15% |
| #5 | Legendary | 9.5% |
| #6 | Mythic | 0.5% |

### Elite Egg

- Price: **500,000,000 Money**
- Incubation: **12 minutes**
- Suggested unlock: **Highest Feed ≥ Lv.10 + Farm Lv.6**

| Pet Slot | Rarity | Candidate Chance |
|---|---|---:|
| #1 | Rare | 25% |
| #2 | Rare | 25% |
| #3 | Epic | 25% |
| #4 | Legendary | 12% |
| #5 | Legendary | 12% |
| #6 | Mythic | 1% |

### Design Rule: Overlapping Value Bands

Egg tiers should overlap. A strong Legendary/Mythic from an earlier Egg may remain better than a low roll from the next Egg. This preserves attachment, prevents every zone/tier unlock from invalidating prior pets, and makes hatching the new tier a chase rather than an automatic upgrade.

### Design Rule: Rising Rarity Floor

As progression advances, the lowest available rarity may rise. Early Eggs can contain Common pets, while later Eggs can begin at Uncommon/Rare. This creates a sense of progression without requiring every individual result to be stronger than all previous results.

Exact species, final odds, prices, and unlock requirements must be validated through simulation and playtesting.

# 10. Variants and Traits

The final game may contain two separate rarity layers.

## 10.1 Variant

One primary visual/status category, for example:

-   Normal
-   Shiny
-   Rainbow
-   Celestial

## 10.2 Traits / Mutations

2026-10-01 presentation update: owned eggs expose only their reserved Variant
through a name prefix and effects; species and pet rarity remain hidden until
hatch. Shiny uses gold glints, Rainbow orbit ribbons, and Celestial a star halo.
These cosmetic effects also follow the pet. Variant odds and income multipliers
are unchanged; no new Trait or Variant economy is introduced.

Optional independent rare modifiers.

A pet may eventually look like:

``` text
Species: Dragon
Rarity: Mythic
Variant: Celestial
Traits: Giant, Lucky, Golden Aura
Feed: Lv.27
```

Exact Variant and Trait odds/multipliers are **not locked**.

### Design Rule

Extreme income should result from a combination of:

**Base Rarity × Feed × Variant × Traits**

rather than Feed multiplier alone becoming absurdly large.

------------------------------------------------------------------------

# 11. Pet Income Formula

Conceptual formula:

``` text
FinalIncomePerSecond =
    BaseIncome
    × FeedMultiplier
    × VariantMultiplier
    × TraitMultipliers
    × ApplicableGlobalBonuses
```

The server calculates authoritative income.

The client may display estimated/current income but cannot award Money
itself.

------------------------------------------------------------------------

# 12. Feed System

Feed is the central mechanic.

## 12.1 Feed Requirements

Before attempting Feed:

-   player owns the pet;
-   pet is valid;
-   pet is on the player's Pedestal;
-   no other Feed transaction is active;
-   player has enough Food;
-   pet is not already being traded/deleted;
-   request passes server cooldown/idempotency validation.

## 12.2 Resolution Order

The server resolves a Feed in this order:

1.  validate request;
2.  deduct Food;
3.  determine whether Protection applies;
4.  roll Explosion;
5.  if Explosion occurs, roll **Miracle Save (5%)**;
6.  if Miracle Save succeeds, keep the pet at its pre-attempt Feed Level, keep the Food consumed, skip Critical Feed, and resolve the attempt as a failed-but-survived Feed;
7.  if Miracle Save fails, enter failure/Revive state;
8.  if no Explosion occurred, roll Critical Feed;
9.  determine number of Feed Levels gained;
10. update FeedLevel;
11. calculate new income;
12. update visual state;
13. save/queue persistence;
14. notify client.

**Critical Feed is rolled only when the Feed survives without an Explosion. Miracle Save does not count as a successful Feed.**

------------------------------------------------------------------------

# 13. Critical Feed

Current prototype rule (owner update, 2026-10-01):

  Result       Chance   Feed Gain
  ---------- -------- -----------
  Normal          99%          +1
  Critical         1%          +2

Critical grants one additional level on top of the normal +1. Mega and Insane
are retired. Gains still cap at level 40; at level 39 the actual gain is +1.
The 1% roll occurs only after surviving Explosion; Miracle Save is not eligible.

## 13.1 Important Rule

Skipped Feed Levels do **not** trigger additional Explosion rolls.

Example:

``` text
Current: Lv.17
Explosion roll: Survived
Critical result: +2
New level: Lv.19
```

The player does not roll a second Explosion check for the skipped level.

This makes Critical Feed especially valuable at extreme levels and must
therefore be included in final probability simulations.

------------------------------------------------------------------------

# 14. Feed Multiplier v0.2

Current locked working curve:

    Feed Lv.   Multiplier
  ---------- ------------
           0           ×1
           1         ×1.3
           2         ×1.7
           3         ×2.3
           4         ×3.2
           5           ×5
           6           ×7
           7          ×10
           8          ×15
           9          ×22
          10          ×35
          11          ×60
          12         ×100
          13         ×160
          14         ×270
          15         ×500
          16         ×850
          17       ×1,500
          18       ×2,700
          19       ×5,000
          20      ×10,000
          21      ×15,000
          22      ×22,000
          23      ×30,000
          24      ×40,000
          25      ×50,000
          26      ×70,000
          27      ×95,000
          28     ×130,000
          29     ×180,000
          30     ×250,000
          31     ×350,000
          32     ×475,000
          33     ×625,000
          34     ×800,000
          35   ×1,000,000
          36   ×1,400,000
          37   ×2,000,000
          38   ×2,800,000
          39   ×3,800,000
          40   ×5,000,000

Levels above 40 are not yet balanced.

------------------------------------------------------------------------

# 15. Mythic Feed Income Reference

Using Mythic base income of **45,000/s**:

    Feed   Multiplier   Mythic Income
  ------ ------------ ---------------
       0           ×1           45K/s
       5           ×5          225K/s
      10          ×35        1.575M/s
      12         ×100          4.5M/s
      15         ×500         22.5M/s
      20         ×10K          450M/s
      25         ×50K         2.25B/s
      30        ×250K        11.25B/s
      35          ×1M           45B/s
      40          ×5M          225B/s

These figures exclude Variant, Traits, and global bonuses.

A true God Roll can therefore exceed these values substantially without
requiring Feed multiplier itself to become billions of times stronger.

------------------------------------------------------------------------

# 16. Explosion System

Explosion is the primary scarcity mechanism for Feed progression.

## 16.1 Economy v0.4 Candidate Curve

The early and midgame remain relatively forgiving so the average naturally pushed pet ends near Lv.12. After Lv.20, risk rises sharply so extreme Feed Levels become statistical prestige rather than normal progression.

| Target Feed | Explosion Chance |
|---:|---:|
| 1–3 | 0% |
| 4–5 | 2% |
| 6–7 | 4% |
| 8–9 | 7% |
| 10 | 10% |
| 11 | 12% |
| 12 | 14% |
| 13 | 16% |
| 14 | 18% |
| 15 | 20% |
| 16 | 25% |
| 17 | 28% |
| 18 | 30% |
| 19 | 33% |
| 20 | 35% |
| 21–25 | **55%** |
| 26–30 | **64%** |
| 31–35 | **76%** |
| 36–40 | **88%** |

These post-Lv.20 values are still **balance candidates**, but they currently fit the intended rarity curve substantially better than the earlier softer curve.

## 16.2 Miracle Save — Locked Direction

Every time an Explosion actually occurs, the server performs a separate **5% Miracle Save** roll.

If Miracle Save triggers:

- the pet is **not destroyed**;
- the pet remains at the **Feed Level it had before the attempt**;
- the Food spent on the failed attempt remains consumed;
- any Protection used for that attempt remains consumed;
- the Feed does **not** increase the pet's level;
- Critical Feed is **not** rolled;
- no Revive prompt is needed because the pet survived;
- the player may attempt to Feed the pet again normally.

If Miracle Save does not trigger, the Explosion proceeds to the normal **Revive or Lose Pet** state.

Miracle Save is a universal built-in rule, not a paid perk. It should be presented as a rare jackpot survival moment with distinctive audio/VFX. The displayed Explosion Chance should remain the true Explosion Chance; Miracle Save is shown separately rather than being hidden inside the risk number.

> **Explosion creates fear. Miracle Save creates stories.**

## 16.3 Natural Distribution Including Critical Feed + Miracle Save

Historical analysis, not current balance: the figures below used the retired
94% +1 / 5% +2 / 0.9% +3 / 0.1% +5 table. Recalculate before relying on these
estimates with the 2026-10-01 99% +1 / 1% +2 rule.
The historical calculation used the 5% Miracle Save rule and no Revive or Protection:

- expected natural terminal Feed ≈ **Lv.12.38**;
- skipped Critical levels do not receive additional Explosion rolls;
- Miracle Save leaves the pet at the same Feed Level and allows another future attempt.

| Reach Feed | Natural Chance | Approx. Frequency |
|---:|---:|---:|
| Lv.5 | 96.48% | 1 in 1.04 |
| Lv.10 | 71.90% | 1 in 1.39 |
| Lv.12 | 56.20% | 1 in 1.78 |
| Lv.15 | 33.21% | 1 in 3.01 |
| Lv.20 | 6.81% | 1 in 14.7 |
| Lv.25 | 0.220% | 1 in 454 |
| Lv.30 | 0.00298% | 1 in 33,547 |
| Lv.35 | 0.00000970% | 1 in 10.3M |
| Lv.40 | ~0.00000000523% | ~1 in 19.1B |

The 5% Miracle Save makes memorable survivals meaningfully possible without destroying the intended scarcity of extreme Feed Levels.

## 16.4 Distribution Goal

| Feed | Intended Meaning |
|---|---|
| 0–5 | Safe beginner progression |
| 6–10 | Common progression |
| ~12 | Average mature pushed pet |
| 15 | Strong |
| 20 | Highly valuable |
| 25 | Extremely rare |
| 30 | Server-level legend |
| 35 | Community anomaly |
| 40 | Game-wide legend |

Core philosophy:

> **Do not hard-cap pet power. Cap how many pets statistically survive to extreme power.**

# 17. Pet Growth

Every successful Feed should visibly grow the pet.

## 17.1 Physical Growth

Physical size should use a controlled curve rather than unlimited linear
scaling.

Recommended practical world-size ceiling:

**approximately 10×--15× original size**

This ceiling exists for:

-   collision;
-   camera;
-   Pen readability;
-   server performance;
-   pathfinding;
-   visual obstruction.

## 17.2 Growth Beyond Physical Cap

After practical scale reaches its maximum, progression may continue
visually through:

-   stronger aura;
-   particles;
-   glow;
-   crown;
-   orbiting effects;
-   special footsteps;
-   mutation appearance;
-   Rank-specific VFX.

Feed Level and economic power are not capped merely because physical
size is capped.

------------------------------------------------------------------------

# 18. Feed Rank

Rank is a presentation layer on top of Feed Level.

Feed Level remains the authoritative prestige number.

Possible names:

-   Rookie
-   Bronze
-   Silver
-   Gold
-   Diamond
-   Master
-   Grandmaster
-   Immortal
-   Ascended
-   Divine

Example:

``` text
DIVINE
Feed Lv.37
```

Exact thresholds are not locked.

At the highest Rank, Feed Level may continue increasing without
inventing endless new Rank names.

------------------------------------------------------------------------

# 19. Farm System

The Farm continuously generates Food.

Basic model:

```text
FoodPerSecond = BaseFarmOutput × FoodProductionMultiplier
```

Farm upgrades cost Money and create an opportunity-cost decision:

> Spend Money on another Egg, or improve Food generation?

Farm production must remain easy to understand. Avoid hidden mechanics such as "the longer you AFK, the faster the Farm becomes" unless intentionally introduced later.

## 19.1 Economy v0.4 Candidate Farm Curve

The current direction uses fewer, more meaningful Farm levels rather than dozens of tiny upgrades. Each upgrade should feel like a milestone and can later receive a visible model/technology upgrade.

| Farm Lv. | Base Food/s | Upgrade Cost |
|---:|---:|---:|
| 1 | 2 | Free |
| 2 | 6 | 5K |
| 3 | 18 | 50K |
| 4 | 50 | 500K |
| 5 | 140 | 5M |
| 6 | 400 | 50M |
| 7 | 1.2K | 500M |
| 8 | 3.5K | 5B |
| 9 | 10K | 50B |
| 10 | 30K | 500B |
| 11 | 90K | 5T |
| 12 | 250K | 50T |
| 13 | 700K | 500T |
| 14 | 2M | 5Qa |
| 15 | 5M | 50Qa |

The cost curve intentionally grows faster than production in many stages. This creates soft grind pressure as progression advances, while the early game remains generous.

These values are **candidate balance**, not final.

# 20. Feed Food Cost

Every Feed consumes Food.

Food cost should increase with Feed Level so Feed cannot become meaningless button spam. Food cost should also scale moderately with pet Rarity, because feeding a high-base-income pet should require more commitment than feeding a low-rarity pet.

## 20.1 Formula

```text
FinalFeedFoodCost = BaseFeedFoodCost[TargetFeedLevel] × RarityFoodMultiplier[PetRarity]
```

**Variant and Traits do not increase Food cost.** A player who gets lucky with Shiny/Rainbow/Celestial or rare Traits should feel rewarded rather than punished with a dramatically higher feeding tax.

## 20.2 Rarity Food Multipliers

Current candidate:

| Rarity | Food Cost Multiplier |
|---|---:|
| Common | ×1.00 |
| Uncommon | ×1.15 |
| Rare | ×1.35 |
| Epic | ×1.65 |
| Legendary | ×2.00 |
| Mythic | **×2.50** |

The multiplier is deliberately mild relative to the enormous Base Income gap between rarities. Rarity must remain valuable.

Example at Base Feed Cost = 380K:

| Rarity | Final Cost |
|---|---:|
| Common | 380K |
| Uncommon | 437K |
| Rare | 513K |
| Epic | 627K |
| Legendary | 760K |
| Mythic | 950K |

## 20.3 Economy v0.4 Base Feed Food Costs

| Target Feed | Base Food Cost |
|---:|---:|
| 1 | 30 |
| 2 | 45 |
| 3 | 70 |
| 4 | 110 |
| 5 | 180 |
| 6 | 300 |
| 7 | 500 |
| 8 | 850 |
| 9 | 1.4K |
| 10 | 2.4K |
| 11 | 4K |
| 12 | 6.5K |
| 13 | 11K |
| 14 | 18K |
| 15 | 30K |
| 16 | 50K |
| 17 | 85K |
| 18 | 140K |
| 19 | 230K |
| 20 | 380K |
| 21 | 650K |
| 22 | 1.1M |
| 23 | 1.8M |
| 24 | 3M |
| 25 | 5M |
| 26 | 8M |
| 27 | 13M |
| 28 | 21M |
| 29 | 34M |
| 30 | 55M |
| 31 | 85M |
| 32 | 130M |
| 33 | 200M |
| 34 | 300M |
| 35 | 450M |
| 36 | 650M |
| 37 | 900M |
| 38 | 1.25B |
| 39 | 1.7B |
| 40 | 2.3B |

These values are **candidate balance** and must be tested together with Farm output, Egg progression, Explosion risk, and Food acceleration purchases.

## 20.4 Pacing Philosophy

F2P should be able to Feed normally, but midgame and late-game waiting should become noticeable enough that acceleration is attractive.

Target emotional outcome:

> **“I can wait and keep playing for free, but a Food boost would make this much more comfortable.”**

Do not stack maximum Food pain at the same point where Egg scarcity, Explosion risk, and Revive pressure are also at their harshest.

# 21. Feed Presentation

A Feed should resolve quickly, approximately **1--2 seconds**, but still
create suspense.

## 21.1 Normal Success

Possible presentation:

``` text
FEED SUCCESS!
Lv.19 → Lv.20
Income ×10,000
```

Pet visibly grows.

## 21.2 Miracle Save

When Miracle Save triggers after an Explosion, the presentation should briefly make the player believe the pet may be gone, then reverse the moment clearly:

``` text
MIRACLE SAVE!
YOUR PET SURVIVED!
Feed Level unchanged
```

Use a distinctive recovery flash, sound cue, and reaction-friendly timing. The event should feel rare and clip-worthy, but the UI must clearly show that the Feed did not succeed and the Food remains spent.

## 21.2 Critical Success

``` text
CRITICAL FEED!
+2 LEVELS
Lv.17 → Lv.19
```

Use stronger audio/VFX than normal success.

2026-10-01 presentation: both outcomes lift and spin for the same opening
2.4 seconds. Critical continues spinning for another 1.6 seconds with escalating
gold particles, then plays its finish burst and popup. Normal does not get this
extra spin. Server presentation locks follow the same configured duration.

## 21.3 Explosion

Sequence:

1.  pet reacts/shakes;
2.  short anticipation;
3.  explosion VFX/SFX;
4.  pet disappears;
5.  failure UI appears.

Backend RNG must be honest. Presentation must never imply that visual
timing can manipulate the already-determined result unless that is
explicitly designed.

------------------------------------------------------------------------

# 22. Protection

Protection is a risk-reduction system used **before** a Feed attempt.

Protection does not guarantee survival. It should reduce risk enough to feel meaningful while preserving tension.

Protection may come from two sources:

1. **Paid Protection** purchased for Robux/convenience.
2. **Earned Protection Tokens** obtained through gameplay/events.

Both should apply the **same gameplay effect**. Free players should not receive a deliberately weaker version.

## 22.1 Candidate Risk Reduction

| Target Feed | Normal Risk | Protected Risk |
|---:|---:|---:|
| 6–10 | 4–10% | roughly 3 percentage points lower |
| 11–15 | 12–20% | roughly 6pp lower |
| 16–20 | 25–35% | roughly 10pp lower |
| 21–25 | 55% | **40%** |
| 26–30 | 64% | **48%** |
| 31–35 | 76% | **58%** |
| 36–40 | 88% | **68%** |

Protection must preserve danger even for whales.

## 22.2 Candidate Paid Protection Prices

| Feed Range | Protect |
|---|---:|
| 1–5 | — |
| 6–10 | 9 R$ |
| 11–12 | 15 R$ |
| 13–15 | 29 R$ |
| 16–18 | 59 R$ |
| 19–20 | 99 R$ |
| 21–23 | 149 R$ |
| 24–25 | 199 R$ |
| 26–28 | 299 R$ |
| 29–30 | 499 R$ |
| 31–35 | 699 R$ |
| 36–40 | 999 R$ |

These are **candidate production prices** and require live economy simulation.

## 22.3 Earned Free Protection

Protection must not be perceived as a Robux-only survival mechanic. Active F2P players should have a limited but meaningful path to earn Protection through gameplay.

Current design direction:

- target roughly **1–3 earned Protection Tokens per active day**;
- Tokens are **bound to the account**;
- Tokens cannot be traded, sold, or converted into Money;
- suggested inventory cap: **10 Tokens**;
- earned and paid Protection have the same protection strength;
- paid Protection buys convenience, immediacy, and volume rather than exclusive power.

### Guardian Event — Candidate

A recurring event may appear roughly every **45–60 minutes** and stay active for approximately **5–8 minutes**.

Example objective:

```text
Guardian Event
0 / 100 Guardian Points
Reward: 1 Protection Token
```

Possible point sources:

| Activity | Example Points |
|---|---:|
| Collect Event Orb | +10 |
| Hatch an Egg | +15 |
| Successfully Feed a Pet | +20 |
| Complete Food objective | +20 |
| Complete special event objective | +30 |

One event should normally award at most **1 Token**. A daily event-earned cap around **2 Tokens** is a reasonable starting candidate.

### Daily Protection Contract — Candidate

A daily mission chain taking approximately **15–20 minutes** of normal play may award **1 Protection Token**.

The goal is to create a real F2P planning loop:

> “I have two Protections saved. Tonight I can try pushing my valuable pet.”

## 22.4 Monetization Principle

Free Protection is expected to support, not necessarily reduce, monetization. Players learn the value of Protection by using it. When free supply is exhausted during a high-value Feed push, paid Protection becomes understandable rather than mysterious.

Protection should normally be cheaper than failure recovery, but expensive enough that using it on every high-level Feed remains a meaningful decision.

# 23. Revive

When a pet explodes **and the 5% Miracle Save fails**, the player may receive an opportunity to Revive it.

## 23.1 Revive Rule

Revive restores the pet to the state immediately **before the failed
Feed**.

Example:

``` text
Pet: Lv.29
Attempt: Lv.29 → Lv.30
Result: Explosion
Revive purchased
Result after Revive: Lv.29
```

The player must attempt Feed again to reach Lv.30.

Food consumed by the failed attempt remains consumed.

Revive must never silently count the failed Feed as a success.

## 23.2 Candidate Revive Prices

    Feed Range      Revive
  ------------ -----------
          1--5       9 R\$
         6--10      29 R\$
        11--12      59 R\$
        13--15     129 R\$
        16--18     249 R\$
        19--20     499 R\$
        21--23     699 R\$
        24--25     999 R\$
        26--28   1,499 R\$
        29--30   1,999 R\$
        31--35   2,999 R\$
        36--40   4,999 R\$

These values are working candidates.

------------------------------------------------------------------------

# 24. Extreme Monetized Progression Target

The current balancing objective is that a player deliberately
brute-forcing **one pet toward Feed Lv.40** through repeated Revives
faces an expected premium cost on the order of:

**\~100,000 Robux**

A previous rough no-Protection calculation produced approximately:

**\~108,000 R\$**

For design-scale discussion, this was roughly treated as around
**35,000--40,000 THB**, depending on Robux purchase pricing/channel.

This does **not** include:

-   cost of obtaining the original rare pet;
-   Premium Eggs;
-   Luck;
-   Food acceleration;
-   Protection;
-   Variant/God Roll hunting;
-   other account progression.

The objective is not to force every Lv.40 owner to spend this amount.

A player may:

-   get extremely lucky;
-   use Critical Feed;
-   reach high Feed as F2P;
-   spend significantly less;
-   spend significantly more.

The number is an **expected monetization/balance target**, not a
guaranteed price for prestige.

------------------------------------------------------------------------

# 25. Revive Privacy and Prestige Integrity

Revive history must remain private.

Do **not** publicly display:

-   Revive Count;
-   `Revived ×17`;
-   Zero-Revive badge;
-   No-Revive leaderboard;
-   Revive history in Inspect;
-   Revive history in Trade UI.

The public identity of a pet should be based on:

-   Species;
-   Rarity;
-   Variant;
-   Traits;
-   Feed Level;
-   Rank;
-   Income.

A player viewing a Feed Lv.35 pet should see a Feed Lv.35 pet---not a
receipt of how much money the owner spent saving it.

Internal Revive data may still be logged for analytics and economy
balancing.

------------------------------------------------------------------------

# 26. Inventory

Required long-term inventory actions:

-   inspect;
-   place;
-   remove;
-   pick up;
-   lock;
-   sell;
-   sort;
-   search;
-   favorite (optional).

Suggested sort options:

-   Highest Feed
-   Highest Income
-   Rarity
-   Variant
-   Newest

Locked pets cannot be sold or traded.

------------------------------------------------------------------------

# 27. Pet Slots

The player has a limited number of active Pen slots.

Initial design reference:

**5 starting slots**

Additional slots may come from:

-   normal progression;
-   Money upgrades;
-   premium Gamepass;
-   future unlocks.

The slot limit creates optimization:

> Which pets are valuable enough to occupy the Pen?

------------------------------------------------------------------------

# 28. Pet Index

The Index supports collection-focused players.

Possible records:

-   Species discovered
-   Rarities discovered
-   Variants discovered
-   Highest Feed per species
-   Highest Feed ever
-   Best income
-   completion percentage

Index progression should provide long-term goals beyond Money/sec.

------------------------------------------------------------------------

# 29. Trading Strategy

Trading is planned, but **not for Prototype and not necessarily Day-1
Launch**.

Recommended rollout:

1.  Prototype: no Trading.
2.  Initial V1/soft launch: preferably no Trading.
3.  Observe real economy.
4.  Fix duplication/exploit risks.
5.  Add direct Pet-to-Pet Trading.
6.  Consider larger market systems only much later.

The reason for delaying Trade is data.

Before pets circulate freely, the developer should understand:

-   Mythic supply;
-   Variant supply;
-   Feed distribution;
-   high-level pet supply;
-   player income distribution;
-   exploit behavior;
-   duplication risk;
-   account progression speed.

------------------------------------------------------------------------

# 30. Future Direct Trading

First implementation should be direct Player-to-Player pet exchange.

Initial recommended rules:

-   Pet-to-Pet trading only;
-   no Money trading initially;
-   no Food trading initially;
-   locked pets cannot trade;
-   both players must own offered pets;
-   unique Pet IDs required;
-   server validates every offer;
-   server performs atomic exchange;
-   double confirmation;
-   trade cooldown;
-   internal Trade History;
-   minimum progression/playtime requirement.

Example:

``` text
PLAYER A
Mythic Celestial
Feed Lv.18

        ↕

PLAYER B
Legendary Rainbow Feed Lv.22
+ Mythic Normal Feed Lv.11
```

------------------------------------------------------------------------

# 31. External Secondary Markets

The game itself does not need to create, guarantee, price, or act as
middleman for external real-money pet transactions.

If communities independently assign perceived value to rare pets,
internal game balance should still be based on the Roblox economy and
game data.

Do not balance a Revive simply because an external community claims a
particular pet is worth a certain amount of real money.

Official game systems should focus on secure in-game ownership and
Trade.

------------------------------------------------------------------------

# 32. Leaderboards

Primary prestige leaderboard:

## Highest Feed

Secondary candidates:

-   Highest Income Pet
-   Total Income
-   Index Completion
-   Pets Hatched
-   Farm Power

Extreme milestones may trigger server announcements.

Example:

``` text
GLOBAL / SERVER EVENT
Sorayot's Celestial Dragon reached Feed Lv.35!
```

Global announcements should be reserved for genuinely rare achievements
to avoid notification spam.

------------------------------------------------------------------------

# 33. Monetization

Potential monetization categories:

## Permanent / Gamepass

-   2× Money
-   2× Food
-   Extra Pet Slots
-   Auto Farm
-   Lucky Eggs

## Consumable / Developer Product

-   Protection
-   Revive
-   Food Packs
-   Money Packs
-   Luck Boosts
-   Premium Eggs

## Future

-   Limited Eggs
-   Event content
-   cosmetic effects
-   premium hatch animations
-   cosmetic Pen themes

## Monetization Rule

Do not directly sell:

> Feed Lv.30

Instead sell:

-   faster acquisition;
-   more attempts;
-   resource acceleration;
-   risk reduction;
-   failure recovery.

Money can increase opportunity, but it should not directly certify
prestige.

## PolicyService Rule

The server queries `PolicyService:GetPolicyInfoForPlayerAsync()` once per player
session and caches the result. Paid-random-related offers require an explicit
`ArePaidRandomItemsRestricted == false`; restricted, loading, malformed and failed
responses fail closed. The client may present this status, but only the server
authorizes a prompt or applies an ongoing benefit.

This gate covers Money Packs, Welcome Treat Pack, x2 Money, Robux Food that
changes Feed probability, and Grow Now / Grow All. An owned x2 Money pass is
paused for a restricted or unverifiable session. Deterministic direct Revive,
Revive Charm and exact-stock Merchant Refill remain available. Earned Money and
Money-purchased Food remain the unpaid gameplay path; no guaranteed paid
alternative is offered.

An already-issued Developer Product receipt must still be fulfilled and recorded
idempotently; policy checks must never discard a charged receipt. Every new
monetization feature must be classified through the centralized policy service
before launch. Historical mixed Money balances predate source tracking, so their
Robux-versus-earned provenance cannot be reconstructed from the current save.

------------------------------------------------------------------------

# 34. Emotional Loop

Target emotional cycle:

``` text
See Desired Pet
↓
Hatch
↓
Rare Result
↓
Attachment
↓
Feed
↓
Success
↓
Growth
↓
"One More"
↓
Risk Increases
↓
Protection Decision
↓
Feed
↓
Critical / Success / Explosion
↓
If Explosion:
Revive or Accept Loss
↓
Continue / Rebuild
```

Important emotions:

-   anticipation;
-   greed;
-   attachment;
-   fear of loss;
-   relief;
-   regret;
-   pride;
-   envy/flex;
-   collection satisfaction.

------------------------------------------------------------------------

# 35. Social Design

Players should naturally want to inspect other Pens.

High Feed pets should be recognizable through:

-   size;
-   aura;
-   Feed label;
-   Rank;
-   rare Variant appearance.

A powerful Pen should function as a trophy room.

Future social features may include:

-   Inspect Player;
-   Inspect Pet;
-   server milestone announcements;
-   trading;
-   visit bonuses;
-   favorite pets.

------------------------------------------------------------------------

# 36. Economy Design Rules

All major systems are connected:

``` text
Egg Price
↕
Hatch Odds
↕
Base Income
↕
Farm Upgrade Cost
↕
Food/sec
↕
Feed Cost
↕
Feed Multiplier
↕
Explosion Risk
↕
Critical Feed
↕
Protection
↕
Revive
```

Changing one value can alter the value of several others.

Therefore final balancing should use simulation rather than intuition
alone.

## 36.1 Percentile-Based Balancing

Analyze at least:

-   median player;
-   P75;
-   P90;
-   P99;
-   P99.9;
-   P99.99;
-   extreme outliers.

Do not balance standard progression around the strongest observed
player.

------------------------------------------------------------------------

# 37. Analytics

Recommended events:

``` text
SessionStart
SessionEnd

EggPurchase
EggHatched
PetCreated
PetPlaced
PetRemoved
PetSold

FarmUpgrade
FoodGenerated
MoneyGenerated

FeedUIOpened
FeedAttempt
FeedProtected
FeedSuccess
FeedCritical
FeedExplosion
FeedLevelReached

ReviveOfferShown
RevivePurchased
ReviveDeclined
PetPermanentlyLost

DeveloperProductPrompted
DeveloperProductPurchased

InventoryOpened
PetInspected
```

For each Feed event, record internally where appropriate:

-   Feed level before;
-   Feed level after;
-   rarity;
-   variant;
-   explosion probability;
-   whether Protection was active;
-   Critical result;
-   Food cost;
-   current pet income.

Analytics must never rely on client claims for authoritative economic
values.

------------------------------------------------------------------------

# 38. Anti-Exploit Architecture

The server is authoritative.

The client must **never** decide:

-   Money awarded;
-   Food awarded;
-   hatch result;
-   rarity result;
-   Variant result;
-   Feed success;
-   Explosion;
-   Critical Feed;
-   Feed Level;
-   pet creation;
-   pet deletion;
-   Revive result;
-   Protection application;
-   Trade ownership.

## 38.1 Remote Validation

Every server Remote should validate:

-   player ownership;
-   argument types;
-   valid IDs;
-   state;
-   cooldown;
-   affordability;
-   transaction status.

## 38.2 Important Attack Cases

Test:

-   Remote spam;
-   duplicate purchase request;
-   fake PetId;
-   feeding another player's pet;
-   feeding while trading;
-   selling while feeding;
-   leaving during Feed;
-   leaving during Revive prompt;
-   reconnect after explosion;
-   duplicated receipt callbacks;
-   DataStore retry;
-   multiple servers loading same player state;
-   client changing displayed Money;
-   teleport/rejoin timing attacks.

------------------------------------------------------------------------

# 39. Persistence

Suggested player data:

``` lua
PlayerData = {
    DataVersion = 1,

    Money = 0,
    Food = 0,

    FarmLevel = 1,
    FarmPower = 1,

    MaxPetSlots = 5,

    Inventory = {},
    PlacedPetIds = {},

    PetIndex = {},
    Statistics = {},

    Settings = {}
}
```

Each pet should preserve at minimum:

``` text
PetId
SpeciesId
Rarity
Variant
Traits
FeedLevel
Locked
CreatedAt
```

Use migration/version logic from the beginning.

------------------------------------------------------------------------

# 40. Tutorial

Tutorial should teach through the real core loop.

1.  Buy first Egg.
2.  Hatch first Pet.
3.  Place Pet in Pen.
4.  Observe Money generation.
5.  Upgrade Farm.
6.  Observe Food generation.
7.  Pick up Pet.
8.  Carry Pet to Pedestal.
9.  Feed Pet.
10. Watch Pet grow and income increase.

The player should experience the core fantasy within the first few
minutes.

Early Feed attempts should not immediately punish the player with severe
Explosion probability.

------------------------------------------------------------------------

# 41. First-Session Experience

Desired first-session emotional sequence:

``` text
"I have a pet."
→
"My pet makes money."
→
"I can make Food."
→
"I can feed the pet."
→
"It got bigger!"
→
"It earns much more!"
→
"Wait... later it can explode?"
→
"How far should I push it?"
```

The game should reveal risk after the player understands and values
successful growth.

------------------------------------------------------------------------

# 42. PROTOTYPE DEFINITION

## 42.1 Prototype Objective

The Prototype exists to answer:

> **Is the Feed loop fun enough to justify building the full game?**

It is **not** intended to prove:

-   full content quantity;
-   final art quality;
-   final economy;
-   trading;
-   live events;
-   retention systems;
-   full monetization.

## 42.2 Prototype Core Question

Can the following loop create attachment and tension?

> **Hatch → Place → Earn → Farm → Feed → Grow → Risk → Explode/Survive**

If this is not fun, stop expanding content and improve the Feed loop
first.

------------------------------------------------------------------------

# 43. PROTOTYPE SCOPE --- MUST BUILD

## 43.1 One Functional Player Plot

Prototype Plot contains only:

-   spawn;
-   fenced Pen;
-   one Egg machine/stand;
-   one Farm;
-   one Feeding Pedestal.

No large world is required.

## 43.2 One Egg

Only one prototype Egg.

Contains six test pets.

Prototype hatch odds should be deliberately test-friendly so every
rarity can be tested quickly.

Do not use production Mythic odds during development.

## 43.3 Six Pets

Exactly one test species for each rarity:

1.  Common
2.  Uncommon
3.  Rare
4.  Epic
5.  Legendary
6.  Mythic

Use the locked base-income values.

Models may be temporary.

## 43.4 Inventory

Minimum prototype Inventory:

-   show owned pets;
-   display rarity;
-   display Feed Level;
-   display income;
-   select;
-   place;
-   remove;
-   pick up;
-   lock;
-   sell if needed for loop testing.

Search/favorites/advanced filters can wait.

## 43.5 Pet Placement

Placed pets:

-   appear in Pen;
-   wander simply;
-   generate Money;
-   retain individual identity;
-   can be removed/picked up.

## 43.6 Money

Implement:

``` text
BaseIncome × FeedMultiplier = PetIncome/sec
```

Only placed pets produce Money.

Money is server authoritative.

## 43.7 Farm

Prototype Farm requires:

-   Food/sec;
-   Farm Level;
-   Money upgrade cost;
-   upgrade button;
-   persistent state.

No farming minigame.

## 43.8 Food

Food HUD.

Server-authoritative generation.

Food consumed on Feed attempt.

## 43.9 Carry System

Player can:

-   choose pet;
-   pick it up;
-   visibly carry it;
-   take it to Pedestal;
-   place it on Pedestal.

This interaction is part of the game's identity and should not be
skipped in prototype.

## 43.10 Feeding Pedestal

Only one pet can occupy it.

Pedestal opens Feed UI showing at minimum:

``` text
Pet Name
Rarity
Current Feed
Current Income
Next Feed
Food Cost
Explosion Risk
Feed Button
Protected Feed option
```

## 43.11 Feed RNG

Implement server-side:

-   Explosion roll;
-   Critical roll after survival;
-   Feed increase;
-   multiplier update;
-   Food deduction;
-   pet destruction.

## 43.12 Feed Growth

Successful Feed visibly enlarges pet.

Prototype does not require perfect final scaling, but growth must be
obvious and satisfying.

## 43.13 Critical Feed

Implement the candidate Critical table.

Use debug configuration so odds can be changed quickly.

## 43.14 Explosion

Prototype Explosion requires:

-   anticipation;
-   VFX;
-   SFX;
-   pet disappearance;
-   failure UI;
-   permanent deletion if Revive is declined/expired.

## 43.15 Protection

Implement functional Protected Feed.

For prototype:

-   configurable price;
-   configurable risk reduction;
-   receipt validation;
-   one attempt only.

Protection is consumed/applied to the specific Feed attempt.

## 43.16 Revive

Implement Revive because it is part of the core monetization/emotional
test.

Requirements:

-   capture pre-attempt pet state safely;
-   explosion enters pending recovery state;
-   purchase restores pre-failure state;
-   failed Food remains spent;
-   Feed is not automatically retried;
-   decline permanently finalizes loss.

Prototype prices may be temporary/test prices.

## 43.17 Save/Load

Save:

-   Money;
-   Food;
-   Farm;
-   Inventory;
-   placed pets;
-   Feed Levels;
-   lock state.

Prototype must survive reconnect tests.

------------------------------------------------------------------------

# 44. PROTOTYPE DEBUG TOOLS

Development must include internal debug commands/UI.

Required debug capabilities:

-   Add Money
-   Add Food
-   Spawn pet by rarity/species
-   Set Feed Level
-   Force Feed Success
-   Force Explosion
-   Force Critical type
-   Set Explosion chance
-   Set Critical odds
-   Set Farm Level
-   clear player data
-   print pet state

These tools must be Studio/developer restricted and impossible for
normal production clients to invoke.

Debug tools are essential because manually grinding to Lv.40 during
development is unacceptable.

------------------------------------------------------------------------

# 45. PROTOTYPE CONFIGURATION

Balance values should be centralized.

Suggested modules:

``` text
GameConfig
PetConfig
EggConfig
FeedConfig
FarmConfig
MonetizationConfig
```

Do not scatter values such as `0.35`, `45000`, or `499` across scripts.

Example conceptual configuration:

``` lua
FeedConfig.ExplosionChance[level]
FeedConfig.Multiplier[level]
FeedConfig.CriticalResults
FeedConfig.FoodCost[level]
FeedConfig.Protection[level]
FeedConfig.RevivePrice[level]
```

This allows simulation and live balancing without rewriting core logic.

------------------------------------------------------------------------

# 46. PROTOTYPE ARCHITECTURE

Suggested server modules:

``` text
DataService
PetService
MoneyService
EggService
FarmService
FeedService
MonetizationService
PlotService
```

Suggested client controllers:

``` text
HUDController
InventoryController
EggController
FarmController
FeedController
CarryController
EffectsController
```

Suggested Remote organization:

``` text
Remotes/
    Egg/
    Inventory/
    Farm/
    Feed/
    Pet/
```

Exact names may change, but responsibilities should remain separated.

------------------------------------------------------------------------

# 47. PROTOTYPE DEVELOPMENT ORDER

## Phase 0 --- Project Foundation

-   folder architecture;
-   configuration modules;
-   Remote structure;
-   data schema;
-   logging conventions.

## Phase 1 --- Data

Build:

-   DataService;
-   default data;
-   migrations;
-   save/load;
-   Studio testing data;
-   session safety.

**Exit condition:** Money/Food/basic pet data survive rejoin.

## Phase 2 --- Pet Foundation

Build:

-   pet creation;
-   unique PetId;
-   inventory;
-   placement;
-   removal;
-   Pen ownership;
-   simple wandering.

**Exit condition:** six test pets can be spawned, stored, placed, and
reloaded correctly.

## Phase 3 --- Money

Build:

-   base income;
-   placed-pet income;
-   Money HUD;
-   server award loop.

**Exit condition:** placing/removing pets correctly changes Money/sec.

## Phase 4 --- Egg

Build:

-   Egg config;
-   purchase validation;
-   server RNG;
-   hatch result;
-   pet creation;
-   simple hatch presentation.

**Exit condition:** player can buy, hatch, receive, and place a pet.

## Phase 5 --- Farm

Build:

-   Food/sec;
-   Farm Level;
-   upgrade cost;
-   upgrade validation;
-   Farm UI.

**Exit condition:** Money can be converted into improved Food
production.

## Phase 6 --- Carry + Pedestal

Build:

-   pick up;
-   carry;
-   drop/return;
-   Pedestal ownership;
-   single-pet Pedestal state.

**Exit condition:** a real owned pet can be physically brought to Feed.

## Phase 7 --- Feed Core

Build:

-   Food cost;
-   Feed request;
-   Explosion probability;
-   success;
-   Feed Level;
-   multiplier;
-   income recalculation;
-   physical growth.

**Exit condition:** complete Feed loop works server-authoritatively.

## Phase 8 --- Critical Feed

Build:

-   Critical RNG;
-   multi-level skip;
-   no intermediate Explosion rolls;
-   Critical presentation.

**Exit condition:** +2/+3/+5 Feed gains work correctly.

## Phase 9 --- Explosion Juice

Build:

-   suspense timing;
-   explosion VFX;
-   sound;
-   pet removal;
-   loss state.

**Exit condition:** losing a pet feels clear and emotionally noticeable.

## Phase 10 --- Protection + Revive

Build:

-   Developer Products;
-   receipt processing;
-   protected Feed;
-   pending Revive;
-   restore state;
-   failure handling.

**Exit condition:** purchases cannot duplicate pets or apply twice.

## Phase 11 --- Multiplayer Safety

Test:

-   two or more players;
-   ownership;
-   Remote spam;
-   simultaneous interactions;
-   reconnect;
-   purchase callbacks;
-   exploit cases.

## Phase 12 --- Balance Simulation

Run large simulations including:

-   Explosion;
-   Critical;
-   Protection scenarios;
-   Revive scenarios.

Measure:

-   average terminal Feed;
-   probability of reaching 15/20/25/30/35/40;
-   expected attempts;
-   expected Food;
-   expected Robux for premium brute-force strategies.

## Phase 13 --- Playtest Decision

Only after core playtesting decide whether to expand to V1.

------------------------------------------------------------------------

# 48. PROTOTYPE --- DO NOT BUILD

Do not spend prototype time on:

-   Trading
-   Global Marketplace
-   3 final Eggs
-   all 18 final pets
-   multiple worlds
-   zones
-   clans
-   PvP
-   Merge
-   Breeding
-   Daily Rewards
-   Battle Pass
-   quests
-   full Index
-   global leaderboards
-   limited events
-   complex Traits
-   final Celestial/Rainbow economy
-   Offline Income
-   elaborate cosmetics
-   final Rank VFX
-   huge map
-   expensive final models
-   complex NPC systems

These systems do not answer whether the core Feed loop works.

------------------------------------------------------------------------

# 49. PROTOTYPE SUCCESS METRICS

Prototype should be judged by behavior, not feature count.

## 49.1 Comprehension

Can a new tester understand:

**Pet → Money → Farm → Food → Feed**

without a long explanation?

## 49.2 Greed

After a successful Feed, does the tester want to Feed again?

## 49.3 Fear

At meaningful risk levels, does the tester hesitate before pressing
Feed?

## 49.4 Attachment

Does losing a pet create genuine disappointment?

## 49.5 Growth Satisfaction

Does successful growth feel visually and economically meaningful?

## 49.6 Critical Excitement

Does Critical Feed create a memorable positive moment?

## 49.7 Monetization Intent

When a valuable pet explodes, does Protection/Revive feel understandable
and valuable rather than arbitrary?

## 49.8 Replay Desire

After losing a pet, does the tester want to rebuild rather than quit
immediately?

If these metrics fail, improve the core loop before adding content.

------------------------------------------------------------------------

# 50. V1 AFTER PROTOTYPE

Once the prototype proves the core mechanic, expand toward launch.

Recommended V1 additions:

-   3 Eggs;
-   18 polished pets;
-   finalized hatch pools;
-   Variant system;
-   polished Farm progression;
-   finalized Food costs;
-   finalized Egg prices;
-   Pet Index;
-   Feed Ranks;
-   more Pet Slots;
-   Gamepasses;
-   proper tutorial;
-   improved plot visuals;
-   social inspection;
-   leaderboards;
-   audio polish;
-   mobile/controller UX;
-   analytics;
-   anti-exploit hardening;
-   economy simulation;
-   live-ops configuration.

Trading should still be considered separately after observing the
initial live economy.

------------------------------------------------------------------------

# 51. POST-LAUNCH ROADMAP

Possible order:

## Update A --- Economy / Content Expansion

-   additional pets;
-   additional Egg;
-   Farm expansion;
-   new Variant content.

## Update B --- Trading

-   direct Pet-to-Pet Trade;
-   Trade History;
-   account/progression requirement;
-   anti-dupe validation.

## Update C --- Collection

-   deeper Index;
-   collection rewards;
-   rare visual milestones.

## Update D --- Limited Content

-   limited Eggs;
-   seasonal pets;
-   event cosmetics.

## Update E --- Social Prestige

-   stronger inspect;
-   rare Feed announcements;
-   Pen customization;
-   community milestones.

Actual roadmap should respond to live player behavior rather than being
permanently fixed before launch.

------------------------------------------------------------------------

# 52. Balance Status

## LOCKED / CURRENT CORE DIRECTION

- Core loop: Egg → Pet → Money → Farm → Food → Feed
- Money and Food as primary currencies
- Personal Pen
- one Feeding Pedestal
- physical Carry-to-Feed interaction
- Feed can destroy pet
- player may stop at any Feed Level
- Explosion rolled before Critical
- Critical skips levels without extra Explosion rolls
- base incomes: 10 / 150 / 500 / 3K / 10K / 45K
- Feed Multiplier v0.2 through Lv.40
- target natural mature/average pet around Lv.12
- Feed rarity controlled statistically
- physical pet size capped practically, progression continues
- **Feed Food Cost scales by Feed Level and moderately by Rarity**
- **Variant/Traits do not increase Feed Food Cost**
- Protection reduces risk but never guarantees
- **Protection can be earned through gameplay as well as purchased**
- **earned Protection has the same gameplay strength as paid Protection**
- earned Protection is bound/non-tradable
- Revive restores pre-failure state
- failed Food remains consumed
- Revive history is private
- no public Zero-Revive prestige
- extreme Lv.40 monetized progression target around 100K R$ expected order of magnitude
- Trading planned after economy validation
- Prototype focuses only on validating core Feed loop
- F2P remains possible but progression intentionally becomes grindy enough that acceleration is attractive
- long incubation on rare/special Eggs may create return timing without making payment mandatory

## ECONOMY v0.4 CURRENT CANDIDATE DIRECTION

- 3 launch Eggs / 18 pets
- candidate Egg prices: **5K / 2M / 500M**
- candidate normal Egg incubation: **10 sec / 2 min / 12 min**
- Farm candidate: **15 meaningful levels**, 2 Food/s → 5M Food/s
- Feed Food base costs: 30 at Lv.1 → 2.3B at Lv.40
- Rarity Food multipliers: **1.00 / 1.15 / 1.35 / 1.65 / 2.00 / 2.50**
- candidate post-Lv.20 Explosion: **55% / 64% / 76% / 88%** by five-level bands
- historical, retired Critical candidate: natural mean terminal Feed ≈ **12.18** (not recalculated for the 2026-10-01 rule)
- natural Lv.30 ≈ **1 in 48K**
- natural Lv.35 ≈ **1 in 16.7M**
- natural Lv.40 ≈ **1 in 34B**
- active F2P target: roughly **1–3 earned Protection Tokens/day**
- suggested earned Protection inventory cap: **10**

## BALANCE CANDIDATES / NOT FINAL

- exact Critical odds
- exact Egg odds
- exact Mythic probability
- final Egg prices
- final Farm prices and output
- final Feed Food costs
- final Rarity Food multipliers
- Variant odds
- Trait system
- Variant/Trait multipliers
- exact Protection event cadence/objectives
- exact free Protection daily cap
- Protection reduction curve
- final Protection Robux prices
- final Revive Robux prices
- Food Production Boost ladder/prices
- Rank thresholds
- maximum active Pet Slots
- offline progression
- levels above Feed 40

# 53. Final Design Statement

The central fantasy of **Feed Your Pet** is not simply owning the rarest
pet.

It is owning a pet that became valuable, surviving the temptation to
risk it, and eventually choosing how far to push it.

A new player should celebrate Feed Lv.10--12.

A committed player should respect Feed Lv.20.

Feed Lv.25 should attract attention.

Feed Lv.30 should be a serious flex.

Feed Lv.35 should be something a server remembers.

Feed Lv.40 should be capable of becoming a community story.

The game's defining question remains:

> **How far are you willing to push something you do not want to lose?**

------------------------------------------------------------------------

# 54. AI Agent / Codex Implementation Directive

When implementing this GDD:

1.  **Do not invent major gameplay systems that are not specified.**
2.  **Do not implement Post-Launch features during Prototype.**
3.  **Keep all economy/RNG values configurable.**
4.  **Never trust the client for authoritative state.**
5.  **Prefer modular services over giant scripts.**
6.  **Every individual pet must preserve a unique server-authoritative
    identity.**
7.  **Feed must be transaction-safe before visual polish is added.**
8.  **Revive and Developer Product receipt handling must be
    idempotent.**
9.  **Do not permanently delete an exploded pet until the recovery state
    is resolved safely.**
10. **Do not expose internal Revive Count publicly.**
11. **Critical Feed is rolled only after Explosion survival.**
12. **Skipped Critical levels do not receive intermediate Explosion
    rolls.**
13. **Do not hard-code production balance values throughout scripts.**
14. **Build debug tools before manually grinding high Feed Levels.**
15. **Prototype priority is gameplay feel, correctness, persistence, and
    exploit resistance---not content quantity.**

------------------------------------------------------------------------

# 55. Monetization Pressure and Retention Timing

## 55.1 Soft Monetization Pressure

Feed Your Pet should not copy the economy numbers of other Roblox games directly. The intended lesson is the **shape of player pressure**, not the exact prices, timers, or multipliers.

The desired experience is:

- F2P remains fully playable.
- F2P progression should become intentionally grindy enough that acceleration feels attractive.
- Small purchases should create an obvious improvement in pacing.
- Medium spenders should progress substantially faster but should not instantly finish progression.
- High spenders can create more attempts and protect valuable progression, but cannot directly purchase Feed prestige.

Target emotional response:

> “I can keep playing for free, but spending a little would make this much easier.”

Avoid a hard paywall. Also avoid stacking every pain point at maximum severity simultaneously. Food scarcity, Egg scarcity, Explosion risk, and Revive cost should not all become punishing at the same progression point.

Pressure should shift over the player lifecycle:

```text
Early Game  → generous progression; teach and create attachment
Mid Game    → Food/time pressure makes acceleration attractive
Late Game   → valuable pets make Protection and Revive increasingly meaningful
Extreme     → God Rolls + Feed prestige + risk become the primary chase
```

## 55.2 Egg Incubation as a Return Loop

Rare and special Eggs may use long incubation timers to create anticipation and a natural reason to return to the game.

Reference design direction, **not locked balance**:

- special/Premium Egg opportunities can appear intermittently rather than always being available;
- a rough exploration range is one opportunity every **10–30 minutes**;
- valuable Eggs may require long incubation, potentially up to roughly **2 hours** for high-value categories;
- exact spawn intervals and incubation times must be balanced specifically for Feed Your Pet.

The desired loop is:

```text
Rare Egg Opportunity Appears
        ↓
Player Obtains Egg
        ↓
Start Incubation
        ↓
Continue Playing or Leave
        ↓
Egg Becomes Ready Later
        ↓
Player Has a Concrete Reason to Return
        ↓
Hatch → New Pet → Feed Loop Continues
```

The timer should create anticipation, not merely inconvenience. Long timers are most appropriate when the Egg itself feels sufficiently valuable.

Potential future monetization may include incubation acceleration or convenience, but exact skip prices, speed multipliers, and whether a full instant-hatch option should exist are **not locked**. These must be tested against retention and player sentiment.

### Design Principle

> **Waiting should create a future appointment with the game. Paying should improve convenience, not be the only reasonable way to participate.**



------------------------------------------------------------------------

# 56. v0.4 Change Log

This revision incorporates the latest connected-economy direction:

- added Egg economy candidate progression;
- replaced the softer post-Lv.20 Explosion candidate with a harsher statistical-ceiling curve;
- added natural Feed distribution including Critical Feed;
- changed Farm direction to 15 meaningful levels;
- added full Base Feed Food Cost curve through Lv.40;
- added **Rarity-based Food Cost multipliers**;
- explicitly excluded Variant/Traits from Food Cost scaling;
- added **earned/free Protection Tokens**;
- added Guardian Event and Daily Protection Contract candidates;
- clarified that earned and paid Protection have identical gameplay strength;
- preserved soft monetization pressure and rare-Egg incubation return-loop principles.

**End of GDD v0.4**
