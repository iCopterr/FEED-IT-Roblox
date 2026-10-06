# Feed Your Pet — Implementation Rules and Workflow

Updated: 2026-10-06 (Asia/Bangkok).

This document consolidates the owner's project instructions and explains the
workflow used to implement changes. It is a reference, not a replacement for
`AGENTS.md`, the GDD, or the latest owner instruction. It does not authorize new
features, publishing, purchases, or production data changes.

## 1. Sources of truth

- [AGENTS.md](../AGENTS.md): repository rules and standing owner preferences.
- [PROJECT_STATUS.md](../PROJECT_STATUS.md): current implementation, tests,
  unfinished work, limitations, and session handoff.
- [Feed_Your_Pet_GDD_v0.5.md](../Feed_Your_Pet_GDD_v0.5.md): design reference.
- Existing source files, Git history, and relevant Studio state: what actually
  exists, rather than what chat memory suggests exists.

Apply the latest explicit owner decision when it supersedes an older design.
Otherwise follow the GDD. If a conflict is unresolved, explain it and ask before
changing gameplay. Do not treat unfinished work as wrong or recreate a system
just because a previous session implemented it.

## 2. Owner's standing implementation rules

### Keep the project focused

- The project is a Prototype / Pre-Production game. Validate the core loop and
  the decision: **"I love this pet. Do I stop now, or risk one more Feed?"**
- Prioritize gameplay feel, attachment, meaningful risk, correctness, and fast
  iteration rather than content quantity.
- Do not add trading, global marketplaces/leaderboards, worlds, breeding,
  battle passes, large quests, events, complex traits, or other out-of-scope
  systems unless explicitly requested.
- An explicit request can authorize a feature excluded by the original
  prototype scope. That does not authorize adjacent features automatically.
- Do not remove meaningful Feed risk or automatically risk a valuable pet.

### Preserve existing work

- Inspect before editing. Continue from the existing implementation.
- Preserve unrelated edits, uploaded artwork, authored UI, and Studio objects.
- Never reset, clean, discard, force-push, overwrite another session's work,
  or perform a destructive revert without clear authorization.
- When environment work is requested, do not move existing gameplay objects or
  redesign plot interiors without permission. The owner's earlier environment
  request allowed changes to the added Environment only, with no surrounding water.
- For UI changes, respect the owner's authored format and existing game style.
  Do not replace a layout unnecessarily.
- **Do not use the Roblox UI Director skill.** The owner explicitly prohibited it.

### Keep gameplay server-authoritative

- The server decides currency and food awards, hatch/rarity/variant results,
  Feed outcomes, level changes, ownership, creation, deletion, and repair.
- Clients request actions and display server results; they do not supply trusted
  economy values or decide outcomes through animations.
- Validate ownership, argument types, IDs, state, cooldown, affordability, and
  transaction eligibility for important remotes.
- Defend against spam, duplicate requests, forged PetIds, actions on another
  player's pets, overlapping transactions, disconnects, and retries.
- Studio/debug tools must be restricted to Studio or authorized developers.
  Use them for testing instead of manually grinding progression.

### Preserve identity, saves, and transactions

- Every individual pet keeps a unique server-issued `PetId` across loading,
  placement, Feed, explosion, repair, and reconnects.
- Preserve species, rarity, variant, traits, Feed level, locks, and creation
  information. Never identify a pet only by species or inventory position.
- Use versioned saves and migrations. Do not reset existing players to defaults
  when adding fields or features.
- Prevent duplication, item loss, and partial grants on retries, shutdown,
  reconnect, or multiple-server access.
- Developer Product receipts must be idempotent: the same receipt cannot award
  currency, pets, charms, or other rewards twice.
- Recovery must preserve the same pet. Failed Feed food stays consumed;
  repair must not automatically retry the failed Feed.

### Follow Feed resolution rules

- Consume food for an accepted Feed attempt, including failure.
- Roll Explosion before Critical. Critical is only rolled when no Explosion
  occurs; Miracle Save does not make a failed attempt a successful Feed.
