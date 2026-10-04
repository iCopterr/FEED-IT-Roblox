# Offline earnings

Owner-requested on 2026-10-04; supersedes the earlier GDD exclusion of offline
income. No farm, offline feeding, growth, hatch result or purchase is simulated.

## Rules

- Only pets placed in the saved pen earn offline Money.
- Rate uses the shared PetIncome calculation: feed level, variant and the
  broken-pet 10% income penalty. Paid x2 does **not** apply to offline earnings.
- Maximum **24 hours of uncollected offline time**, shared across visits. Leaving
  without collecting preserves the reward; it does not reset or extend its cap.
- Rate is evaluated from the last saved pets, not from a client estimate.
- New profiles and migrated v13 profiles receive no retroactive launch reward.
- Claiming transfers the bank into Money. No minimum away duration or fee.

## Persistence

Schema v14 adds `OfflineEarnings = {CheckpointAt, PendingMoney, PendingSeconds}`.
Load accrues inside DataService's exclusive session-acquisition UpdateAsync;
pending reward and the session lock become durable together. A retried lock
acquisition that already owns the same session skips accrual.

Each successful save/release persists a fresh timestamp alongside the detached
profile snapshot. Normal logout excludes online time. After a crash, offline
accounting resumes from the last durable snapshot, matching its persisted Money
and placed pets. Saves retain the record/session ownership checks.

Collect is server-only, ignores client-supplied amounts, shares FeedLocks with
other gameplay transactions, and atomically updates Money and clears the bank
before yielding to save. It never rolls back an ambiguous save. A retry confirms
the already-applied claim instead of granting again. Reconnecting sees either
the pending reward or the credited balance. Currency/ledger always save together.

## UI

`OfflineIncomeUI` is created by the client, using the game's font, outlines,
studs and money artwork. Positive pending rewards show a responsive welcome
popup with amount, credited duration and Collect. Full-menu HUD suppression
applies. Collect plays the existing SoundService Buy template only after server
confirmation, with generic click sound suppressed. Failed requests retain a
retry button; a late duplicate activation is ignored.

GuiService MenuOpened/MenuClosed toggle top and bottom screen reminders with
the offline rate and current cap estimate. These remain normal PlayerGui content;
they do not modify, replace or force themselves above Roblox CoreGui. On small
screens the native Roblox menu may obscure them. Actual ESC-menu layering and
audible playback require an interactive device check; callback wiring and sound
selection have automated coverage.

## Files / testing

- Balance: `src/shared/Config/OfflineIncomeConfig.luau`.
- Ledger: `src/server/Data/OfflineEarnings.luau` + DataService integration.
- Remote: `src/server/Services/OfflineIncomeService.luau` (`State`, `Collect`).
- Client: `Controllers/OfflineIncomeController.luau`, `UI/OfflineIncome.luau`.
- Detached test: `docs/studio/test-offline-income.luau` in Studio edit context.
- Opt-in multiplayer test: `OfflineIncomeVerification` (memory-only fixture).
- Regressions: `DataPersistenceVerification`, `PageFocusVerification`.

Verified 2026-10-04: 40 detached checks + 15 live UI/remote checks + 19 persistence
checks + 19 PageFocus checks. Rojo build and Luau compile checks pass. The live
fixture verifies the first Collect returns 36000 and a duplicate returns zero.
Seven identical extra copies of this task's Studio scripts were removed before
the final live rerun; no canonical source or unrelated asset was removed.

Studio defaults to process-local memory; stopping and restarting Play does not
preserve earnings. Do not enable production DataStore writes just to test this.
Use the detached save/rejoin harness or the isolated verification fixture.
