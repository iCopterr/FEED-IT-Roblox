# Wall Runner Simulator — AI Agent Instructions

## 1. Purpose and source of truth

This project is a Roblox **Collection / Auto-run / Pet Simulator / Incremental
Progression** game in the Concept / MVP phase, not a completed production game.

Primary design reference: `Wall_Runner_Simulator_GDD_v0.1_EN.md`.
Implementation and handoff reference: `PROJECT_STATUS.md`.

Place this file and the GDD in the Wall Runner project root. This file is not
intended to replace another game's agent instructions.

Before significant implementation:

1. Read this file and the latest explicit owner instructions.
2. Read `PROJECT_STATUS.md` and the relevant GDD sections.
3. Run `git status` and `git diff`.
4. Inspect existing source, configuration, tests, and relevant Studio state.
5. Identify what is implemented, unfinished, or blocked before changing it.

If no handoff exists, create one after inspecting the actual project. Do not
infer a completed implementation from the GDD. Do not recreate existing systems
because another agent wrote them or stopped midway.

The latest explicit owner decision may supersede the GDD. Otherwise follow the
GDD. Explain unresolved conflicts and ask before changing a core mechanic.
All GDD prices, timers, counts, speeds, and pacing targets are prototype
assumptions, not validated results. Keep them configurable.

## 2. Core identity and priorities

**Collect Power → Run → Break Walls → Earn Trophies → Hatch / Equip Pets →
Collect Faster → Run Farther → Rebirth / Unlock Worlds**

The prototype should answer:

> Does collecting and upgrading make the next run visibly more satisfying?

Prioritize, in order:

1. Data correctness and no loss or duplication.
2. Transaction safety and server authority.
3. Reliable collection, running, and rewards.
4. Persistence and recovery.
5. Clear progression and mobile usability.
6. Gameplay feel and performance.
7. Visual polish.
8. Additional content.

Do not solve a weak core loop by adding unrelated systems. Use placeholder art
until collection, impacts, progress, and rewards are understandable and fun.

## 3. MVP scope and development order

Approved MVP scope:

- Two worlds, ten walls per world.
- Per-player Power pickups, automatic runs, rewards, and New Best feedback.
- Four eggs and sixteen species, with single-egg opening.
- Pet inventory, three equipped pets, Equip Best, Unequip, Lock, and confirmed Delete.
- Rebirth and permanent world unlocks.
- Tutorial, settings, persistence, and responsive mobile/PC/tablet UI.

Implement in stages:

1. Greybox World 1: pickup → run → reward.
2. Pet loop: egg → equip → verified increase in pickup gains.
3. Progression: Rebirth → World 2 through configuration.
4. Persistence hardening: reconnects and duplicate-safe transactions.
5. Tutorial, effects, audio, and mobile polish.
6. Closed playtest and measured balance iteration before public release.

Design schema, identity, and transaction boundaries from the first stage; the
later persistence milestone is not permission to build unsafe early systems.
MVP content quantity is a ceiling for the planned scope, not a requirement to
build all final art before testing the loop.

Do not add trading, PvP, Power theft, clans, fusion, shiny variants, battle
passes, daily streaks, collectible buffs, magnets, paid luck/RNG, Trophy sales,
World 3, or other post-MVP features without explicit owner approval. Do not set
Robux prices or implement proposed monetization merely because it appears in
the GDD's future-options section.

## 4. Power and pickup rules

Power is accumulated capability. **Running does not spend or reset Power.**
Do not mix a consumable-Power economy into the MVP.

Use the configured formula:

```text
PetGain = 1 + sum(bonuses of equipped individual pets)
RebirthGain = 1 + 0.5 * RebirthCount
PowerGain = max(1, floor(BasePickup * WorldGain * PetGain * RebirthGain * TemporaryBoost))
```

- Pet bonuses stack additively, not multiplicatively. Display `+50%`, not `x1.5`.
- WorldGain is 1 for World 1 and 5 for World 2; TemporaryBoost is 1 in the MVP.
- Example: Base 1, two +50% pets, World 1, and one Rebirth yield 3 Power.
- Every pickup location has a stable ID and a server-validated collection area.
- Cooldown/visibility is per player. Two players may collect the same location
  independently; do not destroy the shared pickup for everybody.
