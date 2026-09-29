-- Invoked with the current filesystem EggLabelAnchor module as local Anchor.
assert(not game:GetService('RunService'):IsRunning())
assert(not workspace:FindFirstChild('_EggCenterLabelReview'))
local camera=workspace.CurrentCamera
_G.EggCenterCamera={cf=camera.CFrame,type=camera.CameraType}
local folder=Instance.new('Folder');folder.Name='_EggCenterLabelReview';folder.Parent=workspace
local count=0
for _,template in workspace.EggTemplates:GetChildren() do if template:IsA('Model') then
 local model=template:Clone();model:ScaleTo(1)
 local bounds,size=model:GetBoundingBox()
 model:PivotTo(CFrame.new(0,1.2+size.Y/2,0)*bounds:ToObjectSpace(model:GetPivot()))
 local label=game.ReplicatedStorage.ConveyorPetLabel:Clone()
 label.NameLabel.Text=template.Name=='advanced_egg' and 'Advanced Egg' or template.Name
 label.Rarity.Visible=false;label.Price.Text='$2M';label.Price.Position=UDim2.fromOffset(0,28);label.Size=UDim2.fromOffset(240,56)
 local anchor=Anchor.Bind(model,label)
 local shell=model:FindFirstChild('Shell',true)
 for _,angle in {0,45,90,180} do
  model:PivotTo(CFrame.new(0,model:GetPivot().Y,0)*CFrame.Angles(0,math.rad(angle),0))
  local d=anchor.WorldPosition-shell.Position
  assert(math.abs(d.X)<.001 and math.abs(d.Z)<.001,'Horizontal label mismatch')
  local cf,s=model:GetBoundingBox();assert(anchor.WorldPosition.Y>=cf.Position.Y+s.Y/2+2.49)
  assert(label.StudsOffsetWorldSpace==Vector3.zero)
  count+=1
 end
 if template.Name=='advanced_egg' then model.Parent=folder else model:Destroy() end
end end
camera.CameraType=Enum.CameraType.Scriptable
camera.CFrame=CFrame.lookAt(Vector3.new(1,6.8,19),Vector3.new(0,4.8,0))
return 'PASS '..count..' center/height checks across six egg templates and four headings; Advanced preview ready'
