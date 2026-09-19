# Feed Your Pet — Project Status

**Phase:** Prototype

**Design Reference:** `Feed_Your_Pet_GDD_v0.5.md`

**Last Updated:** 2026-09-19

> This file is the current-state handoff between Codex sessions. Update it
> before ending a meaningful development session. Do not mark a feature
> complete unless it has been implemented and reasonably verified.

---

## 1. Current Goal

Build a playable prototype that validates:

**Hatch → Place → Earn → Farm → Feed → Grow → Risk → Explode / Survive**

The versioned data foundation and server-side pet foundation are implemented.
Pet creation, plots, placement, income, active farming and Feed outcomes have
Studio server verification. Next: visually playtest Feed tension and effects;
Studio-only free Revive is implemented; paid Revive/Protection remain deferred.

## 2. Overall Progress

| System | Status | Notes |
| --- | --- | --- |
| Project Setup | ✅ Complete / Verified | Filesystem layout, toolchain, build, and server launch verified. |
| Git Setup | ✅ Complete / Verified | `main` tracks `origin/main`; initial commit pushed successfully. |
| Rojo Setup | ✅ Complete / Verified | Live Studio sync and server/client bootstrap verified. |
| Base Architecture | 🟨 In Progress | DataService and PetService now exist; remaining gameplay services are pending. |
| Player Data Schema | ✅ v4 Studio Verified | Adds FeedPlateLevel; old saves start at level 1 without resetting progress. |
| DataService | 🟦 Implemented / Needs Testing | Studio runtime verified; live DataStore rejoin test remains. |
| Plot System | ✅ Layout / Ownership Verified | Six static plots, three facing three; five pet slots each. All 19 checks pass. Platform player limit still needs setting to 6. |
| Egg System | ⬜ Not Started | |
| Pet Conveyor Alpha | ✅ Server Verified | Static center conveyor; six random priced pet rarities, inventory purchase and expiry. 37 multiplayer + five isolated client checks pass; physical playtest pending. |
| Pet Identity | ✅ Complete / Verified | Creation, unique GUIDs, lock/unlock and removal passed in Studio; live persistence remains pending. |
| Inventory | 🟨 In Progress | Stud inventory UI, selection/details, and server-validated lock requests implemented; live verification and placement pending. |
| HUD | 🟦 Implemented / Needs Testing | Money/Food snapshots, responsive Stud layout, loading/empty states; Studio constructor verified, live test pending. |
| Number Formatting | ✅ Studio Verified | Shared K/M/B/T amounts across UI/world labels; 44 formatter/parser/sign checks pass. |
| Pet Placement | 🟦 Free Position Implemented | Click/tap inside own Pen, exact local coordinates, five-pet cap and click pickup; build passes, Studio test pending. |
| Pet Wandering | ✅ Server Verified | 21 Studio checks pass: walk/pause, live pickup, grown-pet bounds on six plots, cleanup and saved anchors. Manual feel pending. |
| Money Generation | ✅ Server Verified | Placed pets pay BaseIncome x FeedMultiplier each second; 15 Studio checks pass. HUD rate included; published persistence remains separate. |
| Farm | ✅ Upgrades Server Verified | Ten levels with preserved custom prices; Money purchase and active-only output. Manual sign input/feel pending. |
| Feed Plate Upgrades | ✅ Studio Verified | Six authored signs, ten saved levels, farm-matched prices and up to 45% relative explosion-risk reduction; 58 multiplayer checks pass. |
| Food | ✅ Server Verified | Active farming pays 2 Food/sec at level one; memory save verified and immediate HUD pushes implemented. |
| Carry System | 🟦 Click Flow Implemented | Equip/unequip and hand-held models retained; hold-E replaced by click placement and nearby click pickup. Updated test pending. |
| Feeding Pedestal | ✅ Staging Server Verified | Six feed plates; carry/click placement and hold-E pickup. 23 multiplayer checks pass; Feed UI/RNG deferred. |
| Feed UI | 🟦 Outcome UI Implemented | Risk/cost, max-level limit, pickup and outcome banners; five updated isolated controller checks pass. Visual review pending. |
| Feed Transaction | ✅ Studio Verified | Configured Food cost, authoritative outcomes, replay and save locks; 55 multiplayer checks pass. |
| Explosion RNG | ✅ Studio Verified | Explosion first, 5% Miracle Save, otherwise persisted quarantine. |
| Critical Feed | ✅ Studio Verified | Configured odds; no skipped-level rolls; gains capped at 40. |
| Pet Growth | 🟦 Implemented | Success scales plate/Pen models and income; manual visual review pending. |
| Explosion Presentation | 🟦 Implemented | Float/spin, burst/fade and banners; six isolated effect checks pass. |
| Protection | ⬜ Not Started | |
| Revive / Keep Base | 🟦 Choice Flow Server Verified | Failed Feed offers old-level Studio Revive or level-0 reset; 72 Feed checks pass. Legacy regression rerun and revised UI testing pending. Paid recovery not implemented. |
| Save / Load | 🟦 Implemented / Needs Testing | Memory-mode flow verified; production backend remains untested. |
| Debug Tools | ✅ Studio Memory Verified | Currency grants, six-rarity spawn, pet/farm levels, one-use Feed outcomes. 47 multiplayer + 12 gate + 10 isolated UI checks pass. |
| Core Loop Playtest | ⬜ Not Started | |

Status legend: ⬜ Not Started · 🟨 In Progress · 🟦 Implemented / Needs Testing · ✅ Complete / Verified · ❌ Blocked

## 3. Current Feature

**Current Feature:** Failed-feed Revive or keep-at-base choice

**Status:** Implemented; 72 Feed and 47 Debug multiplayer checks pass. Revised UI physical testing, isolated production/save-failure checks, and legacy recovery regression remain pending because MCP disconnected.

**Objective:** Keep exploded pets at base Feed level (0), with Revive able to restore the pre-failure level through an explicit recovery choice.

## 4. Completed

- Failed Feed offers Revive to the pre-failure level or Keep at level 0.
  Both retain identity and consume the saved recovery offer without refunding
  Food. Level-0 pets can equip and grow again; old requests cannot undo a reset.

- FeedPlateConfig defines ten levels, the same current prices as FarmConfig,
  and 0–45% relative risk reduction. FarmConfig itself was not changed.
  Server-validated purchases, stale-click protection, shared Feed/Revive locks,
  save retries, v3-to-v4 migration, risk display and six authored signs are implemented.

- Shared K/M/B/T formatter across HUD/inventory income, popups, farm signs,
  conveyor labels/prompts, Feed/Revive displays and debug amounts. Debug input
  accepts K/M/B/T suffixes while retaining server numeric validation.

- Authored Studio Debug panel, server-validated bounded currency/spawn/level
  commands, replay-safe sequences and one-use per-pet Feed outcome overrides.
  Both remote availability and mutations require Studio plus memory data.

- Broken Pets panel with previous level/income, record browsing, Keep Playing
  and Studio-only free Revive. Original identity/stats restored to inventory;
  exact explosion validation, replay protection and shared save locks/retries.

- Implemented server-owned pet wandering with configurable speed, pauses and
  travel distance. Live model position drives pickup; pickup temporarily pauses
  wandering. No world geometry, economy or save-schema changes.

- Authored center conveyor, pet rarity/price labels and purchase feedback UI.
  Six weighted pet rarities, moving bounded offers, hold-E purchases, unique
  inventory identity, replay/race protection, save retry and automatic expiry.

- Six authored farm upgrade signs, displaying level, production and next-price
  Buy Upgrade button. GDD 15-level prices added to FarmConfig; owner/range/life/
  affordability/stale-click checks, atomic Money+FarmLevel save and HUD push.

- Feed now uses configured costs and RNG, increases level/income, quarantines
  exploded pets in schema v3, and queues atomic saves with retry locks.
