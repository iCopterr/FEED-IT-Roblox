-- Prototype only. Prices, timers and weighted pet pools are tuned here.
local Config = {
	Order = table.freeze({"prototype_egg","advanced_egg","elite_egg","master_egg","supreme_egg","ultimate_egg"}),
	RequestCooldown = .25,
	SaveRetrySeconds = 5,
	HatchDistance = 10,
	HatchPromptName = "HatchEgg",
	Definitions = table.freeze({
		master_egg = table.freeze({
			DisplayName="Master Egg", Theme="Ancient Monsters", Price=5_000_000_000, HatchSeconds=1200, TemplateName="master_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="master_pet_1",Weight=38}),
				table.freeze({SpeciesId="master_pet_2",Weight=30}),
				table.freeze({SpeciesId="master_pet_3",Weight=18}),
				table.freeze({SpeciesId="master_pet_4",Weight=11}),
				table.freeze({SpeciesId="master_pet_5",Weight=2.5}),
				table.freeze({SpeciesId="master_pet_6",Weight=0.5}),
			}),
		}),
		supreme_egg = table.freeze({
			DisplayName="Supreme Egg", Theme="Divine Creatures", Price=50_000_000_000, HatchSeconds=1800, TemplateName="supreme_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="divine_phoenix",Weight=45}),
				table.freeze({SpeciesId="heavenly_kirin",Weight=28}),
				table.freeze({SpeciesId="supreme_pet_5",Weight=18}),
				table.freeze({SpeciesId="godly_behemoth",Weight=7}),
				table.freeze({SpeciesId="supreme_pet_4",Weight=1.8}),
				table.freeze({SpeciesId="supreme_pet_6",Weight=0.2}),
			}),
		}),
		ultimate_egg = table.freeze({
			DisplayName="Ultimate Egg", Theme="Cosmic Creatures", Price=500_000_000_000, HatchSeconds=2700, TemplateName="ultimate_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="supreme_pet_1",Weight=45}),
				table.freeze({SpeciesId="supreme_pet_2",Weight=28}),
				table.freeze({SpeciesId="supreme_pet_3",Weight=18}),
				table.freeze({SpeciesId="galaxy_dragon",Weight=7}),
				table.freeze({SpeciesId="cosmic_hydra",Weight=1.8}),
				table.freeze({SpeciesId="world_eater",Weight=0.2}),
			}),
		}),
		advanced_egg = table.freeze({
			DisplayName="Advanced Egg", Theme="Elemental Creatures", Price=2_000_000, HatchSeconds=120, TemplateName="advanced_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="moss_buddy",Weight=35}),
				table.freeze({SpeciesId="clover_cub",Weight=27}),
				table.freeze({SpeciesId="river_sprite",Weight=20}),
				table.freeze({SpeciesId="dusk_fox",Weight=11}),
				table.freeze({SpeciesId="sun_guardian",Weight=6}),
				table.freeze({SpeciesId="moon_spirit",Weight=1}),
			}),
		}),
		elite_egg = table.freeze({
			DisplayName="Elite Egg", Theme="Mythical Creatures", Price=500_000_000, HatchSeconds=720, TemplateName="elite_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="crystal_cub",Weight=34}),
				table.freeze({SpeciesId="prism_buddy",Weight=28}),
				table.freeze({SpeciesId="amethyst_spirit",Weight=20}),
				table.freeze({SpeciesId="solar_phoenix",Weight=12}),
				table.freeze({SpeciesId="lunar_guardian",Weight=5.5}),
				table.freeze({SpeciesId="astral_dragon",Weight=0.5}),
			}),
		}),
		prototype_egg = table.freeze({
			DisplayName = "Basic Egg",
			Theme = "Normal Creatures",
			Price = 2000,
			HatchSeconds = 10,
			TemplateName = "prototype_egg",
			-- Test-friendly odds, not final production rarity distribution.
			Results = table.freeze({
				table.freeze({SpeciesId="test_common",Weight=36}),
				table.freeze({SpeciesId="test_uncommon",Weight=29}),
				table.freeze({SpeciesId="test_rare",Weight=18}),
				table.freeze({SpeciesId="test_epic",Weight=11}),
				table.freeze({SpeciesId="test_legendary",Weight=5}),
				table.freeze({SpeciesId="test_mythic",Weight=1}),
			}),
		}),
	}),
}

function Config.Pick(eggId: string, roll: number): string
	assert(type(roll)=="number" and roll>=0 and roll<1,"Invalid hatch roll")
	local definition=assert(Config.Definitions[eggId],"Unknown egg")
	local total=0
	for _,entry in definition.Results do total+=entry.Weight end
	local cursor=0
	for _,entry in definition.Results do
		cursor+=entry.Weight
		if roll*total<cursor then return entry.SpeciesId end
	end
	error("Invalid egg result weights")
end

return table.freeze(Config)
