local brokenIncomeMultiplier = 0.1
return table.freeze({
	StationName = "Pet Repair Station",
	Shop = table.freeze({Id="revive", Rarity="Divine", DisplayName="Repair Charm", Icon="💖", Effect="FULL REPAIR",
		Description="Repair a broken pet at the Pet Repair Station. Restores full income at its current level. No expiry.",
		Price=5000000, Weight=.5, RewardType="Revive", Amount=1, StockLimit=1}),
	BrokenIncomeMultiplier = brokenIncomeMultiplier,
	BrokenIncomeLabel = string.format("%.0f%% INCOME", brokenIncomeMultiplier * 100),
	MachineDistance = 16,
	PromptDistance = 12,
	PromptHoldSeconds = .125,
	RequestCooldown = 0.25,
	SnapshotCooldown = 0.25,
	SaveRetrySeconds = 5,
	RefreshSeconds = 1,
	Shards = table.freeze({
		ExchangeCost = 100,
		ByRarity = table.freeze({
			Common = 1,
			Uncommon = 2,
			Rare = 5,
			Epic = 10,
			Legendary = 20,
			Mythic = 35,
			Fabled = 60,
			Celestial = 100,
		}),
	}),
})
