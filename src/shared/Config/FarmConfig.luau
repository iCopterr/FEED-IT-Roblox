return table.freeze({
	-- GDD 19.1: costs are indexed by the TARGET farm level.
	UpgradeCost = table.freeze({[2]=5000, [3]=50000, [4]=500000, [5]=5000000,
		[6]=50000000, [7]=500000000, [8]=5000000000, [9]=50000000000,
		[10]=500000000000, [11]=5000000000000, [12]=50000000000000,
		[13]=500000000000000, [14]=5000000000000000, [15]=50000000000000000}),
	UpgradeDistance = 14,
	UpgradeCooldown = 0.5,
	UpgradeSaveRetrySeconds = 5,
	SignRefreshSeconds = 0.5,
	FoodPerSecond = table.freeze({2, 6, 18, 50, 140, 400, 1200, 3500, 10000, 30000, 90000, 250000, 700000, 2000000, 5000000}),
	TickSeconds = 1,
	ScanSeconds = 0.1,
	EnterRadius = 5,
	RearmRadius = 7,
	MaxWorkDistance = 2,
	RequestCooldown = 0.2,
	-- Set to an owned, published running animation later. Empty means no animation.
	RunAnimationId = "",
})
