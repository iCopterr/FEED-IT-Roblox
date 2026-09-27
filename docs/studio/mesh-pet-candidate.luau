-- EDITOR ONLY: convert a cloned thin-wedge pet sculpture into rigid mesh sections.
-- Retains visible boxes, rig anchors and Motor6Ds. No production mesh generation.
-- EXPERIMENTAL: EditableMesh content is session-only. Do not install this model
-- until its meshes are uploaded with owner approval and save/reload is verified.
-- Primitive Studs surfaces are not retained; inspect appearance before approval.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local model=assert(game:GetService("Selection"):Get()[1],"Select a candidate")
assert(model:IsA("Model") and model:IsDescendantOf(workspace),"Select a disposable Workspace model clone")
assert(model:GetAttribute("OptimizationCandidate") and not model:GetAttribute("OptimizationComplete"),"Fresh candidate required")
assert(not model:FindFirstChildWhichIsA("MeshPart",true),"Already contains meshes; inspect separately")
local groups={}
for _,p in model:GetDescendants()do
 if not p:IsA("WedgePart")then continue end
 assert(p.Size.X<=.04 and p.Transparency==0,"Only thin opaque triangle wedges are supported")
 local w=assert(p:FindFirstChildWhichIsA("WeldConstraint"))
 assert(w.Part1==p and w.Part0 and w.Part0:IsDescendantOf(model),"Unexpected rig")
 local key=w.Part0.Name.."|"..p.Material.Name
 groups[key]=groups[key]or {Anchor=w.Part0,Material=p.Material,Parts={}}
 assert(groups[key].Anchor==w.Part0,"Rig anchor names must be unique")
 table.insert(groups[key].Parts,p)
end
local keys={};for key in groups do table.insert(keys,key)end;table.sort(keys)
local assets=game:GetService("AssetService")
for _,key in keys do
 local group=groups[key]
 local mesh=assert(assets:CreateEditableMesh())
 local vertexCache,colorCache={},{}
 local lower,upper=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 local function vertex(position)
  lower=lower:Min(position);upper=upper:Max(position)
  local id=string.format("%.5f,%.5f,%.5f",position.X,position.Y,position.Z)
  if not vertexCache[id]then vertexCache[id]=mesh:AddVertex(position)end
  return vertexCache[id]
 end
 for _,p in group.Parts do
  local half=p.Size/2
  -- Each source wedge is a thin triangular prism. Preserve its middle surface,
  -- not six invisible extrusion faces; double-sided rendering handles the back.
  local cf=group.Anchor.CFrame:ToObjectSpace(p.CFrame)
  local a,b,c=cf*Vector3.new(0,-half.Y,-half.Z),cf*Vector3.new(0,-half.Y,half.Z),cf*Vector3.new(0,half.Y,half.Z)
  local face=mesh:AddTriangle(vertex(a),vertex(b),vertex(c))
  local colorKey=tostring(p.Color)
  if not colorCache[colorKey]then colorCache[colorKey]=mesh:AddColor(p.Color,1)end
  local color=colorCache[colorKey];mesh:SetFaceColors(face,{color,color,color})
  local normal=mesh:AddNormal((b-a):Cross(c-a).Unit)
  mesh:SetFaceNormals(face,{normal,normal,normal})
 end
 local center=(lower+upper)/2
 for _,id in mesh:GetVertices()do mesh:SetPosition(id,mesh:GetPosition(id)-center)end
 local baked=assets:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
 baked.Name=group.Anchor.Name.."_Mesh"
 baked.CFrame=group.Anchor.CFrame*CFrame.new(center)
 baked.Anchored=true;baked.CanCollide=false;baked.CanTouch=false;baked.CanQuery=false;baked.Massless=true
 baked.Color=Color3.new(1,1,1);baked.Material=group.Material;baked.DoubleSided=true
 local weld=Instance.new("WeldConstraint");weld.Name="DetailWeld";weld.Part0=group.Anchor;weld.Part1=baked;weld.Parent=baked
 baked.Parent=model
 for _,p in group.Parts do p:Destroy()end
 model:SetAttribute("MeshSections",(model:GetAttribute("MeshSections")or 0)+1)
 task.wait()
end
model:SetAttribute("OptimizationComplete",true)
model:SetAttribute("OptimizationMethod","Thin-wedge surface meshes, per rigid limb")
model:SetAttribute("RequiresMeshUpload",true)
