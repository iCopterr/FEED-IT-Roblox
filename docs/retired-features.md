# Retired-feature audit — 2026-09-23

Current gameplay is hatch/place/earn, buy food at the Money merchant, feed,
then timed Rescue or base-level reset on failure. This supersedes historical
Farm and Protection sections in the GDD and older project-status entries.

Removed after checking bootstrap, imports, Studio and the current redesign:

- AFK farm and farm upgrade configs, services, controllers and sign view.
- Feed-plate upgrade config, service, controller and sign view. The feeding
  pedestal itself remains active.
- Unmapped farm/plate upgrade sign assets (already absent from Studio).
- Old Token-merchant and retired farm/plate tests and obsolete guides.
- Token-protection risk tables, old rarity food costs and unused RNG injection.
- Unused Stud tint helper and obsolete fixed-income-per-rarity table.
- Farming action guards and debug snapshot fields for retired gameplay.

Current tests cover RNG order/caps, per-food risk boundaries, migrations,
Money food purchases, duplicate requests, timed Rescue, and debug commands.
Removed files can be recovered from Git before this cleanup commit.

Intentionally retained:

- Schema v9 legacy fields and defaults: FarmLevel, FarmPower, FeedPlateLevel,
  Tokens and ProtectionTokens. They keep old data readable and have no active
  gameplay effect. Currency validation caps now live inside PlayerDataSchema.
- DataService/DataStoreAdapter: published servers use these for persistent player
  records; ordinary Studio tests use their isolated in-process memory mode.
- Plot capacity upgrades, food risk reductions, pedestal, timed Rescue,
  wandering, egg templates, and Studio art recipes are still used or retained
  project assets. No world art or player data was deleted.

Historical project-status sections are an audit trail, not the current design.
