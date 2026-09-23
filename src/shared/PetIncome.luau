local Feed=require(script.Parent.Config.FeedConfig)
local Variants=require(script.Parent.Config.VariantConfig)
return function(pet,level)
	local multiplier=Feed.Multiplier[level or pet.FeedLevel]
	local rate=if multiplier then pet.BaseIncome*multiplier*Variants.Multiplier(pet.Variant) else 0
	return if rate==rate and rate>=0 and rate<math.huge then rate else 0
end
