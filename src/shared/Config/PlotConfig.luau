--!strict
local GameConfig = require(script.Parent.GameConfig)

return table.freeze({
	FolderName = "PlayerPlots",
	PlayerCapacity = 6,
	SlotCount = GameConfig.StartingMaxPetSlots,
	CharacterOffset = Vector3.new(0, 4, 0),
	CharacterWaitSeconds = 10,
})
