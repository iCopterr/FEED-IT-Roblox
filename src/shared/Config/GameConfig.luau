--!strict

local GameConfig = {
	PlayerDataVersion = 2,
	PetDataVersion = 2,

	StartingMoney = 0,
	StartingFood = 0,
	StartingFarmLevel = 1,
	StartingFarmPower = 1,
	StartingMaxPetSlots = 5,
}

return table.freeze(GameConfig)
