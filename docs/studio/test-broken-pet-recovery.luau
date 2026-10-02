-- Detached profiles only: exercise the real Feed -> recovery -> UI -> income ->
-- revive code without changing a live player's save or making any purchases.
assert(not game:GetService("RunService"):IsRunning(),"Edit-only test")
local root=game.ServerScriptService.Server
local shared=game.ReplicatedStorage.Shared
local client=game.StarterPlayer.StarterPlayerScripts.Client
local cache,deps={},{}
local function fresh(module)
	if deps[module] then return deps[module] end
	if cache[module] then return cache[module] end
	local fn=assert(loadstring(module.Source,"@"..module.Name))
	setfenv(fn,setmetatable({script=module,require=fresh},{__index=getfenv()}))
	cache[module]=fn();return cache[module]
end
local Schema=fresh(root.Data.PlayerDataSchema)
local Config=fresh(shared.Config.ReviveConfig)
assert(Config.BrokenIncomeMultiplier==0.1 and Config.BrokenIncomeLabel=="10% INCOME")
local PetIncome=fresh(shared.PetIncome)
local profile=Schema.CreateDefault()
assert(profile.Money==2000 and fresh(shared.Config.EggConfig).Definitions.prototype_egg.Price==2000)
local players={}
local now,clock=100000,0
local point=workspace.ReviveMachine.InteractionPoint
local rootPart={Position=point.Position}
local humanoid={Health=100}
local attrs={}
local player={Parent=players,UserId=123,SetAttribute=function(_,k,v)attrs[k]=v end}
player.Character={FindFirstChild=function(_,name)return if name=="HumanoidRootPart" then rootPart else nil end,
	FindFirstChildOfClass=function()return humanoid end}
local locked=false
local saves,persisted=0,nil
local delayed={}
local depsData={GetData=function(p)return if p==player then profile else nil end,
	Save=function()saves+=1;persisted=assert(Schema.Migrate(profile));return true end}
deps[root.Services.DataService]=depsData
deps[root.Services.FeedLocks]={IsLocked=function()return locked end,
	Begin=function()if locked then return false end;locked=true;return true end,Finish=function()locked=false end}
local pet={DataVersion=2,PetId="recovery-test",SpeciesId="test_rare",EggId="prototype_egg",Rarity="Uncommon",Variant="Rainbow",
	Traits={},FeedLevel=20,BaseIncome=fresh(shared.Config.PetConfig).Species.test_rare.BaseIncome,Locked=true,Placed=false,CreatedAt=5}
local old=Schema.CreateDefault();old.DataVersion=12
old.PendingRecovery[pet.PetId]={Pet=table.clone(pet),AttemptId="legacy-paid",ExplodedAt=1,FoodSpent=1}
local migrated=assert(Schema.Migrate(old))
assert(migrated.Inventory[pet.PetId].Broken and migrated.Inventory[pet.PetId].BreakId=="legacy-paid")
assert(migrated.Inventory[pet.PetId].FeedLevel==20 and next(migrated.PendingRecovery)==nil)
assert(old.PendingRecovery[pet.PetId].Pet.Broken==nil and old.Inventory[pet.PetId]==nil,"Migration mutated old save")
local conflict=table.clone(old);conflict.Inventory={[pet.PetId]=pet}
assert(Schema.Migrate(conflict)==nil,"Migration silently overwrote a conflicting pet")
profile.Inventory[pet.PetId]=pet;profile.Food=4;profile.ReviveCharges=1
profile.Settings.TutorialStep="Done"
local expected=PetIncome(pet)*Config.BrokenIncomeMultiplier
local multiplier=1
deps[root.Services.PlotService]={GetPlot=function()return {} end}
deps[root.Services.MonetizationService]={Multiplier=function()return multiplier end}
deps[root.Services.CarryService]={GetPetId=function()return nil end,GetEggId=function()return nil end}
deps[root.Services.PlacementService]={}
deps[root.Services.PedestalService]={GetFeedPet=function()return profile.Inventory[pet.PetId] end,
	GetPetId=function()return nil end,BeginPresentation=function()return CFrame.new() end,EndPresentation=function()end}
