--!strict

export type SpeciesDefinition = {
	SpeciesId: string,
	DisplayName: string,
	EggId: string,
	Rarity: string,
	BaseIncome: number,
}

local rarityBaseIncome: { [string]: number } = table.freeze({
	Common = 10,
	Uncommon = 150,
	Rare = 500,
	Epic = 3_000,
	Legendary = 10_000,
	Mythic = 45_000,
})

local species: { [string]: SpeciesDefinition } = table.freeze({
	test_common = table.freeze({
		SpeciesId = "test_common",
		DisplayName = "Common Test Pet",
		EggId = "prototype_egg",
		Rarity = "Common",
		BaseIncome = rarityBaseIncome.Common,
	}),
	test_uncommon = table.freeze({
		SpeciesId = "test_uncommon",
		DisplayName = "Uncommon Test Pet",
		EggId = "prototype_egg",
		Rarity = "Uncommon",
		BaseIncome = rarityBaseIncome.Uncommon,
	}),
	test_rare = table.freeze({
		SpeciesId = "test_rare",
		DisplayName = "Rare Test Pet",
		EggId = "prototype_egg",
		Rarity = "Rare",
		BaseIncome = rarityBaseIncome.Rare,
	}),
	test_epic = table.freeze({
		SpeciesId = "test_epic",
		DisplayName = "Epic Test Pet",
		EggId = "prototype_egg",
		Rarity = "Epic",
		BaseIncome = rarityBaseIncome.Epic,
	}),
	test_legendary = table.freeze({
		SpeciesId = "test_legendary",
		DisplayName = "Legendary Test Pet",
		EggId = "prototype_egg",
		Rarity = "Legendary",
		BaseIncome = rarityBaseIncome.Legendary,
	}),
	test_mythic = table.freeze({
		SpeciesId = "test_mythic",
		DisplayName = "Mythic Test Pet",
		EggId = "prototype_egg",
		Rarity = "Mythic",
		BaseIncome = rarityBaseIncome.Mythic,
	}),
})

local PetConfig = {
	DefaultVariant = "Normal",
	PetIdGenerationAttempts = 5,
	PrototypeEggId = "prototype_egg",
	RarityBaseIncome = rarityBaseIncome,
	Species = species,
}

return table.freeze(PetConfig)
