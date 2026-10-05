local Storage=game:GetService("ReplicatedStorage")
local Pets=require(Storage.Shared.Config.PetConfig)
local Variants=require(Storage.Shared.Config.VariantConfig)
local Colors=require(Storage.Shared.Config.InventoryConfig).RarityColors
local Income=require(Storage.Shared.PetIncome)
local Compact=require(Storage.Shared.NumberFormat).Money
local BrokenVisual=require(Storage.Shared.BrokenPetVisual)
local WarningColor=require(Storage.Shared.Config.ReviveConfig).BrokenVisual.WarningColor
local Presentation={}
function Presentation.Update(model,pet)
 local income=Income(pet)
 local label=model:FindFirstChild("PetLabel",true)
 if label and model:GetAttribute("FeedLevel")==pet.FeedLevel and model:GetAttribute("IncomePerSecond")==income
  and model:GetAttribute("Variant")==pet.Variant and model:GetAttribute("Broken")== (pet.Broken==true) then return end
 local body=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
 if not body then return end
 BrokenVisual.Apply(model,pet.Broken==true,true)
 local anchor=body:FindFirstChild("PetLabelAnchor")
 if not anchor then anchor=Instance.new("Attachment");anchor.Name="PetLabelAnchor";anchor.Parent=body end
 local bounds,size=model:GetBoundingBox()
 anchor.Position=body.CFrame:PointToObjectSpace(bounds.Position+Vector3.new(0,size.Y/2+2.3,0))
 -- Model growth can scale descendant UI properties. Reapply the authored pixel
 -- dimensions instead of retaining a label inherited from the old model scale.
 if label then label:Destroy() end
 label=Storage:WaitForChild("PetLabel"):Clone();label.Parent=anchor
 label.Adornee=anchor
 local species=Pets.Species[pet.SpeciesId]
 label.NameLabel.Text=Variants.Name(species and species.DisplayName or pet.SpeciesId,pet.Variant)
 label.Rarity.Text=pet.Rarity..(if pet.Broken then " • BROKEN" else "");label.Rarity.TextColor3=if pet.Broken then WarningColor else Colors[pet.Rarity] or Color3.new(1,1,1)
 label.Income.Text="$"..Compact(income).."/s";label.Income.TextColor3=if pet.Broken then WarningColor else Color3.fromRGB(110,255,100)
 model:SetAttribute("SpeciesId",pet.SpeciesId);model:SetAttribute("Rarity",pet.Rarity)
 model:SetAttribute("Variant",pet.Variant);model:SetAttribute("FeedLevel",pet.FeedLevel)
 model:SetAttribute("IncomePerSecond",income)
 model:SetAttribute("Broken",pet.Broken==true)
 game:GetService("CollectionService"):AddTag(model,"PetVisual")
end
return Presentation
