-- Stud Design System v1.0. Skin and copy belong here, not in controllers.
local UIConfig = {
	StudAssetId = "rbxassetid://6927295847",
	TilePixels = 100,
	CornerPixels = 15,
	StrokePixels = 5,
	Font = Enum.Font.FredokaOne,
	SnapshotInterval = 2,
	RequestCooldown = 0.25,
	Palette = {
		Money = Color3.fromRGB(255, 195, 55),
		Food = Color3.fromRGB(112, 219, 89),
		Primary = Color3.fromRGB(235, 100, 202),
		Panel = Color3.fromRGB(104, 87, 175),
		Card = Color3.fromRGB(111, 172, 241),
		Selected = Color3.fromRGB(255, 210, 96),
		TextStroke = Color3.fromRGB(48, 15, 60),
	},
	Text = {
		Money = "MONEY\n%s", Food = "FOOD\n%s", Open = "MY PETS",
		Title = "MY PETS  •  %d", Close = "CLOSE", Loading = "Loading your pets…",
		Empty = "Your pet collection starts here.\nNo pets yet.",
		Select = "Select a pet to inspect it.",
		Details = "%s\n%s • %s\nFeed %d\nBase income: %s / sec\n%s",
		Stored = "In inventory", Placed = "In your Pen", Lock = "LOCK PET", Unlock = "UNLOCK PET",
		Saving = "Saving…", Retry = "Unable to refresh. Retrying…",
		LockError = "Could not change lock. Please try again.",
		Place = "PLACE PET", Pickup = "HOLD E NEAR PET",
		Equip = "EQUIP PET", Unequip = "UNEQUIP",
		PickupTooFar = "Walk closer to your placed pet to pick it up.",
		PenFull = "Your Pen is full. Pick up a pet first.",
		PlacementError = "Could not move pet. Please try again.",
		Slots = "PEN  %d / %d", Card = "%s\n%s • Feed %d\n%s",
		Locked = "LOCKED", Unlocked = "UNLOCKED",
	},
}

return UIConfig