- Authored FeedPanel/FeedBanner, close-on-Feed, risk display, level-40 limit,
  accelerating float/spin, success growth, Miracle flash and explosion burst.
  Plate E opens UI; pickup is inside UI; no main-screen Feed shortcut.

- Six authored feed plates and PedestalService transient single-pet staging;
  held-ID/ownership/distance validation, occupied rejection, timed pickup,
  inventory status and lifecycle cleanup. Feed UI and transactions deferred.

- Active Food farm: six authored stations, owner-only server proximity sessions,
  elapsed-time Food payouts, exit/rearm safety, cleanup, Food HUD push and save.

- Added PlacementService, atomic validated placement/pickup, template preflight,
  idempotence, saved-state visual reconciliation and leave cleanup.
- Added inventory Place Pet/Pick Up controls and throttled caller-only requests.
- Authored six editable pet templates directly in Workspace through MCP and
  exported the static asset for Rojo/Git. No runtime geometry generator added.

- Revised Workspace.PlayerPlots to six static, editable plots per user request:
  three per side, facing a 40-stud empty center lane. Conveyor is not implemented.
- Each plot has anchored ground, a fenced Pen with entrance, five slot markers,
  personal Spawn and owner sign. No runtime model generator or cloning remains.
- Added PlotService ownership assignment, respawn routing, release/reuse, and
  slot access capped by both the physical five-slot limit and loaded player data.
- Exported the real Studio hierarchy to src/world/PlayerPlots.rbxmx and mapped
  only Workspace.PlayerPlots through Rojo; unrelated world Instances preserved.
- Added opt-in multiplayer PlotVerification and passed all 18 assertions.
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

- Reconnect Studio MCP and rerun ReviveVerification plus revised client/public
  KeepBase/save-failure checks. Test the two recovery buttons visually.

- Physical feed plate sign mouse/touch/gamepad input and visual risk-display review.

- Visual Play review of compact numeric text across UI and world labels.

- Physical debug panel input/layout review and full-loop playtest using its
  grants, level editing and one-use forced outcomes.

- Manual wandering movement/pickup feel review; server verification complete.

- Physical mouse/touch and visual review of Feed effects/UI and Revive panel.
  Protection and paid Revive are not implemented; free Revive is Studio-only.
- Manual plate click/touch/hold-E presentation review; server verification complete.
- Manual farm sign mouse/touch/gamepad input and visual review. Farm running
  animation asset remains unimplemented; upgrades/purchases are now implemented.
- Fresh Play-session verification of HUD startup and visible one-second payout
  updates after the latest UI recovery fix; no server economy changes this session.

- Production DataStore persistence and cross-server session behavior still need
  an end-to-end test in a published test server or Studio with API access enabled.
- Data schema migrations beyond v1 will be added only when the schema version changes.
- PetService creation, unique IDs, snapshot isolation, lock/unlock and removal
  passed 15 real Studio server integration checks through MCP.

## 6. Next Tasks

Latest priority: reconnect Studio MCP and finish recovery UI/legacy regression,
then review the purple feed plate upgrade signs and reduced Feed risk,
then fresh memory Play using STUDIO DEBUG to review high-level Feed,
explosion -> Broken Pets -> free Revive -> inventory, then game pacing. Money balancing is
explicitly deferred. Verify onboarding and live DataStore
rejoin/outage/session transfer separately.
The numbered list below retains older prototype follow-ups.

0. Restart Play and verify the HUD appears without the FeedYourPetUI infinite-yield
   warning, balances change on each payout, and carry/popups start independently.
1. Verify actual inventory button input across desktop/touch/gamepad.
2. Review simple prototype pet wandering within the owner's Pen.
3. After validating active farming, implement the prototype Feeding Pedestal/Feed transaction.
4. Verify pet identity, placement, Feed Level, and lock state survive a real DataStore rejoin.

## 7. Files Modified This Session

Current recovery-choice session: FeedService, ReviveService, FeedController,
FeedEffects, ReviveController, ReviveUI.rbxmx, FeedVerification,
ReviveVerification, DebugVerification, docs/revive.md, docs/feed-config.md,
and this handoff. Prior checkpoint 84f4126 already contains reset config and
the pedestal return-to-inventory parameter. Earlier lists below are historical.

Current plate-upgrade session: default.project.json; GameConfig and new
FeedPlateConfig; PlayerDataSchema; FeedResolver/FeedService and new
FeedPlateUpgradeService; client/server bootstraps; FeedController/HUDController;
new FeedPlateUpgradeController/FeedPlateSignView; authored
src/world/FeedPlateUpgradeSigns.rbxmx; FeedVerification and new
FeedPlateUpgradeVerification; docs/feed-plate-upgrades.md, docs/feed-config.md,
and this handoff. The list below records the preceding number-format session.

```text
src/shared/NumberFormat.luau
src/server/NumberFormatVerification.luau
src/server/Services/ConveyorService.luau
src/client/UI/FarmSignView.luau
src/client/Controllers/HUDController.luau
src/client/Controllers/IncomeEffectsController.luau
src/client/Controllers/DebugController.luau
src/client/Controllers/ReviveController.luau
src/client/Controllers/FeedController.luau
src/client/Controllers/FeedEffects.luau
src/ui/DebugUI.rbxmx
docs/number-format.md
PROJECT_STATUS.md
```

## 8. Current Uncommitted Work

### Latest — Recovery choice implemented (supersedes partial checkpoint notes)

- Continued from user-requested checkpoint 84f4126. Feed failures again use the
  existing PendingRecovery record to hold the pre-failure pet until a choice.
  This prevents using a reset pet and later restoring an old version.
- Revive restores the old level (free Studio-only as before); KeepBase restores
  level 0 in Studio AND published servers. Both consume the exact PetId+AttemptId
  offer atomically and save with shared locks/retries. Food remains spent.
- Pending offers survive save/reload; legacy broken records support both choices.
  No schema/store/price/odds changes. No paid recovery added.
- Authored ReviveUI reused with PET RECOVERY and KEEP AT LEVEL 0 text; controller
  routes both buttons, disables choices while busy, and removes confirmed offers
  locally so a throttled snapshot cannot leave a stale actionable button.
- PASS captured through MCP: 72 FeedVerification and 47 DebugVerification
  multiplayer checks. Build and synced source compilation passed before the
  final small client stale-offer cleanup. Final Rojo build/diff checks are local.
- ReviveVerification returned no result in the sequential run; isolated rerun
  was scheduled but its result could not be retrieved. Do not count it as passed.
  MCP 58741 stopped listening; alternate 58742 reports zero connected instances.
  Public KeepBase/save-retry isolated test did not execute (connection refused).
- NEXT: enable/reconnect the Roblox Studio MCP plugin; rerun ReviveVerification,
  isolated client/public KeepBase/save-failure checks and physical UI review.
  Production DataStore rejoin/outage testing remains separate. No Computer Use.

### In progress — Base-level explosion reset and Revive clarification

- Baseline 0f3db31; clean tree before edits. Read existing Feed, pedestal,
  recovery, tests and relevant GDD; MCP 58741 confirmed Edit mode.
- Partial edits: FeedConfig.ExplosionResetLevel=0; FeedService retains inventory
  identity and resets level instead of creating PendingRecovery; pedestal clears
  after explosion presentation; Feed notice/banner explains reset and retained
  pet. DebugVerification assertion updated. ReviveVerification now seeds legacy
  recovery fixtures, preserving the existing recovery service.
- User subsequently clarified: reset to base level, but Revive should be used
  when Feed fails. Earlier assumption to defer its new purpose is superseded.
  Proposed flow: restore pre-failure level OR keep level-0 pet; accepting the
  reset closes that attempt's recovery. Food stays spent either way.
