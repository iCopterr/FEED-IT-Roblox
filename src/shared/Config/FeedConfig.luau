-- GDD v0.5 sections 13, 14, 16 and 20. Chances are fractions, not percentages.
-- Cost/risk keys are TARGET levels (current FeedLevel + 1), not current levels.
-- Candidate balance only; full Feed transactions are not enabled by this module.
local FeedConfig = {
	MaxConfiguredLevel = 40,
	MiracleSaveChance = 0.05,
	CriticalResults = table.freeze({
		table.freeze({Id="Normal", Chance=0.94, LevelGain=1}),
		table.freeze({Id="Critical", Chance=0.05, LevelGain=2}),
		table.freeze({Id="Mega", Chance=0.009, LevelGain=3}),
		table.freeze({Id="Insane", Chance=0.001, LevelGain=5}),
	}),
	ExplosionChance = table.freeze({
		0, 0, 0, .02, .02, .04, .04, .07, .07, .10,
		.12, .14, .16, .18, .20, .25, .28, .30, .33, .35,
		.55, .55, .55, .55, .55, .64, .64, .64, .64, .64,
		.76, .76, .76, .76, .76, .88, .88, .88, .88, .88,
	}),
	BaseFoodCost = table.freeze({
		30, 45, 70, 110, 180, 300, 500, 850, 1400, 2400,
		4000, 6500, 11000, 18000, 30000, 50000, 85000, 140000, 230000, 380000,
		650000, 1100000, 1800000, 3000000, 5000000, 8000000, 13000000, 21000000, 34000000, 55000000,
		85000000, 130000000, 200000000, 300000000, 450000000, 650000000, 900000000, 1250000000, 1700000000, 2300000000,
	}),
	RarityFoodMultiplier = table.freeze({
		Common=1, Uncommon=1.15, Rare=1.35, Epic=1.65, Legendary=2, Mythic=2.5,
	}),
	-- Presentation defaults (seconds, studs and degrees/sec). Not GDD balance.
	-- Future client effects must display the server outcome, never roll it.
	Presentation = table.freeze({
		CloseUIOnAcceptedFeed = true,
		FloatHeight = 4,
		FloatSeconds = 0.6,
		SpinSeconds = 2.4,
		SpinStartDegreesPerSecond = 45,
		SpinEndDegreesPerSecond = 1080,
		SpinAccelerationExponent = 2,
		Success = table.freeze({ReturnSeconds=0.6, FlashSeconds=0.35, BannerSeconds=2.5, BannerText="FEED SUCCESS!"}),
		Explosion = table.freeze({BurstSeconds=0.5, FadeSeconds=0.4, BannerSeconds=3, BannerText="YOUR PET EXPLODED!"}),
		MiracleSave = table.freeze({ReturnSeconds=0.8, BannerSeconds=3, BannerText="MIRACLE SAVE!"}),
	}),
	Multiplier = table.freeze({
		[0] = 1, 1.3, 1.7, 2.3, 3.2, 5, 7, 10, 15, 22,
		35, 60, 100, 160, 270, 500, 850, 1500, 2700, 5000,
		10000, 15000, 22000, 30000, 40000, 50000, 70000, 95000, 130000, 180000,
		250000, 350000, 475000, 625000, 800000, 1000000, 1400000, 2000000, 2800000, 3800000, 5000000,
	}),
}

-- Preserve fractional Food costs; the schema supports them and the GDD does
-- not specify rounding. Variant/traits deliberately do not affect this cost.
function FeedConfig.GetFoodCost(targetLevel: number, rarity: string): number?
	if type(targetLevel) ~= "number" or targetLevel % 1 ~= 0 then return nil end
	local base = FeedConfig.BaseFoodCost[targetLevel]
	local multiplier = FeedConfig.RarityFoodMultiplier[rarity]
	return if base and multiplier then base * multiplier else nil
end

return table.freeze(FeedConfig)
