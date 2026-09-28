assert(not game:GetService('RunService'):IsRunning())
local old=workspace:FindFirstChild('RectangularEggReview');if old then old:Destroy()end
local folder=Instance.new('Folder');folder.Name='RectangularEggReview';folder.Parent=workspace
local config=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local report={}
for index,id in config.Order do
 local source=assert(workspace.EggTemplates:FindFirstChild(id));local m=source:Clone()
 m:PivotTo(CFrame.new((index-1)*8,3,1900)*CFrame.Angles(0,math.rad(-20),0))
 local cf,size=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(0,3-cf.Position.Y+size.Y/2,0));m.Parent=folder
 local count=0
 for _,p in m:GetDescendants()do if p:IsA('BasePart')then count+=1;assert(p.Anchored and not p.CanCollide)end end
 assert(count<=40 and m.PrimaryPart and m.PrimaryPart.Name=='Shell')
 assert(m.PrimaryPart.Shape==Enum.PartType.Block)
 local test=source:Clone();test:ScaleTo(.65);test:PivotTo(CFrame.new(0,10,0));assert(test.PrimaryPart and #test:GetDescendants()==#source:GetDescendants());test:Destroy()
 table.insert(report,{id=id,parts=count,size=tostring(size)})
end
local floor=Instance.new('Part');floor.Name='ReviewFloor';floor.Anchored=true;floor.Size=Vector3.new(53,.3,14);floor.Position=Vector3.new(20,2.8,1900);floor.Color=Color3.fromRGB(66,76,90);floor.Parent=folder
workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(20,19,1860),Vector3.new(20,5,1900))
workspace.CurrentCamera.Focus=CFrame.new(20,5,1900)
game:GetService('Selection'):Set({})
return game:GetService('HttpService'):JSONEncode(report)
