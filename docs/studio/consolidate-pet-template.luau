-- Edit-only, one template per invocation. Replace __PET_NAME__ with a queue name.
-- Originals remain installed until a human/agent has visually reviewed the result.
-- Native CSG is serialized geometry; this does not depend on session EditableMesh.
assert(not game:GetService('RunService'):IsRunning(), 'Edit mode required')
local name='__PET_NAME__'
local backups=assert(game.ServerStorage:FindFirstChild('PetModelBackups_20260927'))
local source=assert(backups:FindFirstChild(name))
local staging=game.ServerStorage:FindFirstChild('PetOptimizationCandidates') or Instance.new('Folder')
staging.Name='PetOptimizationCandidates';staging.Parent=game.ServerStorage
if staging:FindFirstChild(name) then print('EXISTS '..name);return end
local ok,err=xpcall(function()
local m=source:Clone();m.Parent=staging;m:SetAttribute('OptimizationState','Building')
local before,beforeMotors=0,0
local groups={}
for _,p in m:GetDescendants() do
 if p:IsA('Motor6D') then beforeMotors+=1 end
 if not p:IsA('BasePart') then continue end
 before+=1
 if p.Transparency>=1 then continue end
 local w=p:FindFirstChildWhichIsA('WeldConstraint')
 if not w or w.Part1~=p then continue end
 local safe=true
 for _,child in p:GetChildren() do if child~=w and not child:IsA('Texture') then safe=false end end
 if not safe then continue end
 local key=w.Part0.Name..'|'..p.Material.Name..'|'..p.Transparency..'|'..p.MaterialVariant..'|'..(p:FindFirstChildOfClass('Texture')and 'Textured'or 'Plain')
 groups[key]=groups[key]or{anchor=w.Part0,parts={}}
 table.insert(groups[key].parts,p)
end
local keys={};for k in groups do table.insert(keys,k)end;table.sort(keys)
for _,key in keys do
 local g=groups[key]
 table.sort(g.parts,function(a,b)if a.Name~=b.Name then return a.Name<b.Name end;return tostring(a.Position)<tostring(b.Position)end)
 -- Bound CSG input size to avoid its triangle ceiling and accidental simplification.
 for start=1,#g.parts,200 do
  local first=g.parts[start];local rest={}
  for i=start+1,math.min(start+199,#g.parts)do table.insert(rest,g.parts[i])end
  if #rest==0 then continue end
  for _,p in g.parts do
   if p.Parent then
    for _,f in {'Top','Bottom','Left','Right','Front','Back'}do p[f..'Surface']=Enum.SurfaceType.Smooth end
   end
  end
  -- A tiny enclosed primer gives each union root-aligned bounds. Without this,
  -- a tilted source wedge can produce a much larger empty bounding box.
  local primer=Instance.new('Part');primer.Size=Vector3.one*.001
  local center=first.Position
  if first:IsA('WedgePart')then center=first.CFrame*Vector3.new(0,-first.Size.Y/6,first.Size.Z/6)end
  primer.CFrame=CFrame.new(center)*source.PrimaryPart.CFrame.Rotation
  primer.Color=first.Color;primer.Material=first.Material;primer.Anchored=true;primer.Parent=m
  for _,f in {'Top','Bottom','Left','Right','Front','Back'}do primer[f..'Surface']=Enum.SurfaceType.Smooth end
  local inputs={first};for _,p in rest do table.insert(inputs,p)end
  local results=game:GetService("GeometryService"):UnionAsync(primer,inputs,{SplitApart=false,CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
  primer:Destroy()
  assert(#results==1,'Expected one rigid section')
  for _,p in results do
   p.Name=g.anchor.Name..'_Geometry_'..start;p.UsePartColor=false
   p.Material=first.Material;p.MaterialVariant=first.MaterialVariant;p.Transparency=first.Transparency
   p.Anchored=first.Anchored;p.Massless=first.Massless;p.CanCollide=first.CanCollide;p.CanTouch=first.CanTouch;p.CanQuery=first.CanQuery
   -- Normalize surface fields. Native CSG still retains internal per-face
   -- legacy material rendering; inspect its stud finish at the intended distance.
   for _,face in {'Top','Bottom','Left','Right','Front','Back'}do p[face..'Surface']=Enum.SurfaceType.Smooth end
   local texture=first:FindFirstChildOfClass('Texture')
   if texture then
    -- Preserve the subtle tiled finish on a consolidated shape's new projection.
    for _,face in Enum.NormalId:GetEnumItems()do local copy=texture:Clone();copy.Face=face;copy.Parent=p end
   end
   p:SetAttribute('SourcePartCount',#rest+1);p.Parent=m
   local w=Instance.new('WeldConstraint');w.Name='DetailWeld';w.Part0=g.anchor;w.Part1=p;w.Parent=p
  end
  first:Destroy();for _,p in rest do p:Destroy()end
 end
 task.wait()
end
local function verify(model)
 local n,t,j,u=0,0,0,0;local root=assert(model.PrimaryPart)
 local connected={[root]=true};local changed=true
while changed do
 changed=false
 for _,joint in model:GetDescendants()do
  if joint:IsA('Motor6D')or joint:IsA('WeldConstraint')then
   local a,b=joint.Part0,joint.Part1
   if a and b and (connected[a]or connected[b])and not(connected[a]and connected[b])then connected[a]=true;connected[b]=true;changed=true end
  end
 end
end
 for _,p in model:GetDescendants()do
  if p:IsA('BasePart')then
   n+=1;assert(connected[p],p.Name..' disconnected')
   local original=source:FindFirstChild(p.Name,true);if original and original:IsA('BasePart')then assert(p.Anchored==original.Anchored and p.CanCollide==original.CanCollide,p.Name..' physics changed')end
   if p:IsA('UnionOperation')then u+=1;t+=p.TriangleCount;assert(p.TriangleCount>0 and p.TriangleCount<20000)end
  elseif p:IsA('Motor6D')then
   j+=1;assert(p.Part0 and p.Part1 and p.Part0:IsDescendantOf(model)and p.Part1:IsDescendantOf(model))
   local a,b=p.Part0.CFrame*p.C0,p.Part1.CFrame*p.C1
   assert((a.Position-b.Position).Magnitude<.005 and (a.UpVector-b.UpVector).Magnitude<.001,p.Name..' motor alignment')
  elseif p:IsA('WeldConstraint')then assert(p.Part0 and p.Part1 and p.Part0:IsDescendantOf(model)and p.Part1:IsDescendantOf(model))end
 end
 assert(n<=100,'100-part budget exceeded');assert(j==beforeMotors,'Rig changed')
 assert(model.Humanoid:FindFirstChildOfClass('Animator'));assert(root.Size==model.Torso.Size)
 return {name=name,before=before,after=n,unionTriangles=t,motors=j,unions=u}
end
local report=verify(m)
local beforeC,beforeS=source:GetBoundingBox();local afterC,afterS=m:GetBoundingBox()
assert((m:GetPivot().Position-source:GetPivot().Position).Magnitude<.001,'Pivot changed')
-- Original wedge boxes include unused corners. Compare actual wedge vertices.
local lo,hi=Vector3.one*math.huge,-Vector3.one*math.huge
for _,p in source:GetDescendants()do if p:IsA('BasePart')then
 local h=p.Size/2;local cf=source.PrimaryPart.CFrame:ToObjectSpace(p.CFrame)
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
  if not p:IsA('WedgePart')or not(y==1 and z==-1)then
   local v=cf*Vector3.new(x*h.X,y*h.Y,z*h.Z);lo=lo:Min(v);hi=hi:Max(v)
  end
 end end end
end end
assert((afterS-(hi-lo)).Magnitude<.12,'Consolidated geometry extents changed')
report.boundsDelta=tostring(afterS-beforeS)
m:SetAttribute('OptimizationState','StructuralChecksPassed')
m:SetAttribute('OriginalPartCount',before);m:SetAttribute('OptimizedPartCount',report.after)
m:SetAttribute('OptimizationMethod','Native CSG per rig anchor; maximum 200 source parts per section')
local data=game:GetService('SerializationService'):SerializeInstancesAsync({m})
local restored=game:GetService('SerializationService'):DeserializeInstancesAsync(data)[1]
restored.Name=name..'_Roundtrip';restored.Parent=staging
local roundtrip=verify(restored)
assert(roundtrip.after==report.after and roundtrip.unionTriangles==report.unionTriangles,'Serialization changed geometry')
local rc,rs=restored:GetBoundingBox();assert((rs-afterS).Magnitude<.001,'Saved bounds changed')
restored:ScaleTo(restored:GetScale()*2)
local _,scaled=restored:GetBoundingBox();assert((scaled-afterS*2).Magnitude<.01,'Growth scale failed')
restored:Destroy()
m:SetAttribute('SerializationVerified',true)
report.serializedBytes=buffer.len(data)
m:SetAttribute("OptimizationReport",game:GetService("HttpService"):JSONEncode(report))
print(game:GetService("HttpService"):JSONEncode(report))





end,debug.traceback)
if not ok then local failed=staging:FindFirstChild(name);if failed then failed:SetAttribute('OptimizationError',tostring(err))end;warn(err)end
