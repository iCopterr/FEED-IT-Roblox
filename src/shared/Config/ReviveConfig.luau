return table.freeze({
	Shop = table.freeze({Id="revive", DisplayName="Revive Charm", Icon="💖", Effect="TIMED RESCUE",
		Description="Restore a broken pet at the Revive Machine within 24 hours. Consumed once; food is not refunded.",
		Price=5000000, Weight=.5, RewardType="Revive", Amount=1, StockLimit=1}),
	WindowSeconds = 24*60*60,
	MachineDistance = 16,
	PromptDistance = 12,
	RequestCooldown = 0.25,
	SnapshotCooldown = 0.25,
	SaveRetrySeconds = 5,
	RefreshSeconds = 1,
})
