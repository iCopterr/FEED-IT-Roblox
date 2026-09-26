return table.freeze({
	Shop = table.freeze({Id="revive", DisplayName="Revive Charm", Icon="💖", Effect="TIMED RESCUE",
		Description="Restores pre-failure growth during the timed Rescue window. Consumed once; food is not refunded.",
		Price=5000000, Weight=.5, RewardType="Revive", Amount=1, StockLimit=1}),
	WindowSeconds = 15,
	RequestCooldown = 0.25,
	SnapshotCooldown = 0.25,
	SaveRetrySeconds = 5,
	RefreshSeconds = 1,
})
