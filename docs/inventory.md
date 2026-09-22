# Inventory and quick slots

Visual direction: original colorful stud UI, purple panels, bright chunky
buttons, FredokaOne and dark outlined text. The hotbar remains translucent black.
Per the user's latest instruction, do not use roblox-ui-director for future UI.

All layout objects are authored in `StarterGui.FeedYourPetUI` and saved in
`src/ui/FeedYourPetUI.rbxmx`. Inventory owns the collection panel; Hotbar owns
ten individual square slot buttons; no BAG button or outer background. Runtime code binds these
objects, clones the authored pet card for actual owned items, and fills saved
ViewportFrames with clones of existing pet/egg models. It never builds the UI
hierarchy from code. Each viewport binds a local Camera render helper because
the cameras stored in StarterGui do not reliably replicate to clients.

- Backquote or INVENTORY toggles the collection. Gamepad Y opens it;
  B closes it. Buttons also support touch and gamepad selection.
- All/Pets/Eggs tabs, name/rarity search, and Newest/Income/Level/Rarity sorting.
- Select an item to inspect rarity, Feed level, current income, lock and state.
- Inventory only manages ADD/REMOVE HOTBAR and lock; it cannot equip items.
- Only hotbar keys/buttons equip or put away stored pets/eggs. Egg UI is informational.
- Placed pets still require nearby hold E; plate pickup stays in the Feed UI.
  Eggs still hatch by pressing E beside a finished egg in the Pen.
- 1–9 and 0 (slot ten), or tapping a black translucent slot, equips/unequips its item.
- Only occupied slots are visible: zero items means no hotbar, one means one square.
- Held slots keep the key number and item name visible; the gold border marks selection.
  The HELD/state label stays hidden. Preview and normal translucent background remain.
- Slot UIStrokes use Border mode (not Contextual text outlines). Floating hotbar
  hints are hidden; equipping/putting away no longer emits placement instructions.
  Visible slots pack together without changing their assigned key; narrow screens wrap.
  Empty-slot keys do nothing. B no longer opens inventory.
- ADD/REMOVE QUICK SLOT changes a shortcut without moving or deleting the item.
  New items fill empty slots automatically. Removed shortcuts stay removed for
  this session. Full bars require removing a shortcut before pinning another.
- Successful Pen/plate placement clears its shortcut immediately; placed items
  cannot be added. Pickup makes the item eligible for an empty slot again.
- Snapshot polling never blocks equip input; stale in-flight snapshots are
  discarded across carry actions and placement to prevent restoring old slots.
- Slot assignments last for the current session; inventory itself remains saved.
  Ten shortcuts do not increase the five-pet Pen capacity.

UIService exposes detached owned-pet snapshots and explicitly projected public
egg fields. It never includes the reserved hatch pet. Snapshot throttling is
separate from mutation throttling, so HUD polling cannot block equip clicks.
Existing server ownership, placement, lock and carry validation remains in use.
HUD Money/Food event updates are preserved; a single inventory snapshot loop
supplies collection and HUD fallback state once per second.

Presentation modules: InventoryController, InventoryModel (filter/sort/shortcuts),
InventoryLayout (responsive reflow), ItemPreview (authored model previews) and
InventoryConfig. No economy or player-data migration is introduced.

Verification: opt-in InventoryVerification server/client scripts use Studio
memory mode, checking ownership/privacy, equip and lock validation, shortcut
reconciliation, actual client startup/previews and viewport bounds. Physical
touch/gamepad comfort still needs a device playtest.
