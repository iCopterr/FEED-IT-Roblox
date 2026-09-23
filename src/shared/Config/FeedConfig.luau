-- GDD v0.5 sections 13, 14, 16 and 20. Chances are fractions, not percentages.
-- Cost/risk keys are TARGET levels (current FeedLevel + 1), not current levels.
-- Candidate balance; Critical gains are capped at 40 per the owner's direction.
local FeedConfig = {
	MaxConfiguredLevel = 40,
	-- Owner's current prototype rule: keep the pet, lose its Feed growth.
	ExplosionResetLevel = 0,
	CooldownSeconds = 0.5,
	SaveRetrySeconds = 5,
	GrowthPerLevel = 0.06,
	MaxVisualScale = 3.4,
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

-- Conservative prototype size curve, keeping the plate and five-pet Pen usable.
function FeedConfig.GetScale(level: number): number
	return math.min(FeedConfig.MaxVisualScale, 1 + math.max(0, level) * FeedConfig.GrowthPerLevel)
end

return table.freeze(FeedConfig)
