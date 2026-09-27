# AGENTS.md

# Feed Your Pet — AI Agent Instructions

This repository contains the Roblox game **Feed Your Pet**.

The game is currently in the **Prototype / Pre-Production phase**.

The primary objective is NOT to build the full game.

The primary objective is to determine whether the core loop is fun:

**Hatch → Place → Earn → Farm → Feed → Grow → Risk → Explode / Survive**

All agents working in this repository must follow the rules below.

---

# 1. Source of Truth

The primary game design reference is:

`Feed_Your_Pet_GDD_v0.5.md`

The current implementation/handoff state is:

`PROJECT_STATUS.md`

Before implementing or significantly modifying any system:

1. Read this `AGENTS.md`.
2. Read `PROJECT_STATUS.md`.
3. Read the relevant section of `Feed_Your_Pet_GDD_v0.5.md`.
4. Run `git status`.
5. Run `git diff`.
6. Inspect the existing implementation.
7. Inspect Roblox Studio through MCP when relevant.
8. Determine what is already complete and what remains.

Do not assume unfinished work is incorrect.

Do not recreate a system simply because another Codex session implemented it.

If the implementation and GDD disagree, do not silently invent a new design.

Prefer the GDD unless the developer has explicitly given a newer instruction.

---

# 2. PROJECT_STATUS.md — Required Handoff

`PROJECT_STATUS.md` is the shared handoff document between Codex sessions and accounts.

Every agent MUST read it before making changes.

Every agent MUST update it before ending a meaningful work session.

## Before Starting Work

1. Read `PROJECT_STATUS.md`.
2. Read the relevant GDD sections.
3. Run `git status`.
4. Run `git diff`.
5. Inspect existing files.
6. Inspect Studio through MCP if relevant.
7. Determine the exact current state.
8. Continue from existing work.

## During Work

Keep track of:

* what was completed;
* what is currently being implemented;
* important architectural decisions;
* files changed;
* bugs discovered;
* incomplete work;
* tests performed.

If the current task changes significantly, update `PROJECT_STATUS.md` when appropriate.

## Before Ending Work

Update `PROJECT_STATUS.md` with:

* Current Feature;
* Overall Progress;
* Completed work;
* In Progress work;
* Next Task;
* Files Modified;
* Known Issues / Blockers;
* Architecture Notes if changed;
* Last Working Commit if applicable;
* Session Handoff.

Do not claim something is complete unless it has actually been implemented and reasonably verified.

If work stops halfway because of a usage limit, error, interruption, or other reason, record the exact unfinished state so another agent can continue safely.

---

# 3. Current Development Goal

The current goal is to build and validate the **Prototype**.

The prototype exists to answer:

> Is the Feed loop fun enough to justify building the full game?

Prioritize:

* gameplay feel;
* Feed tension;
* pet attachment;
* satisfying growth;
* transaction correctness;
* persistence;
* server authority;
* exploit resistance;
* fast iteration.

Do NOT prioritize content quantity.

---

# 4. Prototype Scope

Required prototype systems include:

* one functional Player Plot;
* one fenced Pet Pen;
* one Egg machine;
* one prototype Egg;
* six test pets;
* Inventory;
* Pet Placement;
* simple pet wandering;
* Money generation;
* Farm;
* Food generation;
* Carry system;
* Feeding Pedestal;
* Feed UI;
* Feed RNG;
* Critical Feed;
* visible pet growth;
* Explosion;
* Protection;
* Revive;
* Save / Load;
* internal Debug Tools.

Temporary models and placeholder art are acceptable during Prototype.

---

# 5. DO NOT BUILD During Prototype

Do not implement the following unless explicitly requested by the developer:

* Trading;
* Global Marketplace;
* all final Eggs;
* all final pets;
* multiple worlds;
* zones;
* clans;
* PvP;
* Merge;
* Breeding;
* Battle Pass;
* large quest systems;
* full Pet Index;
* global leaderboards;
* limited events;
* complex Traits;
* final Variant economy;
* Offline Income;
* elaborate cosmetics;
* huge maps;
* complex NPC systems;
* expensive final assets.