- Critical-skipped levels do not receive intermediate Explosion rolls.
- Levels and income are authoritative; visuals represent the resolved result.
- Make success, Critical, growth, and failure recognizable and satisfying, but
  prioritize transaction correctness before visual polish.

### Keep code modular and balance centralized

- Prefer small services/controllers with clear responsibilities and explicit
  state transitions. Avoid giant scripts and unnecessary circular dependencies.
- Keep prices, probabilities, income multipliers, timers, and similar balance
  values in configuration modules rather than scattering magic numbers.
- Reuse helpers; avoid duplicated logic, unnecessary abstraction, deeply nested
  event chains, and uncontrolled global mutable state.
- Use useful Luau types and defensive validation. Comments should explain why.

### Use filesystem + Rojo for managed code

```text
Implementation in src/ → Rojo synchronization → Roblox Studio verification
```

- Determine whether a script is Rojo-managed before changing it.
- Edit managed Luau files in the repository, not primarily through Studio/MCP.
- Do not create competing filesystem and Studio versions of the same script.
- Use Studio/MCP for hierarchy/property inspection, world Instances, visual
  setup, gameplay tests, runtime state, and Output/errors.
- Check existing Instances before creating replacements, especially remotes.
- Never let multiple agents modify the same Studio state simultaneously.

### Verify UI and pet models honestly

- Follow the established font, text border, button, and shine style.
- Check desktop and mobile layouts, safe margins, sizing, alignment, scrolling,
  layering, and modal/HUD behavior relevant to the requested change.
- Preserve newer exceptions: remote panels do not automatically hide unrelated
  HUD, and Settings should layer below remote panels.
- Pet models require geometry and rig verification plus visual inspection from
  useful Studio angles. Remodel visible issues and recheck.
- Set a low part budget before building. Prefer reusable meshes/consolidated
  geometry; do not deliver thousands of individual parts. Report BasePart count.
- Low instance count does not prove low triangle count or good runtime FPS.
- Structural checks are not visual approval. If capture, rendering, device
  testing, or Studio connectivity is blocked, report what remains unverified.

### Commit and hand off

- Commit completed, verified changes at the end of an implementation session
  without asking again; include the handoff update and only relevant files.
- Use meaningful, scoped commit messages. Preserve unrelated owner changes.
- Do not push unless requested. A local commit is not a published Roblox update.
- Update `PROJECT_STATUS.md` before ending a meaningful session, including
  incomplete work and limitations. Never claim completion without evidence.

## 3. Newer gameplay decisions that override historical rules

These are current reference decisions, not permission to rebuild these systems.
Consult their configuration and handoff before modifying them.

- Food comes from the Money merchant. AFK farms, Tokens, consumable Protection,
  and feed-plate upgrades are retired. Plot capacity upgrades and the feeding
  pedestal remain active. Legacy fields exist for save compatibility only.
- Critical is **1%**, granting one additional level beyond normal success:
  **+2 total**, subject to the current level cap. Mega/Insane are retired.
- The **Pet Repair Station** replaces timed Revive. Broken pets retain identity
  and progression, have no 24-hour recovery expiry, and earn **10% of normal
  income** when placed in the pen (90% less).
- Explosion removes the pet from the feed plate and returns it to inventory/
  hotbar. Broken pets cannot be placed on the feed plate or fed until repaired.
- One Repair Charm clears damage; **100 Repair Shards = 1 Repair Charm**.
  Existing revive images, product IDs, and compatibility field names are reused.
- Basic Egg and fresh-player starting Money are **2,000**. Non-basic food Money
  prices were increased 30%; Basic Food was excluded.
- Offline earnings were explicitly requested despite the original exclusion:
  qualifying absence is at least **10 minutes**, with the existing **24-hour
  uncollected cap**. Do not reinterpret this as a 10-minute maximum.
- The requested money/sec leaderboard is the Roblox current-server player list,
  excluding the paid x2 multiplier. Do not expand it to a global board.
- Grow All uses a single **199 Robux** price. Reuse supplied product/image IDs
  and the existing commerce flow rather than inventing replacements.
