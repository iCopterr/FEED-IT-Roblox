-- The station lists damaged pets directly from their single inventory identity.
local Pets=require(script.Parent.Config.PetConfig)
local Variants=require(script.Parent.Config.VariantConfig)
local PetIncome=require(script.Parent.PetIncome)
local Recovery={}

function Recovery.List(data)
	local records={}
	for id,pet in data.Inventory do
		if not pet.Broken then continue end
		local definition=Pets.Species[pet.SpeciesId]
		local repaired=table.clone(pet);repaired.Broken=nil
		table.insert(records,{PetId=id,AttemptId=pet.BreakId,SpeciesId=pet.SpeciesId,
			PetName=Variants.Name(if definition then definition.DisplayName else pet.SpeciesId,pet.Variant),
			Variant=pet.Variant,Rarity=pet.Rarity,FeedLevel=pet.FeedLevel,Locked=pet.Locked,CreatedAt=pet.CreatedAt,
			Income=PetIncome(pet),RestoredIncome=PetIncome(repaired),Placed=pet.Placed,Broken=true})
	end
	table.sort(records,function(a,b)
		if a.CreatedAt~=b.CreatedAt then return a.CreatedAt>b.CreatedAt end
		return a.PetId<b.PetId
	end)
	return records
end

return table.freeze(Recovery)
