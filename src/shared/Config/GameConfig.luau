--!strict

local GameConfig = {
	PlayerDataVersion = 12,
	PetDataVersion = 2,

	StartingMoney = require(script.Parent.TutorialConfig).StartingMoney,
	StartingFood = 0,
	StartingMaxPetSlots = 5,
	-- Legacy save defaults only: these retired systems have no gameplay effect.
	StartingFarmLevel = 1,
	StartingFeedPlateLevel = 1,
	StartingFarmPower = 1,
	StartingProtectionTokens = 0,
	StartingTokens = 0,
}

return table.freeze(GameConfig)
