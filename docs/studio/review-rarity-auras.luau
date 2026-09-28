-- Edit-only particle look review. Does not modify installed pet templates.
assert(not game:GetService('RunService'):IsRunning())
local old=workspace:FindFirstChild('_RarityAuraReview');if old then old:Destroy()end
local folder=Instance.new('Folder');folder.Name='_RarityAuraReview';folder.Parent=workspace
local kinds={'Epic','Legendary','Mythic','Fabled','Divine','Celestial'}
local focus=nil -- Set to a rarity name for a close-up.
local camera=workspace.CurrentCamera
camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=38
camera.CFrame=CFrame.lookAt(Vector3.new(0,15,910),Vector3.new(0,7,950));camera.Focus=CFrame.new(0,7,950)
local template=game.ReplicatedStorage.PetsModel['Ice Dragon']
for i,kind in kinds do
 local m=template:Clone();m.Name=kind;m:SetAttribute('Rarity',kind);m:SetAttribute('Variant','Normal');m.Parent=folder
 local _,size=m:GetBoundingBox();m:ScaleTo(m:GetScale()*7/math.max(size.X,size.Y,size.Z))
 local x=(i-3.5)*9
 m:PivotTo(CFrame.new(x,7,950)*CFrame.Angles(0,math.rad(-15),0))
 local cf,s=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,5-(cf.Position.Y-s.Y/2),0))
 game:GetService('CollectionService'):AddTag(m,'PetVisual')
 local pad=Instance.new('Part');pad.Name=kind..'Base';pad.Size=Vector3.new(8,.25,10);pad.Anchored=true;pad.Position=Vector3.new(x,4.8,950);pad.Material=Enum.Material.SmoothPlastic;pad.Color=Color3.fromRGB(35,40,55);pad.Parent=folder
end
if focus then
 local cf=folder[focus]:GetBoundingBox()
 camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(6,4,-12),cf.Position)
 camera.Focus=CFrame.new(cf.Position)
end
local module=game.StarterPlayer.StarterPlayerScripts.Client.Controllers.VFXController:Clone();module.Parent=game.StarterPlayer.StarterPlayerScripts.Client.Controllers
local vfx=require(module);module:Destroy();vfx.Refresh()
-- Emit a representative live-particle population for an editor screenshot.
for _,e in folder:GetDescendants()do if e:IsA('ParticleEmitter') then e:Emit(math.max(1,math.floor(e.Rate*1.2)))end end
game:GetService('Selection'):Set({})
return 'Epic to Celestial, left-to-right in world X (camera may mirror)'
