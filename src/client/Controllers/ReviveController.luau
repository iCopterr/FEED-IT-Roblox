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

local function buildExchangeUI(panel)
 local brokenTab=panel.Revive:Clone()
 brokenTab.Name="BrokenTab";brokenTab.Text="BROKEN PETS";brokenTab.Position=UDim2.fromOffset(380,16)
 brokenTab.Size=UDim2.fromOffset(150,36);brokenTab.ZIndex=7;brokenTab.Parent=panel
 local exchangeTab=panel.Revive:Clone()
 exchangeTab.Name="ExchangeTab";exchangeTab.Text="SHARD EXCHANGE";exchangeTab.Position=UDim2.fromOffset(540,16)
 exchangeTab.Size=UDim2.fromOffset(160,36);exchangeTab.ZIndex=7;exchangeTab.Parent=panel

 local exchange=panel.Pets:Clone()
 exchange.Name="ExchangePanel";exchange.Position=UDim2.fromOffset(16,84);exchange.Size=UDim2.fromOffset(762,376)
 exchange.Visible=false;exchange.ScrollingEnabled=false;exchange.ScrollBarThickness=0
 exchange.AutomaticCanvasSize=Enum.AutomaticSize.None;exchange.CanvasSize=UDim2.fromOffset(0,0)
 for _,child in exchange:GetChildren() do
  if child:IsA("GuiObject") or child:IsA("UIGridLayout") or child:IsA("UIListLayout") then child:Destroy() end
 end
 exchange.Parent=panel

 local title=panel.PetName:Clone()
 title.Name="ShardTitle";title.Text="REVIVE SHARDS";title.Position=UDim2.fromOffset(24,18)
 title.Size=UDim2.fromOffset(714,42);title.TextSize=30;title.Parent=exchange
 local icon=panel.Robux.ProductIcon:Clone()
 icon.Name="RewardIcon";icon.Image="rbxassetid://133373414506019";icon.Position=UDim2.fromOffset(296,64)
 icon.Size=UDim2.fromOffset(170,140);icon.ZIndex=5;icon.Parent=exchange
 local balance=panel.Details:Clone()
 balance.Name="ShardBalance";balance.Text="YOUR SHARDS • 0";balance.Position=UDim2.fromOffset(24,210)
 balance.Size=UDim2.fromOffset(714,44);balance.TextSize=26;balance.Parent=exchange
 local description=panel.Notice:Clone()
 description.Name="Description";description.Text=[=[Collect shards from Robux food purchases
100 SHARDS = 1 REVIVE CHARM]=]
 description.Position=UDim2.fromOffset(24,252);description.Size=UDim2.fromOffset(714,48)
 description.TextWrapped=true;description.TextSize=18;description.Parent=exchange
 local button=panel.Revive:Clone()
 button.Name="Exchange";button.Text="EXCHANGE • 100 SHARDS";button.Position=UDim2.fromOffset(160,306)
 button.Size=UDim2.fromOffset(442,50);button.ZIndex=5;button.Parent=exchange
 local charms=panel.Notice:Clone()
 charms.Name="CharmCount";charms.Text="OWNED REVIVE CHARMS • 0";charms.Position=UDim2.fromOffset(24,352)
 charms.Size=UDim2.fromOffset(714,20);charms.TextSize=16;charms.Parent=exchange
 return brokenTab,exchangeTab,exchange
end

function Controller.Start()
 local player=Players.LocalPlayer
 local gui=player:WaitForChild("PlayerGui"):WaitForChild("ReviveUI",30)
 local panel=gui.Panel
 local brokenTab,exchangeTab,exchangePanel=buildExchangeUI(panel)
 local brokenObjects={panel.Pets,panel.PetPreview,panel.PetName,panel.Details,panel.Notice,panel.Revive,panel.Robux,panel.Empty}
 local remote=Storage:WaitForChild("PrototypeRevive")
 local snapshot,selected,receivedAt=nil,nil,0
 local requesting,acting=false,false
 local currentTab="Broken"
 local cards={}
 local messages={TooFar="Visit the Revive Machine near the merchant.",NoRevive="Buy a Revive Charm from the merchant.",
  NotEnoughShards="You need 100 Revive Shards.",StaleRequest="Exchange refreshed. Please try again.",
  Busy="",Unavailable="This pet is no longer awaiting revival.",
  PetChanged="This recovery has changed. Refreshing…",Cooldown="",Loading="Loading your pets…"}
 local function remaining(r) return math.max(0,r.ExpiresAt-(snapshot.ServerNow+os.clock()-receivedAt)) end
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
  if not broken then Preview.Set(panel.PetPreview,nil) end
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
   card.Text=r.PetName..string.char(10).."Lv. "..r.FeedLevel.." • "..clockText(remaining(r))
   card.BackgroundColor3=if selected==key then Color3.fromRGB(45,145,115) else Color3.fromRGB(50,65,88)
  end
  for key,card in cards do if not seen[key] then card:Destroy();cards[key]=nil end end
  panel.Empty.Visible=broken and (not snapshot or #snapshot.Records==0)
  local r=selectedRecord()
  Preview.Set(panel.PetPreview,if panel.Visible and broken and r then {Kind="Pet",SpeciesId=r.SpeciesId} else nil)
  panel.PetName.Text=if r then r.PetName else "SELECT A BROKEN PET"
  panel.Details.Text=if r then string.format("%s • LEVEL %d • $%s/s%s%s remaining",r.Rarity,r.FeedLevel,
   Compact(r.Income),string.char(10),clockText(remaining(r))) else ""
  panel.Notice.Text=if r then "Expiry → Level 0 • Failed food stays spent" else "Broken pets remain here for 24 hours"
  local enabled=r~=nil and remaining(r)>0 and snapshot.NearMachine and snapshot.CanRevive and not snapshot.Busy and not acting
  panel.Revive.Active=enabled==true;panel.Revive.AutoButtonColor=enabled==true
  panel.Revive.BackgroundColor3=if enabled then Color3.fromRGB(70,190,110) else Color3.fromRGB(90,95,105)
  panel.Revive.Text="USE 1 REVIVE • "..Compact(snapshot and snapshot.ReviveCharges or 0)
  panel.Robux.Active=r~=nil and remaining(r)>0 and snapshot.NearMachine and not snapshot.Busy and not acting
  panel.Robux.Text="149 ROBUX"

  local shardCount=snapshot and snapshot.ReviveShards or 0
  local cost=snapshot and snapshot.ShardExchangeCost or Config.Shards.ExchangeCost
  exchangePanel.ShardBalance.Text="YOUR SHARDS • "..Compact(shardCount)
  exchangePanel.CharmCount.Text="OWNED REVIVE CHARMS • "..Compact(snapshot and snapshot.ReviveCharges or 0)
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
  panel.Status.Text="";setTab("Broken");panel.Visible=true;task.spawn(refresh);return true
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
   panel.Status.Text="Revive Charm received!"
  else
   panel.Status.Text=if ok then messages[result.Code] or "Unable to exchange shards." else "Reply lost. Checking your balance…"
  end
  render();task.delay(.3,refresh)
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
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize();setTab("Broken");render()
 task.spawn(function() while gui.Parent do refresh();task.wait(Config.RefreshSeconds) end end)
 return gui
end
return Controller
