-- Prototype only. Prices, timers and weighted pet pools are tuned here.
local Config = {
	MaxIncubatingEggs = 1,
	RequestCooldown = .25,
	SaveRetrySeconds = 5,
	Definitions = table.freeze({
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
