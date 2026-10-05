if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("ReviveMachineVerificationReport",60)
if not report then return end
local diagnostics
report.OnClientEvent:Connect(function(attempt)
 report:FireServer({Stage="Started"})
 local ok,failure=xpcall(function()
  local controller=require(script.Parent.Controllers.ReviveController)
  local gui=game.Players.LocalPlayer.PlayerGui:WaitForChild("ReviveUI")
  local panel=gui.Panel
  assert(not panel.Visible,"Broken pets do not auto-open the machine UI")
  assert(controller.Open(),"Machine opens nearby")
  local deadline=os.clock()+15
  repeat task.wait(.1) until panel.Pets:FindFirstChild(attempt) or os.clock()>deadline
  local debugList={}
  for _,child in panel.Pets:GetChildren() do table.insert(debugList,child.Name) end
  local diagnostic
  if not panel.Pets:FindFirstChild(attempt) then
   report:FireServer({Stage="SnapshotRequested",Tab=panel.BrokenTab.Text,Status=panel.Status.Text})
   diagnostic=game.ReplicatedStorage.PrototypeRevive:InvokeServer("Snapshot")
  end
  local warnings={}
  for _,entry in game:GetService("LogService"):GetLogHistory() do
   if entry.messageType~=Enum.MessageType.MessageOutput then table.insert(warnings,entry.message) end
  end
  diagnostics={Snapshot=diagnostic,Warnings=warnings}
  assert(panel.Pets:FindFirstChild(attempt),"Broken pet is listed: "..game:GetService("HttpService"):JSONEncode({
   Visible=panel.Visible,Status=panel.Status.Text,Tab=panel.BrokenTab.Text,Expected=attempt,Children=debugList,Snapshot=diagnostic,Warnings=warnings}))
  controller.Select(attempt);task.wait(.2)
  assert(panel.PetPreview.World:FindFirstChildOfClass("Model"),"Selected pet preview exists")
  assert(panel.PetPreview.World:FindFirstChildOfClass("Model"):FindFirstChild("BrokenRim"),"Repair preview looks broken")
  local player=game.Players.LocalPlayer
  local bag=player.PlayerGui.FeedYourPetUI
  local deadlineHotbar=os.clock()+5
  local returned=false
  repeat
   for _,slot in bag.Hotbar:GetChildren() do
    if slot:IsA("GuiButton") and slot:GetAttribute("ItemKey") then
     local petModel=slot:FindFirstChild("Preview") and slot.Preview.World:FindFirstChildOfClass("Model")
     if petModel and petModel:FindFirstChild("BrokenRim") then returned=true end
    end
   end
   if not returned then task.wait(.1) end
  until returned or os.clock()>deadlineHotbar
  assert(returned,"Exploded pet returns to hotbar with broken appearance")
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
 report:FireServer({Passed=ok,Failure=if ok then nil else tostring(failure),Diagnostics=diagnostics})
end)
report:FireServer({Stage="Ready"})
