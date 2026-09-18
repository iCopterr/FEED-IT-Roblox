--!strict

local GameConfig = {
	PlayerDataVersion = 4,
	PetDataVersion = 2,

	StartingMoney = 0,
	StartingFood = 0,
	StartingFarmLevel = 1,
	StartingFeedPlateLevel = 1,
	StartingFarmPower = 1,
	StartingMaxPetSlots = 5,
}

return table.freeze(GameConfig)
