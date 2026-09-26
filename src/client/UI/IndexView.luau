local Shared = game:GetService("ReplicatedStorage").Shared
local Eggs = require(Shared.Config.EggConfig)
local Pets = require(Shared.Config.PetConfig)
local Number = require(Shared.NumberFormat).Compact
local Preview = require(script.Parent.ItemPreview)
local View = {}
local rarityColors = {
	Common=Color3.fromRGB(164,174,190), Uncommon=Color3.fromRGB(97,222,103),
	Rare=Color3.fromRGB(69,169,255), Epic=Color3.fromRGB(204,104,255),
	Legendary=Color3.fromRGB(255,206,69), Mythic=Color3.fromRGB(255,102,155),
}

function View.Count(discovered, eggId)
	local count = 0
	for _,entry in Eggs.Definitions[eggId].Results do
		if discovered[entry.SpeciesId] == true then count += 1 end
	end
	return count, #Eggs.Definitions[eggId].Results
end

local function petPreview(view, speciesId, unlocked)
	Preview.Set(view, {Kind="Pet", SpeciesId=speciesId})
	-- Tint the viewport's rendered image, so textured meshes and neon parts
	-- remain a solid silhouette without modifying shared pet templates.
	view.ImageColor3 = if unlocked then Color3.new(1,1,1) else Color3.new(0,0,0)
end

function View.Render(panel, discovered, eggId, speciesId)
	local total, unlockedTotal = 0, 0
	for index,id in Eggs.Order do
		local button=panel.Categories["Egg"..index]
		local count,capacity=View.Count(discovered,id)
		total+=capacity;unlockedTotal+=count
		button.Label.Text=Eggs.Definitions[id].DisplayName
		button.Count.Text=string.format("%d / %d",count,capacity)
		button.Border.Color=if id==eggId then Color3.fromRGB(255,221,89) else Color3.fromRGB(25,28,38)
		button:SetAttribute("Selected",id==eggId)
		Preview.Set(button.Preview,{Kind="Egg",EggId=id})
	end
	panel.Progress.Text=string.format("DISCOVERED  %d / %d",unlockedTotal,total)
	panel.CategoryName.Text=Eggs.Definitions[eggId].DisplayName
	local results=Eggs.Definitions[eggId].Results
	for index=1,6 do
		local card=panel.Pets["Pet"..index]
		local entry=results[index]
		card.Visible=entry~=nil
		if not entry then Preview.Set(card.Preview,nil);continue end
		local id=entry.SpeciesId
		local pet=Pets.Species[id]
		local unlocked=discovered[id]==true
		card:SetAttribute("SpeciesId",id)
		card:SetAttribute("Unlocked",unlocked)
		card:SetAttribute("Selected",speciesId==id)
		card.ItemName.Text=if unlocked then pet.DisplayName else "???"
		card.Rarity.Text=if unlocked then pet.Rarity else "UNDISCOVERED"
		card.Rarity.TextColor3=if unlocked then rarityColors[pet.Rarity] else Color3.fromRGB(168,176,193)
		card.Income.Text=if unlocked then "$"..Number(pet.BaseIncome).."/s" else "—"
		card.Border.Color=if id==speciesId then Color3.fromRGB(255,221,89) else Color3.fromRGB(25,28,38)
		petPreview(card.Preview,id,unlocked)
	end
	local pet=Pets.Species[speciesId]
	local unlocked=discovered[speciesId]==true
	local detail=panel.Detail
	detail.ItemName.Text=if unlocked then pet.DisplayName else "UNDISCOVERED"
	detail.Rarity.Text=if unlocked then pet.Rarity else "???"
	detail.Rarity.TextColor3=if unlocked then rarityColors[pet.Rarity] else Color3.fromRGB(168,176,193)
	detail.Level.Text=if unlocked then "LEVEL 0" else "Hatch this egg to discover it"
	detail.Income.Text=if unlocked then "$"..Number(pet.BaseIncome).."/s" else "—"
	detail.Source.Text=Eggs.Definitions[eggId].DisplayName
	petPreview(detail.Preview,speciesId,unlocked)
end

function View.Clear(panel)
	for _,object in panel:GetDescendants() do
		if object:IsA("ViewportFrame") then Preview.Set(object,nil) end
	end
end

return View
