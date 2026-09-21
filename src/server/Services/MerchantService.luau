local Players=game:GetService("Players")
local Data=require(script.Parent.DataService)
local Schema=require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks=require(script.Parent.FeedLocks)
local Config=require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
local FeedConfig=require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local Service={}
local sessions,saving={},{}

local function queueSave(player,profile)
	local token={};saving[player]=token
	task.spawn(function()
		while saving[player]==token and Data.GetData(player)==profile do
			local ok,saved,reason=pcall(Data.Save,player)
			if ok and saved then saving[player]=nil;Locks.Finish(player);return end
			warn("[MerchantService] Purchase save pending:",reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
end

local function aliveAndNear(player)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local merchant=workspace:FindFirstChild("MysteryMerchant")
	local point=merchant and merchant:FindFirstChild("InteractionPoint",true)
	return humanoid and humanoid.Health>0 and root and point and point:IsA("BasePart")
		and (root.Position-point.Position).Magnitude<=Config.PurchaseDistance
end

local function snapshot(player,state)
	local data=Data.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false,Code="Loading"} end
	local now=os.time();local restockId=Config.GetRestockId(now);local stock=Config.GetStock(restockId)
	local items={}
	for slot,id in stock do
		local item=Config.Items[id]
		table.insert(items,{Slot=slot,ItemId=id,Name=item.DisplayName,Description=item.Description,Price=item.Price,
			Purchased=data.MerchantRestockId==restockId and data.MerchantPurchases[tostring(slot)]==true})
	end
	return {Ok=true,Tokens=data.Tokens,ProtectionTokens=data.ProtectionTokens,RestockId=restockId,
		RestocksAt=(restockId+1)*Config.RestockSeconds,ServerNow=now,Items=items,NextSequence=state.Sequence+1,
		Busy=Locks.IsLocked(player) or saving[player]~=nil}
end

function Service.HandleRequest(player,action,slot,expectedRestock,sequence)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	local state=sessions[player]
	if not state then state={Sequence=0,LastRequest=-math.huge,LastSnapshot=-math.huge};sessions[player]=state end
	local now=os.clock()
	if action=="Snapshot" then
		if now-state.LastSnapshot<Config.RequestCooldown then return {Ok=false,Code="Cooldown"} end
		state.LastSnapshot=now;return snapshot(player,state)
	end
	if action~="Purchase" or type(slot)~="number" or slot%1~=0 or slot<1 or slot>Config.StockSlots
		or type(expectedRestock)~="number" or expectedRestock%1~=0 or expectedRestock<0
		or type(sequence)~="number" or sequence%1~=0 or sequence<1 or sequence>9007199254740991 then
		return {Ok=false,Code="InvalidRequest"}
	end
	if sequence==state.Sequence and state.Last and state.Last.Slot==slot and state.Last.RestockId==expectedRestock then return table.clone(state.Last) end
	if sequence~=state.Sequence+1 then return {Ok=false,Code="StaleRequest",NextSequence=state.Sequence+1} end
	if now-state.LastRequest<Config.RequestCooldown then return {Ok=false,Code="Cooldown"} end
	state.LastRequest=now
	if saving[player] or Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	local data=Data.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false,Code="Loading"} end
	local current=Config.GetRestockId(os.time())
	if expectedRestock~=current then return {Ok=false,Code="Restocked"} end
	if not aliveAndNear(player) then return {Ok=false,Code="TooFar"} end
	local itemId=Config.GetStock(current)[slot];local item=itemId and Config.Items[itemId]
	if not item then return {Ok=false,Code="Unavailable"} end
	if data.MerchantRestockId==current and data.MerchantPurchases[tostring(slot)] then return {Ok=false,Code="Sold"} end
	if data.Tokens<item.Price then return {Ok=false,Code="NotEnoughTokens"} end
	if item.RewardType=="Protection" and data.ProtectionTokens+item.Amount>FeedConfig.ProtectionTokenCap then return {Ok=false,Code="ProtectionFull"} end
	local oldTokens,oldFood,oldProtection=data.Tokens,data.Food,data.ProtectionTokens
	local oldRestock,oldPurchases=data.MerchantRestockId,table.clone(data.MerchantPurchases)
	assert(Locks.Begin(player,"MerchantPurchase"))
	if data.MerchantRestockId~=current then data.MerchantRestockId=current;data.MerchantPurchases={} end
	data.Tokens-=item.Price
	if item.RewardType=="Food" then data.Food+=item.Amount else data.ProtectionTokens+=item.Amount end
	data.MerchantPurchases[tostring(slot)]=true
	if not Schema.Validate(data) then
		data.Tokens,data.Food,data.ProtectionTokens=oldTokens,oldFood,oldProtection
		data.MerchantRestockId,data.MerchantPurchases=oldRestock,oldPurchases
		Locks.Finish(player);return {Ok=false,Code="InvalidData"}
	end
	local result={Ok=true,Code="Purchased",Slot=slot,RestockId=current,ItemId=itemId,Name=item.DisplayName,
		RewardType=item.RewardType,Amount=item.Amount,Tokens=data.Tokens,Food=data.Food,
		ProtectionTokens=data.ProtectionTokens,NextSequence=sequence+1}
	state.Sequence=sequence;state.Last=table.clone(result);queueSave(player,data)
	return result
end

function Service.Start()
	assert(Config.StockSlots>0 and Config.StockSlots<=#Config.ItemOrder,"Invalid merchant slot count")
	for _,id in Config.ItemOrder do
		local item=assert(Config.Items[id],"Missing merchant item")
		assert(item.Price>0 and item.Price%1==0 and item.Weight>0 and item.Amount>0,"Invalid merchant item")
		assert(item.RewardType=="Food" or item.RewardType=="Protection","Invalid merchant reward")
	end
	local point=workspace:WaitForChild("MysteryMerchant"):WaitForChild("InteractionPoint")
	local prompt=point:FindFirstChild("OpenMysteryMerchant") or Instance.new("ProximityPrompt")
	prompt.Name="OpenMysteryMerchant";prompt.ActionText="Browse";prompt.ObjectText="Mystery Merchant"
	prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	prompt.HoldDuration=.25;prompt.MaxActivationDistance=Config.PurchaseDistance;prompt.RequiresLineOfSight=false;prompt.Parent=point
	local remote=Instance.new("RemoteFunction");remote.Name="PrototypeMerchant";remote.OnServerInvoke=Service.HandleRequest;remote.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player],saving[player]=nil,nil end)
end
return table.freeze(Service)
