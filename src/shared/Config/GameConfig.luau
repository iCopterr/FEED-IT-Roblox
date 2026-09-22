--!strict

local GameConfig = {
	PlayerDataVersion = 9,
	PetDataVersion = 2,

	StartingMoney = 0,
	StartingFood = 0,
	StartingFarmLevel = 1,
	StartingFeedPlateLevel = 1,
	StartingFarmPower = 1,
	StartingMaxPetSlots = 5,
	-- Deprecated fields retained for old schema/test fixtures; no active currency.
	StartingProtectionTokens = 0,
	StartingTokens = 0,
}

return table.freeze(GameConfig)
