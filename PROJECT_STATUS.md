# Feed Your Pet — Project Status

**Phase:** Prototype

**Design Reference:** `Feed_Your_Pet_GDD_v0.5.md`

**Last Updated:** 2026-09-23

### Current session — remove retired systems (2026-09-23)

- Current feature: dependency-audited cleanup after the Money-food redesign.
  Deleted retired AFK farm and farm/plate upgrade services, configs, controllers,
  sign views/assets, Token merchant tests, unused Stud helper and old guides.
  Removed obsolete protection risk/rarity food-cost tables, rarity-wide income
  anchors, farming guards and retired debug fields. Active balance is unchanged.
- Save schema stays v9. Legacy farm/plate/token fields remain compatible and
  inert; legacy token caps now live in PlayerDataSchema. DataService and its
  memory/persistence adapter remain required transaction infrastructure.
- Updated current Feed resolver/migration and debug tests; merchant, selected
  food, Feed failure and timed Rescue continue covered by FoodShopVerification.
  Details and retention rationale: `docs/retired-features.md`.
- Owner preference recorded in AGENTS.md: commit completed verified work each
  implementation session, including handoff; do not push unless requested.
- Verification complete: Feed RNG/migrations 48, FoodShop/UI 37, Debug 47,
  Inventory 227, legacy Rescue 22, Travel 23, Eggs 157, NumberFormat 41:
  all 602 assertions pass. All 88 remaining Luau scripts pass Studio syntax
  checks; Rojo build and diff checks pass. Studio returned to Edit mode.
  No active world art or player data deleted; retired files recoverable in Git.
  Overall: cleanup complete. Next: playtest current loop; no cleanup blockers.
  Files: retired configs/services/controllers/signs/tests/docs plus their
  dependents, schema compatibility limits, README, AGENTS and this handoff.
- Baseline commit cf3398f. Earlier sections below are historical handoffs and
  may describe retired mechanics; this section and design-decisions.md take
  precedence for current behavior.

### Latest session — unlimited egg purchases / remove MY EGGS screen

- Removed the one-egg ownership/incubation cap. Players can keep buying eggs
  while other eggs are unplaced, incubating or ready; affordability, offer
  ownership and the short transaction/save lock are still server validated.
- Removed the obsolete authored `EggUI` / MY EGGS ScreenGui and its controller.
  Stored eggs remain available in the Inventory Egg tab and hotbar. Placed eggs
  remain visible in the compact right-side Growing Eggs panel; manual E hatch
  and remote hatch both remain available.
- Purchase feedback now directs players to Inventory. Egg placement errors also
  reopen Inventory instead of the removed screen. Removed stale EggPanelOpen
  checks from client controllers and updated egg documentation/tests.
- PASS: Rojo build and `git diff --check`; two-player EggVerification 157/157
  (including a second purchase while the first egg incubates); two-player
  InventoryVerification 227/227; FoodShop/UI startup 37/37. One earlier
  inventory run hit the known tween timing assertion, then passed unchanged.
- Files: EggConfig, EggService, Conveyor/Carry and modal controllers,
  ConveyorVerification, UI verification, `default.project.json`, `docs/eggs.md`,
  removed EggController/EggUI, and this handoff. The implementation was captured
  in user-created commit `cf3398f`; this final verification note is uncommitted.

### Latest session — baby griffin beside black wolf

- Created `Workspace.BabyGriffin_RigTest`: oversized cream eagle head, hooked
  gold beak, layered small wings, feathered chest, front talons, tan lion body,
  hind paws and tufted tail. No animations or gameplay integration.
- Seven studs beyond wolf away from fox for wing clearance; root
  (216.50, 1.615, 49.05), matching display standing plane. Existing off-island
  row preserved; ground needed before runtime physics testing.
- PASS Edit checks: 67 connected unanchored parts, 9 aligned motors,
  Torso-only collision, matching root size, Animator and relative placement.
  Screenshot inspected; runtime not tested. Selected and framed for review.
- New editor recipe `docs/studio/build-baby-griffin.luau`; Studio-owned outside
  Rojo. Save place for persistence. Next user visual review. Recipe/handoff
  only changed; other dirty work preserved. No commit; last recorded working
  commit 7c33222. Overall gameplay progress unchanged.

### Latest session — black wolf beside fox

- Created `Workspace.BlackWolf_RigTest`: charcoal coat with slate highlights,
  heavy chest, layered mane, amber eyes, pointed ears, small fangs, large paws
  and long dark-tipped bushy tail. No animations or gameplay integration.
- Six studs beyond fox away from bunny; root (209.50, 2.31, 49.05), shared
  standing plane. Existing off-island display row preserved; needs ground for Play.
- PASS Edit checks: 71 connected unanchored parts, 9 aligned motors,
  Torso-only collision, matching root size, Animator and relative placement.
  Screenshot inspected. Runtime not tested. Selected and framed for review.
- Recipe `docs/studio/build-black-wolf.luau`; Studio-owned outside Rojo mappings.
  Save place for persistence. Next user appearance review. Recipe and handoff
  only changed; prior dirty work preserved. No commit; last recorded working
  commit 7c33222. Overall gameplay progress unchanged.

### Latest session — fox beside horned bunny

- Created `Workspace.Fox_RigTest`: orange coat, white chest/cheek ruff and
  muzzle, pointed dark-lined ears, dark paws and raised white-tipped tail.
  No animation or gameplay integration. Existing models preserved.
- Six studs beyond bunny away from boar, same standing plane; root
  (203.50, 1.795, 49.05). Off-island display row needs ground before Play.
- PASS Edit checks: 44 connected unanchored parts, 9 aligned motors,
  Torso-only collision, matching root, Animator and relative placement.
  Screenshot capture timed out; visual screenshot and runtime checks pending.
- New editor recipe `docs/studio/build-fox.luau`; Studio-owned outside Rojo.
  Selected and framed; save place for persistence. Next: user visual review.
  Recipe and handoff only changed; concurrent roster/UI work preserved.
  No commit; last recorded working commit 7c33222. Gameplay progress unchanged.

### Latest session — initial five-egg / thirty-pet roster

- Replaced placeholder display names with the requested 30-pet roster across
  Basic, Advanced, Elite, Master and Supreme Eggs (six pets per Egg). Stable
  internal SpeciesIds were retained so authored templates and saved identity
  continue resolving without remapping.
- Every species now has its own configured base income. All 30 values are
  unique; rarity remains descriptive and no longer forces one shared income.
  Existing saved pets intentionally retain their saved rarity and BaseIncome.
- Every result has an individual hatch weight, including different weights for
  pets of the same rarity. Each Egg pool totals exactly 100%. The Egg panel now
  displays pet name, rarity and exact chance so duplicate rarity labels are not
  ambiguous. Debug species selection now shows name, rarity and income.
- Updated MoneyVerification for per-species values and documented the complete
  tuning table in `docs/pet-roster.md`. Placeholder pet models are unchanged.
- PASS: Rojo build and `git diff --check`; live config audit (5 Eggs, 30 pets,
  6 per Egg, unique incomes, 100% pools); two-player EggVerification 157/157;
  two-player MoneyVerification 16/16; Studio syntax analysis 0 errors across
  ReplicatedStorage, ServerScriptService and StarterPlayer.
- Files: PetConfig, EggConfig, PetService, EggController, DebugController,
  ConveyorVerification, MoneyVerification, pet-roster documentation and this
  handoff. Next: playtest economy/odds and tune the centralized values. No
  commit requested; last working commit remains 7c33222.

### Latest session — horned bunny beside boar

- Created `Workspace.HornedBunny_RigTest`: cream body, long pink-lined ears,
  branched tan antlers, cheek fluff, buck teeth, long hind paws and round tail.
  No animations or gameplay integration. Existing models preserved.
- Six studs beside boar on the side away from chicken; follows current moved
  display arrangement. Root (197.50, 1.495, 49.05); shared standing plane.
  Display row remains off-island; ground needed before runtime physics testing.
- PASS Edit checks: 46 connected unanchored parts, 9 aligned Motor6Ds,
  Torso-only collision, matching root size, Animator and relative placement.
  Screenshot inspected. Runtime behavior not tested. Selected/framed model.
- Recipe: `docs/studio/build-horned-bunny.luau`; Studio-owned, outside Rojo.
  Save place for persistence. Next user appearance review. Files changed:
  recipe and handoff only; prior dirty work preserved. No commit this session;
  last recorded working commit 7c33222. Gameplay progress unchanged.

### Latest session — boar left of chicken

- Created `Workspace.Boar_RigTest`: brown stocky body, ivory tusks, snout,
  bristled mane, pointed ears, split hooves and curled tail. No animations.
- Placed seven studs along the chicken's local left, with matching standing
  plane and orientation. Current root (178.45, 2.065, 49.05); chicken has been
  moved to (185.45, 2.12, 49.05). These are off the island: placement follows
  user's display layout; runtime pets would need ground before Play testing.
- Initial ground ray hit the nearby dragon wing; corrected boar elevation to
  the chicken's standing plane. Recipe now uses that plane directly.
- PASS Edit checks: 54 connected unanchored parts, 7 aligned motors,
  Torso-only collision. Humanoid/Animator and calculated HipHeight present.
  Screenshot inspected; Play behavior not tested. Next user visual review.
- New editor recipe `docs/studio/build-boar.luau`; Studio-owned model outside
  Rojo mappings. Save place for persistence. Handoff and recipe only changed;
  other uncommitted work preserved. No commit; last working commit 7c33222.

### Latest session — IceDragon V2 detail pass