- Respawn is configured within the GDD's initial 3–5 second range; start with
  40–60 locations per world arranged into readable walking loops.
- Validate loaded profile, world access, pickup ID, character distance, cooldown,
  run state, and request rate. Never accept a client-provided gain amount.
- Flat icons are presentation only. Logic must not read an image to identify
  a pickup. Do not award pickup Power while the player is running.

## 5. Run state machine and authoritative progress

```text
Idle → Starting → Running → Result → Returning → Idle
```

- Entering a pad shows Run / Back; confirmation is required.
- The server creates a unique run ID and snapshots starting Power.
- Use a one-second countdown, automatic straight-line movement, and no steering.
- Start at 24 studs/second and increase through configuration, capped initially
  at 40 studs/second. Wall spacing starts around 30 studs.
- Pickups, egg opening, and Rebirth are unavailable during a run. Validate the
  relevant state on the server, not only by hiding buttons.
- Each wall passes when `StartingPower >= RequiredPower`; exact equality passes.
- Starting Power, rather than changing live Power or client animation, determines
  eligibility throughout that run.
- The server validates sequential wall progress, plausible position/timing, and
  active run identity. Client-owned character physics is not proof of a wall pass.
- Never accept `WallsPassed`, distance, rewards, or a finish claim as authoritative.
- Players have independent lanes or individually rendered wall outcomes. One
  player's break effects must not remove another player's wall requirement.
- Other players, following pets, and fragments must not obstruct a run.

Failure, finish, or an early Return resolves the active run once. Result UI shows
walls/distance, Trophies, and New Best where applicable, with Run Again and Return
to Lobby. Both actions must safely re-enter the existing state machine; repeated
button presses cannot start overlapping runs or pay twice.

## 6. Wall configuration and reward correctness

World 1 initial balance:

| Wall | Required Power | Additional Trophies |
| --- | ---: | ---: |
| 1 | 10 | 5 |
| 2 | 25 | 8 |
| 3 | 60 | 12 |
| 4 | 120 | 20 |
| 5 | 250 | 30 |
| 6 | 500 | 45 |
| 7 | 1,000 | 65 |
| 8 | 2,000 | 90 |
| 9 | 4,000 | 120 |
| 10 | 8,000 | 180 |

`RunReward` is the sum of rewards for walls passed in that run, with no extra
finish bonus. Runs have no entry fee. Failure before wall 1 pays zero and
explains that more Power is needed.

**Unresolved GDD inconsistency:** the table above totals **575 Trophies**, but
the GDD prose states **675** for a full clear. Ask the owner which is intended
before finalizing payout balance. Do not silently add 100 as a finish bonus or
change a wall reward. Once resolved, keep configuration, documentation, and
tests consistent with the approved total.

- Authoritative reward and payout state must be duplicate-safe per run ID.
- Reject forged, stale, foreign, and already-settled run requests.
- Update balances, records, and applicable lifetime statistics consistently.
- Disconnect cancels an unpaid run. Do not resume or retroactively pay an unpaid
  run on reconnect without a new design instruction.
- A retry must never re-award an already committed payout. Coordinate profile
  session ownership and payout state, including ambiguous save failures.
- Never use a client effect finishing or a screen closing as a payout trigger.

## 7. Egg and pet rules

World 1 initial eggs:

| Egg | Trophy cost | Species: chance / pickup bonus |
| --- | ---: | --- |
| Starter | 50 | Pup: 60% / +50%; Bunny: 30% / +100%; Fox: 9% / +200%; Phoenix: 1% / +500% |
| Forest | 300 | Deer: 60% / +200%; Bear: 30% / +350%; Owl: 9% / +600%; Spirit: 1% / +1,000% |

- Display odds before opening and verify each distribution totals 100%.
- The server validates funds, capacity, world access, state, and cooldown, then
  deducts cost, rolls the result, and adds the pet as one safe transaction.
- Reject insufficient funds/full inventory before any deduction. Starting pet
  capacity is 100; equip limit is 3.
- Each pet has a unique stable instance ID. Preserve it on save/load. Use stable
  species IDs, not display names, as configuration keys.
- Duplicate species are allowed; the same individual pet cannot be equipped twice.
- Equipment changes validate ownership, uniqueness, limits, and current state.
- Equip Best uses configured bonuses of owned pets. Keep ties deterministic;
  clarify any ambiguous locked-pet behavior rather than silently changing it.
