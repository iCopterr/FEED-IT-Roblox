-- Editor-only verification of the separately built reference drake.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local m=assert(workspace:FindFirstChild("EmberDrake_Reference"),"Build missing")
local root=assert(m.PrimaryPart)
local connected={[root]=true}
for _,p in root:GetConnectedParts(true) do
 assert(p:IsDescendantOf(m),"External connection")
 connected[p]=true
end
local parts,motors,welds,unions,triangles=0,0,0,0,0
for _,p in m:GetDescendants() do
 if p:IsA("BasePart") then
  parts+=1
  assert(connected[p] and not p.Anchored,p.Name.." disconnected or anchored")
  assert(p.CanCollide==(p==m.Torso),p.Name.." collision")
  assert(p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0,p.Name.." invalid size")
  if p:IsA("UnionOperation") then unions+=1; triangles+=p.TriangleCount end
 elseif p:IsA("Motor6D") then
  motors+=1
  assert(p.Part0 and p.Part1 and p.Part0:IsDescendantOf(m) and p.Part1:IsDescendantOf(m))
  local a,b=p.Part0.CFrame*p.C0,p.Part1.CFrame*p.C1
  assert((a.Position-b.Position).Magnitude<.001,p.Name.." offset")
  assert((a.UpVector-b.UpVector).Magnitude<.0001,p.Name.." rotation")
 elseif p:IsA("WeldConstraint") then
  welds+=1
  assert(p.Part0 and p.Part1 and p.Part0:IsDescendantOf(m) and p.Part1:IsDescendantOf(m))
 end
end
assert(parts<=100,"Exceeded agreed part budget")
assert(root.Size==m.Torso.Size)
assert(m.Humanoid:FindFirstChildOfClass("Animator"))
assert(motors==9,"Expected root, head, four legs, two wings and tail")
assert(unions==9,"Expected nine baked geometry sections")
assert(triangles<=10000,"Union geometry budget exceeded")
print("PASS",parts,"parts",unions,"unions",motors,"motors",welds,"welds",triangles,"union triangles")