- Updated existing `Workspace.IceDragon_V2` with 92 welded detail parts:
  overlapping flank armor, throat plates, cheek/shoulder crystals, eye rims,
  nostrils, luminous gill marks, frosted leading edges, wing veins/tips/crests,
  breast crystal and tail crown. Richer blue body/ribs and pale wing palette.
  Existing surface/material edits preserved; no animation or gameplay changes.
- Backup: `ServerStorage.IceDragon_V2_BeforeDetails_1790153897`.
  Recipe: `docs/studio/detail-ice-dragon-v2.luau`; refuses duplicate application.
- PASS Edit checks: 1870 connected unanchored parts, 9 aligned Motor6Ds,
  1860 welds; Torso-only collision; 92 added details. Viewport inspected.
  Runtime behavior not tested; high-part-count art prototype still requires
  consolidation before production cloning. Selected and framed for user review.
- Next: user appearance feedback. Studio-owned model outside Rojo; save the
  place to persist it. Files: detail recipe and handoff; other dirty work kept.
  Last working commit 7c33222; no commit. Overall gameplay progress unchanged.

### Latest session — five egg tiers / thirty pet placeholders

- Egg order: Basic -> Advanced -> Elite -> Master -> Supreme. Basic keeps
  prototype_egg internal ID so existing eggs/pets remain compatible.
  Each tier has six distinct species IDs and six authored pet model slots.
- Preserved existing 18 species/pools; added Master Pet 1–6 and Supreme Pet
  1–6 placeholders using copies of existing Elite models. No final pet designs
  or new species names chosen. Five egg templates reuse current shell geometry.
- Existing first-three prices/timers unchanged. Temporary Master 5B/20min,
  Supreme 50B/30min; their provisional pools use Elite weights/rarity incomes.
  Conveyor weights: 68/25/5/1.5/.5. Balance centralized, not final economy.
- Files: EggConfig, PetConfig, ConveyorConfig, EggTemplates/PetTemplates,
  ConveyorVerification, this handoff. Stud materials preserved.
- Build/diff pass. Removed 16 verified identical editor/Rojo duplicate clones;
  source assets preserve all new templates. All 157 two-player EggVerification
  checks passed, including purchases, timers, placement, hatch and save/load
  for Master/Supreme. Studio confirms five eggs with six unique slots each.
- Complete; user supplies final pet choices and balance adjustments later.
  Existing dirty work preserved; not committed. Last commit 7c33222.

### Latest session — ivory and shadow creature concept

- User requested an approximate adaptation of supplied ivory-armored, hollow
  dark creature with gold ornaments and a shadow beast underneath.
- Created `Workspace.IvoryWraith_Concept` via connected Edit MCP port 58742:
  tall arched neck, branching horns, open oval armor frames over dark core,
  elongated legs, gold bridle/charms, ragged shroud and low clawed shadow beast.
  Existing chicken/dragon models preserved. No animation or gameplay integration.
- PASS: 439 unanchored connected parts, 8 Motor6Ds, 430 cosmetic welds;
  Torso-only collision; joint transforms aligned; matching root and Animator.
  HipHeight calculated from geometry; viewport screenshot inspected. Runtime
  standing/movement NOT tested. Art prototype needs optimization before mass use.
- New editor-only recipe: `docs/studio/build-ivory-wraith.luau`. Model remains
  Studio-owned outside Rojo mappings, near X=13/Z=78; save place for persistence.
  Selected model and framed camera. Next: user concept/silhouette feedback.
- Files modified: recipe and handoff only. Other dirty work preserved.
  Last working commit: 7c33222. No commit this session; gameplay progress unchanged.

### Latest session — preserve Studio stud/material edits

- Captured current Studio appearance: all 428 BaseParts in seven Rojo-managed
  world roots use Plastic (256) and Studs (3) on all six faces. No Texture/Decal
  children existed inside those mapped roots.
- Saved exact settings in SkyIsland, PlotUpgradeSigns, MysteryMerchant,
  EggTemplates, PetConveyor, PetTemplates and PlayerPlots .rbxmx assets.
  Existing conveyor extension and merchant relocation retained.
- Build/diff checks pass. Requested commit scope: these seven world assets
  and handoff; unrelated UI/gameplay changes stay uncommitted. Standalone
  Studio-owned art outside Rojo mappings unaffected: save place for persistence.
- Future mapped-model appearance edits must be exported to files before
  reconnecting Rojo, because filesystem properties override Studio edits.

### Latest session — reference-inspired IceDragon V2 art trial

- User's new style direction supersedes uniformly box-shaped pets: angular
  sculpted anatomy, raised neck, tapered muzzle/tail, broad scalloped wings,
  stud surface detail and selective glow, based on their supplied references.
- Created standalone `Workspace.IceDragon_V2` at (13, 3.45, 49) through port
  58742 after Studio plugin reconnected. Older dragon and chicken preserved.
  New editor-only recipe: `docs/studio/build-ice-dragon-v2.luau`.
- Completed art/rig construction: tapered faceted segments, swept horns,
  jaw/teeth, bent legs/claws, cyan eyes and dorsal crystals. No animations or
  gameplay integration. Humanoid/Animator; calculated HipHeight; matching root.
  Torso is an invisible sole collider under welded visible body surfaces.
- PASS Edit checks: 1778 parts, 9 Motor6Ds, 1768 welds; all connected,
  unanchored; Torso-only collisions; joint position/orientation alignment.
  Viewport captures inspected. Runtime standing/movement not tested.
- IMPORTANT: detailed wedge-built ART TRIAL, not a production pet template.
  High part count needs mesh/CSG consolidation before cloning across pens.
  Next: user silhouette feedback, then geometry optimization if accepted.
- Studio-owned model outside Rojo mapping; save place for persistence.
  Recipe retained for reconstruction. Files: recipe and this handoff only;
  other ongoing uncommitted UI/gameplay work preserved. No commit made;
  last recorded working commit 56814f9. Overall gameplay progress unchanged.

### Latest session — horizontal side-panel transition

- PenManager opens from offscreen right to its compact resting position (.24s),
  closes toward the right (.18s). Replaced header X with an authored red >
  collapse button outside the left edge, vertically centered.
- Motion.BindPopup accepts optional FromRight; other popups keep their current
  vertical animations. Existing remote/manual gameplay unchanged.
- Files: UI/Motion, PenManagerController, PenManagerUI and this handoff.
  Build/diff pass; synced source verified. Edit tween check did not advance
  while outside Play; added actual client tween assertions to inventory test.
  All 227 two-player inventory checks passed, including horizontal entrance,
  exit and restored position on both clients. Initial fixed-frame close probe
  was timing-sensitive; replaced with position tracking across the transition.
- Complete; next user motion trial. No commit; prior dirty work preserved.
  Last working commit remains 56814f9.

### Latest session — compact right-side manager sizing

- Reduced manager to a compact right-edge card: 510x440 authored design,
  max .82 scale, targeting ~22% screen width / 34% height on desktop.
  At 1920x1080 rendered size is about 418x361. Right margin 16px.
- Dock hides while panel is open and returns on close, matching reference
  interaction; dock scales/centers with viewport. Existing X closes the panel.
  Small-screen fit constraints retained; all remote/manual behavior unchanged.
- Files: PenManagerController and PenManagerUI asset. Studio empty-panel
  screenshot inspected; preview restored. Desktop/mobile bounds assertions,
  build and diff check pass. No new gameplay test for sizing-only change.
- Complete; next user visual trial. Rojo connect prompt still visible in Studio;
  authored geometry mirrored in Edit, controller changes need connected Rojo
  for reliable Play sync. Prior work preserved; no commit; last 56814f9.

### Latest session — right-side egg/pet manager

- Added authored StarterGui.PenManagerUI ScreenGui asset and Rojo mapping.
  Two stacked right-middle egg/paw buttons open a scrolling shared panel with
  model-preview rows, hatch countdowns or pet income/capacity, and per-row actions.
  Uses current cyan/stud/outlined style and existing Motion helper.
- HatchRemote reuses the authoritative Hatch transaction/cache/cooldown and
  only skips proximity. Ownership, placement, ready time, character and locks
  remain checked. Existing E Hatch still requires proximity. PickupRemote
  validates owned placed pets and uses PlacementService to return to inventory.
  No Grow All/Equip Best/paid upgrade behavior added from reference screenshots.
- UI layout is static editable ScreenGui/row template. Controller clones rows,
  binds models/data and actions, handles resizing/polling and modal switching.
- 215 two-player InventoryVerification checks passed including foreign pickup
  rejection, distant pickup and replay rejection. Build/diff checks pass.
  All 117 EggVerification checks passed, including remote distant hatch and
  cached replay across routes; two new client hierarchy checks added after the
  inventory run. Empty panel screenshot inspected; increased icon/title sizes.
- New ScreenGui did not initially appear via Rojo; imported exact authored
  instance tree into StarterGui in Edit (not a runtime builder). Screenshot
  later shows Rojo connect prompt; reconnect may be needed for future sync.
- Files: PenManagerUI, PenManagerController, client init, default.project,
  EggService/UIService, Conveyor/Inventory server tests and inventory client
  test, this handoff. Existing dirty work preserved. No commit; last 56814f9.
- Verified Studio has exactly one ScreenGui, automatic vertical scrolling and
  final 48px icons/32px title. Confirmed new controller, remote hatch code and
  remote test code present in Studio. No new UI layout scripts in runtime.
- Complete; next user mouse/touch interaction and populated-list visual trial.

### Latest session — pen pets hidden from inventory

- InventoryModel excludes pets with Placed=true from bag entries. All/Pets
  lists, search, inventory count and selected detail use the filtered entries.
  Existing reconciliation removes their hotbar shortcuts; pickup restores
  availability under the same pet ID. Pen capacity count remains unchanged.
