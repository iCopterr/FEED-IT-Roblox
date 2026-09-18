return table.freeze({
	-- Owner's Studio-edited prices, limited to levels 1–10 per request.
	-- Costs are indexed by the TARGET farm level.
	UpgradeCost = table.freeze({[2]=20000, [3]=500000, [4]=5000000, [5]=120000000,
		[6]=2000000000, [7]=500000000000, [8]=15000000000000, [9]=200000000000000,
		[10]=1000000000000000}),
	UpgradeDistance = 14,
	UpgradeCooldown = 0.5,
	UpgradeSaveRetrySeconds = 5,
	SignRefreshSeconds = 0.5,
	FoodPerSecond = table.freeze({2, 6, 18, 50, 140, 400, 1200, 3500, 10000, 30000}),
	TickSeconds = 1,
	ScanSeconds = 0.1,
	EnterRadius = 5,
	RearmRadius = 7,
	MaxWorkDistance = 2,
	RequestCooldown = 0.2,
	-- Set to an owned, published running animation later. Empty means no animation.
	RunAnimationId = "",
})
