# Feed Your Pet — Project Status

**Phase:** Prototype

**Design Reference:** `Feed_Your_Pet_GDD_v0.5.md`

**Last Updated:** 2026-09-15

> This file is the current-state handoff between Codex sessions. Update it
> before ending a meaningful development session. Do not mark a feature
> complete unless it has been implemented and reasonably verified.

---

## 1. Current Goal

Build a playable prototype that validates:

**Hatch → Place → Earn → Farm → Feed → Grow → Risk → Explode / Survive**

The versioned data foundation and server-side pet foundation are implemented.
PetService mutations now pass a real Studio server integration test. The next
priority is pet placement and Pen ownership.

## 2. Overall Progress

| System | Status | Notes |
| --- | --- | --- |
| Project Setup | ✅ Complete / Verified | Filesystem layout, toolchain, build, and server launch verified. |
| Git Setup | ✅ Complete / Verified | `main` tracks `origin/main`; initial commit pushed successfully. |
| Rojo Setup | ✅ Complete / Verified | Live Studio sync and server/client bootstrap verified. |
| Base Architecture | 🟨 In Progress | DataService and PetService now exist; remaining gameplay services are pending. |
| Player Data Schema | ✅ Complete / Verified | Version 1 defaults, validation, cloning, and migration boundary implemented. |
| DataService | 🟦 Implemented / Needs Testing | Studio runtime verified; live DataStore rejoin test remains. |
| Plot System | ⬜ Not Started | |
| Egg System | ⬜ Not Started | |
| Pet Identity | ✅ Complete / Verified | Creation, unique GUIDs, lock/unlock and removal passed in Studio; live persistence remains pending. |
| Inventory | 🟨 In Progress | Stud inventory UI, selection/details, and server-validated lock requests implemented; live verification and placement pending. |
| HUD | 🟦 Implemented / Needs Testing | Money/Food snapshots, responsive Stud layout, loading/empty states; Studio constructor verified, live test pending. |
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

**Current Feature:** StarterGui Stud HUD and Inventory UI

**Status:** 🟦 Implemented / Needs Testing

**Objective:** Expose the existing pet foundation through a Stud-themed currency
HUD and inventory with inspection, selection, and authoritative locking.

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
- Added `PetConfig` with exactly one prototype species for each rarity and the
  GDD-locked base-income anchors: 10, 150, 500, 3,000, 10,000, and 45,000.
- Added `PetService` with server-generated GUID `PetId` values and authoritative
  species, Egg, rarity, Variant, traits, Feed Level, income, lock, placement, and timestamps.
- Added defensive GUID collision checks and full `PlayerDataSchema` validation
  with rollback after every pet mutation.
- Added snapshot-returning pet/inventory reads so callers cannot mutate identity
  through returned values.
- Added lock changes and conservative permanent removal: locked or placed pets
  cannot be removed, and Explosion is explicitly reserved for pending recovery.
- Added server-only PetAdded, PetRemoved, and PetChanged events.
- The server bootstrap now starts `PetService` after `DataService`.

## 5. In Progress

- Production DataStore persistence and cross-server session behavior still need
  an end-to-end test in a published test server or Studio with API access enabled.
- Data schema migrations beyond v1 will be added only when the schema version changes.
- PetService creation, unique IDs, snapshot isolation, lock/unlock and removal
  passed 15 real Studio server integration checks through MCP.

## 6. Next Tasks

1. PetService mutation checks passed; verify HUD integration separately.
2. Implement `PlotService` and server-authoritative pet placement/pickup with five slots.
3. Add simple prototype pet spawning/wandering in the Studio-owned Pen.
4. Verify pet identity, placement, Feed Level, and lock state survive a real DataStore rejoin.

## 7. Files Modified This Session

```text
src/ui/FeedYourPetUI.rbxmx
default.project.json
src/client/Controllers/HUDController.luau
src/client/UI/Stud.luau
src/client/init.client.luau
src/server/Services/UIService.luau
src/server/init.server.luau
src/shared/Config/UIConfig.luau
PROJECT_STATUS.md
```

## 8. Current Uncommitted Work

UI changes are being committed as one logical unit. Concurrent verification
work (including PetVerification.server.luau) is separate and is not staged by
the UI session.

## 9. Known Issues / Blockers

**Pet verification blocker resolved:** direct MCP on port 58742 can launch
StudioTestService:ExecutePlayModeAsync("PetVerification") from Edit. The opt-in
server test returns results through EndTest; no server MCP peer is needed.
Connection failures below are historical; UI runtime tests remain separate.