- Server ownership/data records are untouched: no deletion, migration,
  income/placement change or variant loss. Eggs/feed-plate behavior unchanged.
- Files: client/UI/InventoryModel, InventoryVerification.client, this handoff.
  Build/diff checks pass; all 212 two-player InventoryVerification checks pass,
  including new place/hide/pickup/identity tests on both clients. Complete.
  Existing dirty work preserved; no commit. Next: user playtest.
  Last working commit remains 56814f9.

### Latest session — popup TweenService motion

- Added reusable UI/Motion and UIMotionController. Popup opening slides 18px
  into position over .18s; explicit corner-close buttons slide out over .1s.
  Gameplay-triggered visibility changes remain immediate; no remote delay.
- Popup buttons use authored MotionScale children: 1.025 hover, .96 press,
  .09s easing, with mouse/touch handling and selected-card pulse. No HUD motion
  or layout changes. Runtime binds existing UI; does not generate UI geometry.
- Motion tracks responsive resting position, cancels superseded tweens,
  invalidates old close callbacks after hide/reopen, resets hidden buttons and
  disconnects per-button panel listeners on destruction.
- Verification: build/diff check pass. Isolated Studio checks passed for
  open settling, close restoration, resizing during animation, rapid reopen,
  authored button scale and cleanup. All 37 two-player FoodShopVerification
  checks passed. Final selection-pulse wiring was added after this run and
  covered by build/source checks, not a second multiplayer run.
- Files: new UI/Motion and Controllers/UIMotionController; client init and
  six popup controllers; five popup assets; this handoff. Existing dirty work
  preserved; no commit. Next user motion/feel trial (mouse and touch).
  Last working commit remains 56814f9.

### Latest session — popup typography/borders match HUD

- Inspected existing Inventory/Base/Merchant HUD controls in Studio: Fredoka
  One, 5px dark-purple contextual text outline, 5px dark-tinted button border
  and 15px corners. Applied that treatment to popup assets only, preserving
  texture, color, larger headings, layout and action semantics.
- Added authored contextual TextOutline and missing ButtonBorder strokes.
  Emoji labels excluded from font/outline change. Pet/food card selection
  remains white; default border uses dark tint and 5px thickness.
- Verification: Rojo build and diff check pass; Studio font/thickness
  assertions pass. Merchant screenshot inspected; temporary preview restored.
  HUD/hotbar/banner subtrees verified unchanged. No new full gameplay test
  for this cosmetic pass (previous 37-check run passed).
- Files: five popup UI assets, InventoryController, UI/FoodCard and handoff.
  Complete; next user visual trial. Existing dirty work preserved. No commit;
  last working commit remains 56814f9. No known blocker.

### Latest session — cleaner popup text and consistent buttons

- Removed repeated popup tutorials/footer hints and shortened inventory empty
  states. Kept transaction errors, quantities, prices, timers, food effects,
  feeding explosion chance and failure consequence. Rescue timer/food-spent
  information retained. No gameplay changes.
- Enlarged popup title text (36px standard; 30px food sidebar, 26px Debug).
  Sidebar title simplified to FOOD. Existing header bands/layout preserved.
- Authored stud-texture overlays on popup TextButtons; existing ImageButtons
  use matching 96px tiled studs. Overlays are noninteractive; existing labels,
  action colors and button handlers retained. No runtime UI generation.
- Verified HUD/hotbar/banner/open-button asset subtrees unchanged. Build and
  diff check pass; Studio confirms texture instances are present/noninteractive.
  All 37 two-player FoodShopVerification checks passed. Merchant screenshot
  confirms larger readable heading and textured buttons; preview restored.
  Full manual input/mobile visual pass remains for user playtest.
- Files: five popup assets, Inventory/Feed/Egg/Merchant/Revive controllers and
  this handoff. Prior dirty work preserved; no commit. Next user visual trial.
  Last working commit remains 56814f9.

### Latest session — merchant follows extended conveyor

- Moved all 10 existing MysteryMerchant parts +44 studs along Z, preserving
  the previous gap beyond the conveyor end. Shop Base now Z=156; interaction/
  teleport point Z=147.5. Persisted authored asset; no runtime builder.
- TravelService and MerchantService already resolve the moved InteractionPoint,
  so teleport, prompt and purchase-distance validation use the new location.
- Studio Edit assertions pass: shop position, interaction clear of belt,
  shop inside island. Rojo build and diff check pass; no new full Play test.
- Files: src/world/MysteryMerchant.rbxmx and this handoff. Complete; next user
  visual/Play check. Other dirty work preserved; no commit; last commit 56814f9.

### Latest session — conveyor aligned with outer plots

- Resized existing authored Workspace.PetConveyor from 184 to 272 studs along
  the existing center-lane Z axis. Base/rails now end at Z=-136 and +136,
  matching the outer Ground borders of the end plots on both sides.
- Kept width, height and travel direction. Deck length 269.6; rollers at
  +/-135.4; Start/Finish markers at -133/+133 (three-stud edge clearance).
  Redistributed all 18 existing treads and moved the existing sign to Z=-138.
  No new model generator or geometry; persisted changes in PetConveyor.rbxmx.
- Existing ConveyorService reads Start/Finish, so egg travel follows the
  extended lane. TravelSeconds remains 36 (longer route means faster movement).
- Verification: Studio Edit assertions pass for end alignment, marker bounds,
  unchanged width and contained treads; Rojo build and diff check pass.
  No new full Play test or screenshot check in this resize session.
- Current feature complete; next: user visual/Play check of extended belt.
  Files: src/world/PetConveyor.rbxmx and this handoff. Other uncommitted work
  preserved. Last commit remains 56814f9; not committed. No known blocker.

### Latest session — rare hatch variants

- Current feature: newly purchased conveyor eggs reserve a server-only,
  species-independent Variant alongside the existing reserved pet result.
  Shiny 1/1,000 (2x income), Rainbow 1/10,000 (5x), Celestial 1/100,000 (10x);
  Normal 99.889%. Mutually exclusive integer ticket roll, centralized config.
- Shared PetIncome now drives authoritative payouts, inventory estimates and
  Feed result income. Names in inventory/hotbar, hatch results, Feed and Rescue
  include non-Normal variants. Food costs, Feed risk/critical odds unchanged.
- Existing eggs/pets remain unchanged; debug-spawned pets remain Normal.
  Existing schema already preserves Variant, so no migration/version bump.
  No traits, pity, luck boosts, skins/VFX or new UI Instances introduced.
- Completed verification: Rojo build and diff check; two-player EggVerification
  passed, including exhaustive 100,000-ticket counts, income multipliers,
  reserved variant persistence and hatch replay. All 37 two-player
  FoodShopVerification checks passed, including Rainbow preservation through
  Rescue and automatic level-zero reset, plus both client UI startups.
- Files: new shared/Config/VariantConfig and shared/PetIncome; EggService,
  MoneyService, FeedService, ReviveService; client/UI/InventoryModel;
  ConveyorVerification and FoodShopVerification; docs/variants.md; this handoff.
- Overall: gameplay implementation complete and tested; no known blocker.
  Next: user playtest; dedicated variant art remains deferred. Existing uncommitted
  UI/art work preserved. Last working commit remains 56814f9; no commit yet.

### Latest session — standalone ice dragon rig

- Current feature: requested ice dragon art/rig trial, completed in
  `Workspace.IceDragon_RigTest` beside the chicken at X=12, Z=26.
  Frost-blue block body, four clawed feet, cyan triangular wings, horns,
  back crystals, segmented-looking welded tail, and glowing eyes.
- Verified in Edit through localhost:58742/mcp: 84 unanchored parts,
  9 Motor6Ds, 74 cosmetic welds, all parts connected, only Torso collidable,
  matching invisible root/PrimaryPart, Humanoid and Animator. HipHeight 1.01.
  Joint position and orientation-basis assertions pass; screenshot inspected.
- Initial check used overly strict axis-angle tolerance (wing rounding showed
  0.00069 radians) and assumed GetConnectedParts excluded the root. Follow-up
  checks compare rotation basis vectors and membership of every part; pass.
  Temporary Edit peer disconnect on resume recovered on retry.
- No animation assets/controller. Runtime standing/movement remains untested.
  Next: user visual/Play trial. Selected dragon and framed the editor camera.
- Files: `docs/studio/build-ice-dragon.luau` editor-only reproducible recipe,
  plus this handoff. Studio-owned model outside Rojo mappings; save the place
  for editor persistence. Existing chicken and uncommitted UI work preserved.
  Overall gameplay progress unchanged; no current blocker. Last working commit
  remains 56814f9; no commit made in this art session.

### Latest session — standalone blocky chicken rig

- Current feature: user-requested chicken art/rig trial in Workspace, with
  animation deferred. Created `Workspace.Chicken_RigTest` through the connected
  Edit MCP peer at localhost:58742/mcp; built-in bridge had no connected peer.
- Completed: cream block chicken, red comb/wattle, orange beak/toes, wings and
  tail. 35 parts, 7 Motor6Ds, 27 cosmetic WeldConstraints; invisible matching
  HumanoidRootPart is PrimaryPart. Only Torso collides, all parts unanchored.
  Humanoid/Animator present; calculated HipHeight 0.895; RequiresNeck false.
  No animation assets/controller or gameplay/inventory integration added.
- Verification: Edit assertions passed for collisions, anchoring, root size,
  Animator and all joint rest transforms. Screenshot inspected successfully.
  Runtime standing/movement has NOT been tested. Next: user visual/Play trial.
