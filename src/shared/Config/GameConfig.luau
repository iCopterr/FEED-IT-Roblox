--!strict

local GameConfig = {
	PlayerDataVersion = 7,
	PetDataVersion = 2,

	StartingMoney = 0,
	StartingFood = 0,
	StartingFarmLevel = 1,
	StartingFeedPlateLevel = 1,
	StartingFarmPower = 1,
	StartingMaxPetSlots = 5,
	-- Prototype grant so Protection can be tested before quests/products exist.
	StartingProtectionTokens = 3,
}

return table.freeze(GameConfig)
