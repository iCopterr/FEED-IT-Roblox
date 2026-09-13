# Feed Your Pet — Project Status

**Phase:** Prototype

**Design Reference:** `Feed_Your_Pet_GDD_v0.5.md`

**Last Updated:** 2026-09-14

> This file is the current-state handoff between Codex sessions. Update it
> before ending a meaningful development session. Do not mark a feature
> complete unless it has been implemented and reasonably verified.

---

## 1. Current Goal

Build a playable prototype that validates:

**Hatch → Place → Earn → Farm → Feed → Grow → Risk → Explode / Survive**

The immediate priority is establishing the versioned, server-authoritative data foundation.

## 2. Overall Progress

| System | Status | Notes |
| --- | --- | --- |
| Project Setup | ✅ Complete / Verified | Filesystem layout, toolchain, build, and server launch verified. |
| Git Setup | ✅ Complete / Verified | `main` tracks `origin/main`; initial commit pushed successfully. |
| Rojo Setup | ✅ Complete / Verified | Live Studio sync and server/client bootstrap verified. |
| Base Architecture | 🟨 In Progress | Client/server/shared roots exist; gameplay modules not started. |
| Player Data Schema | ✅ Complete / Verified | Version 1 defaults, validation, cloning, and migration boundary implemented. |
| DataService | ⬜ Not Started | |
| Plot System | ⬜ Not Started | |
| Egg System | ⬜ Not Started | |
| Pet Identity | ⬜ Not Started | |
| Inventory | ⬜ Not Started | |
| Pet Placement | ⬜ Not Started | |
| Pet Wandering | ⬜ Not Started | |
| Money Generation | ⬜ Not Started | |
| Farm | ⬜ Not Started | |
| Food | ⬜ Not Started | |
| Carry System | ⬜ Not Started | |
| Feeding Pedestal | ⬜ Not Started | |
| Feed UI | ⬜ Not Started | |
| Feed Transaction | ⬜ Not Started | |
| Explosion RNG | ⬜ Not Started | |
| Critical Feed | ⬜ Not Started | |
| Pet Growth | ⬜ Not Started | |
| Explosion Presentation | ⬜ Not Started | |
| Protection | ⬜ Not Started | |
| Revive | ⬜ Not Started | |
| Save / Load | ⬜ Not Started | |
| Debug Tools | ⬜ Not Started | |
| Core Loop Playtest | ⬜ Not Started | |

Status legend: ⬜ Not Started · 🟨 In Progress · 🟦 Implemented / Needs Testing · ✅ Complete / Verified · ❌ Blocked

## 3. Current Feature

**Current Feature:** Versioned Player-Data Schema

**Status:** ✅ Complete / Verified

**Objective:** Define a safe v1 player-data contract with centralized defaults,
immutable pet identity, placement consistency, validation, and explicit migrations.

## 4. Completed

- Initialized a local Git repository using the `main` branch.
- Configured `origin` as `https://github.com/iCopterr/FEED-IT-Roblox.git`.
- Added a pinned Rojo toolchain definition and Rojo project file.
- Added minimal client, server, and shared source roots.
- Documented the Studio/Rojo ownership boundary and sequential-account workflow.
- Added repository ignore and line-ending rules.
- Installed Rokit 1.2.0 and the project-pinned Rojo 7.7.0.
- Installed the Rojo 7 Studio plugin for the current Windows user.
- Built `build/FeedYourPet.rbxlx` and launched the server on port 34872.
- Committed the foundation as `282e2d9` and pushed `main` to GitHub.
- Connected Roblox Studio MCP on port 58741 and identified the published place.
- Verified Rojo synchronized the client, server, and shared filesystem roots.
- Verified both bootstrap scripts execute in a one-player Studio test.
- Added centralized v1 player and pet data versions/defaults in `GameConfig`.
- Added a server-only `PlayerDataSchema` with typed player/pet contracts.
- Added strict validation for identity, placement slots, serializable settings,
  currencies, farm state, traits, statistics, and collection shapes.
- Added isolated default construction, deep cloning, and an explicit migration pipeline.
- Rejects unversioned, corrupt, or future-version data rather than silently rewriting it.

## 5. In Progress

- Phase 0 service initialization and logging conventions remain.
- `DataService`, DataStore persistence, session locking, and migrations beyond v1 are not implemented.

## 6. Next Tasks

1. Establish the smallest useful server-service bootstrap and logging convention.
2. Implement `DataService` around `PlayerDataSchema` with Studio-safe test data.
3. Add DataStore retries, autosave, shutdown saves, and session safety.
4. Verify Money/Food/default data survive rejoin without duplication or loss.
5. Implement server-authoritative Pet creation and unique `PetId` generation.

## 7. Files Modified This Session

```text
src/server/Data/PlayerDataSchema.luau
src/shared/Config/GameConfig.luau
PROJECT_STATUS.md
```

## 8. Current Uncommitted Work

None.

## 9. Known Issues / Blockers

- Studio Output contains unrelated RigEdit Plus outdated/plugin-icon warnings.
- Studio also reported a Game Settings SecurityPage JSON secrets parse warning.

These warnings do not block Rojo, MCP, or prototype development.

## 10. Architecture Notes

Planned server services:

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

Planned client controllers:

```text
HUDController
InventoryController
EggController
FarmController
FeedController
CarryController
EffectsController
```

Create modules only when they gain a real responsibility. Do not generate empty
architecture merely to fill these lists.

