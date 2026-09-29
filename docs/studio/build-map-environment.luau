-- Edit-mode authoring only. Never install this as a runtime Script.
assert(not game:GetService('RunService'):IsRunning(), 'Stop Play before authoring')
assert(not workspace:FindFirstChild('MapEnvironment'), 'Inspect existing environment before replacing')
local protected={}
for _,root in workspace:GetChildren() do
 for _,p in root:GetDescendants() do
  if p:IsA('BasePart') then table.insert(protected,{part=p,cf=p.CFrame,size=p.Size}) end
 end
 if root:IsA('BasePart') then table.insert(protected,{part=root,cf=root.CFrame,size=root.Size}) end
end
_G.EnvironmentProtectedParts=protected
local root=Instance.new('Folder');root.Name='MapEnvironment';root:SetAttribute('AuthoringVersion','20260929');root.Parent=workspace
local folders={}
for _,name in {'Terrain','Trees','Rocks','Bushes','Flowers','Paths','Decorations','Lighting'} do
 local f=Instance.new('Folder');f.Name=name;f.Parent=root;folders[name]=f
end
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local grass=rgb(115,169,63)
local leaf=rgb(76,142,70)
local wood=rgb(108,73,49)
local stone=rgb(111,127,136)
local function part(folder,name,size,pos,color,shape,rotation)
 local p=Instance.new(shape=='Wedge' and 'WedgePart' or 'Part')
 p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity)
 if shape=='Ball' then p.Shape=Enum.PartType.Ball elseif shape=='Cylinder' then p.Shape=Enum.PartType.Cylinder end
 p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=folders[folder]
 return p
end
local function rock(x,z,s)
 part('Rocks','BorderStone',Vector3.new(8,6,7)*s,Vector3.new(x,1.5*s-0.5,z),stone,'Wedge',CFrame.Angles(0,math.rad(x+z),0))
end
local function tree(x,z,s,pine)
 part('Trees','Trunk',Vector3.new(2.5,10,2.5)*s,Vector3.new(x,4.5*s,z),wood)
 if pine then
  for i=1,3 do
   local w=(13-i*2)*s
   for _,side in {-1,1} do
    part('Trees','PineCrown',Vector3.new(w,6*s,w/2),Vector3.new(x,(7+i*3)*s,z+side*w/4),i==3 and rgb(105,168,80) or leaf,'Wedge',CFrame.Angles(0,side==1 and math.pi or 0,0))
   end
  end
 else
  part('Trees','Canopy',Vector3.new(14,12,14)*s,Vector3.new(x,13*s,z),leaf,'Ball')
  part('Trees','CanopyHighlight',Vector3.new(10,9,10)*s,Vector3.new(x+3*s,16*s,z-2*s),rgb(135,187,81),'Ball')
 end
end
local function bush(x,z,s)
 part('Bushes','LowShrub',Vector3.new(5,3,4)*s,Vector3.new(x,s,z),rgb(87,151,67),'Ball')
end
local function flower(x,z,color)
 part('Flowers','Stem',Vector3.new(.25,1.5,.25),Vector3.new(x,.4,z),leaf)
 part('Flowers','Blossom',Vector3.new(1.5,.65,1.5),Vector3.new(x,1.3,z),color,'Ball')
end
local function lamp(x,z)
 part('Lighting','LanternPost',Vector3.new(.65,4,.65),Vector3.new(x,1.5,z),wood)
 part('Lighting','LanternBase',Vector3.new(1.8,.3,1.8),Vector3.new(x,3.65,z),rgb(61,69,80))
 local glow=part('Lighting','LanternGlass',Vector3.new(1.1,1.5,1.1),Vector3.new(x,4.5,z),rgb(255,221,144));glow.Material=Enum.Material.Neon
 part('Lighting','LanternCap',Vector3.new(2,.5,2),Vector3.new(x,5.5,z),rgb(61,69,80))
 local light=Instance.new('PointLight');light.Color=glow.Color;light.Range=12;light.Brightness=.6;light.Shadows=false;light.Parent=glow
end
-- Only the outer band gets elevation; reserve x +/-140 for future plot expansion.
for _,side in {-1,1} do
 for i,z in {-170,-80,20,115,187} do
  local x=side*(166+(i%2)*5)
  part('Terrain','EdgeMound',Vector3.new(25,9,34),Vector3.new(x,-3,z),grass,'Ball')
  part('Terrain','CliffFacet',Vector3.new(22,25,31),Vector3.new(side*179,-13,z),rgb(102,111,116),'Wedge',CFrame.Angles(0,side*math.pi/2,0))
  rock(x-side*9,z+12,.8)
  tree(x,z,i%2==0 and 1 or .85,i%2==0)
 end
end
for _,z in {-190,197} do
 for _,x in {-110,-55,65,120} do
  part('Terrain','OuterDirtPatch',Vector3.new(.14,21,16),Vector3.new(x,-.38,z),rgb(149,115,73),'Cylinder',CFrame.Angles(0,0,math.pi/2))
  tree(x,z,.8,x<0);rock(x+10,z-4,.7);bush(x-7,z+3,1)
 end
end
-- Small gardens in the inter-plot gaps, not inside the plots themselves.
for _,x in {-88,88} do for _,z in {-48,48} do
 bush(x,z,1.2);bush(x+6,z, .8)
 flower(x-5,z-1,rgb(242,185,214));flower(x-3,z+2,rgb(255,219,122))
 part('Decorations','MushroomStem',Vector3.new(.7,1.5,.7),Vector3.new(x+3,.3,z+2),rgb(241,222,184))
 part('Decorations','MushroomCap',Vector3.new(2.2,1,2.2),Vector3.new(x+3,1.2,z+2),rgb(180,102,172),'Ball')
end end
-- Flush stepping stones stop before plot boundaries and keep wide walking lanes.
for _,side in {-1,1} do for _,z in {-96,0,96} do
 for _,x in {24,32,40} do part('Paths','PlotApproach',Vector3.new(6,.12,7),Vector3.new(side*x,.12,z),rgb(190,188,162),nil,CFrame.Angles(0,math.rad(x%3*4),0)) end
 lamp(side*44,z+7)
end end
-- Perimeter scenery beyond shop; nothing in front of the counter or console.
for _,x in {-18,35} do
 lamp(x,163);bush(x,170,1.1)
 flower(x-3,170,rgb(194,149,237));flower(x+3,171,rgb(248,207,124))
end
for i=1,3 do
 local x=-19-(i%2)*4;local z=153+i*4
 part('Decorations','MerchantCrate',Vector3.new(3,3,3),Vector3.new(x,1,z),rgb(142,97,61))
 part('Decorations','CrateStrap',Vector3.new(3.08,.4,3.08),Vector3.new(x,1.2,z),rgb(84,63,49))
end
for _,x in {15,29} do
 rock(x,167,.5)
 local crystal=part('Decorations','ReviveCrystal',Vector3.new(1.6,4,1.6),Vector3.new(x,1.4,167),rgb(140,136,233),'Wedge',CFrame.Angles(0,math.rad(45),.18))
 crystal.Material=Enum.Material.Neon
end
for _,x in {-7,0,7,15,22,29} do
 part('Paths','ShopApproach',Vector3.new(6,.1,5),Vector3.new(x,.12,140),rgb(190,188,162))
end
local count=0
for _,p in root:GetDescendants() do if p:IsA('BasePart') then count+=1 end end
assert(count<=260,'Environment part budget exceeded')
for _,s in protected do assert(s.part.Parent and s.part.CFrame==s.cf and s.part.Size==s.size,'Existing geometry changed') end
return {addedParts=count,protectedParts=#protected}
