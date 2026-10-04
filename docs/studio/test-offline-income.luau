-- Edit-mode, detached persistence harness. No real profiles, remotes or saves.
assert(not game:GetService("RunService"):IsRunning())
local server = game.ServerScriptService.Server
local function load(module, overrides)
	local factory = assert(loadstring(module.Source, module:GetFullName()))
	local env = setmetatable({script = module}, {__index = getfenv()})
	for key, value in overrides or {} do env[key] = value end
	setfenv(factory, env)
	return factory()
end
local schema = load(server.Data.PlayerDataSchema)
local offlineConfigModule = game.ReplicatedStorage.Shared.Config.OfflineIncomeConfig
local offlineConfig = load(offlineConfigModule)
local earnings = load(server.Data.OfflineEarnings,{require=function(module)
	if module==offlineConfigModule then return offlineConfig end
	return require(module)
end})
local checks = {}
local function check(ok, name) assert(ok, name); table.insert(checks, name) end
local function copy(t)
	if type(t) ~= "table" then return t end
	local out = {}; for k,v in t do out[k] = copy(v) end; return out
end
local function profile()
	local data = schema.CreateDefault()
	data.Inventory.qa = {DataVersion=2,PetId="qa",SpeciesId="test_common",EggId="prototype_egg",
		Rarity="Common",Variant="Normal",Traits={},FeedLevel=0,BaseIncome=10,Locked=false,
		Placed=true,PlotSlot=1,CreatedAt=1}
	data.PlacedPetIds.qa = true
	return data
end
local p = profile()
check(schema.Validate(p), "New v14 profile validates")
earnings.Accrue(p,100000)
check(p.OfflineEarnings.PendingMoney==0, "No first-join retroactive award")
earnings.Accrue(p,100599)
check(p.OfflineEarnings.PendingMoney==0 and p.OfflineEarnings.PendingSeconds==0, "Nine minutes fifty-nine seconds earns nothing")
earnings.Accrue(p,101199)
check(p.OfflineEarnings.PendingMoney==6000 and p.OfflineEarnings.PendingSeconds==600, "Ten-minute session earns its complete duration")
earnings.Accrue(p,101199)
check(p.OfflineEarnings.PendingMoney==6000, "Same timestamp never duplicates")
earnings.Accrue(p,101100)
check(p.OfflineEarnings.PendingMoney==6000, "Negative elapsed grants nothing")
check(p.OfflineEarnings.CheckpointAt==101199, "Clock rollback does not reopen credited interval")
earnings.Accrue(p,500000)
check(p.OfflineEarnings.PendingMoney==864000 and p.OfflineEarnings.PendingSeconds==86400, "24h cap includes uncollected visits")
local before=p.Money
check(earnings.Collect(p)==864000 and p.Money==before+864000, "Collect moves exact reward")
check(earnings.Collect(p)==0 and p.Money==before+864000, "Duplicate collect grants zero")
check(schema.Validate(p), "Collected profile validates")
p.Inventory.qa.Broken=true;p.Inventory.qa.BreakId="break"
check(earnings.Rate(p)==1, "Broken pets earn 10 percent")
p.Inventory.qa.Placed=false;p.Inventory.qa.PlotSlot=nil;p.PlacedPetIds={}
check(earnings.Rate(p)==0, "Stored pets earn nothing")
local legacy=profile();legacy.DataVersion=13;legacy.OfflineEarnings=nil
local migrated=assert(schema.Migrate(legacy))
check(migrated.DataVersion==14 and migrated.OfflineEarnings.CheckpointAt==0, "v13 migration starts without backpay")
local detached=assert(schema.Migrate(migrated));detached.OfflineEarnings.PendingMoney=5
check(migrated.OfflineEarnings.PendingMoney==0, "Ledger save clone is independent")
for _,bad in {0/0, math.huge, -1} do
	local invalid=profile();invalid.OfflineEarnings.PendingMoney=bad
	check(not schema.Validate(invalid), "Reject nonfinite/negative ledger: "..tostring(bad))