Data architecture decisions:

- `PlayerDataSchema` is server-only; clients do not own or validate authoritative data.
- `Inventory` is a dictionary keyed by immutable `PetId`, never by array position.
- `PlacedPetIds` is a set, cross-validated with each pet's `Placed` and `PlotSlot` fields.
- Plot slots must be unique and within `MaxPetSlots`.
- Loaded current-version data is validated and cloned before use.
- New schema versions require an explicit migration function; future versions fail closed.

## 11. Rojo / Studio State

**Rojo:** Rokit 1.2.0 and pinned Rojo 7.7.0 installed; build and serve verified.

**Studio Plugin:** Installed at `%LOCALAPPDATA%/Roblox/Plugins/RojoManagedPlugin.rbxm`.

**Studio Place:** `FeedYourPet`, place ID `127663486570625`, game ID `10766377691`.

**Studio Connection:** Rojo live sync verified on `localhost:34872`.

**MCP Connection:** Global `robloxstudio` MCP entry uses
`npx -y robloxstudio-mcp@latest` with `ROBLOX_STUDIO_PORT=58741`. A new Codex
task successfully reached the bridge, which reports server version 2.6.0. The
Studio Edit peer is connected and tool calls are verified.

Ownership boundary:

- `src/` contains filesystem/Rojo-managed code.
- The Roblox place contains Studio-managed world Instances.
- `default.project.json` intentionally maps only code roots, preventing two
  sources of truth for the prototype world.

## 12. Data / Persistence State

**DataVersion:** Player v1; Pet v1

**Persistence:** Not implemented

Current v1 player fields:

```text
DataVersion, Money, Food, FarmLevel, FarmPower, MaxPetSlots,
Inventory, PlacedPetIds, PetIndex, Statistics, Settings
```

Each v1 pet preserves:

```text
DataVersion, PetId, SpeciesId, EggId, Rarity, Variant, Traits,
FeedLevel, BaseIncome, Locked, Placed, PlotSlot, CreatedAt
```

## 13. Current Feed Implementation

**Status:** Not implemented

Required authoritative resolution order remains:

```text
Food validation → Food deduction → Protection → Explosion roll
→ Explosion / survival → Critical roll after survival → Feed Level update
→ Income update → Visual growth → Persistence
```

## 14. Tests Performed

- PASS — Confirmed the GitHub remote exists and was empty before local initialization.
- PASS — `rojo build` generated `build/FeedYourPet.rbxlx` (2,054 bytes).
- PASS — `rojo serve` listened on `localhost:34872`.
- PASS — Matching Rojo Studio plugin file installed for the Windows user.
- INFO — Studio MCP `get_place_info` timed out because the Studio-side plugin
  was not running/activated.
- PASS — Diagnosed stale MCP listener on port 58742 and pinned the launcher to
  Studio's expected port 58741.
- PASS — MCP health endpoint reports a live v2.6.0 server on port 58741.
- PASS — Installed the official v2.6.0 release plugin asset for Studio.
- PASS — MCP discovered one active Studio Edit instance and read place metadata.
- PASS — Studio contains Rojo-managed `Server`, `Client`, and `Shared` roots with matching source.
- PASS — One-player test printed server and client prototype startup messages.
- PASS — Playtest stopped and Studio returned to Edit mode.
- PASS — Studio syntax analysis reported no errors in `GameConfig` or `PlayerDataSchema`.
- PASS — Fresh defaults use independent nested tables.
- PASS — A valid PetId-keyed placed pet passes schema validation.
- PASS — Migration returns an isolated copy, including copied pet and trait tables.
- PASS — Placement inconsistency and unsupported future data versions are rejected.
- PASS — Rojo build succeeds with the v1 schema (14,584-byte test place).
- PASS — Commit `282e2d9` pushed to `origin/main` and upstream tracking configured.
- PASS — Fresh clone at `a656390` built successfully with Rojo (1,907-byte test place).

## 15. Last Known Working State

No playable prototype state has been established. Git, Rojo, MCP, the bootstrap,
and player-data schema v1 are verified. The project is ready for `DataService`.

## 16. Last Working Git Commit

**Commit:** `82525a0`

**Message:** `feat: add versioned player data schema`

## 17. Important Decisions

- Prototype scope only; GDD v0.5 remains the design source of truth.
- Server-authoritative gameplay and persistent unique Pet IDs remain mandatory.
- Rojo-managed source is edited only in `src/`.
- The prototype world remains Studio-owned unless an explicit future migration
  places selected Instances under Rojo.
- Rojo is pinned with Rokit so sequential Codex sessions share one version.
- Git and `PROJECT_STATUS.md` are the cross-session recovery and handoff system.
- Only one Codex account or Studio editing session operates on this working copy
  at a time.

## 18. Session Handoff

### What Was Done

Verified MCP and Rojo live synchronization against the published Studio place.
Confirmed the synchronized server and client bootstrap scripts run successfully.
Implemented and behaviorally verified the versioned player-data schema v1.

### What Is Currently Incomplete

Server-service initialization, logging conventions, and persistent `DataService`.

### Next Agent Should

1. Read `AGENTS.md`, this file, and relevant GDD sections.
2. Run `git status` and `git diff`.
3. Build `DataService` on the existing schema; do not recreate or loosen it.
4. Keep gameplay server-authoritative and balance values configurable.
5. Continue editing Rojo-managed scripts only through the filesystem.
