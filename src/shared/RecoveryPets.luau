-- Display projections never become usable inventory records. The saved recovery
-- remains the single identity until a server-authoritative revive or expiry.
local Config=require(script.Parent.Config.ReviveConfig)
local Pets=require(script.Parent.Config.PetConfig)
local Variants=require(script.Parent.Config.VariantConfig)
local PetIncome=require(script.Parent.PetIncome)
local Recovery={}

function Recovery.Income(record,now)
	if now>=record.ExplodedAt+Config.WindowSeconds then return 0 end
	return PetIncome(record.Pet)*Config.BrokenIncomeMultiplier
end

function Recovery.List(data,now)
	local records={}
	for id,record in data.PendingRecovery do
		local pet=record.Pet
		local definition=Pets.Species[pet.SpeciesId]
		table.insert(records,{PetId=id,AttemptId=record.AttemptId,SpeciesId=pet.SpeciesId,
			PetName=Variants.Name(if definition then definition.DisplayName else pet.SpeciesId,pet.Variant),
			Variant=pet.Variant,Rarity=pet.Rarity,FeedLevel=pet.FeedLevel,Locked=pet.Locked,CreatedAt=pet.CreatedAt,
			Income=Recovery.Income(record,now),RestoredIncome=PetIncome(pet),
			ExplodedAt=record.ExplodedAt,ExpiresAt=record.ExplodedAt+Config.WindowSeconds,FoodSpent=record.FoodSpent})
	end
	table.sort(records,function(a,b)
		if a.ExplodedAt~=b.ExplodedAt then return a.ExplodedAt>b.ExplodedAt end
		return a.PetId<b.PetId
	end)
	return records
end

return table.freeze(Recovery)
