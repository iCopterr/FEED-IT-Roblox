local Storage=game:GetService("ReplicatedStorage")
local Pets=require(Storage.Shared.Config.PetConfig)
local Variants=require(Storage.Shared.Config.VariantConfig)
local Colors=require(Storage.Shared.Config.InventoryConfig).RarityColors
local Income=require(Storage.Shared.PetIncome)
local Compact=require(Storage.Shared.NumberFormat).Compact
local Presentation={}
function Presentation.Update(model,pet)
 local income=Income(pet)
 local label=model:FindFirstChild("PetLabel",true)
 if label and model:GetAttribute("FeedLevel")==pet.FeedLevel and model:GetAttribute("IncomePerSecond")==income
  and model:GetAttribute("Variant")==pet.Variant then return end
 local body=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
 if not body then return end
 local anchor=body:FindFirstChild("PetLabelAnchor")
 if not anchor then anchor=Instance.new("Attachment");anchor.Name="PetLabelAnchor";anchor.Parent=body end
 local bounds,size=model:GetBoundingBox()
 anchor.Position=body.CFrame:PointToObjectSpace(bounds.Position+Vector3.new(0,size.Y/2+.8,0))
 if not label then label=Storage:WaitForChild("PetLabel"):Clone();label.Parent=anchor end
 label.Adornee=anchor
 local species=Pets.Species[pet.SpeciesId]
 label.NameLabel.Text=Variants.Name(species and species.DisplayName or pet.SpeciesId,pet.Variant)
 label.Rarity.Text=pet.Rarity;label.Rarity.TextColor3=Colors[pet.Rarity] or Color3.new(1,1,1)
 label.Income.Text="$"..Compact(income).."/s";label.Income.TextColor3=Color3.fromRGB(110,255,100)
 model:SetAttribute("SpeciesId",pet.SpeciesId);model:SetAttribute("Rarity",pet.Rarity)
 model:SetAttribute("Variant",pet.Variant);model:SetAttribute("FeedLevel",pet.FeedLevel)
 model:SetAttribute("IncomePerSecond",income)
end
return Presentation