- Architecture: standalone Studio-owned model, outside existing Rojo mappings.
  Reproducible editor-only recipe is `docs/studio/build-chicken.luau`, not a
  runtime generator. Recipe refuses to overwrite an existing named model.
  Corrected supplied C1 formula to limb.CFrame:ToObjectSpace(jointWorld), so
  Part0*C0 == Part1*C1 and limbs do not shift. No animation work performed.
- Location: root approximately (12, 2.12, 12), beside the center conveyor.
  Model selected and editor camera framed for inspection. Save the Studio place
  to persist this editor model; recipe also permits reconstruction if needed.
- Files modified: new editor recipe and this handoff only. Earlier uncommitted
  UI work preserved. Last working commit remains 56814f9; no commit this session.
  Overall prototype progress unchanged; no blocker for the art trial.

### Latest session — reference-style popup pages

- Current feature: cyan stud headers, charcoal stud bodies, near-square cards,
  black borders, outlined white text, red corner close buttons and bright
  green/blue actions across Inventory, Feed/food sidebar, Merchant, Eggs,
  Rescue and Debug. Real authored StarterGui assets; no runtime UI builder.
- Preserved centered pet preview, scrollable food sidebar and all gameplay.
  Selection/availability colors in the existing controllers match the theme.
  Egg Dismiss and Rescue Close hide their panels; Rescue Close does not spend,
  accept, reject or extend a pending timed recovery offer.
- HUD, hotbar, main inventory/travel buttons and outcome banners untouched.
  Compared relevant asset subtrees to pre-theme snapshots (identical).
- Verification: Rojo build and git diff --check pass. All 35 two-player
  FoodShopVerification checks pass, including both client startups, authored
  headers/close controls, title layering, food selection and core transactions.
  Inspected Feed, Inventory and Merchant screenshots in Edit; restored preview
  visibility/scale/position afterward. Other pages covered structurally/startup,
  not a full manual interaction/phone visual pass.
- Fixed header layering discovered in preview and a missing Egg close node
  discovered in the initial failed test; renamed to Dismiss and verified sync.
  Aligned stale editor-side FoodCards border/title/hint/corner properties with
  the authored asset after final screenshot revealed old gold decoration.
- Files: five src/ui assets (FeedYourPetUI, MerchantUI, EggUI, ReviveUI,
  DebugUI); corresponding controllers plus InventoryController; UI/FoodCard;
  FoodShopVerification.client; docs/feed-ui.md; this handoff.
- Overall: style trial implemented and tested; user visual approval pending.
  Next: user playtest/feedback on the reference-style pages, then commit the
  combined uncommitted sidebar/scrolling/theme work when authorized/available.
  Last working commit remains 56814f9. No commit made this session; prior
  staging was blocked by approval-system usage limit. No known runtime blocker.

### Latest session — scrollable food sidebar

- FoodCards now contains authored List (ScrollingFrame) and UIListLayout.
  AutomaticCanvasSize Y supports additional authored food cards; title/footer
  stay fixed. Scrollbar supports standard Roblox mouse/touch scrolling.
- Updated controller and client verification to use FoodCards.List.
  Preserved prior uncommitted centered-pet/sidebar work.
- Build and diff check pass. All 35 FoodShopVerification checks passed,
  including updated client hierarchy/layout and food selection checks.
  Removed an empty editor-created List duplicate left after Rojo reparenting;
  the populated source-managed list remains.
- No new foods or balance changes. Previous commit remains 56814f9;
  previous sidebar commit was blocked by approval-system usage limit.
- Next: user playtest mouse/touch scrolling with more food cards; commit when
  approval is available. Current four cards fit without needing to scroll.

### Latest session — centered Feed pet and right food sidebar

- Reworked the authored FeedPanel: 560x620 main card with larger centered
  rotating pet viewport; separate 240x620 FoodCards sidebar at X=576.
  Four food choices now stack vertically under SELECT FOOD. Existing purple/
  gold style, emoji/image placeholders, Feed and Pick Up Pet remain.
- Controller only handles responsive scale/position: both panels fit and
  center as one 816x620 group. All layout Instances live in StarterGui asset,
  not generated at runtime. Selection/feeding/ownership logic unchanged.
- PASS: 35 two-player FoodShopVerification checks including both client
  startups, selection, pet spin and new centered/vertical-sidebar assertions;
  Rojo build and diff check. Inspected authored layout screenshot in Edit.
  Edit preview shows placeholders; runtime population covered by client tests.
- Removed four exact duplicate editor nodes introduced by Rojo sync after
  comparing their class and relevant properties. Source has one of each.
  Temporary previews removed/restored; Studio returned to Edit.
- Files: FeedYourPetUI.rbxmx, FeedController, FoodShopVerification.client,
  docs/feed-ui.md, this handoff. Previous commit: 56814f9.
- Implemented/tested but NOT committed: staging was blocked by approval-system
  usage limit. Next: user playtest sizing/readability and commit pending changes.

### Latest session — milestone rear expansion and tier colors

- User clarified: physical plot size must NOT increase every upgrade.
  Current milestones: 5–6 slots base size; 7–9 slots +16 studs rear depth;
  10 slots +40 studs total. Each capacity purchase still adds one pet slot.
  Fence/cap colors progress green, blue, purple, orange, gold at slots 6–10;
  base wood/grass restored at five. Grass gets a subtle matching tint.
- Kept original plot/fence format. PlotAppearance resizes/repositions/recolors
  existing authored parts only. Back rails/posts/shrubs move; side rails,
  floor, ground and foundation lengthen. Front edge, entrance, spawn,
  feeding plate, upgrade sign, center lane and width stay fixed.
- Max-size grounds are 80x120; pens 60x84. All six orientations remain
  within the current 320x420 island. No new world geometry or runtime builders.
- PlotService applies loaded capacity before placement, caches authored
  baselines, and restores base appearance when ownership is released.
- Architecture: persisted pet/egg PenPosition uses the ORIGINAL floor origin;
  placement bounds still use the resized floor. No schema migration needed.
  Existing placements do not shift when the center of the floor changes.
- PASS: 100 expanded PlotUpgradeVerification checks (milestones/colors,
  stable pet/egg anchors, exact prices, save/reload, all six plot orientations,
  no generated geometry, reset); 22 ownership/respawn/reuse checks including
  upgrade reset and new-owner isolation. Build, syntax and diff checks pass.
- PASS: 35 FoodShopVerification checks after relaunching from Edit.
  Total: 157 multiplayer checks. An immediately chained run returned nil
  during Studio teardown; independent relaunch completed successfully.
- Visual preview attempted through MCP but screenshot was blank; temporary
  preview sizes were restored and verified before the next test. User
  playtest remains useful for appearance/feel; numeric geometry checks pass.
- Files: PlotAppearance, PlotService, PlotUpgradeConfig, PlotUpgradeSignView,
  PlacementService, EggService, EggVisuals, both plot verification scripts,
  docs/plots.md and this handoff. Previous commit: 421ce50.
- Next: user playtest milestone expansion/color choices and tune config.
  No known gameplay blocker. Included in
  `feat: expand plots at capacity milestones with tier colors`.

### Latest session — larger floating base

- Enlarged SkyIsland grass from 236x320 to 320x420 studs; expanded both
  underlying rock layers to match. Heights and centers remain unchanged.
- Six plots, conveyor, merchant, paths and all gameplay remain unchanged.
- PASS: MCP readback verifies three new sizes and all six original plot
  positions/sizes; Rojo build and diff check. Multiplayer tests not rerun for
  this geometry-only change (previous feature passed 107 checks).
- Files: SkyIsland.rbxmx, docs/plots.md, PlotUpgradeVerification expected
  island size, this handoff. Previous commit: 2e80ff4.
- No blockers. Next: user playtest island space. Included in
  `chore: enlarge floating island base`.

### Current session — larger sky plots and pet-capacity upgrades (verified)

- Current feature: six larger, decorated plots on a compact floating island;
  Money sign upgrades increase active pet slots from 5 through 10.
- User's "farm ... 5 ... 6" interpreted as pet-capacity upgrades, not a return
  of AFK food production. Async clarification was offered; no reply received.
  Food merchant and food-only risk reduction remain unchanged.
- Implemented: 80x80 grounds, 60x44 pens, centers X=±66 and Z=-96/0/96.
  Added open timber rails/posts, caps, foundations, entrance paths and shrubs.
  Real editable Instances created through MCP and exported to static assets.
- Replaced Workspace Baseplate with 236x320 SkyIsland (grass, rock layers,
  promenade). Original Baseplate moved to ServerStorage in Studio for recovery.
  Six plots/central conveyor/merchant kept. No runtime world/UI builders added.
- Added PlotUpgradeConfig/Service/Controller/SignView and six authored signs.
  Starts at five slots; one-slot purchases cap at ten. Prices: 20K,100K,500K,
  2.5M,10M. Uses existing MaxPetSlots data, ownership/distance/alive checks,
  cooldown, expected-capacity compare-and-swap, affordability and save locks.
  Owner signs, placement capacity, inventory and Money HUD use purchased slots.
- PASS: Rojo build, git diff --check, XML parsing, Studio syntax checks,
  six-plot/ten-marker geometry inspection, no duplicate sibling instances in
  inspected gameplay roots. Captured and inspected an Edit viewport overview.
- Reconnected successfully on retry: Rojo localhost:34872, MCP localhost:58742.
  Verified current sources synced and no duplicate map/gameplay siblings.
  Previous interrupted test ended before the retry; all new tests ended in Edit.
- PASS: 53 PlotUpgradeVerification checks (exact debit, ownership/distance,
  replay rejection, all slots 6–10 usable, maximum, save/reload); 19
  PlotVerification checks (spawn/respawn, leaving and plot reuse); 35
  FoodShopVerification checks (shop, feeding, Rescue, both client startups).
  Total: 107 multiplayer checks. Client regression additionally checks all six
  authored sign bindings, correct Adornee/title and no keyboard selection.
