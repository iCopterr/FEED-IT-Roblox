-- Edit mode, detached profiles only. Never writes a real player's DataStore.
assert(not game:GetService("RunService"):IsRunning())
local root=game.ServerScriptService.Server
local cache={}
local function fresh(module)
	if cache[module] then return cache[module] end
	local fn=assert(loadstring(module.Source))
	setfenv(fn,setmetatable({script=module,require=fresh},{__index=getfenv()}))
	cache[module]=fn();return cache[module]
end
local Gift=fresh(root.Data.AccountGift)
local Config=fresh(root.Config.AccountGiftConfig)
local Schema=fresh(root.Data.PlayerDataSchema)
local Food=fresh(game.ReplicatedStorage.Shared.Config.FoodConfig)
local checks=0
local function check(ok,name)assert(ok,name);checks+=1 end
check(#Food.Order==8,"Gift covers all eight current foods")
local recipients=0
for id in Config.UserIds do
	recipients+=1
	local before=Schema.CreateDefault()
	before.ReviveCharges=3;before.ReviveShards=42;before.Food=12
	before.Settings.UnrelatedSetting="keep"
	for _,foodId in Food.Order do if foodId~="basic" then Food.Add(before,foodId,2) end end
	local after,granted=Gift.Apply(before,id)
	check(granted and after~=before,"Eligible account gets detached gift "..id)
	check(after.ReviveCharges==18,"Adds fifteen charms without resetting owned charms")
	for _,foodId in Food.Order do check(Food.Count(after,foodId)==Food.Count(before,foodId)+5,"Adds five "..foodId) end
	check(before.ReviveCharges==3 and before.Settings[Config.ClaimKey]==nil,"Original saved record is not mutated")
	check(after.ReviveShards==42 and after.Money==before.Money and after.Settings.UnrelatedSetting=="keep","Unrelated balances/settings preserved")
	local again,repeated=Gift.Apply(after,id)
	check(not repeated and again==after and again.ReviveCharges==18,"Ambiguous-write retry cannot duplicate gift")
	local saved=assert(Schema.Migrate(after))
	-- Consumed gifts must not be replenished by reconnects.
	for _,foodId in Food.Order do Food.Add(saved,foodId,-5) end
	saved.ReviveCharges-=15
	local rejoined,extra=Gift.Apply(saved,id)
	check(not extra and rejoined.ReviveCharges==3,"Saved claim remains consumed after rejoin")
	for _,foodId in Food.Order do check(Food.Count(rejoined,foodId)==Food.Count(before,foodId),"Rejoin does not replenish "..foodId) end
	check(Schema.Validate(rejoined),"Granted and consumed save validates")
end
check(recipients==3 and Config.UserIds[4750343708] and Config.UserIds[123985255] and Config.UserIds[5250447342],"Only the exact three requested IDs are allowed")
for _,id in {0,-1,1,4750343707,5250447343} do
	local data=Schema.CreateDefault();local after,granted=Gift.Apply(data,id)
	check(not granted and after==data and data.ReviveCharges==0 and data.Food==0,"Unlisted ID receives nothing "..id)
end
local data=Schema.CreateDefault();data.ReviveCharges=9007199254740991
local ok=pcall(Gift.Apply,data,5250447342)
check(not ok and data.Settings[Config.ClaimKey]==nil and data.Food==0,"Overflow fails without a partial grant")
-- Exercise real session acquisition against a detached adapter, including an
-- UpdateAsync that commits but loses its acknowledgement. No production writes.
local function copy(value)
	if type(value)~="table" then return value end
	local out={};for key,item in value do out[key]=copy(item) end;return out
end
local function signal()
	local s={listeners={}}
	function s:Connect(fn)table.insert(self.listeners,fn);return {Disconnect=function()end} end
	function s:Fire(...)for _,fn in self.listeners do fn(...) end end
	return s
end
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers()return {} end
function players:GetPlayerByUserId()return nil end
local jobs,store={},{}
local now,lostAcknowledgement=1000000,false
local adapter={IsMemory=function()return true end,GetStoreName=function()return "DetachedGiftQA" end}
function adapter.UpdateAsync(key,transform)
	local nextValue=transform(copy(store[key]))
	if nextValue then store[key]=copy(nextValue) end
	if lostAcknowledgement then lostAcknowledgement=false;return false,nil,"Simulated lost acknowledgement" end
	return true,copy(store[key]),nil
end
local dataConfig=fresh(game.ReplicatedStorage.Shared.Config.DataConfig)
local fakeGame={JobId="account-gift-qa",PlaceId=0,ReplicatedStorage=game.ReplicatedStorage}
function fakeGame:GetService(name)return if name=="Players" then players else game:GetService(name) end
function fakeGame:BindToClose(fn)self.shutdown=fn end
local factory=assert(loadstring(root.Services.DataService.Source))
setfenv(factory,setmetatable({script=root.Services.DataService,game=fakeGame,
	os={time=function()return now end},
	task={spawn=function(fn)table.insert(jobs,fn)end,defer=function(fn)table.insert(jobs,fn)end,wait=function()end},
	require=function(module)
		if module==root.Data.DataStoreAdapter then return adapter end
		return fresh(module)
	end,
},{__index=getfenv()}))
local service=factory();service.Start();table.clear(jobs)
local function playerFor(id)
	local p={UserId=id,Name="GiftQA",Parent=players,attributes={}}
	function p:SetAttribute(key,value)self.attributes[key]=value end
	function p:Kick(reason)self.kicked=reason end
	return p
end
local function join(p)
	players.PlayerAdded:Fire(p);assert(#jobs==1);table.remove(jobs,1)()
	return service.GetData(p)
end
for id in Config.UserIds do
	local p=playerFor(id)
	lostAcknowledgement=true
	local loaded=assert(join(p))
	local key=dataConfig.PlayerKeyPrefix..id
	check(loaded.ReviveCharges==15 and p.attributes.DataLoaded==true,"Real acquisition grants once despite lost acknowledgement "..id)
	check(store[key].Data.Settings[Config.ClaimKey]==true and store[key].Data.ReviveCharges==15,"Claim and charms are durable before profile exposure")
	for _,foodId in Food.Order do
		check(Food.Count(loaded,foodId)==5 and Food.Count(store[key].Data,foodId)==5,"Real acquisition persists five "..foodId)
		Food.Add(loaded,foodId,-5)
	end
	loaded.ReviveCharges=0
	players.PlayerRemoving:Fire(p)
	loaded=assert(join(p))
	check(loaded.ReviveCharges==0 and Food.Total(loaded)==0,"Actual leave/rejoin does not replenish spent gift")
	players.PlayerRemoving:Fire(p)
end
local lockedId=4750343708
local key=dataConfig.PlayerKeyPrefix..lockedId
store[key]={RecordVersion=dataConfig.StoredRecordVersion,Data=Schema.CreateDefault(),LastSavedAt=now,
	Session={ServerId="other-server",SessionId="other-session",PlaceId=0,AcquiredAt=now,HeartbeatAt=now}}
local lockedPlayer=playerFor(lockedId)
check(join(lockedPlayer)==nil and lockedPlayer.kicked~=nil,"An active foreign session blocks gift acquisition")
check(store[key].Data.ReviveCharges==0 and store[key].Data.Settings[Config.ClaimKey]==nil,"Locked profile cannot receive a partial gift or claim")
print("PASS: "..checks.." account-gift checks: exact recipients, additive inventory, real acquisition, retry/rejoin protection, lock safety and overflow")
