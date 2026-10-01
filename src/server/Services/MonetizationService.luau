local Players=game:GetService("Players")
local Market=game:GetService("MarketplaceService")
local Http=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.Config.MonetizationConfig)
local Shop=require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
local Revive=require(game.ReplicatedStorage.Shared.Config.ReviveConfig)
local Data=require(script.Parent.DataService)
local Adapter=require(script.Parent.Parent.Data.DataStoreAdapter)
local Schema=require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks=require(script.Parent.FeedLocks)
local State=require(script.Parent.CommerceState)
local Service={}
local busy,last,prompted,passes={},{},{},{}
local notices
local function persistenceBlocked()
 -- Studio checkout tests use the isolated in-memory profile. Never allow
 -- nonpersistent fulfillment in a published server.
 return Adapter.IsMemory() and not RunService:IsStudio()
end
local catalog={}
catalog[Config.WelcomePack.ProductId]={Kind="Welcome"}
for _,p in Config.MoneyPacks do catalog[p.ProductId]={Kind="Money",Money=p.Money} end
for id,p in Config.FoodProducts do catalog[p.ProductId]={Kind="Food",ItemId=id} end
for _,p in Config.GrowTiers do catalog[p.ProductId]={Kind="Grow"} end
catalog[Config.GrowAllProductId]={Kind="GrowAll"}
catalog[Config.PersonalRestockProductId]={Kind="Restock"}
catalog[Config.DirectReviveProductId]={Kind="Revive"}

local function near(player,model,distance)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 local object=workspace:FindFirstChild(model)
 local point=object and object:FindFirstChild("InteractionPoint",true)
 return root and hum and hum.Health>0 and point and (root.Position-point.Position).Magnitude<=distance
end
local function save(player,data)
 -- Keep transaction lock after ambiguous writes. Never roll back a paid grant.
 while Data.GetData(player)==data do
  local ok,result=pcall(Data.Save,player)
  if ok and result then return true end
  task.wait(5)
 end
 return false
end
local function release(player)
 busy[player]=nil;Locks.Finish(player)
end
local function refreshPass(player)
 local ok,owns=pcall(Market.UserOwnsGamePassAsync,Market,player.UserId,Config.DoubleMoney.GamePassId)
 if ok and player.Parent==Players then passes[player]=owns==true;player:SetAttribute("DoubleMoneyOwned",owns==true) end
 return ok
end
function Service.Multiplier(player) return if passes[player] then Config.DoubleMoney.Multiplier else 1 end

local function prepare(player,data,kind,arg,extra)
 local p
 if kind=="Product" and type(arg)=="number" then
  local item=catalog[arg]
  if not item or (item.Kind~="Money" and item.Kind~="Welcome") then return end
  p=table.clone(item);p.ProductId=arg
 elseif kind=="Food" and type(arg)=="number" and arg%1==0 and arg>=1 and arg<=Shop.StockSlots then
  if not near(player,"MysteryMerchant",Shop.PurchaseDistance) then return end
  local stock,_,items=State.Stock(data,os.time())
  if stock~=extra then return end
  local id=items[arg];local product=Config.FoodProducts[id]
  if not product or (data.MerchantRestockId==stock and data.MerchantPurchases[tostring(arg)]) then return end
  p={Kind="Food",ItemId=id,Stock=stock,Slot=arg,ProductId=product.ProductId}
 elseif kind=="Restock" and type(arg)=="number" then
  if not near(player,"MysteryMerchant",Shop.PurchaseDistance) then return end
  local stock,_,_,source=State.Stock(data,os.time())
  if stock~=arg then return end
  p={Kind="Restock",SourceStockId=source,ProductId=Config.PersonalRestockProductId}
 elseif kind=="Grow" and type(arg)=="string" then
  local egg=data.IncubatingEggs[arg]
  if not egg or not egg.PenPosition or egg.ReadyAt<=os.time() then return end
  for _,tier in Config.GrowTiers do if egg.ReadyAt-os.time()<=tier.Seconds then
   p={Kind="Grow",EggUid=arg,ProductId=tier.ProductId};break
  end end
 elseif kind=="GrowAll" then
  local eggs={}
  for id,egg in data.IncubatingEggs do if egg.PenPosition and egg.ReadyAt>os.time() then table.insert(eggs,id) end end
  if #eggs==0 then return end
  p={Kind="GrowAll",Eggs=eggs,ProductId=Config.GrowAllProductId}
 elseif kind=="Revive" and type(arg)=="string" and type(extra)=="string" then
  local record=data.PendingRecovery[arg]
  if not record or record.AttemptId~=extra or os.time()>=record.ExplodedAt+Revive.WindowSeconds
   or not near(player,"ReviveMachine",Revive.MachineDistance) then return end
  p={Kind="Revive",PetId=arg,AttemptId=extra,ProductId=Config.DirectReviveProductId}
 end
 return p
