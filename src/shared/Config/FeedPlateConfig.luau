-- Permanent Money upgrades; separate from future single-use Protection.
-- Initial prices match the owner's current farm table, without coupling configs.
local Config = {
	UpgradeCost = table.freeze({[2]=20000, [3]=500000, [4]=5000000, [5]=120000000,
		[6]=2000000000, [7]=500000000000, [8]=15000000000000,
		[9]=200000000000000, [10]=1000000000000000}),
	RiskReduction = table.freeze({0, .05, .10, .15, .20, .25, .30, .35, .40, .45}),
	UpgradeDistance = 14,
	UpgradeCooldown = .5,
	SaveRetrySeconds = 5,
	SignRefreshSeconds = .5,
}

function Config.GetReduction(level: number): number
	return Config.RiskReduction[math.clamp(math.floor(level), 1, #Config.RiskReduction)]
end

function Config.GetRisk(baseRisk: number, level: number): number
	return baseRisk * (1 - Config.GetReduction(level))
end

return table.freeze(Config)
