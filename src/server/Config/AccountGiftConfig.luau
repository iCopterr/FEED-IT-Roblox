-- Owner-requested one-time inventory gift. Keep this key stable after release:
-- changing it would grant the gift again to accounts that already claimed it.
return table.freeze({
	ClaimKey = "AccountGift_20261006_Repair15_Food5",
	UserIds = table.freeze({
		[4750343708] = true,
		[123985255] = true,
		[5250447342] = true,
	}),
	RepairCharms = 15,
	FoodEach = 5,
})
