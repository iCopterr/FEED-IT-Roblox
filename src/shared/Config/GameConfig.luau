--!strict

local GameConfig = {
	PlayerDataVersion = 1,
	PetDataVersion = 1,

	StartingMoney = 0,
	StartingFood = 0,
	StartingFarmLevel = 1,
	StartingFarmPower = 1,
	StartingMaxPetSlots = 5,
}

return table.freeze(GameConfig)
