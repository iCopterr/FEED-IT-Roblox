# Responsive UI

`src/client/UI/DeviceLayout.luau` owns runtime geometry adaptations of existing
authored UI. No new screens, assets, fonts, colors or economy changes.

- Uses ScreenGui's inset-aware AbsoluteSize (existing CoreUISafeInsets remain).
- Narrow portrait: width below 700 and height greater than width. Shop stacks
  eight offers vertically with a scrollable canvas through the last money pack.
  Starter Pack stacks artwork, description and Buy. Settings stacks slider/toggle
  controls below headings. Feed puts the food list below the pet. Inventory and
  Index put selected-item details below their lists; Index eggs scroll horizontally.
  Revive puts the broken-pet list above preview/details and purchase buttons.
- Other orientations retain authored desktop geometry and scale down to fit a
  12px outer margin. Portrait overrides are restored on rotation back. Later
  desktop panel-size edits are read, not replaced by hard-coded dimensions.
- Touch devices in phone landscape mode (inset-aware height at or below 720, or
  a phone-wide aspect ratio of at least 1.8) use a dedicated compact HUD. Travel
  uses 54% scale and starts at the safe canvas top; the Egg/Pet dock stays 62%.
  Touch Settings uses 72%; Shop, Index and Inventory use up to 70%, with about
  50px primary square targets. The two lower primary buttons have a roughly
  14px visible gap, Shop has at least 15px clearance above them, and the
  left and right launchers use matching 24px padding inside the ScreenGui safe
  area on touch devices (including portrait/tablet). Right anchors must use a
  negative offset; positive offsets are clipped by ClipToDeviceSafeArea.
  Desktop retains its existing 18px margins. Money uses 62%; the tutorial hint is
  narrower with 17px text. Desktop windows with the same aspect ratio are
  unchanged because touch input is required.
- Merchant/Debug share fitting; Pen remote gets a larger fitted panel on small
  screens. Shop/Index/Inventory/Settings launchers share scale rules. Existing
  notification/tutorial fitting and world-based hatch reveal remain unchanged.
- Inventory hotbar column math includes cell padding, with 0–10 slots checked.
- Touch menus reserve extra bottom room and move upward by up to 24px, including
  repair/feed, remote panels and purchase thanks. Fitting accounts for the lift,
  so short phones retain a 12px top clearance. Desktop positions restore.
- MenuHUD hides gameplay HUD, navigation, travel, remote launchers, boost and
  tutorial while a full menu/reward popup is open. The remote egg/pet panel is
  an exception: only its own dock hides, with gameplay navigation/HUD retained.
  Remote panels use 20% less scale than the previous fitted side card.
  It leaves the active
  menu and close/purchase controls enabled. Hotbar consumes GameMenuOpen;
  closing the final menu restores previous chrome visibility. Notifications
  and feed-result feedback stay available; Roblox system/touch controls remain.
  Duplicate exported inventory UIScales are neutralized at runtime, not deleted.
- Launcher buttons with both MotionScale and UIScale use one attached scale:
  Motion detaches the animation driver, combines it with the responsive base,
  and disposes it when the button is destroyed. Multiple sibling UIScales do
  not compose in Roblox and previously prevented mobile sizes from taking effect.
- CollectionLaunchers owns Shop/Inventory placement from the rendered Index
  bounds. Index and Inventory share a vertical center; Shop's horizontal center
  matches the combined row, accounting for HUD offsets, resizing and hover scale.
- Settings ScreenGui uses DisplayOrder -1 while closed so its launcher stays
  behind remote panels. Opening Settings restores the authored page order.
- UI click sounds ignore JumpButton and all descendants of Roblox TouchGui,
  including controls added after startup or moved into TouchGui later.

Verification: `docs/studio/verify-device-layout.luau` runs against temporary cloned
Studio instances at 320x568, 390x844, 600x900, 844x390, 1024x768, 1920x1080 and
2560x1080. Checks modal bounds, desktop restoration and last Shop offer reachability.
`test-authored-inventory-layout.ps1` covers 15 viewport/hotbar combinations and
preservation of desktop edits; Starter Pack and shine regression tests also pass.
`docs/studio/test-mobile-landscape-hud.luau` checks a 1368x630 touch viewport
against the authored HUD sizes, including exact primary/secondary/Settings
scales, launcher gaps and offsets, plus caps for the travel, right-side, Money
and tutorial elements.
`test-launcher-scale.luau` verifies real Instance pixel widths and TweenService
hover/press behavior, including a responsive size change during hover and
restoration to desktop size. Mobile margins are checked across six viewport
sizes, keeping both right-anchored buttons and the left group inside safe bounds.

Studio edit-mode portrait previews of the seven adapted menus were inspected
using temporary 390x700 frames (shown at .72 scale). Preview overlays were removed.
This is not a full real-device or Play input test. Dynamic owned-pet previews,
touch drag/scroll, safe-area notches, console focus and purchase prompts still
need a runtime device-emulator/physical-device pass. Existing decorative rotated
shine layers can spill outside cards in Studio edit previews; runtime CanvasGroup
clipping needs confirmation, and those authored decorations were not rewritten.
