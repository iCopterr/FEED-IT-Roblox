assert(not game:GetService('RunService'):IsRunning())
local old=workspace:FindFirstChild('PetSizeComparison');if old then old:Destroy()end
local folder=Instance.new('Folder');folder.Name='PetSizeComparison';folder.Parent=workspace
local cfgModule=game.ReplicatedStorage.Shared.Config.PetConfig:Clone();cfgModule.Name='SizeReviewConfig';cfgModule.Parent=game.ServerStorage
local cfg=require(cfgModule);cfgModule:Destroy()
local names={'test_common','test_uncommon','test_legendary','moon_spirit','master_pet_1','godly_behemoth'}
local positions={-42,-29,-15,3,25,49}
local out={}
for index,id in names do
 local def=cfg.Species[id];local m=game.ReplicatedStorage.PetsModel[def.TemplateName]:Clone();m.Name=def.DisplayName;m.Parent=folder
 local _,s=m:GetBoundingBox();m:ScaleTo(m:GetScale()*def.BaseFootprint/Vector2.new(s.X,s.Z).Magnitude)
 m:PivotTo(CFrame.new(positions[index],5,1100))
 local cf,size=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,4-(cf.Position.Y-size.Y/2),0))
 table.insert(out,{name=m.Name,height=size.Y,footprint=Vector2.new(size.X,size.Z).Magnitude})
end
local floor=Instance.new('Part');floor.Size=Vector3.new(115,.25,30);floor.Position=Vector3.new(4,3.85,1100);floor.Anchored=true;floor.Color=Color3.fromRGB(60,68,80);floor.Material=Enum.Material.SmoothPlastic;floor.Parent=folder
local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=38
camera.CFrame=CFrame.lookAt(Vector3.new(4,25,1010),Vector3.new(4,9,1100));camera.Focus=CFrame.new(4,9,1100)
game:GetService('Selection'):Set({})
return game:GetService('HttpService'):JSONEncode(out)