- NOT DONE: wire the revised Revive offer/accept-reset transaction and UI,
  update FeedVerification's obsolete quarantine assertions, verify replay/save/
  leave safety and run tests. Current partial code does NOT offer Revive for new
  explosions. Do not report this feature complete or ship the partial change.
- Preserve existing PendingRecovery records and pet IDs; no production data,
  schema, farm prices or explosion odds changed. User requested committing this
  unfinished checkpoint as `wip: checkpoint level-zero explosion reset`.
  Whitespace diff checks pass; revised gameplay tests have not been run.

### Latest Session — Feed plate upgrades — 2026-09-19

- Baseline 015fe8d. User delegated balance values: ten levels, farm-matched
  prices, 5% relative reduction per upgrade, capped at 45%; 20% becomes 11%.
- Direct MCP at localhost:58741; no Computer Use. Cloned/authored six real
  Studio signs beside the feed plates and exported their static Rojo asset.
- Schema v4 persists FeedPlateLevel; migration defaults existing players to 1.
  Pet schema, recovery records, DataStore keys and custom FarmConfig unchanged.
- Server owns price, ownership/range/life validation, level compare-and-swap,
  Money+level mutation, save retry and shared Feed/Revive lock. Client displays
  effective risk; same risk reaches FeedResolver. RNG ordering/cap unchanged.
- PASS: 58 two-player memory-mode checks, six isolated sign UI checks, all
  synchronized source compilation, Rojo build and diff whitespace checks.
- Regression: all 55 existing Feed checks pass with schema v4 and the risk
  modifier. Five isolated save-failure/retry assertions pass against the actual
  service source with injected dependencies; no production data involved.
- Remaining: physical input/visual review, live DataStore outage/rejoin tests.
  This is permanent plate progression, not paid or single-use Protection.

### Latest Session — Compact K/M/B/T numbers — 2026-09-19

- Baseline a2ffc35, clean tree before edits. Inspected existing formatter/call
  sites and Studio FarmSignView. Shared NumberFormat uses up to two decimals,
  strips trailing zeroes and promotes rounded boundaries. No Qa suffix:
  1e15 renders 1000T. Levels/slot counts/percentages/IDs retain existing format.
- Replaced duplicated HUD/popup/farm formatting and raw economy %g displays
  in Feed, Revive, Debug and conveyor labels/prompts. Debug amount starts at 1M
  and accepts K/M/B/T suffixes; server validation still receives real numbers.
- No balance/config/schema/transaction changes. Only DebugUI default Text
  changed in authored assets, synchronized through Rojo; geometry unchanged.
- PASS: 44 read-only Studio NumberFormatVerification checks, synchronized
  compilation, Rojo build and diff checks. No runtime economy test or visual
  input/layout claim for this session. No Computer Use or production writes.
- Next: fresh Play to inspect compact labels, then continue core-loop testing.
  Details: docs/number-format.md. Prior debug/playtest notes remain historical.

### Latest Session — Studio debug panel — 2026-09-19

- Baseline bd7415c; clean tree before changes. Inspected Feed/plate/farm source
  and Studio before edits. Farm/Feed economy configs are unchanged.
- Actual editable DebugUI authored via MCP and exported for Rojo. Studio memory
  mode only: add Money/Food, cycle six rarity spawns, select owned PetId, set
  pet level 0–40 / farm level 1–10, force Success/Critical/Mega/Insane/Explosion
  once or clear the override. Placed-pet level editing requires pickup first;
  plate edits rescale the authored pet immediately. No data reset added.
- DebugService gates before data access; no remote in published or persistent
  Studio sessions. Finite/integer/range/owner/species/mode validation, rate limit
  and monotonic replay-safe requests. Debug mutations reject shared Feed locks.
- DebugFeedOverrides is independent of services; Feed resolves it only after
  eligibility/cost checks, and consumes it only on accepted validation. It is
  per-player + per-pet, transient and cleared on leave. Forced explosion may
  override natural zero-risk/Miracle behavior only in isolated Studio memory.
- PASS: 47 actual two-player memory assertions; 12 isolated access-gate checks
  and 10 isolated client checks. Tests cover grants/replays, six spawns, malformed
  inputs/ownership/levels, plate growth, actual forced outcomes, level-40 cap,
  rejected-Feed override retention, broken state and clearing. Tests auto-ended.
- Build, synced compilation and diff pass. Manual input/layout still pending;
  no Computer Use, production data writes or permanent odds edits.
- Next: fresh Studio Play, open STUDIO DEBUG, set up a high-level pet and test
  Feed/explosion/Revive. Usage and safety details: docs/debug-tools.md.

### Latest Session — Broken pets / free Studio Revive — 2026-09-19

- Baseline 03d67d3, clean tree before implementation. User chose free Studio
  recovery and a broken state, not deletion or automatic level-one reset.
- Reuses schema-v3 PendingRecovery. Revive consumes exact PetId+AttemptId and
  restores pre-failure pet to inventory without Food refund, reroll or placement.
  Durable consumed-record guard prevents duplicate recovery; old attempts cannot
  restore a newer explosion. Shared Feed lock lasts through confirmed save.
- Unconditional server IsStudio gate; public Snapshot remains caller-only.
  No paid products, receipts, expiry, permanent deletion or economy changes.
- Authored actual StarterGui.ReviveUI via MCP, configured/exported to .rbxmx.
  Controller browses records, auto-opens after Feed lock clears and reopens via
  BROKEN PETS. KEEP PLAYING retains recovery. GUI fallback clones its own asset.
  Main carry/Feed/conveyor interactions respect the recovery modal.
- PASS: 22 two-player Studio memory checks covering actual explosions, exact
  restoration, privacy, invalid/foreign/stale/replayed/concurrent requests and
  memory reload. Six isolated service checks cover published denial and failed
  save retry/lock; eight isolated UI checks cover open/close, Studio
  eligibility, successful recovery and duplicate click suppression.
- Build, synced compilation and diff pass. Tests auto-ended. Physical input,
  responsive layout review and production outage/rejoin remain separate.
- No Computer Use, production writes or Farm/Feed balance edits. Next: fresh
  Play, explode a pet, recover it, then equip it from MY PETS. See docs/revive.md.

### Latest Session — Pet wandering — 2026-09-19

- Baseline 20daf78; clean tree before changes. Inspected Studio Placement/Carry
  sources before editing. No Farm/Feed/Money/conveyor config changes.
- Placement registers authored pet clones with WanderingService. Heartbeat
  movement is server-owned, capped after stalls, local to each Pen and inset for
  grown-pet rotation. Pauses 2–4s; speed 3 studs/sec; nearby targets 4–10 studs.
- Initial click/saved anchor stays intact; near-fence pets walk inward before
  turning. No pet collision avoidance/pathfinding/rig animation in this alpha.
- CarryService uses live server position, not original anchor. Valid pickup
  holds pause movement for their four-second timeout window, preventing runaway
  prompts. Ownership/life/distance/hold-time validation remains enforced.
- Destroying a visual clears wandering immediately; repair registers the new
  clone. Held/feed-plate pets are never tracked. No saved wandering state.
- Build, diff and synced compilation pass. All 21 WanderingVerification checks
  passed in a disposable two-player Studio memory test; test auto-ended.
  Covers movement, unchanged anchors/rates, reconciliation, foreign/short/full
  pickup holds, pause, cleanup, repair, memory save and grown-pet bounds on all
  six authored floors. First run used exact -12/0 coordinate expectations and
  hit float conversion; corrected test to compare actual saved initial values.
- No physical input/smoothness claim; no Computer Use or production writes.
- Next: manual movement/pickup review. Production persistence remains separate.

### Latest Session — Pet conveyor alpha — 2026-09-19

- User now explicitly authorizes the previously reserved center conveyor, with
  pets instead of eggs. Existing Common/Uncommon/Rare/Epic/Legendary/Mythic used.