- Latest port retry (2026-09-15): user redirected to localhost:58742.
  Direct MCP at /mcp reaches the correct place's Edit peer and accepts
  start_playtest(play, numPlayers=1), but no server peer registers.
  A read-only execute_luau(target=server) timed out; repeated instance
  discovery still shows only Edit. Stop was requested afterward.
  Pet mutation tests remain NOT RUN. Next: start a Studio server test and
  connect its server-side MCP plugin to port 58742. No Computer Use used.
- Follow-up after reconnect (2026-09-15): port 58741 is connected to one Edit
  peer. This task's built-in MCP tool reaches an empty bridge; five listeners
  exist on ports 58741-58745. Direct MCP JSON-RPC at localhost:58741/mcp works.
  The connected place is 127663486570625 and Studio memory mode is enabled.
  `start_playtest` reports "A test is already running", but no server/client
  peer is available. `stop_playtest` and RunService:Stop() did not clear that
  condition. Manual Studio test stop/plugin reconnect is needed before retry.
  Creation/ID/lock/removal checks remain NOT RUN; no gameplay source changed.
- Latest verification attempt (2026-09-15): MCP tools are available, but
  `get_connected_instances` returned zero instances and `execute_luau` timed
  out waiting for the Studio plugin. Studio is running. Reconnect its MCP
  plugin before retrying creation, unique ID, lock/unlock, and removal tests.
  No pet mutations ran; no Computer Use was used. This attempt changed only
  PROJECT_STATUS.md. Untracked UI files appeared during the session and were
  left untouched.
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

Pet architecture decisions:

- `PetService` exists only under `ServerScriptService`; clients cannot create,
  delete, lock, or choose authoritative pet results.
- `PetConfig` defines six placeholder prototype species and may be replaced with
  final species later without changing persistent pet identity rules.
- `CreatePet` derives all authoritative fields from configuration; callers provide
  only a known server-side `SpeciesId`.
- `GetPet` and `GetInventory` return deep pet snapshots, including cloned Traits.
- `PetIndex` records discovery and remains true after a pet leaves the inventory.
- Ordinary removal rejects locked and placed pets. Explosion must not call this
  path; it will use the future pending-recovery/Revive transaction.

## 11. Rojo / Studio State

**Rojo:** Rokit 1.2.0 and pinned Rojo 7.7.0 installed; build and serve verified.

**Studio Plugin:** Installed at `%LOCALAPPDATA%/Roblox/Plugins/RojoManagedPlugin.rbxm`.

**Studio Place:** `FeedYourPet`, place ID `127663486570625`, game ID `10766377691`.

**Studio Connection:** Rojo live sync verified on `localhost:34872`.

**MCP Connection:** Global `robloxstudio` MCP entry uses
`npx -y robloxstudio-mcp@latest` with `ROBLOX_STUDIO_PORT=58741`. A new Codex
task successfully reached the bridge, which reports server version 2.6.0. The
Studio Edit peer was previously verified. The latest attempt reports zero
connected instances; runtime verification is currently blocked (see section 9).

Ownership boundary:

- `src/` contains filesystem/Rojo-managed code.
- The Roblox place contains Studio-managed world Instances.
- `default.project.json` maps code roots plus the StarterGui UI model.
  The prototype world remains Studio-owned.
- `StarterGui.FeedYourPetUI` was authored using MCP and exported to
  `src/ui/FeedYourPetUI.rbxmx` for Rojo/Git persistence. Re-export Studio UI
  edits to this model before a filesystem resync; Rojo sync is not a reverse export.

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
- PASS — `PetConfig` contains exactly six species, one per rarity, with locked base incomes.
- PASS — All six configured prototype pet shapes pass `PlayerDataSchema.ValidatePet`.
- PASS — Rojo synchronized `PetConfig` and `PetService`; Studio syntax analysis found no errors.
- PASS — One-player Studio startup loaded data and started PetService with six species.
- PASS — Final PetService Rojo build succeeds and `git diff --check` is clean.
- PASS — All 15 PetVerification server checks: same-species unique GUIDs,
  creation defaults, create/read/inventory snapshot isolation, lock, repeated
  lock, locked removal rejection, unlock, successful removal, duplicate removal
  rejection, other-pet preservation, unknown species rejection, invalid lock
  type rejection, and final player schema validation. Memory mode asserted.

## 15. Last Known Working State

No playable prototype state has been established. Git, Rojo, the bootstrap,
schema v1, DataService, and the server-side pet foundation are implemented.
Pet mutation integration tests pass; live DataStore tests remain pending.

## 16. Last Working Git Commit

**Commit:** `5ca59a0`

**Message:** `feat: add server-authoritative pet foundation`

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

### Pet Verification — 2026-09-15

