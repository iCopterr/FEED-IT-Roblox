local Config = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local FeedResolver = {}
-- Injected RNG is server-side only, enabling deterministic verification.
function FeedResolver.Roll(level, random)
	assert(type(level)=="number" and level%1==0 and level>=0 and level<Config.MaxConfiguredLevel, "MaxLevel")
	if random() < Config.ExplosionChance[level+1] then
		return {Code=if random()<Config.MiracleSaveChance then "MiracleSave" else "Explosion", FeedLevel=level, Gain=0}
	end
	local roll, cumulative = random(), 0
	for _, result in Config.CriticalResults do
		cumulative += result.Chance
		if roll < cumulative then
			local final = math.min(Config.MaxConfiguredLevel, level + result.LevelGain)
			return {Code="Success", Critical=result.Id, FeedLevel=final, Gain=final-level}
		end
	end
	error("Invalid Critical RNG/configuration")
end
return table.freeze(FeedResolver)