- Authored real conveyor parts through MCP, plus BillboardGui label template
  and purchase-feedback ScreenGui; exported three assets and mapped in Rojo.
  Runtime clones existing pet/UI assets only; no world geometry generator.
- ConveyorConfig: 4s spawn, 36s travel, 10-offer cap; weights 600/250/100/40/9/1;
  temporary prices 100/1.5K/5K/30K/100K/450K Money. Not GDD egg balance.
- ConveyorService resolves random offers, server-clock movement/expiry and
  validated purchases. Atomic non-yielding payment+PetService creation; one
  winner per offer, replay-safe cached result, queued save retries with lock.
  New pets enter inventory at level 0/unplaced. No conveyor pet produces income.
- ConveyorController interpolates motion and animates authored tread positions,
  handles hold-E/gamepad/touch purchase prompts and success/error feedback.
  Immediate authoritative Money HUD push via ConveyorPurchaseChanged.
- Tests PASS: 37 two-player memory checks, five isolated client source checks,
  geometry inside reserved lane, unique assets, build/diff/synced compilation.
  Main verification spawns deterministic offers; automatic scheduling and real
  mouse/touch/gamepad feel still need ordinary Play review. Tests auto-ended.
- Farm config inspected in both Studio/filesystem BEFORE changes; preserved
  custom 10-level prices and output exactly. No Farm/Feed code/config edits.
- Production onboarding remains a known gap: zero starting Money/no starter
  pet outside existing developer-only Studio test grant. No free grant added.
- Files: ConveyorConfig, ConveyorService, ConveyorController, ConveyorVerification,
  PetConveyor.rbxmx, ConveyorPetLabel.rbxmx, ConveyorUI.rbxmx, HUDController,
  client/server bootstraps, default.project.json, docs/conveyor.md, PROJECT_STATUS.md.
- Baseline: 79e2e9c. Next: start ordinary Play and buy a passing pet; use existing
  Studio starter pet for initial income. No Computer Use/live DataStore writes.

### Latest Session — Keep custom levels 1–10 — 2026-09-18

- User requested removal of farm levels 11–15, preserving custom prices 1–10.
- Important: Studio contained newer user edits absent from the filesystem.
  An initial file-based patch temporarily overwrote those prices via Rojo.
  Captured the pre-edit Studio source and restored all custom prices into the
  authoritative file; verified exact parity in Studio afterward. Inspect both
  sources BEFORE editing configuration in future; do not discard Studio edits.
- Costs to reach levels 2–10: 20K, 500K, 5M, 120M, 2B, 500B, 15T, 200T, 1Qa.
  Level 1 remains free; Food/sec for 1–10 stays 2,6,18,50,140,400,1200,3500,10000,30000.
- Removed costs/rates 11–15; six sign previews now say 1/10 and first price 20K.
  Existing saved levels above 10 are not erased; effective rate/display uses
  level 10 and purchases are blocked. FarmPower remains applied.
- Files: FarmConfig, FarmService, FarmUpgradeService, FarmUpgradeVerification,
  FarmUpgradeSigns.rbxmx, docs/farm.md, PROJECT_STATUS.md.
- Tests: build/diff PASS, exact restored-price and sign assertions PASS in MCP.
  30 multiplayer cap/legacy-save checks passed BEFORE restoring custom prices;
  tests now expect 20K/500K/1Qa but this latest price version has not been rerun.
- Baseline: 053d2ac. Next: verify custom price pacing in Play; no Feed changes.

### Latest Session — In-world farm upgrade signs — 2026-09-18

- Added six actual Studio sign models beside farms, exported as standalone
  FarmUpgradeSigns.rbxmx and mapped by Rojo. No runtime geometry generator.
- Each has authored SurfaceGui level/rate/next rate/price/button/status. Runtime
  clones GUI only into PlayerGui with Board Adornee for Roblox input support.
- New FarmUpgradeService validates owner via PlotService, alive character,
  14-stud range, GDD price, affordability, cooldown and expected current level.
  Non-yielding Money/FarmLevel mutation; DataService saves both together.
  Save failure holds purchase lock and retries without rollback/double charge.
- Reused persisted FarmLevel/FarmPower; schema unchanged. Upgrades work while
  farming and affect next payout; no passive income, no exit-input change.
  First upgrade costs 5K and raises Food/sec 2 -> 6. Maximum level 15.
- Immediate Money HUD update; public signs refresh every .5 seconds and clear
  on owner departure. No client-provided cost/reward. Stale clicks cannot buy
  the next level. Saving/insufficient funds/foreign/distant/max states disable UI.
- Tests PASS: 27 actual two-player Studio memory checks, 10 isolated sign-view
  checks, 12 geometry/input-property checks, Rojo build and Luau compilation.
  Tests auto-ended; no Computer Use or live DataStore writes.
- NOT verified: physical mouse/touch/gamepad activation, visual camera feel,
  live backend outage/rejoin. Existing double Money precision above 2^53 remains.
- Feed reset-to-level-1 was discussed but NOT requested for implementation;
  existing explosion quarantine and Feed odds remain unchanged.
- Files: default.project.json; FarmConfig; FarmUpgradeService; FarmUpgradeController;
  FarmSignView; FarmUpgradeVerification; HUDController; client/server bootstraps;
  FarmUpgradeSigns.rbxmx; docs/farm.md; PROJECT_STATUS.md.
- Baseline: 1d93a04. Next: fresh Play and click the nearby farm sign's Buy button.

### Latest Session — Feed outcomes and animation — 2026-09-18

- User approved retaining exploded pets safely but unusable until Revive exists,
  and capping Critical gains at 40. No paid recovery, expiry or deletion added.
- Implemented configured costs, explosion-before-Critical, 5% Miracle Save,
  capped actual gains, income updates and plate/Pen scaling. Held size remains
  normalized. Conservative configurable visual curve reaches 3.4x at level 40.
- Schema v3 migrates v2 and deep-clones PendingRecovery records; pre-failure
  pet identity/stats/lock and consumed Food metadata persist together.
- FeedLocks prevents concurrent feed, pickup, placement and removal. Cached
  retries never charge/reroll; save retries retain the resolved state and block
  another feed until confirmation. Leave/shutdown reuse DataService saves.
- Client closes panel, animates authored pet clones and shows editable banners.
  Server sends visual-only broadcasts; private balance/recovery data stays local.
- Tests: Rojo build, synchronized Luau compilation, no duplicate source objects;
  55 real two-player Studio memory checks, six isolated effects checks, five
  isolated controller checks PASS. Initial scale assertion needed tolerance
  for Roblox float storage (1.05999994 vs 1.06); no growth bug was found.
- MCP localhost:58741/mcp works; Rojo sync works. Tests auto-ended. No Computer
  Use and no live DataStore writes. Manual appearance/latency/input review and
  production rejoin/outage/session safety tests are NOT claimed complete.
- Files: FeedService, FeedResolver, FeedLocks, PedestalService, CarryService,
  PlacementService, PetService, PlayerDataSchema, FeedVerification, FeedConfig,
  GameConfig, FeedController, FeedEffects, CarryController, FeedYourPetUI.rbxmx,
  docs/feed-config.md, docs/feed-ui.md, PROJECT_STATUS.md.
- Baseline: c458ca1. This session's logical commit is the Feed outcome feature.

Historical session notes follow; their old incomplete statuses are superseded
by the current feature and latest session above.

### Latest Session — Feed config first — 2026-09-18

- User requested Feed config first, ahead of UI closing, floating/accelerating
  spin, explosion/success animations and screen banners. Extended the existing
  FeedConfig, preserving its income Multiplier curve exactly.
- Added target-level 1–40 Food costs and explosion odds, rarity cost factors,
  Critical results and 5% Miracle Save from GDD. Added presentation-only defaults
  for float/spin, success/explosion/Miracle banners and return/burst timings.
