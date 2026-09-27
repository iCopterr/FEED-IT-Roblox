if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("FixedLabelReport",60)
if not report then return end
local part=Instance.new("Part");part.Anchored=true;part.CanCollide=false;part.Transparency=1;part.Position=Vector3.new(0,200,0);part.Parent=workspace
local anchor=Instance.new("Attachment");anchor.Parent=part
local labels={}
local camera=workspace.CurrentCamera
local previousType,previousFrame=camera.CameraType,camera.CFrame
local ok,failure=xpcall(function()
 camera.CameraType=Enum.CameraType.Scriptable
 for _,name in {"PetLabel","ConveyorPetLabel"} do
  local label=game.ReplicatedStorage[name]:Clone();table.insert(labels,label)
  label.Adornee=anchor;label.AlwaysOnTop=true;label.Parent=anchor
  label.NameLabel.Text="Celestial Leviathan"
  local first
  for _,distance in {12,48} do
   camera.CFrame=CFrame.lookAt(part.Position+Vector3.new(0,0,distance),part.Position)
   game:GetService("RunService").RenderStepped:Wait()
   game:GetService("RunService").RenderStepped:Wait()
   task.wait(.25)
   assert((label.AbsoluteSize-Vector2.new(240,84)).Magnitude<.1,name.." remains 240x84 pixels; actual "..tostring(label.AbsoluteSize))
   assert(not label.NameLabel.TextScaled and label.NameLabel.TextSize==24,name.." fixed font size")
   if first then assert((label.AbsoluteSize-first).Magnitude<.1,name.." same near and far") end
   first=label.AbsoluteSize
  end
 end
end,debug.traceback)
for _,label in labels do label:Destroy() end
part:Destroy()
camera.CFrame=previousFrame;camera.CameraType=previousType
report:FireServer({Passed=ok,Failure=if ok then nil else tostring(failure)})
