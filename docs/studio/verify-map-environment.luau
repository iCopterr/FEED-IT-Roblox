local root=workspace:FindFirstChild('MapEnvironment');assert(root)
local checked=0
for _,s in assert(_G.EnvironmentProtectedParts) do
 assert(s.part.Parent and s.part.CFrame==s.cf and s.part.Size==s.size,'Protected geometry changed: '..s.part.Name)
 checked+=1
end
local count=0
for _,p in root:GetDescendants() do
 assert(not p:IsA('LuaSourceContainer'),'No scripts allowed')
 if p:IsA('BasePart') then
  count+=1;assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery)
  for _,plot in workspace.PlayerPlots:GetChildren() do
   local g=plot:FindFirstChild('Ground');assert(g)
   local v=g.CFrame:PointToObjectSpace(p.Position)
   assert(math.abs(v.X)>g.Size.X/2 or math.abs(v.Z)>g.Size.Z/2,'Decoration inside plot: '..p.Name)
  end
 end
end
return game:GetService('HttpService'):JSONEncode({addedParts=count,unchangedExistingParts=checked,scripts=0,collidableDecor=0})
