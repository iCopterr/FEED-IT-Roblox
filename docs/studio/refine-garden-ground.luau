local root=workspace.MapEnvironment
assert(root:GetAttribute('GardenReferencePass'))
assert(not root:GetAttribute('GardenGroundRefined'))
-- Lift only the new visual overlay clear of the old ground's decal depth bias.
for _,p in root.Terrain:GetChildren() do
 if p.Name=='CentralMeadow' then p.Position=Vector3.new(p.Position.X,.34,p.Position.Z);p.Color=Color3.fromRGB(133,174,76) end
 if p.Name=='OuterMeadow' or p.Name=='EndMeadow' then p.Position=Vector3.new(p.Position.X,.30,p.Position.Z) end
end
for _,p in root.Paths:GetChildren() do p.Position=Vector3.new(p.Position.X,.46,p.Position.Z) end
-- Make flower clusters legible at player distance without filling the pen.
for _,p in root.Flowers:GetChildren() do
 if p.Name=='Blossom' then p.Size*=1.45 end
end
local rng=Random.new(813)
for _,side in {-1,1} do
 for _,z in {-117,-85,-22,16,79,115} do
  local cluster=Instance.new('Model');cluster.Name='BorderGarden';cluster.Parent=root.Bushes
  for i=1,3 do
   local p=Instance.new('Part');p.Name='Shrub';p.Shape=Enum.PartType.Ball;p.Size=Vector3.new(4,2.5,3.8)
   p.Position=Vector3.new(side*(140+(i%2)*2),.5,z+i*2.7)
   p.Color=Color3.fromRGB(68+i*14,129+i*11,58);p.Material=Enum.Material.SmoothPlastic
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=cluster
  end
  for i=1,2 do
   local p=Instance.new('Part');p.Name='Flower';p.Shape=Enum.PartType.Ball;p.Size=Vector3.new(1.1,1.1,1.1)
   p.Position=Vector3.new(side*138,1,z+i*3);p.Color=i==1 and Color3.fromRGB(253,233,172) or Color3.fromRGB(239,167,203)
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=cluster
  end
 end
end
root:SetAttribute('GardenGroundRefined',true)
_G.GardenSelection=game:GetService('Selection'):Get()
game:GetService('Selection'):Set({})
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(245,285,245),Vector3.new(0,0,4))
return 'Ground and edge garden refinement complete'