- Locked pets cannot be deleted. Require confirmation before deletion, and keep
  equipment references consistent when an unlocked equipped pet is deleted.
- RNG is server-authoritative; hatch animation presents the selected result.
- Species names are placeholders. Create original designs rather than copying
  reference-game assets. Do not invent unspecified World 2 species, odds, or
  bonuses as approved final design; propose them for owner review.

## 8. Rebirth and world progression

```text
RebirthCost = ceil(2000 * 2^RebirthCount)
```

- Rebirth requires lobby state, sufficient Trophies, and explicit confirmation.
- Show the reset losses and new bonus before confirmation.
- Cost is an eligibility threshold: **all Power and Trophies reset to 0**.
  Do not subtract only the cost and preserve a surplus.
- Increase RebirthCount once. Preserve pets, equipment, personal records, and
  unlocked worlds. Validate and commit the reset as one transaction.
- Current counts 0, 1, and 2 require 2,000, 4,000, and 8,000 Trophies respectively.
- Guard exponential costs and balances against nonfinite/unsafe numeric values;
  do not silently introduce a gameplay cap to hide an overflow.

World 1 starts unlocked. World 2 unlocks permanently after previously passing
World 1 wall 10 and reaching at least one Rebirth. Entry is free.

- World 2: pickup multiplier 5, wall requirements 20 times World 1, wall rewards
  5 times World 1. Initial egg price proposals are 1,000 and 5,000 Trophies.
- Power and Trophies are shared across worlds; BestWall is tracked per world.
- Unlocked worlds survive Rebirth. Check authoritative eligibility for portal
  travel, collections, runs, and eggs; client UI access is not sufficient.

## 9. Tutorial, UI, audio, and presentation

Onboarding: collect 10 Power → first run / wall 1 → one-time 45 Trophy tutorial
bonus → Starter Egg → Equip Best → show wall 3 / Rebirth / World 2 goals.

- The first wall gives 5; the tutorial bonus gives 45. Together they fund one
  Starter Egg. Do not grant a second run reward or an extra starter egg.
- Tutorial progress and the claim flag persist. Server-validated prerequisites
  and duplicate-safe claiming prevent repeated bonuses after reconnects.
- HUD shows Power, Trophies, Rebirth, gain per pickup, and Pets/Eggs/Worlds/Settings.
- Use text with icons, not color-only meaning. Support touch, mouse, and tablet.
- Test safe areas, screen sizes, readable rewards, scrolling, and touch targets.
  Do not overlap Roblox's jump control or interrupt runs with shop popups.
- During runs, display the next wall and its required Power clearly.
- Settings include music, SFX, camera shake, reduced VFX, and Hide Other Pets.
- Wall fragments are client presentation, nonblocking, and expire in 1–2 seconds.
  Limit effects; respect reduced VFX and camera shake settings.
- Pet following is client-side presentation and cannot push characters.
- Preserve owner-authored UI where applicable. Do not use Roblox UI Director
  unless the owner explicitly reverses the earlier preference.

## 10. Architecture, configuration, and persistence

Prefer small services: profile adapter, PickupService, game RunService,
RewardService, EggService, PetService, RebirthService, WorldService, and
AnalyticsService. Distinguish the game run module from Roblox's engine RunService.
Clients handle UI, following pets, audio, and effects only.

Centralize static values in `WorldConfig`, `WallConfig`, `EggConfig`, `PetConfig`,
and `BalanceConfig`. Do not scatter balance values through gameplay scripts.

Persistent data must support at least:

```text
SchemaVersion, Power, Trophies, RebirthCount, UnlockedWorlds,
BestWalls per world, individual Pets and lock state, EquippedPetIds,
TutorialStep, TutorialRewardClaimed, LifetimeTrophies, Settings
```

- Use migrations, session locking, autosave, save-on-leave, and shutdown saving.
- Loading failure must not overwrite an existing save with an empty profile.
  Disable spending and progression transactions until loading succeeds.
- Preserve pet IDs and references. Validate saved types, finite balances, and
  configuration IDs; handle invalid data explicitly rather than losing items.
- Serialize conflicting transactions and test repeated remote requests, retries,
  session conflicts, disconnects, and committed-but-unacknowledged saves.
