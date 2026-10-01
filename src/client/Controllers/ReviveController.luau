local Players=game:GetService("Players")
local Storage=game:GetService("ReplicatedStorage")
local Config=require(Storage.Shared.Config.ReviveConfig)
local Preview=require(script.Parent.Parent.UI.ItemPreview)
local Motion=require(script.Parent.Parent.UI.Motion)
local Compact=require(Storage.Shared.NumberFormat).Compact
local Controller={}
local Purchases=require(script.Parent.Parent.UI.Purchases)
local function clockText(seconds)
 seconds=math.max(0,math.floor(seconds))
 return string.format("%02d:%02d:%02d",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
function Controller.Start()
 local player=Players.LocalPlayer
 local gui=player:WaitForChild("PlayerGui"):WaitForChild("ReviveUI",30)
 local panel=gui.Panel
 local remote=Storage:WaitForChild("PrototypeRevive")
 local snapshot,selected,receivedAt=nil,nil,0
 local requesting,acting=false,false
 local cards={}
 local messages={TooFar="Visit the Revive Machine near the merchant.",NoRevive="Buy a Revive Charm from the merchant.",
  Busy="",Unavailable="This pet is no longer awaiting revival.",
  PetChanged="This recovery has changed. Refreshing…",Cooldown="",Loading="Loading your pets…"}
 local function remaining(r) return math.max(0,r.ExpiresAt-(snapshot.ServerNow+os.clock()-receivedAt)) end
 local function selectedRecord()
  if snapshot then for _,r in snapshot.Records do if r.AttemptId==selected then return r end end end
 end
 local render
 render=function()
  local seen={}
  for index,r in snapshot and snapshot.Records or {} do
   local key=r.AttemptId;seen[key]=true
   local card=cards[key]
   if not card then
    card=panel.Pets.PetTemplate:Clone();card.Name=key;card.Parent=panel.Pets;cards[key]=card
    card.Activated:Connect(function() if not acting then selected=key;render() end end)
   end
   card.Visible=true;card.LayoutOrder=index
   card.Text=r.PetName.."\nLv. "..r.FeedLevel.." • "..clockText(remaining(r))
   card.BackgroundColor3=if selected==key then Color3.fromRGB(45,145,115) else Color3.fromRGB(50,65,88)
  end
  for key,card in cards do if not seen[key] then card:Destroy();cards[key]=nil end end
  panel.Empty.Visible=not snapshot or #snapshot.Records==0
  local r=selectedRecord()
  Preview.Set(panel.PetPreview,if panel.Visible and r then {Kind="Pet",SpeciesId=r.SpeciesId} else nil)
  panel.PetName.Text=if r then r.PetName else "SELECT A BROKEN PET"
  panel.Details.Text=if r then string.format("%s • LEVEL %d • $%s/s\n%s remaining",r.Rarity,r.FeedLevel,Compact(r.Income),clockText(remaining(r))) else ""
  panel.Notice.Text=if r then "Expiry → Level 0 • Failed food stays spent" else "Broken pets remain here for 24 hours"
  local enabled=r~=nil and remaining(r)>0 and snapshot.NearMachine and snapshot.CanRevive and not snapshot.Busy and not acting
  panel.Revive.Active=enabled==true;panel.Revive.AutoButtonColor=enabled==true
  panel.Revive.BackgroundColor3=if enabled then Color3.fromRGB(70,190,110) else Color3.fromRGB(90,95,105)
  panel.Revive.Text="USE 1 REVIVE • "..Compact(snapshot and snapshot.ReviveCharges or 0)
  panel.Robux.Active=r~=nil and remaining(r)>0 and snapshot.NearMachine and not snapshot.Busy and not acting
  panel.Robux.Text="149 ROBUX"
 end
 local function refresh()
  if requesting or acting or not panel.Visible then return end
  requesting=true
  local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
  requesting=false
  if ok and result.Ok then
   snapshot=result;receivedAt=os.clock()
   if not result.NearMachine then panel.Visible=false end
   if selected and not selectedRecord() then selected=nil end
  elseif not ok or result.Code~="Cooldown" then
   snapshot=nil;panel.Status.Text=if ok then messages[result.Code] or "Unable to load pets." else "Connection interrupted. Retrying…"
  end
  render()
 end
 function Controller.Open()
  local point=workspace:FindFirstChild("ReviveMachine") and workspace.ReviveMachine:FindFirstChild("InteractionPoint")
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if not point or not root or (root.Position-point.Position).Magnitude>Config.MachineDistance then return false end
  for _,name in {"MerchantUI","DebugUI","IndexUI","PenManagerUI","ConveyorUI"} do
   local other=player.PlayerGui:FindFirstChild(name);if other and other:FindFirstChild("Panel") then other.Panel.Visible=false end
  end
  local main=player.PlayerGui:FindFirstChild("FeedYourPetUI")
  if main then main.Inventory.Visible=false;main.FeedPanel.Visible=false end
  panel.Status.Text="";panel.Visible=true;task.spawn(refresh);return true
 end
 function Controller.Select(attemptId)
  if not acting then selected=attemptId;render() end
 end
 game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt,who)
  if who and who~=player then return end
  local machine=workspace:FindFirstChild("ReviveMachine")
  if machine and prompt.Name=="OpenReviveMachine" and prompt:IsDescendantOf(machine) then Controller.Open() end
 end)
 panel.Revive.Activated:Connect(function()
  local r=selectedRecord()
  if acting or not r or not panel.Revive.Active then return end
  acting=true;render();panel.Status.Text="Restoring…"
  local ok,result=pcall(function() return remote:InvokeServer("Revive",r.PetId,r.AttemptId) end)
  acting=false
  panel.Status.Text=if ok and result.Ok then "Pet returned to your inventory." else if ok then messages[result.Code] or "Unable to restore." else "Reply lost. Checking recovery…"
  selected=nil;snapshot=nil;render();task.spawn(refresh)
 end)
 panel.Robux:SetAttribute("SuppressClickSound",true)
 panel.Robux.Activated:Connect(function()
  local r=selectedRecord()
  if r and panel.Robux.Active then Purchases.Request("Revive",r.PetId,r.AttemptId) end
 end)
 panel.Close.Activated:Connect(function() Motion.Close(panel) end)
 panel:GetPropertyChangedSignal("Visible"):Connect(function()
  player:SetAttribute("RevivePanelOpen",panel.Visible)
  if not panel.Visible then Preview.Set(panel.PetPreview,nil) end
 end)
 local DeviceLayout=require(script.Parent.Parent.UI.DeviceLayout)
 local function resize() DeviceLayout.Apply(panel,gui.AbsoluteSize,"Revive") end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize();render()
 task.spawn(function() while gui.Parent do refresh();task.wait(Config.RefreshSeconds) end end)
 return gui
end
return Controller