Do not expand scope because a feature "would be cool."

Prototype features must help validate the Feed loop.

---

# 6. Core Game Identity

The central player decision is:

> Do I keep this valuable pet now, or risk feeding it one more time?

The emotional loop is:

**Acquire → Attach → Improve → Risk → Survive → Greed → Risk Again → Explode or Become Legendary**

Do not remove meaningful risk from Feed progression.

The player must explicitly choose when to risk a valuable pet.

---

# 7. Feed Rules

Feed is the most important gameplay system.

The server must resolve Feed transactions safely and according to the GDD.

Important rules:

* Explosion is rolled before Critical Feed.
* Critical Feed is rolled only after Explosion survival.
* Critical-skipped levels do not receive intermediate Explosion rolls.
* Food is consumed on the Feed attempt.
* Feed Level and income are server authoritative.
* Protection applies only to the relevant Feed attempt.
* Revive restores the pre-failure state.
* Failed Food remains consumed after Revive.

Do not change the Feed order or probability behavior without checking the GDD and receiving explicit instruction when the design is ambiguous.

Feed must be transaction-safe before visual polish is prioritized.

---

# 8. Server Authority

The server is authoritative.

The client must NEVER decide:

* Money awarded;
* Food awarded;
* hatch result;
* rarity result;
* Variant result;
* Traits;
* Feed success;
* Explosion;
* Critical Feed;
* Feed Level;
* pet creation;
* pet deletion;
* Protection;
* Revive;
* ownership.

The client may request actions and display results.

The server validates and performs authoritative actions.

Never trust client-provided economy values.

---

# 9. Remote Validation

Every important Remote must validate relevant conditions including:

* player ownership;
* argument types;
* valid IDs;
* current state;
* cooldown;
* affordability;
* transaction state.

Consider attack/error cases such as:

* Remote spam;
* duplicate requests;
* fake PetId;
* feeding another player's pet;
* selling during Feed;
* leaving during Feed;
* leaving during Revive;
* reconnecting after Explosion;
* duplicate Developer Product receipts;
* DataStore retries;
* multiple server state;
* fake client currency values.

---

# 10. Pet Identity

Every pet must preserve a unique server-authoritative identity.

Every individual pet requires a unique `PetId`.

Important pet data includes at minimum:

* PetId;
* SpeciesId;
* Rarity;
* Variant;
* Traits;
* FeedLevel;
* Locked;
* CreatedAt.

Do not identify pets only by species or inventory position.

Do not regenerate IDs when loading existing pets.

Never duplicate pets during:

* save/load;
* placement;
* removal;
* Feed;
* Revive;
* reconnect;
* error recovery.

---

# 11. Persistence Safety

Player data must support migration/versioning from the beginning.

Important persisted state includes:

* Money;
* Food;
* Farm state;
* Inventory;
* placed pets;
* Feed Levels;
* lock state.

Reconnects must not duplicate, delete, reset, or incorrectly restore pets.

Be especially careful around:

* Feed transactions;
* Explosion;
* pending Revive;
* Developer Product receipts;
* server shutdown;
* player leaving;
* reconnect;
* DataStore retries.

---

# 12. Revive Safety

Do not permanently delete an exploded pet until recovery state is safely resolved.

An exploded pet eligible for Revive should enter a safe pending recovery state.

Revive restores the pre-failure state.

Revive must NOT automatically retry the failed Feed.

Failed Food remains consumed.

Developer Product receipt handling must be idempotent.

Processing the same receipt multiple times must never duplicate:

* pets;
* currency;
* Protection;
* Revive;
* rewards.

---

# 13. Economy Configuration

Do not scatter balance values throughout scripts.

Balance values must be centralized in configuration modules.

Preferred structure:

