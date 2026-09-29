local root=workspace.MapEnvironment
local checked=0
for _,s in assert(_G.GardenProtected) do
 local p=s.part
 assert(p.Parent and p.CFrame==s.cf and p.Size==s.size and p.Color==s.color and p.Material==s.material and p.Transparency==s.transparency,'Protected object changed: '..p.Name)
 checked+=1
end
local count,scripts=0,0
for _,p in root:GetDescendants() do
 if p:IsA('LuaSourceContainer') then scripts+=1 end
 if p:IsA('BasePart') then
  count+=1;assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery)
  assert(p.Material~=Enum.Material.Water)
 end
end
assert(scripts==0 and count<=1000)
for _,m in root.Trees:GetChildren() do
 for _,p in m:GetDescendants() do if p:IsA('BasePart') then
  local h=p.Size/2
  local ex=math.abs(p.CFrame.RightVector.X)*h.X+math.abs(p.CFrame.UpVector.X)*h.Y+math.abs(p.CFrame.LookVector.X)*h.Z
  local ez=math.abs(p.CFrame.RightVector.Z)*h.X+math.abs(p.CFrame.UpVector.Z)*h.Y+math.abs(p.CFrame.LookVector.Z)*h.Z
  for _,plot in workspace.PlayerPlots:GetChildren() do
   local g=plot.Ground;local d=p.Position-g.Position
   assert(math.abs(d.X)>ex+g.Size.X/2 or math.abs(d.Z)>ez+g.Size.Z/2,'Tree overlaps plot')
  end
 end end
end
return game:GetService('HttpService'):JSONEncode({parts=count,trees=#root.Trees:GetChildren(),protectedUnchanged=checked,scripts=scripts,water=false,treeBoundsClear=true})
