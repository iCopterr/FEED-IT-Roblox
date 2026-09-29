local root=assert(workspace:FindFirstChild('MapEnvironment'))
local roots=0;for _,r in workspace:GetChildren() do if r.Name=='MapEnvironment' then roots+=1 end end
assert(roots==1)
assert(#root.Trees:GetChildren()==18 and #root.Rocks:GetChildren()==30)
local count=0
local function checkPart(p)
 assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery)
 count+=1
end
for _,p in root:GetDescendants() do
 assert(not p:IsA('LuaSourceContainer'))
 if p:IsA('BasePart') then checkPart(p) end
end
for _,model in root.Trees:GetChildren() do
 local parts=0
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then
  parts+=1
  local half=p.Size/2
  local extent=Vector3.new(
   math.abs(p.CFrame.RightVector.X)*half.X+math.abs(p.CFrame.UpVector.X)*half.Y+math.abs(p.CFrame.LookVector.X)*half.Z,
   0,
   math.abs(p.CFrame.RightVector.Z)*half.X+math.abs(p.CFrame.UpVector.Z)*half.Y+math.abs(p.CFrame.LookVector.Z)*half.Z)
  for _,plot in workspace.PlayerPlots:GetChildren() do
   local g=plot.Ground;local delta=p.Position-g.Position
   assert(math.abs(delta.X)>extent.X+g.Size.X/2 or math.abs(delta.Z)>extent.Z+g.Size.Z/2,'Tree intrudes on plot bounds')
  end
 end end
 assert(parts==19)
end
for _,p in root.Rocks:GetChildren() do assert(p:IsA('MeshPart') and p.MeshId==workspace.Rock.MeshId) end
local checked=0
for _,s in assert(_G.OwnerEnvironmentProtected) do
 assert(s.part.Parent and s.part.CFrame==s.cf and s.part.Size==s.size,'Unrelated geometry changed: '..s.part.Name);checked+=1
end
assert(count==504)
local camera=_G.OwnerEnvironmentCamera
if camera then workspace.CurrentCamera.CFrame=camera.cf;workspace.CurrentCamera.CameraType=camera.type end
return game:GetService('HttpService'):JSONEncode({trees=18,treePartsEach=19,rockMeshes=30,environmentParts=count,unrelatedPartsUnchanged=checked,treePlotBoundsClear=true})
