assert(not game:GetService('RunService'):IsRunning())
local old=workspace:FindFirstChild('PetSizeComparison');if old then old:Destroy()end
local folder=Instance.new('Folder');folder.Name='PetSizeComparison';folder.Parent=workspace
local shared=game.ReplicatedStorage.Shared:Clone();shared.Parent=game.ServerStorage
local cfg=require(shared.Config.PetConfig);local models=require(shared.PetModels)
local egg=workspace:GetAttribute('SizeReviewEgg') or 'master_egg'
local ids={'test_common'}
for id,def in cfg.Species do if def.EggId==egg and id~='test_common' then table.insert(ids,id)end end
table.sort(ids,function(a,b)return cfg.Species[a].BaseFootprint<cfg.Species[b].BaseFootprint end)
local x=0;local maximumHeight=0;local maximumDepth=0;local out={}
for _,id in ids do
 local def=cfg.Species[id];local m=assert(models.GetTemplate(id)):Clone();m.Name=def.DisplayName
 m:ScaleTo(models.GetScale(id,0))
 local bounds,size=m:GetBoundingBox()
 x+=size.X/2+5
 m:PivotTo(CFrame.new(x,4+size.Y/2,1600)*bounds:ToObjectSpace(m:GetPivot()))
 for _,part in m:GetDescendants()do if part:IsA('BasePart')then part.Anchored=true;part.CanCollide=false end end
 m.Parent=folder
 local label=Instance.new('BillboardGui');label.Name='ComparisonLabel';label.Size=UDim2.fromOffset(150,32);label.AlwaysOnTop=true;label.StudsOffsetWorldSpace=Vector3.new(0,size.Y/2+2,0);label.Parent=m.PrimaryPart
 local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=.25;text.BackgroundColor3=Color3.fromRGB(24,29,40);text.TextColor3=Color3.new(1,1,1);text.TextSize=16;text.Text=def.DisplayName;text.Parent=label
 table.insert(out,{name=m.Name,height=size.Y,width=size.X,depth=size.Z,footprint=def.BaseFootprint})
 x+=size.X/2+5;maximumHeight=math.max(maximumHeight,size.Y);maximumDepth=math.max(maximumDepth,size.Z)
end
shared:Destroy()
local floor=Instance.new('Part');floor.Name='ReviewFloor';floor.Size=Vector3.new(x+10,.25,maximumDepth+12);floor.Position=Vector3.new(x/2,3.85,1600);floor.Anchored=true;floor.Color=Color3.fromRGB(55,65,80);floor.Material=Enum.Material.SmoothPlastic;floor.Parent=folder
local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=45
local aspect=math.max(1,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y))
local distance=math.max((x+20)/(2*math.tan(math.rad(22.5))*aspect),maximumHeight*1.8)+maximumDepth/2
local target=Vector3.new(x/2,4+maximumHeight*.4,1600)
camera.CFrame=CFrame.lookAt(target+Vector3.new(0,distance*.22,-distance),target);camera.Focus=CFrame.new(target)
game:GetService('Selection'):Set({})
return game:GetService('HttpService'):JSONEncode(out)