- Added src/server/PetVerification.server.luau, gated by IsStudio and explicit
  StudioTestService test arguments. No service implementation changes.
- All 15 checks passed on an actual Studio server using memory data. Both
  generated pets were removed by the test; the test ended automatically.
- From direct MCP execute_luau at localhost:58742/mcp, task.spawn a pcall of
  StudioTestService:ExecutePlayModeAsync("PetVerification") and retain the
  returned result in an Edit-side attribute for polling. This avoids MCP's
  timeout and the missing server-peer problem. Result was passed=true.
- Existing concurrent UI changes preserved; no Computer Use used.
- Next: PlotService/placement. UI runtime and real DataStore tests are pending.

### StarterGui Revision — 2026-09-15

- User requested real StarterGui Instances instead of runtime UI construction.
  Created `StarterGui.FeedYourPetUI` via MCP: 69 descendants, HUD, inventory,
  four Stud ImageButtons including a hidden editable PetCardTemplate.
- Exported the hierarchy to `src/ui/FeedYourPetUI.rbxmx` and mapped it through
  Rojo on port 34872. A clean Rojo build now includes the ScreenGui.
- HUDController binds the existing PlayerGui clone and clones only the saved
  pet-card template for owned pets. No runtime ScreenGui/layout constructor
  remains. Stud module now handles selection tint only.
- Verified: Rojo build, diff whitespace, synchronized controller compilation,
  one StarterGui root, all four button textures/tiles/strokes, hidden template.
  Existing live-play and screenshot limitations remain; no new runtime claim.
- Selected the ScreenGui in Studio Explorer. Inventory is hidden by default;
  enable its Visible property to inspect the panel while editing.
- UI revision and prior UI implementation are committed together with message
  `feat: add StarterGui stud HUD and inventory`. Concurrent verification source
  is excluded. Next: live snapshot/selection/lock and viewport tests.

### UI Session — 2026-09-15 (latest implementation)

- Completed: Money/Food HUD; inventory toggle/close; owned-pet cards; rarity,
  Variant, Feed Level, base income, placement and lock details; selection;
  Pen occupancy; loading/empty/error states; responsive uniform scaling.
- Added reusable Stud components and centralized UIConfig with user texture
  `rbxassetid://6927295847`, 100px tiles, 15px corners, 5px border/text strokes,
  FredokaOne, bevel text strokes, and vertical gradients. Textured surfaces
  use whole 100px tile dimensions before uniform viewport scaling.
- UIService exposes caller-only snapshots and validated/throttled lock requests.
  It does not accept currency values or expose pet creation/deletion. HUD polls
  every two seconds; no save/schema changes. Base income is explicitly labelled
  because Feed income and Money generation are not implemented yet.
- Files modified: client/server bootstraps; added client/Controllers/HUDController,
  client/UI/Stud, server/Services/UIService, shared/Config/UIConfig (all `.luau`),
  and this handoff. UI work is uncommitted; prior concurrent handoff notes preserved.
- Tests PASS: Rojo build; git diff --check; synchronized Studio Luau compilation;
  actual HUD constructor and ImageButton token assertions through MCP in Edit mode.
- Tests NOT RUN: live snapshots, owned-pet selection, lock requests, respawn,
  touch/gamepad interaction and visual screenshot review. MCP start acknowledged
  but connected peer stayed in Edit mode; screenshot capture timed out.
  The temporary CoreGui preview was removed after constructor verification.
- Connection: direct MCP JSON-RPC at http://localhost:58741/mcp works; built-in
  tool bridge times out. No Computer Use used. Runtime remains blocked by the
  Studio test-state issue described above, not by source compilation.
- Next: restore a real Play session; verify fresh balances, empty inventory,
  create test pets server-side, select/lock/unlock, reject foreign/invalid IDs
  and request spam, verify respawn and narrow viewport layout. Then continue
  PlotService/placement. Feed UI waits for authoritative pedestal/Feed state.
- Last working commit remains `5ca59a0`; no commit created in this UI session.

### What Was Done

Implemented `PetConfig` and `PetService` with six prototype species, locked base
incomes, GUID identity, validated create/read/lock/remove operations, snapshots,
rollback safety, and server-only events. Added PetService to server startup.

### What Is Currently Incomplete

Interactive PetService mutation testing, pet placement/Pen ownership, simple
wandering, and live DataStore/cross-server lease testing.

### Next Agent Should

1. Read `AGENTS.md`, this file, and relevant GDD sections.
2. Run `git status` and `git diff`.
3. Run PetService mutation checks through Roblox MCP; do not use Computer Use.
4. Continue with PlotService and placement/pickup while preserving inventory and slot consistency.
5. Do not point Studio at production data; use the isolated Studio store for backend tests.
