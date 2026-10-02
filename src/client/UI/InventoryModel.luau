local Shared=game:GetService("ReplicatedStorage").Shared
local Pets=require(Shared.Config.PetConfig)
local Variants=require(Shared.Config.VariantConfig)
local PetIncome=require(Shared.PetIncome)
local Config=require(Shared.Config.InventoryConfig)
local Model={}
local Foods=require(Shared.Config.FoodConfig)
local Revive=require(Shared.Config.ReviveConfig).Shop

function Model.Entries(snapshot)
	local entries={}
	for id,pet in snapshot.Inventory do
		-- Placed pets remain owned in server data, but are not bag items.
		if pet.Placed then continue end
		local definition=Pets.Species[pet.SpeciesId]
		entries["pet:"..id]={Key="pet:"..id,Id=id,Kind="Pet",Variant=pet.Variant,Name=Variants.Name(definition and definition.DisplayName or pet.SpeciesId,pet.Variant),
			SpeciesId=pet.SpeciesId,Rarity=pet.Rarity,Level=pet.FeedLevel,Locked=pet.Locked,
			Income=PetIncome(pet),CreatedAt=pet.CreatedAt,Broken=pet.Broken==true,
			State=if snapshot.CarriedPetId==id then "HELD" elseif snapshot.FeedPlatePetId==id then "FEED PLATE"
				elseif pet.Placed then "IN PEN" else "STORED"}
	end
	for _,egg in snapshot.Eggs or {} do
		if egg.Placed then continue end
		entries["egg:"..egg.EggUid]={Key="egg:"..egg.EggUid,Id=egg.EggUid,Kind="Egg",Name=egg.Name,
			EggId=egg.EggId,Rarity="Egg",Level=0,Income=0,CreatedAt=egg.StartedAt,ReadyAt=egg.ReadyAt,
			State=if snapshot.CarriedEggUid==egg.EggUid then "HELD" elseif not egg.Placed then "STORED"
				elseif egg.ReadyAt<=snapshot.ServerNow then "READY" else "INCUBATING"}
	end
	for _,id in Foods.Order do
		local amount=(snapshot.Foods or {})[id] or 0
		local food=Foods.Types[id]
		if amount>0 then entries["food:"..id]={Key="food:"..id,Id=id,Kind="Food",Name=food.Name,
			Rarity=food.Rarity,Quantity=amount,Reduction=food.Reduction,Level=0,Income=0,CreatedAt=0,State="FOOD"} end
	end
	-- Recovery items share the consumables tab, but never enter the feed selector.
	if (snapshot.ReviveCharges or 0)>0 then
		entries["item:revive"]={Key="item:revive",Id="revive",Kind="Food",Name=Revive.DisplayName,
			Rarity=Revive.Rarity,Quantity=snapshot.ReviveCharges,Reduction=0,Icon=Revive.Icon,
			Effect="Full Repair",Description=Revive.Description,Level=0,Income=0,CreatedAt=0,State="CHARM"}
	end
	return entries
end

function Model.Filter(entries,category,query,sort)
	local result={};query=string.lower(query or "")
	for _,entry in entries do
		if ((category=="All" and entry.Kind~="Food") or category==entry.Kind)
			and string.find(string.lower(entry.Name.." "..entry.Rarity),query,1,true) then table.insert(result,entry) end
	end
	table.sort(result,function(a,b)
		local left,right
		if sort=="Income" then left,right=a.Income,b.Income
		elseif sort=="Level" then left,right=a.Level,b.Level
		elseif sort=="Rarity" then left,right=Config.RarityOrder[a.Rarity] or 0,Config.RarityOrder[b.Rarity] or 0
		else left,right=a.CreatedAt,b.CreatedAt end
		if left~=right then return left>right end
		return a.Key<b.Key
	end)
	return result
end

function Model.CanSlot(entry)
	return entry~=nil and (entry.State=="STORED" or entry.State=="HELD")
end

function Model.Reconcile(slots,known,entries)
	for i=1,Config.HotbarSlots do if slots[i] and not Model.CanSlot(entries[slots[i]]) then slots[i]=nil end end
	for key in known do if not Model.CanSlot(entries[key]) then known[key]=nil end end
	for _,entry in Model.Filter(entries,"All","","Newest") do
		if Model.CanSlot(entry) and not known[entry.Key] then
			known[entry.Key]=true
			for i=1,Config.HotbarSlots do if not slots[i] then slots[i]=entry.Key;break end end
		end
	end
end

function Model.SlotOf(slots,key)
	for i=1,Config.HotbarSlots do if key and slots[i]==key then return i end end
	return nil
end

function Model.TogglePin(slots,key)
	local existing=Model.SlotOf(slots,key)
	if existing then slots[existing]=nil;return true end
	for i=1,Config.HotbarSlots do if not slots[i] then slots[i]=key;return true end end
	return false
end

return Model
