--!strict
return table.freeze({
 StartingSlots = 5,
 MaxSlots = 10,
 -- Physical expansions are milestones, not every capacity purchase.
 RearDepthBySlots = table.freeze({[5]=0,[6]=0,[7]=16,[8]=16,[9]=16,[10]=40}),
 -- Five slots retains the authored wood/grass colors.
 TierColors = table.freeze({
  [6]=Color3.fromRGB(112,193,126),
  [7]=Color3.fromRGB(100,176,224),
  [8]=Color3.fromRGB(178,139,224),
  [9]=Color3.fromRGB(237,164,96),
  [10]=Color3.fromRGB(244,211,102),
 }),
 -- Prices are per target capacity, independent of food/risk balance.
 UpgradeCost = table.freeze({[6]=20000,[7]=100000,[8]=500000,[9]=2500000,[10]=10000000}),
 UpgradeDistance = 16,
 UpgradeCooldown = .5,
 SaveRetrySeconds = 5,
 SignRefreshSeconds = .5,
})
