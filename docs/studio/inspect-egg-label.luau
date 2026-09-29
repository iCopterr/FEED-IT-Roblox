local label=game.ReplicatedStorage.ConveyorPetLabel
local out={label={studs=tostring(label.StudsOffset),world=tostring(label.StudsOffsetWorldSpace),extents=tostring(label.ExtentsOffset),worldExtents=tostring(label.ExtentsOffsetWorldSpace),sizeOffset=tostring(label.SizeOffset)}}
local m=workspace.EggTemplates.advanced_egg
out.firstPart=m:FindFirstChildWhichIsA('BasePart',true).Name
out.primaryPart=m.PrimaryPart.Name
local offers=workspace.PetConveyor:FindFirstChild('Offers')
out.offers={}
if offers then for _,egg in offers:GetChildren() do
 local l=egg:FindFirstChild('ConveyorPetLabel',true)
 if l then table.insert(out.offers,{egg=egg:GetAttribute('EggId'),adornee=l.Adornee.Name,world=tostring(l.StudsOffsetWorldSpace),studs=tostring(l.StudsOffset),extents=tostring(l.ExtentsOffset),sizeOffset=tostring(l.SizeOffset)}) end
end end
return game:GetService('HttpService'):JSONEncode(out)