- Stabilized an existing FoodShop test: its second Snapshot could race client
  polling and receive Cooldown. Retry only that response; unexpected failures
  still fail. No production Feed behavior changed.
- Inspected front-facing sign screenshot at player scale: clear capacity,
  next-slot and compact Money price. Physical mouse/touch purchase feel remains
  a user playtest item; server purchases and client binding are verified.
- No current blockers. Next: user playtest larger layout/sign interaction and
  tune the configurable upgrade costs as needed.
- Files: new PlotUpgrade modules/config/test, SkyIsland and PlotUpgradeSigns
  assets; PlayerPlots asset, PlotService/Config, both bootstraps, HUDController,
  PlotVerification, both FoodShopVerification tests, default.project.json,
  docs/plots.md, this handoff.
- Previous working commit: 9bab27e. This verified session is included in
  `feat: expand sky plots and add pet capacity upgrades`.

### Latest session — remove feed plate upgrades

- Removed upgrade service/controller from startup, upgrade-sign project mapping,
  and all six matching Studio sign models. Feeding plates and their interactions
  remain unchanged. Removed HUD wait for retired upgrade event.
- Feed server/client now use base explosion risk multiplied only by selected
  food reduction. Removed plate level/reduction labels from Feed UI/snapshot.
- Legacy FeedPlateLevel is retained as inactive schema compatibility data;
  retired modules/config/sign asset remain recoverable, never started by bootstrap.
- PASS: 35 two-player FoodShopVerification checks, including level-10 data granting
  no bonus, no signs/event, feeding/pickup-related UI startup, purchases and Rescue.
  Rojo build and diff check pass. Tests returned Studio to Edit. No blockers.
- Files: both bootstraps, FeedService, FeedController, HUDController,
  FoodShopVerification.server, default.project.json, design decisions and handoff.
  Includes prior deferred-food discussion notes; no special foods implemented.
- Previous gameplay commit 1d733d9; included in `feat: remove feed plate upgrades`.
  Next: user playtest food-only risk and approve fresh-player onboarding if desired.

### Latest discussion — defer special foods

- Recorded Lucky Treat, Growth Feast and Mystic Meal as deferred ideas in
  docs/design-decisions.md, not approved implementation. No gameplay changes.
- Verified fresh profiles still start with zero Money and no starter pet; the
  existing Studio starter pet is developer-account-only. Fresh-player onboarding
  is the recommended next prototype task, pending user approval.
- Files: design decisions and this handoff. Documentation-only; diff check used,
  no gameplay tests needed. Last gameplay commit 1d733d9. No active implementation.

### Latest session — Food inventory and interactive Feed panel

- Added Food tab inside existing inventory; shows owned food stacks, quantities,
  risk reduction and emoji/image placeholders. Food excluded from All (pets/eggs)
  and hotbar; no equip/lock actions for food. Empty Food tab points to merchant.
- Reworked authored FeedPanel to 720x620 responsive layout: pet ViewportFrame
  slowly rotates the existing model while panel is visible; four food cards show
  quantity/reduction and selected border. Click chooses food only; Feed sends the
  selected type to the server. Unowned food cannot enable Feed. Pickup retained.
- New FoodCard presenter binds authored ImageLabels/emoji children, ready for
  future pictures; no runtime UI constructors, UI Director or Computer Use.
- UI/Feed snapshots provide cloned per-type counts and Feed pet SpeciesId.
  No balance, rarity-food bonus, save schema or transaction changes.
- PASS: 32 combined two-player FoodShopVerification checks, including client
  food filtering/hotbar exclusion, image placeholders, preview rotation and
  selection of unowned/owned foods. Existing purchase/Feed/Rescue checks pass.
  Rojo build, diff check and synchronized Luau compilation pass.
- Removed matching duplicate new UI/module Instances from Rojo sync; source
  assets retained. Screenshot appearance and physical click/touch review remain
  user playtest tasks; no blocking implementation issues.
- Files: Feed/Inventory controllers; InventoryModel/Layout, ItemPreview and new
  FoodCard; UIService/FeedService, FoodConfig; FeedYourPetUI asset; both
  FoodShopVerification files and handoff. Previous commit a8de655; included in
  `feat: add food inventory and pet preview feed selection`.
- Next: playtest layout and food choice clarity. Food HUD stays removed.

### Latest session — remove Food HUD

- Removed only the authored HUD.Food row and HUD controller food bindings/reflow.
  Money stays bottom-left; feeding UI quantities and all food gameplay stay intact.
- Updated InventoryVerification and FoodShopVerification client assertions to
  require no Food HUD and preserve the FeedPanel food display.
- PASS: all 30 combined two-player FoodShopVerification checks, Rojo build,
  diff whitespace and Studio hierarchy/controller compilation. No blockers.
- Files: HUDController, FeedYourPetUI.rbxmx, both client verification files and
  this handoff. Removed row is recoverable through Git. No economy/schema changes.
- Next: user playtest. Previous commit 35cb346; included in
  `ui: remove food counter from main HUD`. Rarity-food bonus remains idea-only.

### Current session — food shop / timed Rescue redesign (verified)

- User approved level-0 failure, immediate-only Rescue, replacing AFK farms with
  restocking food purchases, and removing Tokens/consumable Protection. No real
  players/refunds; remote DataStore access disabled with DataConfig.MemoryOnly.
  Existing save infrastructure retained; no remote data deleted.
- Implemented Money merchant: Basic always available; two distinct weighted
  special offers every 30 minutes, one purchase per player/offer. FoodConfig owns
  prices, quantities and 0/15/30/45% relative risk reductions; one serving per Feed.
- Feed validates selected food server-side and multiplies its reduction with plate
  upgrades. Existing RNG order/critical cap unchanged. Old ProtectedFeed rejected.
- Rescue lasts 15 seconds plus the failure-presentation allowance, based on the
  original server timestamp. Expiry/Keep Base restores the same pet at level 0;
  immediate free Studio Rescue restores old growth. No Food refunds or replay.
- AFK farm/upgrade services and controllers no longer start; removed six Farm
  submodels from PlayerPlots and unmapped farm signs (assets/history retained).
  Removed the matching six stale sign models left in Studio after unmapping;
  the full FarmUpgradeSigns.rbxmx asset is retained for recovery.
  Token HUD, popup and debug grants removed; authored food selector replaces
  Protection button. Existing UI style used, no UI Director or Computer Use.
- Schema v9 adds special Foods; Basic remains Food. HUD sums all servings.
  Old farm/token fields/modules remain inactive compatibility/reference data.
- PASS: 30 combined two-player checks; real timeout returns original identity at
  level 0; ownership, duplicate requests, Money/food accounting, stock isolation.
  Rojo build, diff whitespace and synchronized script compilation pass.
- Fixed shop/Rescue startup lifecycle: early 3s fallback clones could be replaced
  by Roblox's initial StarterGui copy, leaving stale controller references. Now
  wait for actual authored ScreenGuis. Both clients render Money shop stock and
  initialize HUD successfully. No anytime recovery button or Token UI remains.
- In progress/blockers: none for this implementation. Physical click/touch and
  visual comfort still need user playtest; automated tests verify UI binding and
  server transitions, not screenshot appearance or physical inputs.
- Removed confirmed identical Rojo duplicates in Studio: FoodConfig,
  FoodShopVerification, FoodType and Money. Filesystem assets remain intact.
- Files: shared food/data/game/merchant/revive configs; schema/adapter; feed,
  merchant, rescue, HUD/debug/travel/UI services/controllers; both bootstraps;
  authored merchant/feed/rescue/debug UI; plots/merchant world; project mapping;
  new FoodShopVerification pair, InventoryVerification, design decisions/handoff.
- Next: playtest food prices, personal stock and 15s Rescue pacing. Old
  Farm/Protection/Merchant verification scripts target the superseded design.
- Previous working commit a643007; this session is included in
  `feat: replace farm economy with food shop and timed rescue`.
  Direct MCP localhost:58742 and Rojo connected; tests ended back in Edit mode.

### Latest discussion — failure, Rescue and food-shop proposal

- Recorded pending design in docs/design-decisions.md: preserve failed pets at
  base level 0; immediate limited-time Rescue only (15s proposed test window),
  no Food refund or timer restart on disconnect. Not implemented this session.
- Recorded restocking merchant food types with different failure-risk reduction
  as a proposal, not an approved farm replacement. Balance/currency/migration and
  interactions with existing protection/plate upgrades need decisions first.
- Documentation only; no gameplay changes or tests. Existing Token HUD edits preserved.

### Latest session — remove travel button delay

- Removed 0.6s post-request client lock; buttons release as soon as server replies.
  Error-label reset is nonblocking. Reduced server spam guard from 1.5s to 0.1s.
  No pre-teleport timer; server validation/network round trip still applies.
- Verified all 23 two-player TravelVerification checks with 0.15s between valid
  destinations, plus build and diff whitespace checks. Token HUD changes untouched.
- Files: HUDController, TravelConfig, TravelVerification and this handoff.
- No blockers; next user responsiveness playtest. Previous commit 0ddb97f;
  included in `fix: remove unnecessary travel button delay`.

### Latest session — Base / Merchant travel buttons (server verified)

- Implemented larger 250x86 stud ImageButtons in authored HUD.Travel at top center,
  matching Inventory texture/style; Base green and Merchant blue per user follow-up.
  Responsive row scale; Inventory moves below it
  on narrow screens to avoid overlap. Client binds existing buttons only.
