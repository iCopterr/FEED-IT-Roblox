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
  assert(panel.PetName.Text~="SELECT A BROKEN PET" and panel.Details.Text:find("AFTER REPAIR"),"Selected identity and repaired income shown")
  assert(panel.Revive.Active and panel.Robux.Active,"Charm and configured paid repair available")
  assert(panel.Robux.Position.X.Offset>panel.Revive.Position.X.Offset,"Robux button beside charm")
  assert(panel:FindFirstChild("BrokenTab") and panel:FindFirstChild("ExchangeTab") and panel:FindFirstChild("ExchangePanel"),
   "Revive Machine has separate broken-pet and exchange tabs")
  assert(controller.ShowTab("Exchange"));task.wait(.1)
  assert(panel.ExchangePanel.Visible and not panel.Pets.Visible,"Exchange tab replaces the broken-pet view")
  assert(panel.ExchangePanel.ShardBalance.Text:find("100") and panel.ExchangePanel.Exchange.Active,
   "Exchange tab shows the saved shard balance and available exchange")
  assert(controller.ShowTab("Broken"));task.wait(.1)
  assert(panel.Pets.Visible and not panel.ExchangePanel.Visible,"Broken-pet tab restores recovery view")
  panel.Visible=false;task.wait(.1)
  assert(#panel.PetPreview.World:GetChildren()==0,"Closing frees preview geometry")
 end,debug.traceback)
 report:FireServer({Passed=ok,Failure=if ok then nil else tostring(failure)})
end)
