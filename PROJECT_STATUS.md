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

The immediate priority is establishing the Git/Rojo project foundation.

## 2. Overall Progress

| System | Status | Notes |
| --- | --- | --- |
| Project Setup | ✅ Complete / Verified | Filesystem layout, toolchain, build, and server launch verified. |
| Git Setup | ✅ Complete / Verified | `main` tracks `origin/main`; initial commit pushed successfully. |
| Rojo Setup | 🟦 Implemented / Needs Testing | Rojo 7.7.0 and Studio plugin installed; interactive Studio connection pending. |
| Base Architecture | 🟨 In Progress | Client/server/shared roots exist; gameplay modules not started. |
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

**Current Feature:** Rojo Studio Connection Verification

**Status:** 🟨 In Progress

**Objective:** Connect the installed Rojo Studio plugin to `localhost:34872`
and confirm live filesystem-to-Studio synchronization.

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

## 5. In Progress

- Verify the Rojo plugin connection inside Roblox Studio.

## 6. Next Tasks

1. Verify Rojo → Roblox Studio synchronization.
2. Save or publish the Studio-owned prototype place and document its location.
3. Establish the smallest useful configuration and service/controller modules.
4. Begin the minimum persistent player-data architecture.
5. Begin the unique Pet identity/data model.

## 7. Files Modified This Session

```text
.gitattributes
.gitignore
README.md
default.project.json
rokit.toml
src/client/init.client.luau
src/server/init.server.luau
src/shared/ProjectInfo.luau
PROJECT_STATUS.md
```

## 8. Current Uncommitted Work

None. The working tree was clean after commit `282e2d9`; this status update is
the only follow-up change before its documentation commit.

## 9. Known Issues / Blockers

- Roblox Studio synchronization requires Studio to be installed/opened and the
  Rojo plugin connection to be tested interactively.
- The Studio-owned place location has not yet been recorded.

Neither issue blocks filesystem-based architecture work after the Rojo build is validated.

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

## 11. Rojo / Studio State

**Rojo:** Rokit 1.2.0 and pinned Rojo 7.7.0 installed; build and serve verified.

**Studio Plugin:** Installed at `%LOCALAPPDATA%/Roblox/Plugins/RojoManagedPlugin.rbxm`.

**Studio Connection:** Interactive connection not yet verified.

**MCP Connection:** Not documented.

Ownership boundary:

- `src/` contains filesystem/Rojo-managed code.
- The Roblox place contains Studio-managed world Instances.
- `default.project.json` intentionally maps only code roots, preventing two
  sources of truth for the prototype world.

## 12. Data / Persistence State

**DataVersion:** Not established

**Persistence:** Not implemented

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
- PENDING — Rojo Studio plugin live synchronization.
- PASS — Commit `282e2d9` pushed to `origin/main` and upstream tracking configured.
- PENDING — Fresh-clone verification.

## 15. Last Known Working State

No playable prototype state has been established. The filesystem project
foundation and Rojo CLI are working; Studio live synchronization remains to be tested.

## 16. Last Working Git Commit

**Commit:** `282e2d9`

**Message:** `chore: initialize Git and Rojo project`

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

Created the initial Git/Rojo repository foundation and documented the workflow.

### What Is Currently Incomplete

Studio plugin sync verification, Studio place location documentation, and a
fresh-clone verification.

### Next Agent Should

1. Read `AGENTS.md`, this file, and relevant GDD sections.
2. Run `git status` and `git diff`.
3. Finish the verification items above rather than recreating the setup.
4. Record the Studio place location after it is created or identified.