- Added server TravelService and TravelConfig: Base resolves caller-owned plot Spawn;
  Merchant resolves existing InteractionPoint. Server rejects arbitrary destinations,
  unloaded/dead characters, save/feed locks and spam (1.5s). Exits farm before travel,
  clears velocity, retains held items, charges nothing. Registered in server bootstrap.
- Added opt-in memory-only TravelVerification for own-plot/merchant destination,
  invalid input, cooldown, transaction lock, currency and authored button checks.
- Files: HUDController, FeedYourPetUI.rbxmx, TravelService, TravelConfig,
  server bootstrap, TravelVerification and this handoff. Prior Token HUD edits preserved.
- Reconnected through direct MCP port 58742; removed confirmed duplicate Travel row
  and identical TravelVerification script created by sync (filesystem sources retained).
- Verified 23 two-player TravelVerification checks: own plot, merchant destination,
  invalid target, cooldown, transaction lock, no charge and larger authored buttons.
  Center alignment and green/blue gradient assertions, Rojo build and diff check pass.
  Screenshot response exceeded tool output size; physical visual/input review remains.
- Next: user playtest including travel from farm/while carrying. No implementation blocker.
- Previous commit 4ba935d; included in `feat: add base and merchant teleport buttons`.
  No UI Director or Computer Use used. Unfinished Token HUD files excluded from commit.

### Latest session — disable WASD inventory navigation

- Inventory disables GuiNavigation/auto-selection for keyboard, mouse and touch,
  clears selection, and restores previous navigation settings when closed.
- Uses actual last input type instead of GamepadEnabled (connected controller)
  to opt into gamepad navigation. Keyboard movement inputs are not intercepted.
- Files: InventoryController and this handoff. Token HUD edits remain untouched.
- Verified synchronized compile, Rojo build, diff check, navigation property access,
  and six state-transition checks using the actual extracted controller function.
  Physical WASD/gamepad input still requires playtest; no full multiplayer claim.
- No implementation blockers. Next: user input-feel check. Previous commit 8a72936;
  included in fix commit for keyboard inventory navigation.

### Latest session — three eggs / eighteen pets

- Completed: Advanced Egg (2M, 120s) and Elite Egg (500M, 720s), six new named
  species each. Prices/timers/result weights use GDD 9.2 candidates; prototype egg
  and saved IDs remain unchanged. Conveyor distribution 70/25/5. Unlock gates deferred.
- Reused the existing egg template and exact per-rarity pet model copies under
  new species names. No new geometry/runtime model builders. Removed 12 identical
  Studio-only duplicate models created by live sync; filesystem templates retained.
- Updated PetService's obsolete six-species/prototype-only startup assertion to
  validate each species against its configured egg pool and retain rarity/income checks.
- Verified: all 18 pool outcomes and three conveyor selections; 104 two-player
  EggVerification checks including both new purchases, placement, configured timer,
  fast-forwarded memory-only hatch, original identity, carry model and save/load.
  Initial startup timeout exposed the fixed six-species assertion. Build/diff checks pass.
- Files: EggConfig, PetConfig, ConveyorConfig, PetService, PetTemplates.rbxmx,
  ConveyorVerification, docs/egg-content.md and this handoff. No schema change.
- Next: playtest prices/odds/timers; no egg implementation blockers. Included in
  `feat: add advanced and elite conveyor eggs with twelve pets`.
- Token HUD edits remain separate/uncommitted and its verification is incomplete.

### Latest session — Token HUD restyle (verification incomplete)

- User explicitly prohibits roblox-ui-director for future work. Do not use it.
- Implemented authored MerchantUI.TokenHUD Frame with medal emoji, purple outlined
  compact value, transparent background, aligned above Food/Money. Coin emoji was
  unsupported in Studio, so replaced with visually verified medal emoji.
- MerchantController binds TokenHUD.Value and reflows with the existing currency
  scale/spacing. Merchant transactions and farm-drop popup behavior are unchanged.
- Removed one confirmed duplicate Studio-only TokenHUD Frame; source asset retained.
- Files: MerchantUI.rbxmx, MerchantController, InventoryVerification.client.luau,
  this handoff. Build/diff whitespace passed; screenshot shows clean single row.
- NOT fully verified: first two-player test timed out waiting for Token Value to
  replace placeholder. Added snapshot diagnostic to client test; rerun is pending in
  game attribute TokenHudTest. Direct client-1 inspection timed out (plugin connection).
  Do not claim live token updates pass. Next: inspect rerun result, merchant client
  startup/remote availability and live value. Avoid spawning another test until done.
- Last commit 6c81031. Token changes remain uncommitted pending verification.

### Latest session — fix overlapping currency rows in Studio

- Root cause: two Food and two Money frames existed in Studio HUD after live sync;
  placeholder glyphs overlapped live values. Filesystem asset already had one of each.
- Removed exactly two duplicate Studio-only rows via MCP; retained authored rows.
  Diagnostic font edits were on removed duplicates; original typography retained.
- Added client verification for unique currency rows and eventual live balances.
  Initial test checked balance before async snapshot; corrected test to await it.
- Verified clean large-number screenshot (5.6B/$18T), restored placeholder preview,
  unique edit hierarchy, 202 two-player checks, Rojo build and diff whitespace.
- Files modified: client InventoryVerification and this handoff; no economy/data changes.
- No blockers. Next: user visual review. Previous commit `0f2c7e6`; checks/handoff
  included in `test: detect duplicate currency HUD rows and stale placeholders`.

### Latest session — bottom-left currency HUD

- Completed: replaced top Food/Money stud panels with transparent bottom-left rows,
  emoji icons (chicken/money), yellow Food and green dollar amounts with black outlines.
  K/M/B/T formatting and existing timestamp-ordered live balance events preserved.
- Editable StarterGui asset owns all layout objects. HUD controller only binds/reflows;
  narrow-screen currency sits above the hotbar/touch area. Inventory button remains top-right.
- No nonfunctional plus button or unimplemented friend-boost claim added from reference.
- Files: FeedYourPetUI asset, HUDController, UIConfig and this handoff.
- Verified: 194 two-player Studio startup/inventory checks, authored hierarchy inspection,
  screenshot review, 5.6B/$18T formatting checks, Rojo build and diff whitespace checks.
- No blockers/in-progress work. Next: user visual/mobile comfort review.
  Previous commit `a2c8b35`; included in `feat: restyle currency HUD at bottom left`.

### Latest session — preserve held-slot number and name

- User clarification implemented: key number and pet/egg name remain visible
  while held. Gold border remains; HELD/state label and floating hints stay hidden.
- Files: InventoryController, client InventoryVerification, docs/inventory.md,
  this handoff. Supersedes earlier notes about hiding key/name labels.
- Verified: 194 two-player Studio checks pass with visible held-slot labels,
  Rojo build and git diff whitespace checks pass. No blockers or unfinished work.
- Next: user visual review. Previous commit `5b36ce1`; included in
  `fix: preserve hotbar number and name while held`.

### Latest session — visible slot borders and no floating instructions

- Fixed actual border defect: ten slot UIStrokes were Contextual, which outlines
  empty TextButton text. Authored strokes now use Border mode.
- Removed carry success/put-away instruction notices and hid authored Hotbar.Hint.
  Inventory status errors remain available without floating text above the hotbar.
- Files: InventoryController, FeedYourPetUI asset, client InventoryVerification,
  docs/inventory.md and this handoff. No gameplay/save changes.
- Verified: 194 two-player Studio checks pass, including each border mode and hidden
  hint; synchronized StarterGui assertions, Rojo build and diff whitespace checks pass.
- No blockers/in-progress work. Next: user visual review. Previous commit `3223872`;
  correction included in `fix: render hotbar borders and remove carry hints`.

### Latest session — border-only held-slot indicator

- Completed: held hotbar slots hide key/name/state text and use the gold border
  as the selection indicator. Preview and normal translucent background remain;
  key/name labels return when put away. No gameplay or ownership changes.
- Modified InventoryController, InventoryLayout, client InventoryVerification,
  docs/inventory.md and this handoff.
- Verified: all 172 two-player Studio checks pass including held-slot hidden labels;
  86 sources compile, Rojo build and git diff whitespace checks pass.
- In progress/blockers: none. Next: user visual review. Previous commit `8b53ef6`;
  included in `fix: show held hotbar selection with border only`.

### Latest session — ten dynamic square hotbar slots

- Completed: ten authored slots mapped to 1–9/0; BAG object and keyboard B toggle
  removed. Main INVENTORY/backquote/gamepad controls remain. Empty-slot input is a no-op.
- Only occupied slots render; zero items hides the bar, one item shows one square.
  Squares pack together preserving key assignments; narrow screens wrap. The outer
  frame is fully transparent and does not intercept input. Slot backgrounds remain black/translucent.
- Files: InventoryConfig, InventoryController, InventoryLayout, FeedYourPetUI asset,
  client InventoryVerification, docs/inventory.md and this handoff. Prior uncommitted
  hotbar-only equip/placement work preserved; no server or save-schema changes.
- Verified: 172 two-player Studio checks pass, including ten authored slots, no BAG,
  transparent frame and 0/1/10-item square layouts on desktop/mobile; 86 sources compile,
  Rojo build and git diff whitespace checks pass.
- In progress: none. Next: physical input/visual comfort playtest. No known blockers.
  Commit handoff: this work and the hotbar-only equip/placement changes below are
  included in the requested `feat: streamline ten-slot hotbar equip and placement` commit.
  Previous working commit: `22e0845`.

### Latest session — hotbar-only equip and placement cleanup

- Current feature: one-key/tap hotbar equip; inventory manages shortcuts rather than holding.
- Completed: inventory Hold button now Add/Remove Hotbar; legacy egg panel carry
  action removed. Existing nearby pickup and hatch behavior is preserved.
