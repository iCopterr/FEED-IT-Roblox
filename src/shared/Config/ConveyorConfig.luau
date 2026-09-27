-- Conveyor egg availability. Pet results, prices and timers live in EggConfig.
local Config = {
	SpawnSeconds=4,
	TravelSeconds=36,
	MaxOffers=10,
	StepSeconds=.1,
	BuyDistance=10,
	BuyHoldSeconds=.25,
	RequestCooldown=.25,
	SaveRetrySeconds=5,
	Offers=table.freeze({
		table.freeze({EggId="prototype_egg",Weight=68,Color=Color3.fromRGB(255,235,180)}),
		table.freeze({EggId="advanced_egg",Weight=25,Color=Color3.fromRGB(120,220,255)}),
		table.freeze({EggId="elite_egg",Weight=5,Color=Color3.fromRGB(210,140,255)}),
		table.freeze({EggId="master_egg",Weight=1.5,Color=Color3.fromRGB(255,170,75)}),
		table.freeze({EggId="supreme_egg",Weight=.5,Color=Color3.fromRGB(255,225,90)}),
	}),
}
function Config.Pick(roll: number)
	assert(type(roll)=="number" and roll>=0 and roll<1,"Roll must be in [0,1)")
	local total=0
	for _,offer in Config.Offers do total+=offer.Weight end
	local cumulative=0
	for _,offer in Config.Offers do
		cumulative+=offer.Weight
		if roll*total<cumulative then return offer end
	end
	error("Invalid conveyor weights")
end
return table.freeze(Config)