- Money packs must respect the owner's requested PolicyService restrictions.
  Future paid random-item features need their own current policy review; this
  document is not a Roblox compliance approval.

Relevant details: [Feed](feed-config.md), [Repair](revive.md),
[Merchant](merchant.md), [Offline income](offline-income.md), and
[Monetization operations](MONETIZATION_OPERATIONS.md).

## 4. Practical workflow used for this project

### Step 1 — Understand the current request and repository

1. Identify the requested change and any newer owner instruction.
2. Read `AGENTS.md`, `PROJECT_STATUS.md`, and relevant GDD/documentation sections.
3. Run `git status` and `git diff` to identify existing changes.
4. Inspect the affected configuration, services, controllers, and saved data.
5. Inspect relevant Studio state through MCP when the task affects runtime,
   Instances, UI, world objects, or models. Documentation-only work need not
   launch a game test.
6. Determine what is already complete, what is broken, and what actually needs
   changing. Do not restart previous work from scratch.

### Step 2 — Choose a scoped implementation

1. State the intended outcome and important assumptions in plain language.
2. Prefer the smallest change compatible with the design and existing structure.
3. Identify authoritative state, identity preservation, persistence, and retry
   behavior before adding presentation.
4. Ask only when a missing choice materially changes the result or needs new
   authority. Do not invent a major system to resolve uncertainty.

### Step 3 — Implement in the correct source

1. Edit managed source files through targeted patches.
2. Centralize new balance values in the appropriate configuration.
3. Preserve unrelated changes and existing public interfaces when practical.
4. Add relevant verification cases or update expectations for changed behavior.
5. Let Rojo synchronize and confirm the correct scripts/Instances are present.

### Step 4 — Verify proportionately to risk

1. Check diffs, syntax, and the Rojo build.
2. Run focused detached tests for calculations, migrations, state transitions,
   and failures without touching real player saves.
3. Use relevant Studio gameplay/integration suites for actual service and client
   behavior; test multiple players where ownership or isolation matters.
4. For economy changes, test duplicate actions, invalid inputs, save retries,
   lost acknowledgements, disconnect/rejoin, and session conflicts as relevant.
5. For UI/models, inspect visuals and interaction, including device sizes and
   camera angles relevant to the change.
6. Run nearby regression tests. A successful build alone does not prove the
   whole game works or that production behavior has been tested.
7. Keep tests memory-only or isolated when possible. Do not make real purchases,
   overwrite production profiles, publish, or broaden changes without authority.

### Step 5 — Clean up, document, and commit

1. Remove only temporary test objects/markers created during the session and
   restore camera/UI state if changed for testing.
2. Review the final diff and confirm unrelated files remain untouched.
3. Update `PROJECT_STATUS.md` with Current Feature, Overall Progress, Completed,
   In Progress, Next Task, Files Modified, Known Issues/Blockers, changed
   Architecture Notes, baseline/working commit, and Session Handoff.
4. Commit the verified logical change and handoff; do not push automatically.
5. Give a concise result: what changed, what passed, what remains unverified,
   and any required publishing or user action.

## 5. Priority order when tradeoffs are necessary

1. Data correctness.
2. Transaction safety.
3. No duplication or item loss.
4. Server authority.
5. Core Feed gameplay.
6. Persistence.
7. Player understanding.
8. Gameplay feel.
9. Debuggability.
10. Performance.
11. Visual polish.
12. Additional content.

## 6. Example: the latest three-account gift

For UserIds `4750343708`, `123985255`, and `5250447342`, the requested gift was
implemented as 15 Repair Charms and 5 of each of the eight foods, added once on
join. The server allowlist and stable claim marker prevent repeated rewards.
The rewards and marker commit together during safe profile acquisition.

Verification included additive quantities, existing inventory preservation,
actual DataService acquisition through a detached adapter, a committed save
with lost acknowledgement, spending/rejoin, session locks, and overflow.
There were 112 gift checks and 19 live memory-only persistence checks. The
change was committed as `20c39b1`; production delivery still requires publishing
and joining a server running the new code.
