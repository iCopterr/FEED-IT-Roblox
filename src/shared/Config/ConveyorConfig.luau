-- Temporary direct-pet alpha balance, NOT egg/hatch odds. Prices are Money.
local Config = {
	SpawnSeconds=4,
	TravelSeconds=36,
	MaxOffers=10,
	StepSeconds=.1,
	BuyDistance=10,
	BuyHoldSeconds=.5,
	RequestCooldown=.25,
	SaveRetrySeconds=5,
	Offers=table.freeze({
		table.freeze({SpeciesId="test_common",Rarity="Common",Weight=600,Price=100,Color=Color3.fromRGB(221,226,230)}),
		table.freeze({SpeciesId="test_uncommon",Rarity="Uncommon",Weight=250,Price=1500,Color=Color3.fromRGB(122,236,122)}),
		table.freeze({SpeciesId="test_rare",Rarity="Rare",Weight=100,Price=5000,Color=Color3.fromRGB(103,180,255)}),
		table.freeze({SpeciesId="test_epic",Rarity="Epic",Weight=40,Price=30000,Color=Color3.fromRGB(202,123,255)}),
		table.freeze({SpeciesId="test_legendary",Rarity="Legendary",Weight=9,Price=100000,Color=Color3.fromRGB(255,210,80)}),
		table.freeze({SpeciesId="test_mythic",Rarity="Mythic",Weight=1,Price=450000,Color=Color3.fromRGB(255,113,156)}),
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
