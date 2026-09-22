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
	moss_buddy = table.freeze({SpeciesId="moss_buddy", DisplayName="Moss Buddy", EggId="advanced_egg", Rarity="Uncommon", BaseIncome=rarityBaseIncome.Uncommon}),
	clover_cub = table.freeze({SpeciesId="clover_cub", DisplayName="Clover Cub", EggId="advanced_egg", Rarity="Uncommon", BaseIncome=rarityBaseIncome.Uncommon}),
	river_sprite = table.freeze({SpeciesId="river_sprite", DisplayName="River Sprite", EggId="advanced_egg", Rarity="Rare", BaseIncome=rarityBaseIncome.Rare}),
	dusk_fox = table.freeze({SpeciesId="dusk_fox", DisplayName="Dusk Fox", EggId="advanced_egg", Rarity="Epic", BaseIncome=rarityBaseIncome.Epic}),
	sun_guardian = table.freeze({SpeciesId="sun_guardian", DisplayName="Sun Guardian", EggId="advanced_egg", Rarity="Legendary", BaseIncome=rarityBaseIncome.Legendary}),
	moon_spirit = table.freeze({SpeciesId="moon_spirit", DisplayName="Moon Spirit", EggId="advanced_egg", Rarity="Mythic", BaseIncome=rarityBaseIncome.Mythic}),
	crystal_cub = table.freeze({SpeciesId="crystal_cub", DisplayName="Crystal Cub", EggId="elite_egg", Rarity="Rare", BaseIncome=rarityBaseIncome.Rare}),
	prism_buddy = table.freeze({SpeciesId="prism_buddy", DisplayName="Prism Buddy", EggId="elite_egg", Rarity="Rare", BaseIncome=rarityBaseIncome.Rare}),
	amethyst_spirit = table.freeze({SpeciesId="amethyst_spirit", DisplayName="Amethyst Spirit", EggId="elite_egg", Rarity="Epic", BaseIncome=rarityBaseIncome.Epic}),
	solar_phoenix = table.freeze({SpeciesId="solar_phoenix", DisplayName="Solar Phoenix", EggId="elite_egg", Rarity="Legendary", BaseIncome=rarityBaseIncome.Legendary}),
	lunar_guardian = table.freeze({SpeciesId="lunar_guardian", DisplayName="Lunar Guardian", EggId="elite_egg", Rarity="Legendary", BaseIncome=rarityBaseIncome.Legendary}),
	astral_dragon = table.freeze({SpeciesId="astral_dragon", DisplayName="Astral Dragon", EggId="elite_egg", Rarity="Mythic", BaseIncome=rarityBaseIncome.Mythic}),
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
