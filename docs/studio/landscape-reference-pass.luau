-- Edit-mode only. All changes stay inside MapEnvironment; no water or gameplay edits.
assert(not game:GetService('RunService'):IsRunning())
local root=assert(workspace:FindFirstChild('MapEnvironment'))
assert(not root:GetAttribute('GardenReferencePass'),'Already landscaped; inspect before rerunning')
local protected={}
for _,p in workspace:GetDescendants() do
 if p:IsA('BasePart') and not p:IsDescendantOf(root) then
  table.insert(protected,{part=p,cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,transparency=p.Transparency})
 end
end
_G.GardenProtected=protected
local camera=workspace.CurrentCamera
_G.GardenCamera={cf=camera.CFrame,type=camera.CameraType}
local backup=root:Clone();backup.Name='MapEnvironmentBeforeGarden_20260929';backup.Parent=game.ServerStorage
for _,name in {'Terrain','Trees','Rocks','Bushes','Flowers','Paths'} do root[name]:ClearAllChildren() end
local rng=Random.new(290929)
local rgb=Color3.fromRGB
local function part(folder,name,size,pos,color,shape)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos);p.Color=color
 p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=root[folder]
 return p
end
local function clean(clone)
 local all=clone:GetDescendants();table.insert(all,clone)
 for _,p in all do
  if p:IsA('BasePart') then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  elseif p:IsA('LuaSourceContainer') or p:IsA('Camera') or p:IsA('PostEffect') or p:IsA('ProximityPrompt') then p:Destroy() end
 end
end
local function bounds(m)
 local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
 for _,p in m:GetDescendants() do if p:IsA('BasePart') then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);lo=lo:Min(v);hi=hi:Max(v)
  end end end
 end end
 return lo,hi
end
local treeCount=0
local function tree(x,z,height)
 local m=workspace.Tree:Clone();clean(m);treeCount+=1;m.Name=string.format('GardenTree%02d',treeCount)
 local lo,hi=bounds(m);m:ScaleTo(m:GetScale()*height/(hi.Y-lo.Y))
 m:PivotTo(CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0));lo,hi=bounds(m)
 local center=(lo+hi)/2
 m:PivotTo(m:GetPivot()+Vector3.new(x-center.X,-.25-lo.Y,z-center.Z))
 local green=rgb(rng:NextInteger(72,105),rng:NextInteger(133,162),rng:NextInteger(46,69))
 for _,p in m:GetDescendants() do if p:IsA('BasePart') and p.Color.G>p.Color.R*1.15 and p.Color.G>p.Color.B*1.1 then p.Color=green end end
 m:SetAttribute('SourceTemplate','Workspace.Tree');m.Parent=root.Trees
end
local rockCount=0
local function rock(name,x,y,z,size,color)
 local p=workspace.Rock:Clone();clean(p);rockCount+=1;p.Name=name;p.Size=size
 p.CFrame=CFrame.new(x,y,z)*CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0)
 p.Color=color or rgb(132,143,131);p:SetAttribute('SourceTemplate','Workspace.Rock');p.Parent=root.Rocks
 return p
end
-- Cover only non-plot ground with a softer grass palette. Original island stays intact.
for _,side in {-1,1} do
 local p=part('Terrain','OuterMeadow',Vector3.new(52,.12,420),Vector3.new(side*158,-.35,4),rgb(111,162,67));p.Material=Enum.Material.Grass
 local lane=part('Terrain','CentralMeadow',Vector3.new(38,.08,282),Vector3.new(side*28,.145,0),rgb(137,176,84));lane.Material=Enum.Material.Grass
end
for _,row in {{-172,68},{176,76}} do
 local p=part('Terrain','EndMeadow',Vector3.new(264,.12,row[2]),Vector3.new(0,-.35,row[1]),rgb(115,166,70));p.Material=Enum.Material.Grass
end
-- Irregular scalloped grassy shoulders and a continuous boulder perimeter.
for _,side in {-1,1} do
 for i=0,12 do
  local z=-193+i*32
  local h=rng:NextNumber(16,26)
  rock('BorderBoulder',side*rng:NextNumber(178,183),h*.24-1,z,Vector3.new(rng:NextNumber(25,33),h,rng:NextNumber(32,40)))
  if i%2==0 then
   local mound=part('Terrain','GrassyShoulder',Vector3.new(35,6,49),Vector3.new(side*169,-2,z),rgb(106,156,63),Enum.PartType.Ball);mound.Material=Enum.Material.Grass
  end
 end
 for i=0,8 do
  local x=-148+i*37
  local h=rng:NextNumber(14,23)
  rock('EndBoulder',x,h*.22-1,side<0 and -201 or 209,Vector3.new(40,h,28))
 end