local forced="Explosion"
deps[root.Services.DebugFeedOverrides]={Resolve=function(_,_,level)return {Code=forced,FeedLevel=if forced=="Success" then level+1 else level,Gain=if forced=="Success" then 1 else 0} end,Consume=function()end}
deps[root.Services.PetService]={GetInventory=function()return assert(Schema.Migrate(profile)).Inventory end}
local fakeGame={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
	return if name=="Players" then players else game:GetService(name)
end}
local function service(module)
	local fn=assert(loadstring(module.Source,"@"..module.Name))
	setfenv(fn,setmetatable({script=module,game=fakeGame,require=fresh,
		os={time=function()return now end,clock=function()clock+=1;return clock end},
		task={spawn=function(f,...)f(...)end,delay=function(_,f)table.insert(delayed,f)end,wait=function()error("Unexpected save retry")end},
	},{__index=getfenv()}))
	local value=fn();deps[module]=value;return value
end
local Money=service(root.Services.MoneyService)
local Feed=service(root.Services.FeedService)
local Revive=service(root.Services.ReviveService)
local UI=service(root.Services.UIService)
local result=Feed.HandleRequest(player,"Feed",pet.PetId,1,"basic")
assert(result.Accepted and result.Code=="Explosion",tostring(result.Code))
assert(profile.Inventory[pet.PetId]==pet and pet.Broken and pet.FeedLevel==20 and next(profile.PendingRecovery)==nil)
assert(profile.Food==3 and locked and saves==1)
assert(Feed.HandleRequest(player,"Feed",pet.PetId,1,"basic").AttemptId==result.AttemptId and profile.Food==3)
local function finish() local callbacks=delayed;delayed={};for _,f in callbacks do f() end end
finish()
assert(not locked and Schema.Validate(profile))
assert(Money.GetRate(player)==0,"Stored broken pets must not bypass pen capacity")
local function place() local p=profile.Inventory[pet.PetId];p.Placed=true;p.PlotSlot=1;profile.PlacedPetIds[pet.PetId]=true end
local function pickup() local p=profile.Inventory[pet.PetId];p.Placed=false;p.PlotSlot=nil;profile.PlacedPetIds[pet.PetId]=nil end
place()
assert(Money.GetRate(player)==expected,"Broken income must equal 10% of the pre-failure rate")
local previous=profile.Money
local paid=Money.Tick(player)
assert(paid==expected*fresh(shared.Config.MoneyConfig).TickSeconds and profile.Money==previous+paid)
multiplier=2;assert(Money.GetRate(player)==expected*2)
assert(Money.GetBaseRate(player)==expected,"Leaderboard/base income includes x2 pass")
multiplier=1
local snap=Revive.HandleRequest(player,"Snapshot")
assert(snap.Ok and #snap.Records==1 and snap.Records[1].Income==expected and snap.Records[1].RestoredIncome==expected/Config.BrokenIncomeMultiplier)
local inventory=UI.HandleRequest(player,"Snapshot")
assert(inventory.Inventory[pet.PetId].Broken)
local Inventory=fresh(client.UI.InventoryModel)
assert(Inventory.Entries(inventory)["pet:"..pet.PetId]==nil,"Placed pets remain in pen UI")
pickup();inventory=UI.HandleRequest(player,"Snapshot")
local entry=Inventory.Entries(inventory)["pet:"..pet.PetId]
assert(entry and entry.Broken and entry.Income==expected and Inventory.CanSlot(entry),"Broken pet must remain usable")
assert(Schema.Validate(persisted) and persisted.Inventory[pet.PetId].BreakId==result.AttemptId)
profile=assert(Schema.Migrate(persisted))
now+=86400*365;place()
assert(Money.GetRate(player)==expected,"Break expired or lost its reduced income rate")
pickup()
forced="Success"
assert(Feed.HandleRequest(player,"Feed",pet.PetId,2,"basic").Accepted);finish()
assert(profile.Inventory[pet.PetId].FeedLevel==21 and profile.Inventory[pet.PetId].Broken,"Broken pet could not upgrade")
forced="Explosion"
assert(Feed.HandleRequest(player,"Feed",pet.PetId,3,"basic").Accepted);finish()
assert(profile.Inventory[pet.PetId].FeedLevel==21 and profile.Inventory[pet.PetId].BreakId==result.AttemptId,"Repeated break reset progress/episode")
expected=PetIncome(profile.Inventory[pet.PetId])
assert(expected==fresh(shared.Config.PetConfig).Species.test_rare.BaseIncome*fresh(shared.Config.FeedConfig).Multiplier[21]*5*Config.BrokenIncomeMultiplier,"Damage penalty stacked")
local foreign={Parent=players}
assert(not Revive.HandleRequest(foreign,"Revive",pet.PetId,result.AttemptId).Ok)
assert(Revive.HandleRequest(player,"Revive",pet.PetId,"old-attempt").Code=="PetChanged")

-- Run the actual client controller on a detached clone and mocked remotes.
-- This catches missing cards, render exceptions and automatic selection.
if not RECOVERY_HEADLESS then
local gui=game.StarterGui.ReviveUI:Clone()
local pg=Instance.new("Folder");pg.Name="PlayerGui";gui.Parent=pg
player.PlayerGui=pg;player.WaitForChild=function(_,name)assert(name=="PlayerGui");return pg end
players.LocalPlayer=player
local queue={}
local responseMode,previewFails=nil,false
local realPreview=fresh(client.UI.ItemPreview)
local env=setmetatable({script=client.Controllers.ReviveController,
	require=function(module)
		if module==client.UI.Purchases then return {Request=function()error("No purchases in test")end} end
		if module==client.UI.ItemPreview then return {Set=function(...)
			if previewFails then error("Simulated unavailable preview") end
			return realPreview.Set(...)
		end} end
		return fresh(module)
	end,
	game={GetService=function(_,name)
		if name=="Players" then return players end
		if name=="ReplicatedStorage" then return {Shared=shared,WaitForChild=function()
			return {InvokeServer=function(_,...)
				if responseMode=="nil" then return nil end
				if responseMode=="error" then error("Simulated dropped reply") end
				return Revive.HandleRequest(player,...)
			end} end} end
		if name=="ProximityPromptService" then return {PromptTriggered={Connect=function()end}} end
		return game:GetService(name)
	end},
	task={spawn=function(f)table.insert(queue,f)end,delay=function()end},
},{__index=getfenv()})
local fn=assert(loadstring(client.Controllers.ReviveController.Source));setfenv(fn,env)
local controller=fn()
local ok,err=xpcall(function()
	controller.Start();table.clear(queue) -- do not start the background polling loop
	assert(controller.Open());table.remove(queue,1)()
	local panel=gui.Panel
	assert(panel.Pets:FindFirstChild(result.AttemptId) and panel.Pets[result.AttemptId].Visible,"Broken pet missing at machine")
	assert(panel.PetName.Text~="SELECT A BROKEN PET" and panel.Details.Text:find("AFTER REPAIR"),"Automatic selection failed")
	assert(panel.Title.Text=="PET REPAIR STATION" and not panel.Details.Text:find("remaining"),"Old timer still shown")
	assert(panel.PetPreview.World:FindFirstChildOfClass("Model"),"Broken pet preview missing")
	assert(controller.ShowTab("Exchange") and panel.ExchangePanel.Visible and not panel.Pets.Visible)
	assert(controller.ShowTab("Broken") and panel.Pets[result.AttemptId].Visible)
	assert(panel.Pets.ZIndex>panel.PageTexture.ZIndex,"Background covers repair list")
	assert(panel.Pets[result.AttemptId].Text:find("10%% INCOME"),"Stale broken income label")
	local function reopen()
		panel.Visible=false;assert(controller.Open())
		while #queue>0 do table.remove(queue,1)() end
	end
	-- Empty first visit must not hide a pet that breaks later in the session.
	local damaged=profile.Inventory[pet.PetId];local breakId=damaged.BreakId
	damaged.Broken=nil;damaged.BreakId=nil;reopen()
	assert(panel.Empty.Visible and not panel.Pets:FindFirstChild(breakId))
	damaged.Broken=true;damaged.BreakId=breakId;reopen()
	assert(panel.Pets[breakId].Visible and not panel.Empty.Visible)
	for _,mode in {"nil","error"} do
		responseMode=mode;reopen()
		assert(panel.Pets[breakId].Visible,"Transient reply deleted known broken pet")
	end
	responseMode=nil;previewFails=true;reopen()
	assert(panel.Pets[breakId].Visible,"Preview failure hid broken pet")
	previewFails=false;reopen()
	assert(panel.Status.Text=="" and panel.PetPreview.World:FindFirstChildOfClass("Model"))
	local layout=fresh(client.UI.DeviceLayout)
	for _,size in {Vector2.new(390,844),Vector2.new(844,390),Vector2.new(1368,630)} do
		layout.Apply(panel,size,"Revive")
		local exchange=panel.ExchangePanel
		assert(exchange.RewardIcon.AnchorPoint==Vector2.zero)
		assert(exchange.ShardTitle.Position.Y.Offset+exchange.ShardTitle.Size.Y.Offset<exchange.RewardIcon.Position.Y.Offset,"Artwork overlaps title")
		assert(exchange.RewardIcon.Position.Y.Offset+exchange.RewardIcon.Size.Y.Offset<exchange.ShardBalance.Position.Y.Offset,"Artwork overlaps balance")
	end
end,debug.traceback)
pg:Destroy();assert(ok,err)
end

place()
local restored=Revive.HandleRequest(player,"Repair",pet.PetId,result.AttemptId)
assert(restored.Ok and profile.ReviveCharges==0 and profile.Inventory[pet.PetId].FeedLevel==21)
assert(profile.Inventory[pet.PetId].Variant=="Rainbow" and profile.Inventory[pet.PetId].Locked and profile.Food==1)
assert(profile.Inventory[pet.PetId].Placed and profile.PlacedPetIds[pet.PetId] and not profile.Inventory[pet.PetId].Broken)
assert(Money.GetRate(player)==expected/Config.BrokenIncomeMultiplier,"Repair must immediately restore full placed income")
assert(not Revive.HandleRequest(player,"Repair",pet.PetId,result.AttemptId).Ok and profile.ReviveCharges==0)
pickup();assert(Money.GetRate(player)==0)
assert(Feed.HandleRequest(player,"Feed",pet.PetId,4,"basic").Accepted);finish()
assert(profile.Inventory[pet.PetId].BreakId~=result.AttemptId,"New damage reused an old repair ID")
assert(Revive.HandleRequest(player,"Repair",pet.PetId,result.AttemptId).Code=="PetChanged")
profile.ReviveShards=100
assert(Revive.HandleRequest(player,"Exchange",1).Ok and profile.ReviveCharges==1 and profile.ReviveShards==0)
assert(Revive.HandleRequest(player,"Repair",pet.PetId,profile.Inventory[pet.PetId].BreakId).Ok)
assert(not profile.Inventory[pet.PetId].Broken and profile.Food==0 and profile.ReviveCharges==0)
assert(Revive.HandleRequest(player,"KeepBase",pet.PetId,result.AttemptId).Code=="InvalidRequest")
assert(Schema.Validate(profile) and not assert(Schema.Migrate(persisted)).Inventory[pet.PetId].Broken)
print("PASS: v12 migration/conflict safety, usable broken pets, upgrade/repeated failure, permanent 10% placed income, x2, repair current level/placement, shards, replay and new damage ID")
if not RECOVERY_HEADLESS then print("PASS: real ReviveController machine cards, preview, tabs and responsive exchange geometry") end