```text
GameConfig
PetConfig
EggConfig
FeedConfig
FarmConfig
MonetizationConfig
```

Example:

```lua
FeedConfig.ExplosionChance[level]
FeedConfig.Multiplier[level]
FeedConfig.CriticalResults
FeedConfig.FoodCost[level]
FeedConfig.Protection[level]
FeedConfig.RevivePrice[level]
```

Core gameplay code should consume configuration values rather than hard-code production balance.

---

# 14. Architecture

Prefer small modular services over giant scripts.

Suggested server responsibilities:

```text
DataService
PetService
EggService
MoneyService
FarmService
FeedService
MonetizationService
PlotService
```

Suggested client controllers:

```text
HUDController
InventoryController
EggController
FarmController
FeedController
CarryController
EffectsController
```

Exact names may change when justified.

Responsibilities should remain separated.

Avoid unnecessary circular dependencies.

---

# 15. Rojo Rules

Luau source managed by Rojo must be edited in the filesystem.

Preferred workflow:

```text
Codex
  ↓
Filesystem / src
  ↓
Rojo
  ↓
Roblox Studio
```

Before editing a Script, determine whether it is Rojo-managed.

If it is Rojo-managed:

1. edit the filesystem source;
2. let Rojo synchronize it into Studio.

Do not use Studio/MCP as the primary source editor for Rojo-managed scripts.

Do not create two competing sources of truth for the same Script.

---

# 16. Roblox Studio / MCP Rules

MCP may be used for:

* inspecting Roblox Studio;
* reading Explorer hierarchy;
* creating/configuring Instances;
* constructing prototype environment elements;
* inspecting properties;
* running Play tests;
* reading runtime state;
* checking Output/errors;
* testing gameplay;
* inspecting visual behavior.

Prefer filesystem/Rojo for source code.

Prefer Studio/MCP for:

* world Instances;
* visual setup;
* runtime inspection;
* testing;
* debugging.

Never allow multiple agents to modify the same Studio state simultaneously.

---

# 17. Git Rules

Git is the project history and recovery system.

Before significant implementation:

```bash
git status
git diff
```

Understand existing uncommitted changes before modifying them.

Never automatically:

* reset;
* clean;
* discard changes;
* checkout over changes;
* force push;
* delete branches;
* revert another agent's work

without understanding the state and receiving permission when destructive.

Do not assume uncommitted changes belong to the current agent.

Commit logical working units.

Owner preference (2026-09-23): commit completed, verified changes at the end of
each implementation session without asking again. Include the handoff update;
preserve unrelated user changes. Do not push unless requested.

Current design supersedes historical Farm/Protection guidance below and in the
GDD: Food is purchased from the Money merchant; AFK farms, Tokens, consumable
Protection and feed-plate upgrades are retired. Plot capacity upgrades and
the feeding pedestal remain active. Legacy save fields are compatibility only.

Good examples:

```text
feat: add server-authoritative feed transaction
feat: implement pet placement
feat: add prototype farm generation
fix: prevent duplicate revive processing
fix: preserve pet identity after reconnect
```

Avoid meaningless commit messages such as:

```text
update
stuff
changes
fix
```

---

# 18. Agent Handoff Rules

Another Codex session/account may continue from the same repository.

Therefore:

**Filesystem + Git + PROJECT_STATUS.md are more trustworthy than chat memory.**

When continuing existing work:

1. Read `AGENTS.md`.
2. Read `PROJECT_STATUS.md`.
3. Read relevant GDD sections.
4. Run `git status`.
5. Run `git diff`.
6. Inspect existing implementation.
7. Inspect Studio/MCP if relevant.
8. Determine completed work.
9. Determine incomplete work.
10. Continue from the current state.

Never restart an implementation simply because the previous agent stopped midway.

Never overwrite unfinished work without inspecting it first.

If previous chat context conflicts with the actual repository state, inspect the repository and resolve the discrepancy before proceeding.

