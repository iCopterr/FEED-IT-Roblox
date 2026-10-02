local Feed=require(script.Parent.Config.FeedConfig)
local Variants=require(script.Parent.Config.VariantConfig)
local Repair=require(script.Parent.Config.ReviveConfig)
return function(pet,level)
	local multiplier=Feed.Multiplier[level or pet.FeedLevel]
	local rate=if multiplier then pet.BaseIncome*multiplier*Variants.Multiplier(pet.Variant) else 0
	if pet.Broken then rate*=Repair.BrokenIncomeMultiplier end
	return if rate==rate and rate>=0 and rate<math.huge then rate else 0
end
