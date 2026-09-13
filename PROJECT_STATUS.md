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

The versioned, server-authoritative data foundation is implemented. The immediate
priority is verifying live DataStore rejoin behavior, then building pet identity.

## 2. Overall Progress

| System | Status | Notes |
| --- | --- | --- |
| Project Setup | ✅ Complete / Verified | Filesystem layout, toolchain, build, and server launch verified. |
| Git Setup | ✅ Complete / Verified | `main` tracks `origin/main`; initial commit pushed successfully. |
| Rojo Setup | ✅ Complete / Verified | Live Studio sync and server/client bootstrap verified. |
| Base Architecture | 🟨 In Progress | Client/server/shared roots and the first server service exist. |
| Player Data Schema | ✅ Complete / Verified | Version 1 defaults, validation, cloning, and migration boundary implemented. |
| DataService | 🟦 Implemented / Needs Testing | Studio runtime verified; live DataStore rejoin test remains. |
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
| Save / Load | 🟦 Implemented / Needs Testing | Memory-mode flow verified; production backend remains untested. |
| Debug Tools | ⬜ Not Started | |
| Core Loop Playtest | ⬜ Not Started | |

Status legend: ⬜ Not Started · 🟨 In Progress · 🟦 Implemented / Needs Testing · ✅ Complete / Verified · ❌ Blocked

## 3. Current Feature

**Current Feature:** Session-Safe DataService

**Status:** 🟦 Implemented / Needs Testing

**Objective:** Load and save the v1 schema through atomic updates with retry,
autosave, shutdown saving, isolated Studio data, and single-session ownership.

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
- Added centralized production/Studio store names, retry policy, autosave interval,
  session lease timeout, acquisition policy, and shutdown timeout in `DataConfig`.
- Added a DataStore adapter with bounded exponential retry and jitter.
- Studio defaults to process-local memory data; optional Studio persistence uses a
  separate test DataStore and cannot write to the production store name.
- Added `DataService` with atomic `UpdateAsync` load/migrate/session acquisition.
- Added unique per-load lease tokens, heartbeat refresh, stale-lock takeover, and
  fail-closed handling for active foreign sessions or malformed/future records.
- Added validated snapshots, serialized per-player save operations, 60-second
  autosave, final PlayerRemoving save/release, and concurrent shutdown saving.
- Added an idempotent last-session marker so a retried release can recognize a
  prior successful write even when the first response was ambiguous.
- The server now starts `DataService` from the Rojo-managed bootstrap.

## 5. In Progress

- Production DataStore persistence and cross-server session behavior still need
  an end-to-end test in a published test server or Studio with API access enabled.
- Data schema migrations beyond v1 will be added only when the schema version changes.

## 6. Next Tasks

1. Enable API access only in a dedicated Studio/test experience and set
   `UseDataStoreInStudio = true`, or use a published private test server.
2. Verify Money/Food/default data survive rejoin without duplication or loss.
3. Verify simultaneous joins reject an active lease and stale leases recover.
4. Implement server-authoritative Pet creation and unique `PetId` generation.

## 7. Files Modified This Session

```text
src/server/Data/DataStoreAdapter.luau
src/server/Services/DataService.luau
src/server/init.server.luau
src/shared/Config/DataConfig.luau
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
- One stored record owns both player data and its optional session lease so load,
  migration, lock acquisition, saves, and releases remain atomic under `UpdateAsync`.
- A lease is owned by both a server ID and a unique per-load session ID. Saves
  fail closed and disconnect the player if this server no longer owns that lease.
- Autosaves refresh the lease heartbeat every 60 seconds; a foreign lease becomes
  reclaimable after 180 seconds without a heartbeat.
- `LastSessionId` makes release idempotent after an unknown DataStore write result.
- Save operations for one player are serialized to prevent autosave, leave, and
  shutdown handlers from racing each other.

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

**Persistence:** Implemented; Studio memory flow verified, live backend test pending

Stored records use wrapper version 1:

```text
RecordVersion, Data, Session, LastSessionId, LastSavedAt
```

The optional session lease stores:

```text
ServerId, SessionId, PlaceId, AcquiredAt, HeartbeatAt
```

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
- PASS — Rojo synchronized `DataConfig`, `DataStoreAdapter`, and `DataService` into Studio.
- PASS — Studio syntax analysis reported no errors in the bootstrap or new modules.
- PASS — Studio memory adapter preserves copy isolation across writes.
- PASS — Studio memory adapter update and cancelled-update behavior passed.
- PASS — One-player Studio run started DataService in isolated memory mode and loaded v1 defaults.
- PASS — Final Rojo build succeeds with DataService and `git diff --check` is clean.
- NOT RUN — Production DataStore rejoin and cross-server lease contention tests.

## 15. Last Known Working State

No playable prototype state has been established. Git, Rojo, MCP, the bootstrap,
schema v1, and Studio DataService flow are working. Live DataStore behavior still
needs a dedicated backend test before persistence is marked fully verified.

## 16. Last Working Git Commit

**Commit:** `bcd0e02`

**Message:** `feat: implement session-safe player persistence`

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

Implemented the DataStore adapter, DataService, server bootstrap, isolated Studio
test mode, retries, atomic session leases, autosave, leave saving, and shutdown saving.
Verified schema/module syntax, memory adapter semantics, Rojo build, and a one-player load.

### What Is Currently Incomplete

Live DataStore rejoin testing, cross-server lease contention testing, and pet creation.

### Next Agent Should

1. Read `AGENTS.md`, this file, and relevant GDD sections.
2. Run `git status` and `git diff`.
3. Do not point Studio at production data. Use the isolated Studio store only in a
   dedicated test experience when API access is enabled.
4. Test live save/rejoin and active/stale lease behavior before marking persistence verified.
5. Then implement server-authoritative Pet creation with immutable `PetId` values.
