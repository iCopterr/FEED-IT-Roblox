--!strict
return table.freeze({
 StartingSlots = 5,
 MaxSlots = 10,
 -- Prices are per target capacity, independent of food/risk balance.
 UpgradeCost = table.freeze({[6]=20000,[7]=100000,[8]=500000,[9]=2500000,[10]=10000000}),
 UpgradeDistance = 16,
 UpgradeCooldown = .5,
 SaveRetrySeconds = 5,
 SignRefreshSeconds = .5,
})
