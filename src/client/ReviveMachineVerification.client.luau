if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("ReviveMachineVerificationReport",60)
if not report then return end
report.OnClientEvent:Connect(function(attempt)
 local ok,failure=xpcall(function()
  local controller=require(script.Parent.Controllers.ReviveController)
  local gui=game.Players.LocalPlayer.PlayerGui:WaitForChild("ReviveUI")
  local panel=gui.Panel
  assert(not panel.Visible,"Broken pets do not auto-open the machine UI")
  assert(controller.Open(),"Machine opens nearby")
  local deadline=os.clock()+15
  repeat task.wait(.1) until panel.Pets:FindFirstChild(attempt) or os.clock()>deadline
  assert(panel.Pets:FindFirstChild(attempt),"Broken pet is listed")
  controller.Select(attempt);task.wait(.2)
  assert(panel.PetPreview.World:FindFirstChildOfClass("Model"),"Selected pet preview exists")
  assert(panel.PetName.Text~="SELECT A BROKEN PET" and panel.Details.Text:find("remaining"),"Selected identity and timer shown")
  assert(panel.Revive.Active and not panel.Robux.Active,"Charm available; Robux disabled until configured")
  assert(panel.Robux.Position.X.Offset>panel.Revive.Position.X.Offset,"Robux button beside charm")
  panel.Visible=false;task.wait(.1)
  assert(#panel.PetPreview.World:GetChildren()==0,"Closing frees preview geometry")
 end,debug.traceback)
 report:FireServer({Passed=ok,Failure=if ok then nil else tostring(failure)})
end)