---

# 19. Debug Tools

Prototype development should include developer-only debugging tools.

Required/useful capabilities include:

* Add Money;
* Add Food;
* Spawn pet by rarity/species;
* Set Feed Level;
* Force Feed Success;
* Force Explosion;
* Force Critical result;
* Set Explosion chance;
* Set Critical odds;
* Set Farm Level;
* Clear player test data;
* Print pet state.

Debug functionality must be Studio/developer restricted.

Normal production players must never be able to invoke developer debug functions.

Do not manually grind to high Feed Levels during development.

---

# 20. Feed Presentation

Feed must feel satisfying and tense.

Prioritize:

* anticipation;
* clear risk information;
* satisfying successful Feed;
* obvious pet growth;
* meaningful income increase;
* Critical Feed excitement;
* impactful Explosion;
* clear failure feedback.

Gameplay results must be determined authoritatively by the server.

Visual effects must represent the result rather than secretly determine it.

Correctness comes before polish.

---

# 21. Prototype Validation

Evaluate the Prototype through player behavior rather than feature count.

Important questions:

## Comprehension

Can a new player understand:

**Pet → Money → Farm → Food → Feed**

without a long explanation?

## Greed

After Feed succeeds, does the player want to Feed again?

## Fear

At meaningful Explosion risk, does the player hesitate?

## Attachment

Does losing a valuable pet create genuine disappointment?

## Growth Satisfaction

Does Feed progression feel visually and economically meaningful?

## Critical Excitement

Does Critical Feed create a memorable positive moment?

## Monetization Understanding

Does Protection / Revive feel understandable and valuable rather than arbitrary?

## Replay Desire

After losing a pet, does the player want to rebuild rather than quit?

If these fail, improve the core Feed loop.

Do not solve core-loop problems by adding unrelated content.

---

# 22. Code Quality

Prefer:

* Luau type annotations where useful;
* clear names;
* small modules;
* explicit state transitions;
* centralized configuration;
* defensive validation;
* server-authoritative logic;
* reusable helpers;
* understandable code.

Avoid:

* giant monolithic scripts;
* duplicated logic;
* magic numbers;
* deeply nested event chains;
* unnecessary global mutable state;
* client-authoritative economy;
* unnecessary abstractions.

Comments should explain WHY when behavior is not obvious.

Do not comment every line.

---

# 23. When Unsure

If multiple reasonable implementation approaches exist:

1. choose the simplest approach compatible with the GDD;
2. preserve server authority;
3. preserve pet identity;
4. preserve transaction safety;
5. keep balance configurable;
6. keep Prototype scope small;
7. prefer implementations that are easy to test and debug.

Do not invent major gameplay systems to solve implementation uncertainty.

---

# 24. Priority Order

When tradeoffs are required, prioritize:

1. Data correctness
2. Transaction safety
3. No duplication / item loss
4. Server authority
5. Core Feed gameplay
6. Persistence
7. Player understanding
8. Gameplay feel
9. Debuggability
10. Performance
11. Visual polish
12. Additional content

---

# 25. Final Rule

Owner preference (2026-09-24): For every requested pet model, create it,
verify its geometry and rig, inspect it visually in Studio from useful angles,
and remodel/recheck visible issues until the model looks cohesive and readable.
Do not declare a model complete from structural checks alone. If visual
verification is blocked, report that limitation explicitly.

Owner preference (2026-09-27): Use as few parts as practical for every pet
model. Do not deliver models built from thousands of individual parts.
Prefer reusable meshes or consolidated geometry, report final BasePart counts,
and verify the saved geometry and rig. Set a low part budget before building;
do not equate low instance count with low triangle count or proven runtime FPS.

The purpose of this Prototype is not to prove how much content can be built.

The purpose is to prove that this decision is fun:

> **"I love this pet. Do I stop now, or risk one more Feed?"**

Every major Prototype feature should help answer that question.
