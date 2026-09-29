local result={}
for _,template in workspace.EggTemplates:GetChildren() do
 if template:IsA('Model') then
  local model=template:Clone();model:ScaleTo(1)
  local bounds,size=model:GetBoundingBox()
  local parts={}
  for _,p in model:GetDescendants() do if p:IsA('BasePart') then
   table.insert(parts,{name=p.Name,position=tostring(p.Position),size=tostring(p.Size),orientation=tostring(p.Orientation),transparency=p.Transparency})
  end end
  local from=CFrame.lookAt(workspace.PetConveyor.Start.Position,workspace.PetConveyor.Finish.Position)*CFrame.new(0,size.Y/2,0)*bounds:ToObjectSpace(model:GetPivot())
  model:PivotTo(from)
  local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
  for _,p in model:GetDescendants() do if p:IsA('BasePart') then
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local v=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2);lo=lo:Min(v);hi=hi:Max(v)
   end end end
  end end
  table.insert(result,{name=template.Name,scale=template:GetScale(),primary=template.PrimaryPart and template.PrimaryPart.Name,boundsSize=tostring(size),boundsUp=tostring(bounds.UpVector),pivotUp=tostring(template:GetPivot().UpVector),liveMin=tostring(lo),liveMax=tostring(hi),parts=parts})
  model:Destroy()
 end
end
return game:GetService('HttpService'):JSONEncode(result)
