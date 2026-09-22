-- Prototype only. Prices, timers and weighted pet pools are tuned here.
local Config = {
	MaxIncubatingEggs = 1,
	RequestCooldown = .25,
	SaveRetrySeconds = 5,
	HatchDistance = 10,
	HatchPromptName = "HatchEgg",
	Definitions = table.freeze({
		advanced_egg = table.freeze({
			DisplayName="Advanced Egg", Price=2_000_000, HatchSeconds=120, TemplateName="prototype_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="moss_buddy",Weight=25}),
				table.freeze({SpeciesId="clover_cub",Weight=25}),
				table.freeze({SpeciesId="river_sprite",Weight=25}),
				table.freeze({SpeciesId="dusk_fox",Weight=15}),
				table.freeze({SpeciesId="sun_guardian",Weight=9.5}),
				table.freeze({SpeciesId="moon_spirit",Weight=0.5}),
			}),
		}),
		elite_egg = table.freeze({
			DisplayName="Elite Egg", Price=500_000_000, HatchSeconds=720, TemplateName="prototype_egg",
			Results=table.freeze({
				table.freeze({SpeciesId="crystal_cub",Weight=25}),
				table.freeze({SpeciesId="prism_buddy",Weight=25}),
				table.freeze({SpeciesId="amethyst_spirit",Weight=25}),
				table.freeze({SpeciesId="solar_phoenix",Weight=12}),
				table.freeze({SpeciesId="lunar_guardian",Weight=12}),
				table.freeze({SpeciesId="astral_dragon",Weight=1}),
			}),
		}),
		prototype_egg = table.freeze({
			DisplayName = "Prototype Egg",
			Price = 5000,
			HatchSeconds = 10,
			TemplateName = "prototype_egg",
			-- Test-friendly odds, not final production rarity distribution.
			Results = table.freeze({
				table.freeze({SpeciesId="test_common",Weight=40}),
				table.freeze({SpeciesId="test_uncommon",Weight=25}),
				table.freeze({SpeciesId="test_rare",Weight=18}),
				table.freeze({SpeciesId="test_epic",Weight=10}),
				table.freeze({SpeciesId="test_legendary",Weight=5}),
				table.freeze({SpeciesId="test_mythic",Weight=2}),
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
