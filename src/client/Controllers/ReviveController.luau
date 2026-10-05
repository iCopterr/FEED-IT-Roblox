local Players=game:GetService("Players")
local Storage=game:GetService("ReplicatedStorage")
local Config=require(Storage.Shared.Config.ReviveConfig)
local Preview=require(script.Parent.Parent.UI.ItemPreview)
local Motion=require(script.Parent.Parent.UI.Motion)
local Compact=require(Storage.Shared.NumberFormat).Compact
local Controller={}
local Purchases=require(script.Parent.Parent.UI.Purchases)
local View=require(script.Parent.Parent.UI.ReviveView)

function Controller.Start()
 local player=Players.LocalPlayer
 local gui=player:WaitForChild("PlayerGui"):WaitForChild("ReviveUI",30)
 local panel=gui.Panel
 local brokenTab,exchangeTab,exchangePanel=View.Build(panel)
 local brokenObjects={panel.Pets,panel.PetPreview,panel.PetName,panel.Details,panel.Notice,panel.Revive,panel.Robux,panel.Empty}
 local remote=Storage:WaitForChild("PrototypeRevive")
 local snapshot,selected=nil,nil
 local requesting,acting=false,false
 local refreshQueued=false
 local refreshFailed=false
 local currentTab="Broken"
 local cards={}
 local function setPreview(entry)
  -- A streamed/missing model must never stop the damaged-pet list refreshing.
  local ok,err=pcall(Preview.Set,panel.PetPreview,entry)
  if not ok then warn("[RepairStation] Preview unavailable:",err) end
 end
 local messages={TooFar="Visit the Pet Repair Station near the merchant.",NoRevive="Get a Repair Charm from the merchant or exchange shards.",
  NotEnoughShards="You need 100 Repair Shards.",StaleRequest="Exchange refreshed. Please try again.",
  Busy="",Unavailable="This pet no longer needs repair.",
  PetChanged="This pet's damage has changed. Refreshing…",Cooldown="",Loading="Loading your pets…"}
 local function selectedRecord()
  if snapshot then for _,r in snapshot.Records do if r.AttemptId==selected then return r end end end
 end
 local render
 local function setTab(name)
  currentTab=name
  local broken=name=="Broken"
  for _,object in brokenObjects do object.Visible=broken end
  exchangePanel.Visible=not broken
  brokenTab.BackgroundColor3=if broken then Color3.fromRGB(70,190,110) else Color3.fromRGB(40,150,205)
  exchangeTab.BackgroundColor3=if broken then Color3.fromRGB(40,150,205) else Color3.fromRGB(70,190,110)
  if not broken then setPreview(nil) end
  if render then render() end
 end
 render=function()
  local broken=currentTab=="Broken"
  local seen={}
  for index,r in snapshot and snapshot.Records or {} do
   local key=r.AttemptId;seen[key]=true
   local card=cards[key]
   if not card then
    card=panel.Pets.PetTemplate:Clone();card.Name=key;card.Parent=panel.Pets;cards[key]=card
    card.Activated:Connect(function() if not acting then selected=key;render() end end)
   end
   card.Visible=broken;card.LayoutOrder=index
   card.Text=r.PetName.."\nBROKEN • Lv. "..r.FeedLevel.."\n"..Config.BrokenIncomeLabel
   card.BackgroundColor3=if selected==key then Color3.fromRGB(45,145,115) else Color3.fromRGB(50,65,88)
  end
  for key,card in cards do if not seen[key] then card:Destroy();cards[key]=nil end end
  panel.Empty.Visible=broken and (not snapshot or #snapshot.Records==0)
  panel.Empty.Text=if snapshot then "No broken pets\nYour pets are safe!" else "Loading broken pets…"
  brokenTab.Text="BROKEN PETS • "..tostring(snapshot and #snapshot.Records or 0)
  local r=selectedRecord()
  panel.Pets.Visible=broken
  setPreview(if panel.Visible and broken and r then {Kind="Pet",SpeciesId=r.SpeciesId,Broken=true,Level=r.FeedLevel} else nil)
  panel.PetName.Text=if r then r.PetName else "SELECT A BROKEN PET"
  panel.Details.Text=if r then string.format("%s • LEVEL %d\n$%s/s → $%s/s AFTER REPAIR",r.Rarity,r.FeedLevel,
   Compact(r.Income),Compact(r.RestoredIncome)) else ""
  panel.Notice.Text="Repair before feeding • "..Config.BrokenIncomeLabel.." until repaired"
  local enabled=r~=nil and snapshot.NearMachine and snapshot.CanRevive and not snapshot.Busy and not acting
  panel.Revive.Active=enabled==true;panel.Revive.AutoButtonColor=enabled==true
  panel.Revive.BackgroundColor3=if enabled then Color3.fromRGB(70,190,110) else Color3.fromRGB(90,95,105)
  panel.Revive.Text="REPAIR • 1 CHARM ("..Compact(snapshot and snapshot.ReviveCharges or 0)..")"
  panel.Robux.Active=r~=nil and snapshot.NearMachine and not snapshot.Busy and not acting
  panel.Robux.Text="149 ROBUX"

  local shardCount=snapshot and snapshot.ReviveShards or 0
  local cost=snapshot and snapshot.ShardExchangeCost or Config.Shards.ExchangeCost
  exchangePanel.ShardBalance.Text="YOUR SHARDS • "..Compact(shardCount)
  exchangePanel.CharmCount.Text="OWNED REPAIR CHARMS • "..Compact(snapshot and snapshot.ReviveCharges or 0)
  exchangePanel.Exchange.Text="EXCHANGE • "..Compact(cost).." SHARDS"
  local canExchange=snapshot and snapshot.NearMachine and not snapshot.Busy and not acting and shardCount>=cost
  exchangePanel.Exchange.Active=canExchange==true;exchangePanel.Exchange.AutoButtonColor=canExchange==true
  exchangePanel.Exchange.BackgroundColor3=if canExchange then Color3.fromRGB(70,190,110) else Color3.fromRGB(90,95,105)
 end
 local function refresh()
  if requesting or acting or not panel.Visible then return end
  requesting=true
  local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
  requesting=false
  if ok and type(result)=="table" and result.Ok and type(result.Records)=="table" then
   if refreshFailed then panel.Status.Text="";refreshFailed=false end
   snapshot=result
   if not result.NearMachine then panel.Visible=false end
   if selected and not selectedRecord() then selected=nil end
   if not selected and result.Records[1] then selected=result.Records[1].AttemptId end
  elseif ok and type(result)=="table" and result.Code=="Cooldown" then
   -- Open() and Visible may request together. Do not leave a stale/empty list
   -- waiting on the background poll after the first request is throttled.
   if not refreshQueued then
    refreshQueued=true
    task.delay(Config.SnapshotCooldown+.05,function() refreshQueued=false;refresh() end)
   end
  else
   -- Retain the last good list while retrying; a dropped reply is not an empty
   -- inventory. Never let a nil reply terminate the polling coroutine.
   panel.Status.Text="Unable to refresh pets. Retrying…"
   refreshFailed=true
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
  panel.Status.Text="";panel.Pets.CanvasPosition=Vector2.zero
  setTab("Broken");panel.Visible=true;task.spawn(refresh);return true
 end
 function Controller.Select(attemptId)
  if not acting then selected=attemptId;render() end
 end
 function Controller.ShowTab(name)
  if acting or (name~="Broken" and name~="Exchange") then return false end
  setTab(name);return true
 end
 game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt,who)
  if who and who~=player then return end
  local machine=workspace:FindFirstChild("ReviveMachine")
  if machine and prompt.Name=="OpenReviveMachine" and prompt:IsDescendantOf(machine) then Controller.Open() end
 end)
 brokenTab.Activated:Connect(function() Controller.ShowTab("Broken") end)
 exchangeTab.Activated:Connect(function() Controller.ShowTab("Exchange") end)
 exchangePanel.Exchange.Activated:Connect(function()
  if acting or not snapshot or not exchangePanel.Exchange.Active then return end
  acting=true;render();panel.Status.Text="Exchanging shards…"
  local sequence=snapshot.NextExchangeSequence
  local ok,result=pcall(function() return remote:InvokeServer("Exchange",sequence) end)
  acting=false
  if ok and result.Ok then
   snapshot.ReviveCharges=result.ReviveCharges;snapshot.ReviveShards=result.ReviveShards
   snapshot.NextExchangeSequence=result.NextExchangeSequence;snapshot.CanExchange=snapshot.ReviveShards>=snapshot.ShardExchangeCost
   panel.Status.Text="Repair Charm received!"
  else
   panel.Status.Text=if ok then messages[result.Code] or "Unable to exchange shards." else "Reply lost. Checking your balance…"
  end
  render();task.delay(.3,refresh)
 end)
 panel.Revive.Activated:Connect(function()
  local r=selectedRecord()
  if acting or not r or not panel.Revive.Active then return end
  acting=true;render();panel.Status.Text=""
  local ok,result=pcall(function() return remote:InvokeServer("Repair",r.PetId,r.AttemptId) end)
  acting=false
  panel.Status.Text=if ok and result.Ok then "Pet repaired! Full income restored." else if ok then messages[result.Code] or "Unable to repair." else "Reply lost. Checking repair…"
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
  if not panel.Visible then setPreview(nil) else task.spawn(refresh) end
 end)
 local DeviceLayout=require(script.Parent.Parent.UI.DeviceLayout)
 local function resize() DeviceLayout.Apply(panel,gui.AbsoluteSize,"Revive") end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize();setTab("Broken");render()
 Storage:WaitForChild("FeedOutcome").OnClientEvent:Connect(function(result)
  if result.OwnerUserId~=player.UserId or result.Code~="Explosion" then return end
  -- The empty list from an earlier visit is no longer authoritative.
  snapshot=nil;selected=nil
  render();task.defer(refresh)
 end)
 task.spawn(function()
  while gui.Parent do
   local ok,err=pcall(refresh)
   if not ok then requesting=false;warn("[RepairStation] Refresh failed; retrying:",err) end
   task.wait(Config.RefreshSeconds)
  end
 end)
 return gui
end
return Controller