end

local function signal()
	local s={listeners={}}
	function s:Connect(fn) table.insert(self.listeners,fn);return {Disconnect=function()end} end
	function s:Fire(...) for _,fn in self.listeners do fn(...) end end
	return s
end
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers() return {} end
function players:GetPlayerByUserId() return nil end
local player={UserId=998877,Name="OfflineQA",Parent=players,attributes={}}
function player:SetAttribute(k,v) self.attributes[k]=v end
function player:Kick(reason) error("Unexpected kick: "..reason) end
local jobs,store={},{}
local now,failMode=1000000,nil
local adapter={IsMemory=function()return true end,GetStoreName=function()return "DetachedOfflineQA" end}
function adapter.UpdateAsync(key,transform)
	if failMode=="before" then failMode=nil;return false,nil,"Simulated failure" end
	local nextValue=transform(copy(store[key]))
	if nextValue then store[key]=copy(nextValue) end
	if failMode=="after" then failMode=nil;return false,nil,"Simulated lost acknowledgement" end
	return true,copy(store[key]),nil
end
local config=table.clone(require(game.ReplicatedStorage.Shared.Config.DataConfig))
local fakeGame={JobId="offline-qa",PlaceId=0,ReplicatedStorage=game.ReplicatedStorage}
function fakeGame:GetService(name) return if name=="Players" then players else game:GetService(name) end
function fakeGame:BindToClose(fn) self.shutdown=fn end
local data=load(server.Services.DataService,{
	game=fakeGame,os={time=function()return now end},
	task={spawn=function(fn)table.insert(jobs,fn)end,defer=function(fn)table.insert(jobs,fn)end,wait=function()end},
	require=function(module)
		if module==server.Data.DataStoreAdapter then return adapter end
		if module==server.Data.PlayerDataSchema then return schema end
		if module==server.Data.OfflineEarnings then return earnings end
		if module==game.ReplicatedStorage.Shared.Config.DataConfig then return config end
		return require(module)
	end,
})
data.Start();table.clear(jobs) -- never start the real-time autosave loop
local function join()
	players.PlayerAdded:Fire(player)
	assert(#jobs==1);table.remove(jobs,1)()
	return assert(data.GetData(player))
end
local loaded=join()
loaded.Inventory=profile().Inventory;loaded.PlacedPetIds={qa=true}
players.PlayerRemoving:Fire(player)
now+=3600;failMode="after"
loaded=join()
check(loaded.OfflineEarnings.PendingMoney==36000, "Session acquisition retry grants exactly once")
local key=config.PlayerKeyPrefix..player.UserId
check(store[key].Data.OfflineEarnings.PendingMoney==36000, "Reward persisted before profile becomes available")
local service=load(server.Services.OfflineIncomeService,{game=fakeGame,require=function(module)
	if module==server.Services.DataService then return data end
	if module==server.Data.OfflineEarnings then return earnings end
	return require(module)
end})
before=loaded.Money
local locks=require(server.Services.FeedLocks)
assert(locks.Begin(player,"OtherTransaction"))
check(service.Collect(player).Code=="Busy" and loaded.Money==before, "Other transactions block collection without touching balance")
locks.Finish(player)
failMode="before"
check(not service.Collect(player).Ok, "Failed claim save requests retry")
check(loaded.Money==before+36000 and loaded.OfflineEarnings.PendingMoney==0, "In-memory claim is atomic")
local result=service.Collect(player)
check(result.Ok and result.Amount==36000 and loaded.Money==before+36000, "Retry confirms without granting again")
check(service.Collect(player).Amount==0, "Repeated server collect is idempotent")
check(store[key].Data.Money==loaded.Money and store[key].Data.OfflineEarnings.PendingMoney==0, "Balance and cleared ledger persist together")
-- Online time cannot become offline reward: save/leave checkpoints advance.
now+=7200;players.PlayerRemoving:Fire(player)
now+=599;loaded=join()
check(loaded.OfflineEarnings.PendingMoney==0, "Short relog earns nothing")
players.PlayerRemoving:Fire(player)
now+=600;loaded=join()
check(loaded.OfflineEarnings.PendingMoney==6000, "Eligible relog earns full ten minutes")
before=loaded.Money;failMode="after"
check(not service.Collect(player).Ok, "Ambiguous committed claim asks for retry")
check(service.Collect(player).Ok and loaded.Money==before+6000, "Ambiguous-save retry cannot duplicate currency")
now+=5;assert(data.Save(player))
check(store[key].Data.OfflineEarnings.CheckpointAt==now, "Autosave refreshes durable crash checkpoint")
players.PlayerRemoving:Fire(player)
now+=86400*3;loaded=join()
check(loaded.OfflineEarnings.PendingMoney==864000, "Real load path caps a three-day absence to one day")
players.PlayerRemoving:Fire(player)
now+=86400;loaded=join()
check(loaded.OfflineEarnings.PendingMoney==864000, "Uncollected reward survives rejoin without exceeding cap")
check(schema.Validate(loaded), "Final persistence profile validates")
players.PlayerRemoving:Fire(player)

-- Run the actual controller with deterministic menu/button signals, network
-- replies and sound spy. No real player UI, audio or persistence is modified.
local client=game.StarterPlayer.StarterPlayerScripts.Client
local queue,sounds,requests={},{},{}
local reply={Ok=true,PendingMoney=36000,PendingSeconds=3600,Rate=10,MinimumSeconds=600,MaxSeconds=86400}
local collectSignal=signal()
local view={Gui={Parent=true},Popup={Visible=false,Duration={}},Collect={Activated=collectSignal}}
function view.Show(state)view.Popup.Visible=true;view.shown=state end
function view.Menu(open,state)view.menuOpen=open;view.menuState=state end
local fakeGui={}
local localPlayer={}
function localPlayer:WaitForChild()return fakeGui end
function localPlayer:GetAttribute()return true end
local remote={}
function remote:InvokeServer(action)table.insert(requests,action);return reply end
local replicated={}
function replicated:WaitForChild()return remote end
local guiService={MenuIsOpen=false,MenuOpened=signal(),MenuClosed=signal()}
local controllerGame={}
function controllerGame:GetService(name)
	if name=="Players" then return {LocalPlayer=localPlayer} end
	if name=="ReplicatedStorage" then return replicated end
	if name=="GuiService" then return guiService end
	return game:GetService(name)
end
local controller=load(client.Controllers.OfflineIncomeController,{
	game=controllerGame,task={spawn=function(fn)table.insert(queue,fn)end,wait=function()end},
	require=function(module)
		if module==client.UI.OfflineIncome then return {Create=function()return view end} end
		if module==client.Audio.GameSounds then return {Preload=function()end,Play=function(name)table.insert(sounds,name)end} end
		return require(module)
	end,
})
controller.Start();controller.Start()
check(#queue==1, "Controller startup is idempotent")
table.remove(queue,1)()
check(view.Popup.Visible and view.shown.PendingMoney==36000, "Controller requests pending reward after data load")
guiService.MenuOpened:Fire();table.remove(queue,1)()
check(view.menuOpen and view.menuState.Rate==10, "MenuOpened refreshes server estimate and shows reminders")
guiService.MenuClosed:Fire()
check(not view.menuOpen, "MenuClosed hides reminders")
reply={Ok=false,Error="Save unavailable"};collectSignal:Fire()
check(view.Popup.Visible and view.Collect.Text=="RETRY COLLECT" and #sounds==0, "Failed collection keeps popup and plays no success sound")
reply={Ok=true,Amount=36000};collectSignal:Fire()
check(not view.Popup.Visible and sounds[1]=="Buy" and #sounds==1, "Collect callback closes popup and plays Buy once")
collectSignal:Fire()
check(#sounds==1, "Late duplicate activation cannot replay collection sound")
check(requests[#requests]=="Collect", "Collect sends an action only, never a client reward amount")
return {passed=true,checks=checks,count=#checks}