- Avoid circular dependencies, duplicated logic, magic numbers, and giant scripts.
  Use defensive validation, useful Luau types, and comments explaining why.

## 11. Filesystem, Rojo, Studio, and Git workflow

- Inspect the project mapping before assuming Rojo manages a script. If managed,
  edit repository source and let Rojo sync it; do not edit a competing Studio copy.
- Use MCP for relevant hierarchy/world inspection, Instance setup, gameplay tests,
  runtime state, Output, and visual verification.
- Reuse existing appropriate Instances; avoid duplicate same-name remotes.
- Only one agent may modify Studio state at a time. Do not delegate work unless
  the owner or applicable project instructions authorize it.
- Preserve unrelated user edits and assets. Do not use destructive reset/clean,
  checkout-over-changes, force pushes, or broad deletions without authorization.
- Build small logical changes, verify them, update the handoff, and commit them
  with meaningful messages. Standing owner preference: commit verified changes
  without asking again; do not push or publish unless requested.
- Use isolated/memory test profiles where possible. Tests do not authorize real
  purchases, production data changes, or unrestricted debug tools.

For requested pet models, establish a low part budget, verify saved geometry and
rigs, inspect useful Studio angles, and refine visible issues before declaring
completion. Prefer meshes/consolidated geometry; report BasePart counts. Part
count alone does not prove triangle count or FPS. If visual verification is
blocked, report that explicitly.

## 12. Required verification and playtest measures

Test the relevant cases before declaring a feature complete:

- Pickup minimum/flooring, additive bonuses, cooldowns, distance validation,
  world checks, and per-player independence.
- Power exactly equal to a wall requirement passes; one below does not.
- Starting Power is unchanged after a run; a full-clear reward equals the sum of
  the approved wall table, after resolving the 575-versus-675 GDD discrepancy.
- Zero progress, early Return, finish, Run Again, spam, stale IDs, and reconnect
  cannot duplicate payouts or start overlapping runs.
- Egg odds total 100%; insufficient funds/full capacity never deduct cost.
- Forged equipment/deletion requests fail; locks, pet IDs, and equip limits hold.
- Rebirth clears both balances, preserves the correct data, and cannot repeat
  through duplicate requests.
- World 2 gates, permanent unlocks, per-world records, and configured scaling work.
- Tutorial bonus cannot replay; saves restore balances, pets, equipment, and worlds.
- Two players can collect and run simultaneously without interfering.
- Syntax/build checks and nearby regression tests pass.
- Mobile UI and effects are visually inspected; aim for approximately 30 FPS or
  better on target mobile devices with eight concurrent players. Measure actual
  devices; desktop emulation and low part counts are not proof of this target.

Analytics events: `tutorial_step`, aggregated `pickup_collected`, `run_start`,
`run_end`, `egg_open`, `pet_equipped`, `rebirth`, `world_unlock`, `session_end`.
Avoid emitting an expensive analytics event for every visual effect/pickup tick.

Measure first run, first egg, tutorial completion, runs per session, time between
New Best records, Rebirth timing, and exit points. Initial diagnostic targets:
first run within 60 seconds, first egg within 3 minutes, first Rebirth around
15–25 minutes. D1/D7 require enough real data; do not promise retention or revenue.

Future paid random items require checking current Roblox odds-display and
account/regional policy requirements before implementation. The GDD and these
instructions do not certify platform compliance.

## 13. Required session handoff

Before ending meaningful work, update `PROJECT_STATUS.md` with:

- Current Feature and Overall Progress.
- Completed work and exact In Progress state.
- Next Task.
- Files Modified.
- Known Issues / Blockers and unverified behavior.
- Architecture decisions and design changes, if any.
- Last Working Commit / baseline.
- Session Handoff, tests performed, and how to resume safely.

Do not claim a feature is complete from syntax checks alone. Separate code
implementation, functional verification, visual review, target-device performance,
and published/live verification. If interrupted, record the exact unfinished state.

When unsure, prefer the simplest testable approach that preserves the GDD,
server authority, identity, and transaction safety. Ask for decisions such as
unspecified World 2 content or monetization rather than inventing final values.

**Final rule:** every major feature should strengthen the feeling that collecting
and improving pets makes the next wall-breaking run noticeably better.