end
-- Staggered groups instead of one evenly spaced tree row. Keep future plot room free.
for _,side in {-1,1} do
 for i,z in {-170,-132,-65,-13,48,111,166} do tree(side*(i%2==0 and 153 or 162),z+(side*4),i%3==0 and 16 or 23) end
end
for _,z in {-179,184} do for i,x in {-123,-75,57,113} do tree(x,z+(i%2)*5,i%2==0 and 16 or 22) end end
local function shrub(x,z,s)
 part('Bushes','LeafCluster',Vector3.new(4.7,3,4)*s,Vector3.new(x,.8*s,z),rgb(64,128,67),Enum.PartType.Ball)
 part('Bushes','LeafHighlight',Vector3.new(3,2.4,3)*s,Vector3.new(x+1.1*s,1.3*s,z-.7*s),rgb(112,165,66),Enum.PartType.Ball)
end
local colors={rgb(255,228,139),rgb(244,164,195),rgb(245,238,215),rgb(186,168,227)}
local function flowers(x,z,index)
 part('Flowers','FlowerLeaves',Vector3.new(3.5,.55,2.8),Vector3.new(x,-.04,z),rgb(77,132,61),Enum.PartType.Ball)
 for i=1,3 do
  local a=i*2.1
  local p=part('Flowers','Blossom',Vector3.new(.85,.65,.85),Vector3.new(x+math.cos(a),.35+i*.18,z+math.sin(a)),colors[(index+i)%#colors+1],Enum.PartType.Ball)
  p.CastShadow=false
 end
end
-- Garden pockets outside the plot boundaries; retain open front entrances.
for _,side in {-1,1} do
 for i,z in {-153,-104,-50,47,102,155} do
  local x=side*(i%2==0 and 145 or 153)
  shrub(x,z,1.1);flowers(x-side*5,z+3,i)
  rock('GardenStone',x+side*5,.5,z-5,Vector3.new(4.5,3.5,5.5),rgb(149,157,139))
 end
 for _,z in {-48,48} do
  shrub(side*89,z,1);flowers(side*82,z,2);flowers(side*103,z+1,3)
 end
 for _,z in {-96,0,96} do
  shrub(side*44,z-13,.8);flowers(side*43,z+13,1)
 end
end
for i,x in {-130,-87,-35,49,95,132} do
 for _,z in {-167,177} do flowers(x,z,i);shrub(x+6,z+2,.9) end
end
-- Low irregular stepping slabs are visual only and cannot snag movement.
for _,side in {-1,1} do for _,z in {-96,0,96} do
 for i=1,5 do
  local p=rock('ApproachStone',side*(13+i*6.5),.16,z+(i%2)*.7,Vector3.new(5.8,.18,7.5),rgb(190,187,156));p.Parent=root.Paths
 end
end end
for _,x in {-6,1,8,15,22,29} do
 local p=rock('ShopStone',x,.15,140,Vector3.new(6.6,.15,5.5),rgb(190,187,156));p.Parent=root.Paths
end
-- Add simple border fence fragments, kept behind the last row and out of traffic.
for _,z in {-158,166} do for _,x in {-118,104} do
 for _,dx in {-6,6} do part('Decorations','GardenFencePost',Vector3.new(.9,3.7,.9),Vector3.new(x+dx,1.2,z),rgb(141,98,57)) end
 for _,y in {.5,2} do part('Decorations','GardenFenceRail',Vector3.new(12,.6,.55),Vector3.new(x,y,z),rgb(164,119,69)) end
end end
root:SetAttribute('GardenReferencePass',true)
local count=0;for _,p in root:GetDescendants() do if p:IsA('BasePart') then count+=1 end end
assert(count<=1000,'Exceeded reference landscaping part budget')
for _,s in protected do assert(s.part.Parent and s.part.CFrame==s.cf and s.part.Size==s.size,'Outside environment changed') end
camera.CameraType=Enum.CameraType.Scriptable
camera.CFrame=CFrame.lookAt(Vector3.new(350,420,310),Vector3.new(0,0,4))
return game:GetService('HttpService'):JSONEncode({parts=count,trees=treeCount,rocksIncludingPaths=rockCount,protectedParts=#protected})