- GetFoodCost returns nil outside configured levels/rarities; fractional costs
  are preserved. No new level cap or critical overshoot behavior invented.
- Files: src/shared/Config/FeedConfig.luau, docs/feed-config.md, PROJECT_STATUS.md.
- Verification: Rojo build/diff checks passed; synced source evaluated in Studio
  passed 40-level coverage, probability totals/bounds, example costs, invalid
  level/rarity handling, multiplier anchors and nested immutability checks.
- No transaction, UI behavior or animation changed. FeedService remains at
  consumption-only 1 Food. Next: safe outcomes/recovery, then animated display.

### Latest Session — Jump-only farm exit — 2026-09-18

- Removed WASD and MoveDirection exit handlers from FarmController. JumpRequest
  is now the only voluntary exit input; chat exclusion and cooldown remain.
  Server cleanup for death, respawn, leaving and invalid state is unchanged.
- Updated all six static farm signs and docs/farm.md to say Jump to exit.
- Files: FarmController.luau, PlayerPlots.rbxmx, docs/farm.md, PROJECT_STATUS.md.
- Verification: Rojo build/diff checks pass; synced controller passed five
  isolated Studio checks (WASD ignored, jump exits, throttling, chat exclusion,
  no exit outside farming). Physical input review remains separate.
- Next: verify jump-only controls in Play; no Food balance/config changes.

### Latest Session — Remove main-screen Feed button — 2026-09-18

- Removed FeedOpen from the authored UI asset and its controller bindings.
  Automatic opening when staging a pet and hold-E opening at the plate remain.
  Feed and Pick Up Pet buttons inside the panel are unchanged.
- Files: FeedYourPetUI.rbxmx, FeedController.luau, docs/feed-ui.md, PROJECT_STATUS.md.
- Verification: Rojo build and diff checks; no server logic changes.
- Next: check the main screen in a fresh Play session. Baseline: 77144f8.

### Latest Session Handoff — Plate UI Pickup — 2026-09-18

- Replaced plate PickupPet prompt with OpenFeedUI (one-second hold E).
  FeedController opens the existing panel for the owner's nearby staged pet.
  Existing automatic open and reopen button remain. Pen hold-E pickup unchanged.
- Added authored Pickup TextButton to FeedPanel in FeedYourPetUI.rbxmx, matching
  its existing button style. Increased panel height/scaling to fit it. No new
  runtime-generated UI, config or gameplay economy changes.
- FeedService Pickup action validates profile, live character, plate ownership,
  expected pet ID, range and cooldown, then calls existing safe CarryService
  equip. Successful pickup closes the panel; it does not spend Food.
- Updated plate signs, inventory guidance and docs. Updated PedestalVerification
  to test prompt separation and foreign/stale/distant/duplicate UI pickups.
- Files: CarryService, PedestalService, FeedService; CarryController,
  FeedController, HUDController; PedestalVerification; FeedYourPetUI.rbxmx,
  PlayerPlots.rbxmx; docs/feed-ui.md, docs/feed-plate.md; PROJECT_STATUS.md.
- Verified: Rojo build build/FeedPickup.rbxlx, source compilation, UI XML button
  uniqueness/bounds, and git diff --check pass. MCP 58741 reconnected during the
  session; all 28 updated PedestalVerification multiplayer checks passed.
  Three isolated tests using the real UI and mocked input/transport passed:
  prompt opens without pickup, pickup available at zero Food, pickup closes UI.
  Physical input/visual review remains pending. Baseline commit 30a72c4.
  No Computer Use or production data writes.
- Next: verify actual hold-E and pickup button feel in Play. FeedVerification
  was not rerun this session; consumption behavior was unchanged.

Feed UI/consumption implementation, asset, tests and handoff. Baseline: 7189bda.
September 18 continuation verified the saved implementation and reran the build
and diff checks before completing the local commit. No scope/config changes.

### Latest Session Handoff — Feed UI / Food Consumption — 2026-09-17

- User requested Feed UI with feeding logic limited to consuming Food and no
  config yet. Implemented that explicit scope, not full GDD Feed resolution.
  Temporary cost is 1 Food per click (announced default; cost question unanswered).
  No config files were created or changed. One server-local cost constant is
  returned in snapshots; the client never chooses the charged amount.
- Created actual editable FeedPanel/FeedOpen UI objects in StarterGui via MCP,
  exported into existing FeedYourPetUI.rbxmx. Panel shows pet name, rarity,
  current Feed Level, Food/cost, status, Feed and Close. Clear consumption-only
  notice; no misleading success/growth/explosion display. Auto-opens on staging,
  closes on pickup, and supports reopen without disturbing the pet.
- Added FeedService and FeedController. Server checks loaded valid profile,
  own staged pet, current live character, plate distance, affordability and
  cooldown. Monotonic per-player request sequence rejects duplicate, stale and
  future requests; deduction and sequence advance are non-yielding. State is
  per-server session, cleaned on leave. Existing Food persistence reused.
- FeedFoodChanged pushes authoritative balance/FoodAt directly into the HUD.
  Feed/Inventory panels are mutually exclusive, world click/pickup is suppressed
  while the Feed panel is visible. Close the UI to hold E for pickup.
- Testing: all 21 real two-player Studio memory FeedVerification checks passed,
  including exact deduction, insufficient Food, ownership/distance/death/pickup,
  malformed input, replay/cooldown, unchanged pet stats and memory save. Nine
  isolated FeedController tests used the real cloned UI with mocked signals/
  transport: open/render/consume/disable/close/reopen/pickup all passed. These are
  not actual mouse/touch or full rendered-UI tests. No production data writes.
- Build build/FeedUI.rbxlx, source compilation and git diff --check passed.
  Removed one extra FeedPanel and FeedOpen from Studio/Rojo synchronization;
  authored content remains in the static asset. MCP reconnected at 58741.
- Next: review real Play-session Feed UI, then request direction before adding
  Feed progression, RNG or a balance config. No Computer Use used.

### Latest Session Handoff — Feed Plate — 2026-09-16

- User requested a plate to put pets on. Added one editable FeedPlate per plot,
  built as actual Studio parts through MCP and exported into PlayerPlots.rbxmx.
  Central lane, Pens and farms unchanged. No runtime geometry generator.
- Carry a pet, approach own plate (12-stud limit), click/tap to stage. One pet
  maximum; occupied/invalid placement leaves the held pet unchanged. Hold E
  one second to pick up using existing server-timed ownership/range validation.
- PedestalService is a transient visual/state layer, not a second pet inventory.
  Pets retain their original records, IDs, lock and FeedLevel. Staged pets are
  stored for persistence, consume no active Pen slot and earn no Pen income.
  Respawn/leaving clears visuals only; reconnect returns the pet to inventory.
- UIService exposes FeedPlatePetId and rejects inventory equip bypassing hold-E.
  No Food/Money consumption, Feed UI, RNG, Protection or Revive implemented.
- Removed Studio/Rojo duplicate copies of the six authored plates plus the two
  new scripts. Content is preserved in the repository. Check for duplicates
  again when introducing new Rojo objects in this Studio session.
- Verification: all 23 two-player opt-in memory PedestalVerification checks pass:
  held-ID/ownership/distance validation, template-failure recovery, one-pet
  occupancy, inventory bypass rejection, timed hold pickup, currency neutrality,
  memory save, respawn cleanup and schema validity. First run exposed cleanup
  timing during respawn; added character-specific state and reconciliation plus
  an asynchronous test wait. Latest rerun passed. Six geometry checks confirm
  unique anchored plates remain within plot bounds and outside the center lane.
  Rojo build, source compilation and git diff --check pass. Actual physical
  mouse/touch input and visual feel remain unverified. No Computer Use or
  production data writes; main Studio returned to Edit after auto-ending tests.
- Next: review actual click/hold behavior, then Feed UI
  and safe server-authoritative Feed transaction.

