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

-- Stable IDs keep saved pets/templates compatible; display names define the roster.
local species: { [string]: SpeciesDefinition } = table.freeze({
	-- prototype_egg
	test_common = table.freeze({SpeciesId="test_common", DisplayName="Chicken", EggId="prototype_egg", Rarity="Common", BaseIncome=10}),
	test_uncommon = table.freeze({SpeciesId="test_uncommon", DisplayName="Boar", EggId="prototype_egg", Rarity="Common", BaseIncome=16}),
	test_rare = table.freeze({SpeciesId="test_rare", DisplayName="Horned Bunny", EggId="prototype_egg", Rarity="Uncommon", BaseIncome=35}),
	test_epic = table.freeze({SpeciesId="test_epic", DisplayName="Fox", EggId="prototype_egg", Rarity="Uncommon", BaseIncome=55}),
	test_legendary = table.freeze({SpeciesId="test_legendary", DisplayName="Black Wolf", EggId="prototype_egg", Rarity="Rare", BaseIncome=140}),
	test_mythic = table.freeze({SpeciesId="test_mythic", DisplayName="Baby Griffin", EggId="prototype_egg", Rarity="Epic", BaseIncome=600}),
	-- advanced_egg
	moss_buddy = table.freeze({SpeciesId="moss_buddy", DisplayName="Armored Boar", EggId="advanced_egg", Rarity="Uncommon", BaseIncome=80}),
	clover_cub = table.freeze({SpeciesId="clover_cub", DisplayName="Shadow Fox", EggId="advanced_egg", Rarity="Rare", BaseIncome=200}),
	river_sprite = table.freeze({SpeciesId="river_sprite", DisplayName="Saber Tiger", EggId="advanced_egg", Rarity="Rare", BaseIncome=320}),
	dusk_fox = table.freeze({SpeciesId="dusk_fox", DisplayName="Stone Golem", EggId="advanced_egg", Rarity="Epic", BaseIncome=850}),
	sun_guardian = table.freeze({SpeciesId="sun_guardian", DisplayName="Thunder Wolf", EggId="advanced_egg", Rarity="Epic", BaseIncome=1400}),
	moon_spirit = table.freeze({SpeciesId="moon_spirit", DisplayName="Flame Griffin", EggId="advanced_egg", Rarity="Legendary", BaseIncome=4500}),
	-- elite_egg
	crystal_cub = table.freeze({SpeciesId="crystal_cub", DisplayName="Crystal Turtle", EggId="elite_egg", Rarity="Rare", BaseIncome=450}),
	prism_buddy = table.freeze({SpeciesId="prism_buddy", DisplayName="Lava Hound", EggId="elite_egg", Rarity="Rare", BaseIncome=700}),
	amethyst_spirit = table.freeze({SpeciesId="amethyst_spirit", DisplayName="Frost Bear", EggId="elite_egg", Rarity="Epic", BaseIncome=1800}),
	solar_phoenix = table.freeze({SpeciesId="solar_phoenix", DisplayName="Storm Eagle", EggId="elite_egg", Rarity="Epic", BaseIncome=2800}),
	lunar_guardian = table.freeze({SpeciesId="lunar_guardian", DisplayName="Inferno Lion", EggId="elite_egg", Rarity="Legendary", BaseIncome=7500}),
	astral_dragon = table.freeze({SpeciesId="astral_dragon", DisplayName="Ice Dragon", EggId="elite_egg", Rarity="Mythic", BaseIncome=24000}),
	-- master_egg
	master_pet_1 = table.freeze({SpeciesId="master_pet_1", DisplayName="Bone Raptor", EggId="master_egg", Rarity="Epic", BaseIncome=3500}),
	master_pet_2 = table.freeze({SpeciesId="master_pet_2", DisplayName="Phantom Wolf", EggId="master_egg", Rarity="Epic", BaseIncome=5500}),
	master_pet_3 = table.freeze({SpeciesId="master_pet_3", DisplayName="Abyss Serpent", EggId="master_egg", Rarity="Legendary", BaseIncome=12000}),
	master_pet_4 = table.freeze({SpeciesId="master_pet_4", DisplayName="Cerberus", EggId="master_egg", Rarity="Legendary", BaseIncome=18000}),
	master_pet_5 = table.freeze({SpeciesId="master_pet_5", DisplayName="Thunder Wyvern", EggId="master_egg", Rarity="Mythic", BaseIncome=40000}),
	master_pet_6 = table.freeze({SpeciesId="master_pet_6", DisplayName="Crimson Dragon", EggId="master_egg", Rarity="Mythic", BaseIncome=65000}),
	-- supreme_egg
	supreme_pet_1 = table.freeze({SpeciesId="supreme_pet_1", DisplayName="Void Panther", EggId="supreme_egg", Rarity="Epic", BaseIncome=8500}),
	supreme_pet_2 = table.freeze({SpeciesId="supreme_pet_2", DisplayName="Astral Griffin", EggId="supreme_egg", Rarity="Legendary", BaseIncome=22000}),
	supreme_pet_3 = table.freeze({SpeciesId="supreme_pet_3", DisplayName="Eclipse Serpent", EggId="supreme_egg", Rarity="Legendary", BaseIncome=32000}),
	supreme_pet_4 = table.freeze({SpeciesId="supreme_pet_4", DisplayName="Chaos Dragon", EggId="supreme_egg", Rarity="Mythic", BaseIncome=85000}),
	supreme_pet_5 = table.freeze({SpeciesId="supreme_pet_5", DisplayName="Void Reaper Beast", EggId="supreme_egg", Rarity="Mythic", BaseIncome=150000}),
	supreme_pet_6 = table.freeze({SpeciesId="supreme_pet_6", DisplayName="Celestial Leviathan", EggId="supreme_egg", Rarity="Mythic", BaseIncome=300000}),
})

local PetConfig = {
	DefaultVariant = "Normal",
	PetIdGenerationAttempts = 5,
	PrototypeEggId = "prototype_egg",
	RarityBaseIncome = rarityBaseIncome,
	Species = species,
}

return table.freeze(PetConfig)