- Snapshot requests no longer set the action-busy flag, avoiding dropped equip inputs
  during polling. Revision checks discard snapshots crossing carry/placement actions.
- Successful placement immediately removes the shortcut; reconciliation excludes
  Pen/plate pets and placed eggs. Pickup makes items eligible for empty slots again.
- Files modified: InventoryController, CarryController, EggController, InventoryModel,
  InventoryLayout, client InventoryVerification, FeedYourPetUI asset, docs/inventory.md,
  and this handoff. No server, economy, persistence or ownership changes.
- Verified: two-player InventoryVerification passed, including added placement-state
  removal/repeated polling/pickup cases; 86 Studio sources compile; Rojo build and
  diff whitespace checks pass. Physical rapid-input/touch comfort remains to playtest.
- In progress: none. Next: user playtest hotbar feel. Last working commit `22e0845`;
  this hotbar behavior change is included in the commit noted above. No known test blockers.

### Latest session — inventory proportions correction

- Current feature: compact inventory visual correction following the user's screenshot.
- Reduced desktop panel to a maximum 840px width and 82% viewport height; reflowed
  search/filter controls, enlarged typography, centered empty-state text, and tightened
  the detail/action area. Preserved the existing colorful stud style and translucent hotbar.
- Saved matching editable StarterGui defaults in `src/ui/FeedYourPetUI.rbxmx`;
  action buttons are hidden until selection. No runtime layout constructor added.
- Files changed this correction: `InventoryLayout.luau`, `InventoryController.luau`,
  the ScreenGui asset, and this handoff. Existing inventory feature changes preserved.
- Verified: six layout sizes (1280x720, 1005x634, 390x844, 844x390, 360x640,
  320x568), Studio empty-state screenshot, Rojo build, and `git diff --check`.
  Earlier 76-check gameplay verification is unchanged; not rerun for this visual pass.
- Next: user review of populated inventory and physical touch/gamepad comfort.
  No economy, save schema, or server transaction changes in this correction.
- Commit handoff: inventory/hotbar and visual corrections are included in the
  user-requested `feat: add pet and egg inventory with quick-access hotbar` commit.
  Previous merchant commit is `2602bea`. UI Director and
  Computer Use were not used. Inventory restored hidden by default after inspection.

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
Studio-only free Revive and token-based Feed Protection are implemented; paid
Developer Product fulfillment remains deferred until product IDs exist.

## 2. Overall Progress

| System | Status | Notes |
| --- | --- | --- |
| Project Setup | ✅ Complete / Verified | Filesystem layout, toolchain, build, and server launch verified. |
| Git Setup | ✅ Complete / Verified | `main` tracks `origin/main`; initial commit pushed successfully. |
| Rojo Setup | ✅ Complete / Verified | Live Studio sync and server/client bootstrap verified. |
| Base Architecture | 🟨 In Progress | DataService and PetService now exist; remaining gameplay services are pending. |
| Player Data Schema | ✅ v8 Studio Verified | Adds merchant Tokens and purchased stock markers; preserves previous progress. |
| Mystery Merchant | ✅ Server Verified | Three random offers every 30 minutes; Token purchases, private stock limits and memory persistence verified. Manual UI review pending. |
| DataService | 🟦 Implemented / Needs Testing | Studio runtime verified; live DataStore rejoin test remains. |
| Plot System | ✅ Layout / Ownership Verified | Six static plots, three facing three; five pet slots each. All 19 checks pass. Platform player limit still needs setting to 6. |
| Egg System | ✅ Carry/Place Studio Verified | Buy/hold/click Pen starts timer; E hatch returns pet to player. 64 automated checks plus developer playtest. |
| Egg Conveyor | ✅ Server Verified | Eggs replace direct pets; owner inventory slot, range/price validation, offer races/expiry tested. Existing static conveyor retained. |
| Pet Identity | ✅ Complete / Verified | Creation, unique GUIDs, lock/unlock and removal passed in Studio; live persistence remains pending. |
| Inventory / Hotbar | ✅ Studio Verified | Authored pet/egg collection, previews/search/sort/lock/equip, six translucent quick slots. Two-player server/client checks pass; physical device comfort pending. |
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
| Feed UI | 🟦 Protection UI Implemented | Normal/Protected Feed, token count, exact risks, pickup and outcome banners. Protection visual review pending. |
| Feed Transaction | ✅ Studio Verified | Food/token atomic mutation, authoritative outcomes, replay/save locks; expanded 113-check suite passes. |
| Explosion RNG | ✅ Studio Verified | Explosion first, 5% Miracle Save, otherwise persisted quarantine. |
| Critical Feed | ✅ Studio Verified | Configured odds; no skipped-level rolls; gains capped at 40. |
| Pet Growth | 🟦 Implemented | Success scales plate/Pen models and income; manual visual review pending. |
| Explosion Presentation | 🟦 Implemented | Float/spin, burst/fade and banners; six isolated effect checks pass. |
| Protection | ✅ Token Prototype Verified | Single-attempt risk reduction with replay safety; merchant now supplies earned tokens. Paid sources deferred. |
| Revive / Keep Base | 🟦 Choice Flow Server Verified | 72 Feed and 22 legacy recovery checks pass with schema v5. Revised recovery UI physical testing pending. Paid recovery not implemented. |
| Save / Load | 🟦 Implemented / Needs Testing | Memory-mode flow verified; production backend remains untested. |
| Debug Tools | ✅ Studio Memory Verified | Currency grants, six-rarity spawn, pet/farm levels, one-use Feed outcomes. 47 multiplayer + 12 gate + 10 isolated UI checks pass. |
| Core Loop Playtest | ⬜ Not Started | |

Status legend: ⬜ Not Started · 🟨 In Progress · 🟦 Implemented / Needs Testing · ✅ Complete / Verified · ❌ Blocked

## 3. Current Feature

**Current Feature:** Authored inventory and translucent black hotbar

**Status:** Inventory/hotbar implemented and synchronized. Focused two-player server/client verification passes, including previews, public egg data, equip/lock and responsive layout. Manual device comfort remains. Merchant remains committed and verified.

**Objective:** Make owned pets/eggs easy to inspect, find, hold and access through quick slots.

## 4. Completed

- Egg carry/place/E-to-hatch was developer playtested and committed as `7aa05d8`.
- Feed Protection uses saved account-bound tokens, GDD candidate risks, current
  plate reduction, a static authored UI button, server-side transaction/replay
  validation, persistence and protected outcome presentation. New/migrated
  prototype profiles receive three tokens. Paid products are not fabricated.

- Conveyor eggs replace direct pet sales per user request. EggConfig contains
  prototype price/time/pet result weights; PetService prepares reserved identities.
  Schema v5 persists private results and absolute hatch timestamps. Authored egg
  and MY EGGS UI; server-owned purchase/hatch and one incubation slot implemented.

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

- Physical visual/input review of the new side-by-side Feed and Protected Feed
  buttons. Paid receipt fulfillment and earned token sources need later design.

- Egg carry/place/E hatch was physically approved and committed as `7aa05d8`.
  Live backend rejoin/outage/session-transfer testing remains separate.

- MCP reconnected; ReviveVerification passes. Revised recovery client/public
  KeepBase/save-failure checks and physical button review remain.

- Physical feed plate sign mouse/touch/gamepad input and visual risk-display review.

- Visual Play review of compact numeric text across UI and world labels.

- Physical debug panel input/layout review and full-loop playtest using its
  grants, level editing and one-use forced outcomes.

- Manual wandering movement/pickup feel review; server verification complete.

- Physical mouse/touch and visual review of Feed/Protection effects/UI and Revive.
  Paid Protection/Revive remain deferred; free Revive is Studio-only.
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

Latest priority: verify new egg carry/place flow (see section 18), then playtest
conveyor eggs and MY EGGS countdown/result, finish
recovery UI review, then review plate upgrade signs and reduced Feed risk,
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

2026-09-20 Protection: GameConfig, FeedConfig, PlayerDataSchema, FeedService,
FeedController, FeedEffects, authored FeedYourPetUI.rbxmx, FeedVerification,
docs/feed-config.md, new docs/protection.md, and PROJECT_STATUS.md.

2026-09-20 carry/place: GameConfig, PlayerDataSchema, CarryService, EggService,
new EggVisuals, CarryController, EggController, ConveyorController,
ConveyorVerification, docs/eggs.md, PROJECT_STATUS.md. No static assets or
farm/feed balance changed. Runtime clones reuse authored egg and label assets.

Current egg session: EggConfig, GameConfig, ConveyorConfig; PlayerDataSchema;
EggService, PetService, ConveyorService; server/client bootstraps; EggController,
ConveyorController and modal guards in Carry/Feed/FarmUpgrade/FeedPlateUpgrade
controllers; ConveyorVerification rewritten for eggs, schema-version assertion
in FeedPlateUpgradeVerification and remote wait in WanderingVerification;
default.project.json; authored EggTemplates.rbxmx/EggUI.rbxmx; docs/eggs.md,
docs/conveyor.md and this handoff. Prior session lists below are historical.

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

### Latest — Inventory and hotbar — 2026-09-22

- Latest user correction: do NOT use roblox-ui-director again. Follow the
  original colorful stud UI, chunky buttons, FredokaOne and dark outlined text.
  Restyled inventory accordingly; the black translucent hotbar stays as requested.
- Inventory panel/details/cards/buttons now use the same saved stud texture as
  the original HUD. ImageButton text labels are authored children; controller
  bindings and responsive typography updated. All 76 restyle client/server
  checks pass. Final visual review caught transparent gaps in the stud texture;
  added solid matching backplates and verified the corrected appearance in Studio.
  Final Rojo build/diff checks pass. No UI Director skill used for this correction.

