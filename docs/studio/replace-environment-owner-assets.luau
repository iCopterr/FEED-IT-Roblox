-- Edit-mode migration from first-pass primitives to the owner's supplied assets.
assert(not game:GetService('RunService'):IsRunning())
local root=assert(workspace:FindFirstChild('MapEnvironment'))
assert(not root:GetAttribute('OwnerTreeRockReplacement'), 'Already replaced')
local tree=assert(workspace:FindFirstChild('Tree'))
local rock=assert(workspace:FindFirstChild('Rock'))
assert(tree:IsA('Model') and rock:IsA('MeshPart'))
local targets={}
local trunks={}
for _,p in root.Trees:GetChildren() do
 assert(p:IsA('BasePart'),'Inspect changed Trees hierarchy first')
 targets[p]=true
 if p.Name=='Trunk' then table.insert(trunks,p) end
end
local rocks={}
for _,p in root.Rocks:GetChildren() do assert(p:IsA('BasePart'));targets[p]=true;table.insert(rocks,p) end
for _,p in root.Terrain:GetChildren() do if p.Name=='CliffFacet' then targets[p]=true;table.insert(rocks,p) end end
assert(#trunks==18 and #rocks==30,'Unexpected replacement targets')
local protected={}
for _,p in workspace:GetDescendants() do
 if p:IsA('BasePart') and not targets[p] then table.insert(protected,{part=p,cf=p.CFrame,size=p.Size}) end
end
_G.OwnerEnvironmentProtected=protected
local backup=Instance.new('Folder');backup.Name='EnvironmentPrimitivesBackup_20260929';backup.Parent=game.ServerStorage
local staging=Instance.new('Folder');staging.Name='ReplacementStaging';staging.Parent=backup
local function sanitize(obj)
 local all=obj:GetDescendants();table.insert(all,obj)
 for _,p in all do
  if p:IsA('BasePart') then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  elseif p:IsA('LuaSourceContainer') or p:IsA('Camera') or p:IsA('PostEffect') or p:IsA('ProximityPrompt') then p:Destroy() end
 end
end
local function bounds(model)
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);lo=lo:Min(v);hi=hi:Max(v)
  end end end
 end end
 return lo,hi
end
local newTrees={};local newRocks={}
table.sort(trunks,function(a,b) if a.Position.X==b.Position.X then return a.Position.Z<b.Position.Z end return a.Position.X<b.Position.X end)
for i,trunk in trunks do
 local clone=tree:Clone();clone.Name=string.format('Tree%02d',i);sanitize(clone);clone.Parent=staging
 local lo,hi=bounds(clone)
 local height=trunk.Size.Y*1.9
 clone:ScaleTo(clone:GetScale()*height/(hi.Y-lo.Y))
 clone:PivotTo(CFrame.Angles(0,math.rad((i*73)%360),0))
 lo,hi=bounds(clone)
 local center=(lo+hi)/2
 local x,z=trunk.Position.X,trunk.Position.Z
 -- Edge mounds rise to 1.5 studs; dirt patches sit just above the meadow.
 local floor=math.abs(x)>150 and 1.1 or -.35
 clone:PivotTo(clone:GetPivot()+Vector3.new(x-center.X,floor-lo.Y,z-center.Z))
 clone:SetAttribute('SourceTemplate','Workspace.Tree');table.insert(newTrees,clone)
end
for i,old in rocks do
 local clone=rock:Clone();sanitize(clone);clone.Name=old.Name=='CliffFacet' and 'CliffRock' or 'Rock'
 clone:SetAttribute('SourceTemplate','Workspace.Rock')
 if old.Name=='CliffFacet' then
  clone.Size=old.Size;clone.CFrame=old.CFrame
 else
  clone.Size=rock.Size*(old.Size.X/rock.Size.X)
  local base=old.Position.Y-old.Size.Y/2
  clone.CFrame=CFrame.new(old.Position.X,base+clone.Size.Y/2,old.Position.Z)*CFrame.Angles(0,math.rad(i*59),0)
 end
 clone.Parent=staging;table.insert(newRocks,clone)
end
-- Originals remain recoverable in ServerStorage and the previous Git commit.
for p in targets do p.Parent=backup end
for _,p in newTrees do p.Parent=root.Trees end
for _,p in newRocks do p.Parent=root.Rocks end
staging:Destroy()
root:SetAttribute('OwnerTreeRockReplacement',true)
local count=0
for _,p in root:GetDescendants() do if p:IsA('BasePart') then count+=1 end end
assert(count<=520,'Unexpected decoration budget increase')
for _,s in protected do assert(s.part.Parent and s.part.CFrame==s.cf and s.part.Size==s.size,'Unrelated geometry changed') end
return game:GetService('HttpService'):JSONEncode({trees=#newTrees,rocks=#newRocks,environmentParts=count,protectedParts=#protected,backup=backup:GetFullName()})
