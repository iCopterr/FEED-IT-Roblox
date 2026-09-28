--!strict

export type SpeciesDefinition = {
	SpeciesId: string,
	DisplayName: string,
	TemplateName: string,
	EggId: string,
	Rarity: string,
	BaseIncome: number,
	BaseFootprint: number, -- horizontal bounding-box diagonal in studs at Feed Level 0
}

local rarities: { [string]: boolean } = table.freeze({
	Common = true,
	Uncommon = true,
	Rare = true,
	Epic = true,
	Legendary = true,
	Mythic = true,
	Fabled = true,
	Divine = true,
	Celestial = true,
})

-- Stable IDs keep saved pets/templates compatible; display names define the roster.
local species: { [string]: SpeciesDefinition } = table.freeze({
	-- prototype_egg
	test_common = table.freeze({SpeciesId="test_common", DisplayName="Chicken", TemplateName="Chicken", EggId="prototype_egg", Rarity="Common", BaseIncome=10, BaseFootprint=6.3}),
	test_uncommon = table.freeze({SpeciesId="test_uncommon", DisplayName="Boar", TemplateName="Boar", EggId="prototype_egg", Rarity="Common", BaseIncome=16, BaseFootprint=7.1}),
	test_rare = table.freeze({SpeciesId="test_rare", DisplayName="Horned Bunny", TemplateName="Horned Bunny", EggId="prototype_egg", Rarity="Uncommon", BaseIncome=35, BaseFootprint=6}),
	test_epic = table.freeze({SpeciesId="test_epic", DisplayName="Fox", TemplateName="Fox", EggId="prototype_egg", Rarity="Uncommon", BaseIncome=55, BaseFootprint=8}),
	test_legendary = table.freeze({SpeciesId="test_legendary", DisplayName="Black Wolf", TemplateName="Black Wolf", EggId="prototype_egg", Rarity="Rare", BaseIncome=140, BaseFootprint=9}),
	test_mythic = table.freeze({SpeciesId="test_mythic", DisplayName="Baby Griffin", TemplateName="Baby Griffin", EggId="prototype_egg", Rarity="Epic", BaseIncome=600, BaseFootprint=8.5}),
	-- advanced_egg
	moss_buddy = table.freeze({SpeciesId="moss_buddy", DisplayName="Ember Drake", TemplateName="Ember Drake", EggId="advanced_egg", Rarity="Uncommon", BaseIncome=80, BaseFootprint=13}),
	clover_cub = table.freeze({SpeciesId="clover_cub", DisplayName="Frost Wolf", TemplateName="Frost Wolf", EggId="advanced_egg", Rarity="Uncommon", BaseIncome=200, BaseFootprint=9}),
	river_sprite = table.freeze({SpeciesId="river_sprite", DisplayName="Storm Griffin", TemplateName="Storm Griffin", EggId="advanced_egg", Rarity="Rare", BaseIncome=320, BaseFootprint=13.5}),
	dusk_fox = table.freeze({SpeciesId="dusk_fox", DisplayName="Lava Golem", TemplateName="Lava Golem", EggId="advanced_egg", Rarity="Rare", BaseIncome=850, BaseFootprint=11}),
	sun_guardian = table.freeze({SpeciesId="sun_guardian", DisplayName="Thunder Serpent", TemplateName="Thunder Serpent", EggId="advanced_egg", Rarity="Epic", BaseIncome=1400, BaseFootprint=12}),
	moon_spirit = table.freeze({SpeciesId="moon_spirit", DisplayName="Ice Dragon", TemplateName="Ice Dragon", EggId="advanced_egg", Rarity="Legendary", BaseIncome=4500, BaseFootprint=15}),
	-- elite_egg
	crystal_cub = table.freeze({SpeciesId="crystal_cub", DisplayName="Kitsune", TemplateName="Kitsune", EggId="elite_egg", Rarity="Rare", BaseIncome=450, BaseFootprint=10}),
	prism_buddy = table.freeze({SpeciesId="prism_buddy", DisplayName="Minotaur", TemplateName="Minotaur", EggId="elite_egg", Rarity="Rare", BaseIncome=700, BaseFootprint=11.5}),
	amethyst_spirit = table.freeze({SpeciesId="amethyst_spirit", DisplayName="Basilisk", TemplateName="Basilisk", EggId="elite_egg", Rarity="Epic", BaseIncome=1800, BaseFootprint=11}),
	solar_phoenix = table.freeze({SpeciesId="solar_phoenix", DisplayName="Manticore", TemplateName="Manticore", EggId="elite_egg", Rarity="Epic", BaseIncome=2800, BaseFootprint=13}),
	lunar_guardian = table.freeze({SpeciesId="lunar_guardian", DisplayName="Chimera", TemplateName="Chimera", EggId="elite_egg", Rarity="Legendary", BaseIncome=7500, BaseFootprint=13.5}),
	astral_dragon = table.freeze({SpeciesId="astral_dragon", DisplayName="Cerberus", TemplateName="Cerberus", EggId="elite_egg", Rarity="Mythic", BaseIncome=24000, BaseFootprint=14}),
	-- master_egg
	master_pet_1 = table.freeze({SpeciesId="master_pet_1", DisplayName="Hydra", TemplateName="Hydra", EggId="master_egg", Rarity="Epic", BaseIncome=3500, BaseFootprint=18}),
	master_pet_2 = table.freeze({SpeciesId="master_pet_2", DisplayName="Phoenix", TemplateName="Phoenix", EggId="master_egg", Rarity="Legendary", BaseIncome=5500, BaseFootprint=14.5}),
	master_pet_3 = table.freeze({SpeciesId="master_pet_3", DisplayName="Kraken", TemplateName="Kraken", EggId="master_egg", Rarity="Legendary", BaseIncome=12000, BaseFootprint=18}),
	master_pet_4 = table.freeze({SpeciesId="master_pet_4", DisplayName="Ancient Wyvern", TemplateName="Ancient Wyvern", EggId="master_egg", Rarity="Mythic", BaseIncome=18000, BaseFootprint=17}),
	master_pet_5 = table.freeze({SpeciesId="master_pet_5", DisplayName="Bone Dragon", TemplateName="Bone Dragon", EggId="master_egg", Rarity="Mythic", BaseIncome=40000, BaseFootprint=17}),
	master_pet_6 = table.freeze({SpeciesId="master_pet_6", DisplayName="Behemoth", TemplateName="Behemoth", EggId="master_egg", Rarity="Fabled", BaseIncome=65000, BaseFootprint=18}),
	-- supreme_egg
	supreme_pet_1 = table.freeze({SpeciesId="supreme_pet_1", DisplayName="Astral Kitsune", TemplateName="Astral Kitsune", EggId="ultimate_egg", Rarity="Mythic", BaseIncome=100000, BaseFootprint=12}),
	supreme_pet_2 = table.freeze({SpeciesId="supreme_pet_2", DisplayName="Eclipse Griffin", TemplateName="Eclipse Griffin", EggId="ultimate_egg", Rarity="Fabled", BaseIncome=220000, BaseFootprint=16}),
	supreme_pet_3 = table.freeze({SpeciesId="supreme_pet_3", DisplayName="Void Leviathan", TemplateName="Void Leviathan", EggId="ultimate_egg", Rarity="Fabled", BaseIncome=320000, BaseFootprint=19}),
	supreme_pet_4 = table.freeze({SpeciesId="supreme_pet_4", DisplayName="Celestial Dragon", TemplateName="Celestial Dragon", EggId="supreme_egg", Rarity="Divine", BaseIncome=250000, BaseFootprint=18}),
	supreme_pet_5 = table.freeze({SpeciesId="supreme_pet_5", DisplayName="Seraph Beast", TemplateName="Seraph Beast", EggId="supreme_egg", Rarity="Mythic", BaseIncome=150000, BaseFootprint=16}),
	supreme_pet_6 = table.freeze({SpeciesId="supreme_pet_6", DisplayName="World Serpent", TemplateName="World Serpent", EggId="supreme_egg", Rarity="Divine", BaseIncome=300000, BaseFootprint=20}),
	-- Divine / cosmic expansion; existing IDs above are deliberately retained.
	divine_phoenix = table.freeze({SpeciesId="divine_phoenix", DisplayName="Divine Phoenix", TemplateName="Divine Phoenix", EggId="supreme_egg", Rarity="Legendary", BaseIncome=35000, BaseFootprint=16}),
	heavenly_kirin = table.freeze({SpeciesId="heavenly_kirin", DisplayName="Heavenly Kirin", TemplateName="Heavenly Kirin", EggId="supreme_egg", Rarity="Mythic", BaseIncome=65000, BaseFootprint=13}),
	godly_behemoth = table.freeze({SpeciesId="godly_behemoth", DisplayName="Godly Behemoth", TemplateName="Godly Behemoth", EggId="supreme_egg", Rarity="Fabled", BaseIncome=200000, BaseFootprint=20}),
	galaxy_dragon = table.freeze({SpeciesId="galaxy_dragon", DisplayName="Galaxy Dragon", TemplateName="Galaxy Dragon", EggId="ultimate_egg", Rarity="Divine", BaseIncome=550000, BaseFootprint=19}),
	cosmic_hydra = table.freeze({SpeciesId="cosmic_hydra", DisplayName="Cosmic Hydra", TemplateName="Cosmic Hydra", EggId="ultimate_egg", Rarity="Divine", BaseIncome=850000, BaseFootprint=21}),
	world_eater = table.freeze({SpeciesId="world_eater", DisplayName="World Eater", TemplateName="World Eater", EggId="ultimate_egg", Rarity="Celestial", BaseIncome=1500000, BaseFootprint=22}),
})

local PetConfig = {
	DefaultVariant = "Normal",
	PetIdGenerationAttempts = 5,
	MaxWorldFootprint = 40,
	PrototypeEggId = "prototype_egg",
	Rarities = rarities,
	Species = species,
}

return table.freeze(PetConfig)