end
function Service.Request(player,kind,arg,extra)
 local data=Data.GetData(player)
 if not data or player.Parent~=Players then return {Ok=false,Code="Loading"} end
 if persistenceBlocked() then return {Ok=false,Code="PersistenceRequired"} end
 if os.clock()-(last[player] or -math.huge)<1 then return {Ok=false,Code="Cooldown"} end
 last[player]=os.clock()
 if busy[player] or prompted[player] or Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
 if kind=="Pass" then
  if passes[player] then return {Ok=false,Code="Owned"} end
  local ok=pcall(Market.PromptGamePassPurchase,Market,player,Config.DoubleMoney.GamePassId)
  return {Ok=ok,Code=if ok then "Prompted" else "Unavailable"}
 end
 local state=State.Read(data)
 if state.Pending then return {Ok=false,Code="PurchasePending"} end
 -- Bound the ledger before prompting; never prune receipt replay guards.
 local count=0 for _ in state.Receipts do count+=1 end
 if count>=10000 then return {Ok=false,Code="SupportRequired"} end
 local p=prepare(player,data,kind,arg,extra)
 if not p then return {Ok=false,Code="Unavailable"} end
 if p.Kind=="Welcome" and state.WelcomeClaimed then return {Ok=false,Code="Owned"} end
 if not Locks.Begin(player,"PurchaseIntent") then return {Ok=false,Code="Busy"} end
 busy[player]=true
 p.Token=Http:GenerateGUID(false)
 state.Pending=p;State.Write(data,state)
 if not save(player,data) then release(player);return {Ok=false,Code="Loading"} end
 release(player)
 if player.Parent~=Players or Data.GetData(player)~=data then return {Ok=false,Code="Loading"} end
 prompted[player]={ProductId=p.ProductId,Token=p.Token}
 local ok=pcall(Market.PromptProductPurchase,Market,player,p.ProductId)
 -- A thrown prompt can be ambiguous: preserve intent for support/reconciliation.
 return {Ok=ok,Code=if ok then "Prompted" else "PurchasePending"}
end
function Service.ProcessReceipt(receipt)
 local retry=Enum.ProductPurchaseDecision.NotProcessedYet
 local player=Players:GetPlayerByUserId(receipt.PlayerId)
 if not player or persistenceBlocked() or not catalog[receipt.ProductId] or type(receipt.PurchaseId)~="string" then return retry end
 -- Roblox does not provide a periodic receipt retry. Wait out an active
 -- gameplay transaction here instead of requiring another purchase or rejoin.
 while player.Parent==Players and (not Data.GetData(player) or busy[player] or Locks.IsLocked(player)) do
  task.wait(.25)
 end
 local data=Data.GetData(player)
 if not data or player.Parent~=Players or not Locks.Begin(player,"PaidReceipt") then return retry end
 busy[player]=true
 local ok,result=xpcall(function()
  local state=State.Read(data)
  if not state.Receipts[receipt.PurchaseId] then
   local p=state.Pending
   if not p or p.ProductId~=receipt.ProductId then
    -- Non-targeted purchases can also arrive through Roblox's external store.
    local item=catalog[receipt.ProductId]
    if item.Kind~="Money" and item.Kind~="Welcome" then return retry end
    p=table.clone(item)
   end
   local draft=assert(Schema.Migrate(data))
   if not State.Grant(draft,state,p,os.time()) then return retry end
   state.Receipts[receipt.PurchaseId]=true
   if p==state.Pending then state.Pending=nil end
   State.Write(draft,state)
   assert(Schema.Validate(draft),"Invalid paid reward state")
   -- Validate the whole reward on a detached copy before committing in memory.
   -- No yields between reward application and its receipt marker.
   for key,value in draft do data[key]=value end
  end
  if not save(player,data) then return retry end
  player:SetAttribute("WelcomePackOwned",state.WelcomeClaimed==true)
  if notices then notices:FireClient(player,"Purchase received!") end
  return Enum.ProductPurchaseDecision.PurchaseGranted
 end,debug.traceback)
 release(player)
 if not ok then warn("[Commerce] Receipt remains unresolved:",result);return retry end
 return result
end
function Service.Start()
 Market.ProcessReceipt=Service.ProcessReceipt
 local remote=Instance.new("RemoteFunction");remote.Name="MonetizationRequest"
 remote.OnServerInvoke=Service.Request;remote.Parent=game.ReplicatedStorage
 notices=Instance.new("RemoteEvent");notices.Name="MonetizationNotice";notices.Parent=game.ReplicatedStorage
 Market.PromptProductPurchaseFinished:Connect(function(userId,id,purchased)
  -- Completion is NOT proof of payment. Only cancellation clears a reservation.
  local player=Players:GetPlayerByUserId(userId)
  local prompt=player and prompted[player]
  if not prompt or prompt.ProductId~=id then return end
  prompted[player]=nil
  if purchased then return end
  task.spawn(function()
   while player.Parent==Players and (busy[player] or Locks.IsLocked(player)) do task.wait(.2) end
   local data=Data.GetData(player)
   if not data or not Locks.Begin(player,"CancelPurchase") then return end
   busy[player]=true
   local state=State.Read(data)
   if state.Pending and state.Pending.ProductId==id and state.Pending.Token==prompt.Token then
    state.Pending=nil;State.Write(data,state);save(player,data)
   end
   release(player)
  end)
 end)
 Market.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
  if id==Config.DoubleMoney.GamePassId and purchased then task.spawn(refreshPass,player) end
 end)
 local function joined(player)
  task.spawn(function()
   for _=1,6 do if refreshPass(player) or player.Parent~=Players then break end;task.wait(10) end
  end)
  task.spawn(function()
   while player.Parent==Players and not Data.IsLoaded(player) do task.wait(.2) end
   local data=Data.GetData(player)
   if data then player:SetAttribute("WelcomePackOwned",State.Read(data).WelcomeClaimed==true) end
  end)
 end
 Players.PlayerAdded:Connect(joined)
 Players.PlayerRemoving:Connect(function(player) last[player]=nil;prompted[player]=nil;passes[player]=nil end)
 for _,player in Players:GetPlayers() do joined(player) end
end
return Service
