local trees=workspace.MapEnvironment.Trees
for _,p in trees:GetChildren() do
 if p.Name=='PineCrown' then
  local center=p.Position
  local w=p.Size.X
  p.Size=Vector3.new(w,p.Size.Y,w/2)
  p.CFrame=CFrame.new(center+Vector3.new(0,0,-w/4))
  local other=p:Clone();other.CFrame=CFrame.new(center+Vector3.new(0,0,w/4))*CFrame.Angles(0,math.pi,0);other.Parent=trees
 end
end
return 'Paired evergreen crowns into continuous symmetric tiers'
