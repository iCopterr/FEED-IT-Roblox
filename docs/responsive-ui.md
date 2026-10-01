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
- Merchant/Debug share fitting; Pen remote gets a larger fitted panel on small
  screens. Shop/Index/Inventory/Settings launchers share scale rules. Existing
  notification/tutorial fitting and world-based hatch reveal remain unchanged.
- Inventory hotbar column math includes cell padding, with 0–10 slots checked.
  Duplicate exported inventory UIScales are neutralized at runtime, not deleted.

Verification: `docs/studio/verify-device-layout.luau` runs against temporary cloned
Studio instances at 320x568, 390x844, 600x900, 844x390, 1024x768, 1920x1080 and
2560x1080. Checks modal bounds, desktop restoration and last Shop offer reachability.
`test-authored-inventory-layout.ps1` covers 15 viewport/hotbar combinations and
preservation of desktop edits; Starter Pack and shine regression tests also pass.

Studio edit-mode portrait previews of the seven adapted menus were inspected
using temporary 390x700 frames (shown at .72 scale). Preview overlays were removed.
This is not a full real-device or Play input test. Dynamic owned-pet previews,
touch drag/scroll, safe-area notches, console focus and purchase prompts still
need a runtime device-emulator/physical-device pass. Existing decorative rotated
shine layers can spill outside cards in Studio edit previews; runtime CanvasGroup
clipping needs confirmation, and those authored decorations were not rewritten.