### Latest Session Handoff — Active Farm — 2026-09-16

- User explicitly confirmed Food should be generated only while inside the farm.
  This supersedes passive generation in GDD 19 for this prototype interaction.
- Added FarmService, FarmController and FarmConfig. Server scans own-plot
  proximity, anchors/repositions at WorkPoint, pays every elapsed second, and
  restores controls at ExitPoint on exit. Rearm distance prevents recapture.
  Death/removal/displacement/lost profile or station cancels the session.
- Food uses existing persisted Food/FarmLevel/FarmPower fields. Level-one rate
  is 2/sec, higher configured rates follow GDD candidate curve. No new schema,
  offline accrual, upgrades/purchases, animation asset or conveyor implemented.
- Client can only request its own exit, never income or entry. WASD/Jump exits;
  touch/gamepad movement exits after releasing approach input. Animation ID
  remains empty, with lifecycle hook ready for a later published animation.
- Held pets safely return to inventory on entry; farming blocks equip. HUD
  receives immediate Food pushes with stale-snapshot timestamp protection.
- Created six real editable Workspace farm models via MCP, then exported their
  properties into PlayerPlots.rbxmx. Geometry stays out of the Pen and middle lane.
- Studio/Rojo created duplicate copies of new objects/scripts. Removed 12 extra
  farm models and one extra copy of each new script/config; filesystem assets
  retain all authored content. Two initial tests were invalidated by duplicate
  FarmVerification scripts competing for the same test players. Clean rerun
  passed all 27 assertions. Final inspection confirmed exactly six farm models.
- Files: src/world/PlayerPlots.rbxmx; src/shared/Config/FarmConfig.luau;
  src/server/Services/FarmService.luau, CarryService.luau, UIService.luau;
  src/server/FarmVerification.server.luau; src/server/init.server.luau;
  src/client/Controllers/FarmController.luau, HUDController.luau;
  src/client/init.client.luau; docs/farm.md; PROJECT_STATUS.md.
- Verification: 27 real two-player Studio memory checks passed (ownership,
  active-only earning, exact payouts, duplicate/spam protection, held pet safety,
  remote exit, control restoration, rearm, displacement, death, memory save and
  schema). Eleven isolated tests of actual FarmController source with mocked
  input signals passed (all WASD/Space/Jump bindings, throttling, chat exclusion,
  held approach input and renewed movement). These are not physical-input tests.
  All synced source compiled; final Rojo build and git diff --check passed.
- Next: manual client entry/exit/HUD feel validation, then Feed pedestal/transaction.
  No Computer Use, no live DataStore writes. Direct MCP: localhost:58741/mcp.

### Latest Session Handoff — HUD delay/startup fix — 2026-09-16

- Removed the second HUD timer. Each authoritative one-second PetIncome event
  updates the label immediately; MoneyAt still rejects older snapshot results.
- Replaced the unbounded FeedYourPetUI root wait with bounded waits and recovery
  by cloning the existing authored StarterGui asset. Missing templates fail with
  an explicit Rojo diagnostic; no runtime layout or world generator was added.
- Client controllers start independently under xpcall, so a stalled/failed HUD
  cannot prevent CarryController or IncomeEffectsController from starting.
- Files: src/client/Controllers/HUDController.luau, src/client/init.client.luau,
  src/client/UI/GuiBootstrap.luau, src/shared/Config/UIConfig.luau,
  docs/income.md, PROJECT_STATUS.md.
- Verification: direct MCP localhost:58741 confirmed Edit mode and the authored
  StarterGui template. Rojo synced the new helper. All client descendant scripts
  compiled; six Edit checks passed: missing-GUI clone, existing-GUI reuse,
  explicit missing-template failure, immediate payout label, stale snapshot
  rejection, and immediate next payout. Temporary test fixture was destroyed.
  Rojo build build/HUDFix.rbxlx and git diff --check passed.
- Limit: these are targeted Edit tests, not an end-to-end client Play test.
  The original reason Roblox's PlayerGui copy was missing is not established.
  If the authored StarterGui asset is absent too, recovery reports an error;
  restore the Rojo asset before retrying. No Computer Use or live data writes.

## 9. Known Issues / Blockers

- Conveyor alpha: production onboarding (initial pet/Money) is not implemented;
  existing developer Studio starter pet remains the test entry point.

- Current: visual Play review and real DataStore outage/rejoin tests remain.
  Broken pets stay in PendingRecovery until explicitly revived; free recovery
  is Studio-only. Published paid recovery/receipts remain unimplemented.
  Earlier MCP/Rojo connection blockers below are historical, not current.

- Six-player revision: Players.MaxPlayers is read-only through MCP and still
  reports 60. Set Maximum Players to 6 in Creator Dashboard for place
  127663486570625. PlotConfig.PlayerCapacity is six; excess arrivals are rejected
  when no plot is free, but that guard does not configure Roblox matchmaking.
- Latest plot session: all 18 multiplayer assertions pass. Rojo's listener was
  restarted on port 34872, but the Studio plugin did not reconnect automatically.
  Current changed scripts were synchronized from their filesystem contents via
  MCP for testing; reconnect Rojo before relying on future live sync. An initial
  run used stale code and was discarded. Filesystem/build remain authoritative.
- Static model edits in Studio must be exported back to PlayerPlots.rbxmx.
  Rojo does not reverse-export editor changes. See docs/plots.md.

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

Farm upgrades: static Workspace.FarmUpgradeSigns models bind by plot name.
PlayerGui SurfaceGui clones adorn the authored boards. Public sign attributes
are display-only; purchases validate private PlotService ownership and saved
data. Expected current level supplies stale/replay protection, with a save lock
until DataService confirms Money/FarmLevel persistence. No schema change.

Feed: non-yielding Food/outcome mutation, DataService queued atomic save,
per-player FeedLocks until presentation and confirmed save both finish.
Exploded pets live only in PendingRecovery, never usable Inventory. Server
outcomes drive client-only authored-template clones; UI/world assets remain
filesystem/Rojo-owned. No client RNG or paid recovery path exists.

Plot architecture:

- User preference: build models directly as editable Workspace Instances;
  do not add runtime scripts that generate fences or other world geometry.
- PlotService binds the static PlayerPlots folder. It does not create or clone
  geometry. A free plot is assigned to each Player instance and released on leave.
- Ownership attributes are display metadata; the private server map is authoritative.
- Plot number is session-only. Release never modifies Inventory/PlacedPetIds.
- Five physical slots are capped against loaded MaxPetSlots. Placement requests
  cannot choose plot ownership, slots, or expand capacity.
- PlacementService preserves inventory identity and reconciles presentation from
  saved placement. CarryService now handles visible pickup/equip; unequip returns
  the pet to inventory. Carry state is transient, not a new persisted pet record.

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
- `default.project.json` maps code roots, the StarterGui UI model and the static
  Workspace.PlayerPlots model asset. Other world Instances remain Studio-owned.
- `StarterGui.FeedYourPetUI` was authored using MCP and exported to
  `src/ui/FeedYourPetUI.rbxmx` for Rojo/Git persistence. Re-export Studio UI
  edits to this model before a filesystem resync; Rojo sync is not a reverse export.

## 12. Data / Persistence State

**DataVersion:** Player v2; Pet v2 (v1 migration implemented)

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

- PASS — 18 real multiplayer PlotVerification assertions: distinct ownership,
  owner metadata, full-server plot capacity, personal respawn references, five
  physical/active slots, all five slot CFrames, invalid-index rejection, anchored
  and fenced geometry, initial spawn, respawn ownership, departing-player release,
  freed-plot reuse, and new-owner metadata. Test ended automatically.
- PASS — 60 Studio models validated as identical translated layouts before
  export; all 60 have unique grid positions. Rojo static-asset build and diff check pass.
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

