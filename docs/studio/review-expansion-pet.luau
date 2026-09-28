local name='__PET_NAME__';local angle=__ANGLE__
local old=workspace:FindFirstChild('_ExpansionReview');if old then old:Destroy()end
local folder=Instance.new('Folder');folder.Name='_ExpansionReview';folder.Parent=workspace
local template=game.ServerStorage.PetOptimizationCandidates[name]
assert(template:GetAttribute('SerializationVerified'))
local m=template:Clone();m.Parent=folder
local _,size=m:GetBoundingBox();m:ScaleTo(m:GetScale()*15/math.max(size.X,size.Y,size.Z))
m:PivotTo(CFrame.new(0,10,800)*CFrame.Angles(0,math.rad(angle),0))
local cf,s=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,10-cf.Position.Y,0))
local pad=Instance.new('Part');pad.Name='ReviewFloor';pad.Size=Vector3.new(60,.2,60);pad.Anchored=true;pad.Color=Color3.fromRGB(105,114,128);pad.Material=Enum.Material.SmoothPlastic;pad.Position=Vector3.new(0,10-s.Y/2-.1,800);pad.Parent=folder
local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=35
camera.CFrame=CFrame.lookAt(Vector3.new(0,15,768),Vector3.new(0,10,800));camera.Focus=CFrame.new(0,10,800)
game:GetService('Selection'):Set({})
