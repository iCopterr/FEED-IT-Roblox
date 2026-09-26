-- Pure, server-only progress mutations. Call only after an authoritative action
-- succeeds, before its existing save. No extra rewards or client unlock remote.
local Config=require(game.ReplicatedStorage.Shared.Config.TutorialConfig)
local Progress={}

function Progress.Step(data)
	return data and data.Settings.TutorialStep
end

function Progress.Record(data,event,id,kind)
	local settings=data.Settings
	local step=settings.TutorialStep
	if not step or step==Config.Completed then return end
	if event=="BoughtEgg" and step=="BuyEgg" and kind==Config.EggId then
		settings.TutorialEggUid=id;settings.TutorialStep="PlaceEgg"
	elseif event=="Hatched" and id==settings.TutorialEggUid then
		settings.TutorialPetId=kind;settings.TutorialStep="PlacePet"
	elseif event=="BoughtFood" and kind==Config.FoodId and settings.TutorialPetId then
		settings.TutorialBoughtFood=true
		if step=="BuyFood" then settings.TutorialStep="BaseTeleport" end
	elseif event=="Travel" and id=="Merchant" and step=="MerchantTeleport" then
		settings.TutorialStep=if settings.TutorialBoughtFood then "BaseTeleport" else "BuyFood"
	elseif event=="Travel" and id=="Base" and step=="BaseTeleport" then
		settings.TutorialStep="Feed"
	elseif event=="Fed" and id==settings.TutorialPetId and settings.TutorialBoughtFood then
		settings.TutorialStep=Config.Completed
	end
end

function Progress.Reconcile(data)
	local settings=data.Settings
	local step=settings.TutorialStep
	if step=="PlaceEgg" or step=="HatchEgg" then
		local egg=data.IncubatingEggs[settings.TutorialEggUid]
		if egg then settings.TutorialStep=if egg.PenPosition then "HatchEgg" else "PlaceEgg" end
	elseif step=="PlacePet" or step=="EarnMoney" then
		local pet=data.Inventory[settings.TutorialPetId]
		if pet then
			settings.TutorialStep=if not pet.Placed then "PlacePet"
				elseif data.Money>=Config.MoneyTarget then "MerchantTeleport" else "EarnMoney"
		end
	end
	return step~=settings.TutorialStep
end

return table.freeze(Progress)