**Commit:** `015fe8d` (verified baseline before feed plate upgrades; this session's checkpoint follows)

**Message:** `feat: format displayed economy amounts with K M B T suffixes`

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

### Recovery choices — latest

Implementation now supports Revive OR Keep at level 0 after failed Feed. See
latest section 8 entry, not the superseded partial checkpoint notes. Core server
flow passed multiplayer tests; Studio MCP disconnected before remaining checks.

### Feed plate upgrades — 2026-09-19 (current)

See the latest entry in section 8. Plate level is now part of schema v4.
Keep FarmConfig intact; tune plate pricing/reduction in FeedPlateConfig.
Next: physically playtest the authored purple signs and Feed risk display,
then verify live persistence separately. No production data was used.

### One-second Money HUD — 2026-09-16 (latest)

- User requested HUD updates every second. HUDController buffers the newest
  timestamped balance/rate and redraws once per MoneyDisplayInterval=1 second.
  Both payout pushes and snapshot fallback use that same display buffer.
- User then clarified actual payouts should also be every second. TickSeconds,
  PopupInterval and MoneyDisplayInterval are now all 1. Common pays +10 per tick.
  Total earnings per second are unchanged. Older .25s timing notes are historical.
- Files: HUDController, UIConfig, MoneyConfig, IncomeEffectsController,
  MoneyVerification, docs/income.md and this handoff.
- PASS: all 16 updated MoneyVerification multiplayer checks, synchronized HUD
  compilation, Rojo build and diff checks. Test ended automatically.

### One-second Pet Popups — 2026-09-16 (latest)

- User clarified pet floating amounts should show every second, not every .25s.
  IncomeEffectsController now batches four payout messages and sums per PetId
  before displaying. Common level 0 displays +10 per four payouts.
- MoneyService and fast HUD updates remain unchanged at .25s; economy unchanged.
- Files: MoneyConfig, IncomeEffectsController, docs/income.md and this handoff.
  PopupInterval=1 is separate from PopupSeconds=.65 (animation duration).
- PASS: Rojo build, git diff --check, synchronized controller compilation. No
  new Play session was launched for this presentation-only interval change.

### Fast Payouts / Floating Money — 2026-09-16 (latest)

- Income tick reduced from 1s to 0.25s; per-tick amounts scale accordingly so
  per-second earnings are unchanged (Common level 0: +2.5 four times/second).
- MoneyService sends owner-only PetIncome batches containing authoritative balance,
  rate, timestamp and PetId/Amount entries. HUD updates on each payout; existing
  snapshots remain fallback. Timestamp ordering prevents stale balance regressions.
- Added IncomeEffectsController: clones authored BillboardGui above each earning
  pet, rises/fades for 0.65s, then Debris cleans it up. Fractional amounts displayed.
  Effects never award currency. Stored/held pets have no payouts or popups.
- Created editable ReplicatedStorage.PetIncomePopup through MCP, persisted in
  src/ui/PetIncomePopup.rbxmx and mapped by Rojo. One template verified in Studio.
- PASS: all 16 updated MoneyVerification multiplayer assertions; server/client
  synchronized syntax checks; Rojo build; git diff --check. Test ended automatically.
  Actual popup animation/overlap and viewport appearance have NOT been visually reviewed.
- Files: MoneyConfig, MoneyService, UIService, HUDController, IncomeEffectsController,
  client bootstrap, MoneyVerification, PetIncomePopup.rbxmx, default.project.json,
  docs/income.md and this handoff. No schema/economy-rate change.

### Placed Pet Income — 2026-09-16 (latest)

- Added MoneyService: one fixed server tick per second, summing placed pets'
  BaseIncome x FeedMultiplier. Requires loaded valid data and an owned plot.
  Locked placed pets earn; held/stored pets do not. No amount-granting Remote.
- Added FeedConfig's exact GDD level 0-40 multiplier table and MoneyConfig timing.
  Above-40 levels contribute zero (not balanced). No Variant/Trait/global bonuses,
  offline income, catch-up ticks, Feed transactions, or currency purchases added.
- UI snapshots include IncomePerSecond; Money HUD shows balance and +rate/s.
  Existing DataService saves the Money field; player/pet schema remains v2.
- PASS: all 15 multiplayer MoneyVerification checks, including automatic ticking,
  exact/summed rates, Feed curve, ownership, pickup stop and memory save. Test
  ended automatically. Rojo build, synchronized server compilation and diff pass.
- Files: MoneyService, MoneyVerification, FeedConfig, MoneyConfig, server bootstrap,
  UIService, HUDController, UIConfig, docs/income.md and this handoff.
- Next: simple pet wandering, then Farm/Food. Published DataStore rejoin and actual
  HUD visual/input review remain separate. Do not claim pending click/hold-E
  input tests passed merely because the server income integration passed.

### Larger Player Zones — 2026-09-16 (latest)

- Expanded all six actual Workspace plot Models through MCP editor property
  changes: Ground 40x40 -> 60x60; Pen floor 30x22 -> 45x33. Horizontal area is
  2.25x larger. Fence lengths/positions expanded; fence heights remain unchanged.
- Still three plots per side. Centers X=-50/+50, Z=-72/0/72 preserve the 40-stud
  center lane and leave 12-stud row gaps. Spawn/sign positions moved with plots,
  without enlarging their sizes. Five active pets and hold-E pickup unchanged.
- Exported all 84 existing BasePart sizes/CFrames back to PlayerPlots.rbxmx.
  Other properties, hidden markers, editable geometry and unrelated world kept.
  Pen-local saved positions remain valid inside the larger bounds.
- PASS: Studio read-only geometry assertions for all six plots, clear center
  lane, row spacing, Pen dimensions, fences, five hidden slots, anchored parts
  and spawn containment. Rojo build/diff checks pass. No Play server launched.
- Updated PlotVerification dimensions for the next multiplayer run. This turn
  does not claim previously pending free-position/pickup runtime tests passed.
- Direct MCP localhost:58741 is connected again (built-in bridge still empty).
- Files: PlayerPlots.rbxmx, PlotVerification.server.luau, docs/plots.md, this handoff.

### Hold-E Pickup — 2026-09-16 (latest)

- User requested holding E for pickup. Click/tap placement stays unchanged.
- PlacementService attaches a one-second pickup ProximityPrompt to placed pets.
  CarryService validates prompt/model ownership, actual placed state, character,
  distance and elapsed hold time. Leaving range/death/cancel invalidates the hold.
- Removed click pickup. UIService rejects EquipPet for placed pets, and the
  inventory button tells players to approach and hold E. Stored-pet equip stays.
- Updated CarryVerification for missing/short/cancelled/foreign pickup holds and
  successful held-E pickup. Live verification remains pending MCP reconnection.
- PASS: Rojo build and git diff --check. MCP connection check returned zero peers.
- Files: CarryConfig, CarryService, PlacementService, UIService, CarryController,
  HUDController, UIConfig, CarryVerification, docs/placement.md, PROJECT_STATUS.md.
- No save-schema or geometry changes in this revision. Prior free-position v2
  migration and input tests are still pending; do not treat older passes as current.

### Free-position Placement — 2026-09-16 (latest)

- User changed placement from fixed locations/hold E to clicking anywhere inside
  the fenced Pen. Hold prompts removed; equip remains in inventory. Clicking a
  placed owned pet requests nearby pickup into the hand. Mouse and touch supported.
- PlaceHeldPet request includes expected PetId and Vector3. Server checks actual
  held ID, ownership, live character, finite floor coordinates, Pen bounds and
  distance. UI request throttling remains. Five active pets maximum; rejecting
  placement leaves the pet held. No client-selected plot or inventory mutation.
- Player/pet schema v2 adds optional PenPosition {X,Z}, relative to the Pen floor.
  Snapshots and migration clone it. V1 upgrades preserve IDs and old slot positions;
  unchanged store names retain existing records. PlotSlot now tracks capacity and
  legacy fallback, not where users must place pets. Pickup clears PenPosition.
- Hidden all 30 static slot markers (Transparency=1, CanQuery/CanCollide/CanTouch=false).
  References retained for old saves and PlotService validation. No plots, fences,
  or pets deleted; markers are recoverable from Git. No geometry generated.
- 1.75-stud fence inset accommodates current 3-stud placeholder pets. Horizontal
  coordinates are not snapped/clamped; invalid near-fence positions are rejected.
- Updated CarryVerification for free placement, malformed/foreign/outside/air
  positions, exact visual/saved coordinates, pickup, capacity and v1 migration.
  These updated runtime tests have NOT run. Earlier hold-E test passes are historical.
- PASS: Rojo build and git diff --check. MCP ports 58741-58745 all report zero
  connected peers; Studio process 17852 is running. Live sync, compilation and
  actual mouse/touch tests remain unverified until the MCP plugin reconnects.
- Files: CarryController, CarryService, UIService, PlacementService, PetService,
  PlayerDataSchema, GameConfig, CarryConfig, PlacementConfig, CarryVerification,
  PlayerPlots.rbxmx, docs/placement.md and this handoff.
- Next: reconnect Studio MCP/Rojo; run CarryVerification and PlacementVerification,
  verify cursor alignment and pickup on both rotated plot rows. No gamepad cursor
  placement implemented. Prior production persistence/Dashboard-limit tasks remain.

### Equip / Hold E — 2026-09-15 (latest)

- Implemented MY PETS -> EQUIP PET -> walk into own Pen -> hold E for one second.
  Placed pets can be picked into the hand within ten studs; UNEQUIP stores them.
- CarryService welds a scaled clone of the authored template to RightHand (R15)
  or Right Arm (R6). Massless/noncolliding parts preserve the character assembly.
  No world geometry generator, pedestal, feeding, or conveyor was added.
- Server independently validates pet/plot ownership, live character, proximity,
  elapsed hold, cancellation and capacity. Client filters prompt visibility only.
  Old direct PlacePet/PickupPet UI requests are rejected; no hold bypass remains.
- Full Pen keeps the pet held. Switching/unequipping, death, respawn, removal and
  leave clean presentation without deleting inventory. Preparing the held model
  happens before removing persisted placement; existing schema v1 remains valid.
- PASS: all 19 CarryVerification multiplayer assertions. Initial run stopped at
  a deferred respawn cleanup assertion; cleanup now checks character identity and
  the test waits for the new character and cleanup before asserting. Rerun passes.
- PASS: all 28 updated PlacementVerification regression assertions; Rojo build,
  git diff --check and synchronized Studio script compilation. One Equip button
  confirmed in StarterGui. Tests ended automatically and preserved editor assets.
- Actual keyboard/touch/gamepad activation and visual hand pose are not verified;
  tests call the same server hold methods and inspect the configured E prompt.
- Files changed: CarryService, CarryController, CarryConfig, CarryVerification;
  both bootstraps, UIService, HUDController, UIConfig, FeedYourPetUI.rbxmx,
  PlacementVerification, docs/placement.md, PROJECT_STATUS.md.
- Next: manual interaction/pose review, simple wandering, then income. Previous
  live DataStore and Dashboard six-player setting limitations still apply.

### Developer Test Pet — 2026-09-15 (latest)

- User requested a pet in their inventory. Added StudioStarterPet.server.luau:
  grants one test_common through PetService after data loads, only for observed
  developer account iCopter0 (5250447342), only in Studio memory mode, and only
  when inventory is empty. No production reward or public grant Remote exists.
- Memory data resets between Play sessions, so this supplies a pet for manual
  placement/pickup testing on each fresh session. Nonempty inventories are kept.
- Other automated test tags skip the grant. StudioStarterPetVerification opts
  into a solo verification and returns count/species/unplaced validation.
- Files changed: src/server/StudioStarterPet.server.luau and this handoff.
  Source synchronized and compiled; Rojo build and diff checks pass.
- Solo runtime verification did not return an EndTest result; stop requested.
  Do not claim an actual grant was observed. The developer must start a fresh
  ordinary Play session to receive the configured pet; existing PetService
  creation is already covered by earlier integration tests.
- Next gameplay work remains wandering/income; no conveyor implemented.

### Placement / Pickup — 2026-09-15 (latest)

- Implemented server-authoritative placement and inventory pickup. Locked pets
  may move; repeated requests do not duplicate pets. Exactly five active slots.
- Six static templates in Workspace.PetTemplates; clones live in Pen.ActivePets.
  Save/autosave uses existing schema v1 fields. Leave clears visuals, not data.
- First multiplayer run: all 23 checks passed, including template failure,
  missing-model rebuild, memory save/migration and departing/replacement players.
  Final expanded run: all 28 assertions PASS, including the exact UI request
  handler, malformed/foreign requests, snapshot isolation and throttling.
- Rojo build, synchronized Luau compilation and git diff --check pass.
  Studio returned to Edit after both multiplayer tests.
- Final editor check found an extra placement-button preview from asset export.
  Removed both preview copies, restored one from the authored lock-button style,
  and verified exactly one PlacePet and one LockPet. Static asset also has one
  each. Rojo did not recreate an editor-deleted button automatically; recheck
  this UI subtree after a future full reconnect. No pet/plot data was removed.
- Actual button input and published DataStore reconnect remain unverified.
  Studio uses memory mode; no live data writes or Computer Use performed.
- MCP direct /mcp at localhost:58741 and Rojo localhost:34872 are connected.
  Older connection blockers below are historical. Maximum Players still needs
  the separate Dashboard setting to 6; code has only six assignable plots.
- Next: wandering, then income. Do not implement the reserved-center conveyor.
- Files: PlacementService, PlacementConfig, PlacementVerification, UIService,
  HUDController, UIConfig, server bootstrap, static PetTemplates/FeedYourPetUI,
  default.project.json, docs/placement.md and this handoff.

### Six-player Layout Revision — 2026-09-15 (latest)

- PASS: all 19 multiplayer assertions, including the revised six-plot layout,
  three plots per side, respawn, release and reuse. Rojo build/diff checks pass.
- Rojo live sync is connected again on port 34872; prior disconnected notes
  below are historical. Studio returned to Edit mode after the test.
- User clarified six players per server, three plots on each side and a future
  conveyor in the middle. Removed 54 extra plots (recoverable in commit 697648a),
  repositioned/rotated six existing Models, and updated the static model asset.
- Ground centers: X=-40/+40, Z=-48/0/48. The empty middle lane is 40 studs wide.
  Five pet slots per Pen remain unchanged. No conveyor logic/model was added.
- PlotConfig.PlayerCapacity=6; startup validates six plots independently of the
  platform setting and warns if Maximum Players is not 6. Physical slots bound
  assignment to six players. Dashboard player limit remains an external step.
- Updated docs/plots.md and PlotVerification for the six-plot layout.

### Plot Session — 2026-09-15 (latest)

- Completed static Workspace plots/Pens and PlotService. All 18 multiplayer
  checks passed, including respawn, leave and replacement-player reuse.
- Removed the initial uncommitted PlotTemplate generator after the user's
  instruction to put real models in Workspace. Geometry was built through MCP
  editor operations, then exported as a static .rbxmx asset for Git/Rojo.
- Main Studio is back in Edit mode, with Plot01 selected and the camera framed
  toward it. The disposable failed test processes were stopped; editor preserved.
- Rojo server is running on localhost:34872; its Studio connection needs restoring
  before future live edits. Exact current filesystem scripts were copied via MCP
  for this verification after stale-source detection. No Computer Use used.
- Next: placement/pickup preserving PetId, PlacedPetIds and PlotSlot; then wandering.
- UI runtime and live DataStore/cross-server verification remain pending separately.

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