- User requested a black translucent hotbar and inventory using roblox-ui-director;
  explicitly requires all UI layouts in ScreenGui/StarterGui, not runtime generators.
- Replaced the old inventory subtree in authored FeedYourPetUI; added six authored
  hotbar slots. Runtime clones only saved item-card/model templates. Existing
  Inventory visibility/status paths remain compatible with other controllers.
- Unified public pet/egg cards, rarity color, previews, current income, search,
  categories, sorting, lock/equip and session quick-slot pin/remove controls.
- Keyboard 1–6 equips; B/backquote or BAG toggles inventory. Touch buttons and
  gamepad selection/Y/B supported. Placed pet/egg actions still require proximity.
- UIService adds public egg fields and separates snapshot/mutation throttles.
  Private hatch results remain server-only; no schema/economy/config balance edits.
- Files: FeedYourPetUI.rbxmx, HUDController, UIService; new InventoryController,
  InventoryModel, InventoryLayout, ItemPreview, InventoryConfig, inventory docs,
  server/client InventoryVerification, and this handoff.
- Build and synchronized script compilation pass. Removed seven identical
  duplicate Studio copies of newly synced scripts/modules; these had caused two
  test runners to mutate the same profiles. Filesystem originals are preserved.
- Clean run passed 15 server checks, then found missing client preview cameras.
  ItemPreview now supplies a local Camera render helper inside each authored
  ViewportFrame. UI hierarchy remains authored. Clean two-player verification now
  passes: actual client startup/cards/cameras, held egg highlight, ownership,
  equip/unequip, lock, public egg privacy, pin/remove and viewport checks.
- Responsive layout bounds/overlap checks pass for 1280x720, 390x844, 844x390,
  360x640 and 320x568. Manual device comfort still needs playtesting.
- Next: physical input/feel playtest; real save/rejoin testing
  remains the next gameplay priority. Device touch/gamepad comfort remains manual.
- Last working commit: 2602bea (merchant, user committed). This UI work is uncommitted.
- Quick slots store presentation references only, scoped to the session. They do
  not grant ownership or expand the five active pet slots.

### Latest — Mystery Merchant — 2026-09-21

- Implemented MerchantConfig, MerchantService, MerchantController, static
  Workspace.MysteryMerchant and StarterGui.MerchantUI assets, plus opt-in tests.
- Farm rolls 10% for one Token each 60 seconds of continuous active farming;
  leaving resets the minute. No offline rewards. Farm prices/output are untouched.
- Three weighted unique offers per shared 30-minute epoch; one purchase per
  player per slot, persisted across rejoin. Food bundles and Guardian Charm
  (one Protection Token) are the initial rewards. Merchant currency is separate.
- Schema v8 migrates Tokens and merchant purchase markers. Purchases validate
  proximity, sequence, affordability, cap, stock and shared save locks.
- Added Token HUD/drop popup, modal placement guards and Studio + TOKEN debug.
- Files modified: configs GameConfig/MerchantConfig; PlayerDataSchema;
  FarmService/DebugService/MerchantService and server bootstrap; Merchant/Debug
  verification; client bootstrap, Merchant/Debug and modal-aware controllers;
  default.project.json, MerchantUI/DebugUI, MysteryMerchant; merchant/protection docs.
- Verified through MCP localhost:58741: merchant asset present, 80 scripts
  compile, MerchantVerification 27 checks pass; Rojo build/diff check pass.
- Regression batch passed: Merchant 27, Farm 27, Debug 50 and Feed 113 checks
  (217 total), using two-player Studio memory tests. No regression failures.
- In progress: manual shop input/layout and balance playtest. Next: test the
  merchant near the conveyor end; real DataStore reconnect tests remain unverified.
- Merchant checkpoint: `feat: add mystery merchant and farm token drops`
  (this commit). Previous working commit: d4d9173 (Feed Protection).
- Architecture: deterministic epoch stock requires identical config on servers;
  no global stock depletion/MemoryStore. Account purchase markers prevent
  server-hopping same-slot purchases. See docs/merchant.md for tuning and limits.

### Latest — Prototype eggs and hatch timer

- Baseline 8774d91, clean before edits. User confirmed replacing conveyor pets
  with eggs. MCP 58742 reconnected; authored real egg shell and cloned editable
  EggUI directly in Studio, exported assets and mapped them through Rojo.
- One egg (prototype_egg), 5K Money, 10 sec; result weights 40/25/18/10/5/2 for
  Common through Mythic. Prices/time/pools centralized in EggConfig. Existing
  FarmConfig, FeedConfig and six species/income anchors untouched.
- Schema v5 adds IncubatingEggs; full result reserved and saved privately at
  purchase. Absolute server ReadyAt persists; no reset/reroll on reconnect.
  Timer completion permits manual HATCH; consumed egg transfers same PetId to
  inventory. One incubation slot is separate from five active Pen slots.
- Shared save locks/retries cover purchase and hatch; client sends only IDs.
  Existing conveyor range/life/offer/cooldown checks retained. Updated prompt/
  remote is BuyConveyorEgg; ConveyorPurchaseChanged still updates Money HUD.
- PASS: 43 EggVerification two-player memory checks; nine isolated EggController
  checks using authored UI and mocked transport/input; seven actual EggService
  purchase/hatch save-failure checks with injected dependencies; initial synced
  compilation, Rojo build and diff checks.
- Regression PASS: 72 FeedVerification and 22 ReviveVerification checks with
  schema v5. Legacy Revive fixture initially hit request cooldown; inserted an
  explicit .3s wait to test attempt-ID validation, then reran successfully.
  No recovery gameplay changes were needed. Total checks this session: 153.
- Next: physical UI/egg placement review and published test-store rejoin/outage
  tests. Starter Money/pet onboarding remains an existing gap; not changed here.
- Hatch result uses a simple UI reveal; no premium skips, egg tiers, new species,
  offline income or runtime geometry generation added.

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

Egg v6: saved duration plus optional plot-local X/Z; zero timestamps mean not
started. CarryService owns mutually exclusive pet/egg hands and lifecycle cleanup.
EggVisuals clones authored templates into the owner Pen, reconciles saved eggs,
updates countdown once/sec and removes visuals on hatch/leave. One egg slot
remains separate from five active pet slots. No egg pickup/reposition action yet.

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

**DataVersion:** Player v5; Pet v2 (v1–v4 migrations implemented).
IncubatingEggs privately reserves pet results and absolute hatch timestamps.

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

**Commit:** `8774d91` (baseline before eggs; this session's egg checkpoint follows)

**Message:** `feat: offer revive or base-level recovery after failed feeding`

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

### Feed Protection — 2026-09-20 (latest)

- Egg carry/place/E hatch was committed first as `7aa05d8` after developer test.
- Schema v7 adds 0–10 bound ProtectionTokens. New and migrated prototype profiles
  receive three test tokens; no quest/product source has been invented.
- FeedConfig owns GDD candidate risks for targets 6–40. Protected risk retains
  plate-upgrade relative reduction and always remains above zero.
- Authored FeedPanel has side-by-side normal and Protected Feed buttons. It shows
  token balance and exact protected risk; outcome banner identifies Protection.
- Server validates staged ownership, Food, token, level, sequence, cooldown and
  lock. Food + token + outcome mutate atomically and save under the Feed lock.
  Replays return the original result without another token/Food/RNG roll.
- Verification: Rojo build/diff pass; all 76 synced sources compile; expanded
  FeedVerification passes 113 checks. Revive 22, plate-upgrade 58, and egg 64
  regression checks also pass. Physical Protection UI review remains.
- Paid receipt fulfillment needs actual Developer Product IDs. Earned sources
  need explicit quest/event design. Production DataStore verification remains.

### Egg carry/place — 2026-09-20 (completed)

Latest verification update: MCP 58743 is connected and execute_luau works.
All 76 synced Lua sources compile. ExecuteMultiplayerTestAsync(2,
"EggVerification") returned passed=true with 64 checks: carry/place, private
results, saved positions/timers, v5 migration, ready E prompt configuration,
range rejection, hatch return to hands, replay, race and offer expiry.
The developer physically tested the interaction and approved committing it.
Earlier disconnected/NOT RUN notes below are historical. Committed as `7aa05d8`.

- User requested held eggs placed like pets, with hatched pets returning to player.
- Implemented buy -> hold/store -> click/tap own Pen -> timer -> press E beside egg.
  Hatched pet enters inventory, then auto-equips after confirmed save only if
  hands are empty; occupied/dead/farming characters retain it safely in inventory.
- New eggs start time only on placement. Existing v5 egg timers/results survive
  migration and keep progressing; must place them but no countdown restart.
- Shared save lock/retry covers placement. Server validates held ID, owner,
  live character, finite floor position, range and pending transactions.
- Authored templates reused; no Computer Use or generated geometry/UI.
- Expanded existing EggVerification includes placement rejection, exact coordinates,
  visual rebuild, migration, timer/replay and hatch return assertions; 64 pass.
- Follow-up: ready eggs expose instant E Hatch prompt (X/gamepad or touch).
  MY EGGS hatch button is replaced with directions. Server validates live owner,
  timer and 10-stud range even for direct remote calls; client hides non-owner
  prompts. EggConfig now owns hatch distance/prompt name. Added prompt/range
  assertions; runtime and physical input were verified afterward.
- Live DataStore testing and production onboarding remain separate blockers.

### Conveyor eggs — previous v5 implementation

See section 8 latest egg entry and docs/eggs.md. Schema is now v5; keep pending
results private and never reroll/re-time them on load. MCP connected on 58742.
MY EGGS is the new hatch UI. Older direct-pet conveyor notes are historical.

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
