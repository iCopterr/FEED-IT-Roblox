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
deps[root.Services.DebugFeedOverrides]={Resolve=function()return {Code="Explosion",FeedLevel=20,Gain=0} end,Consume=function()end}
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
assert(profile.Inventory[pet.PetId]==nil and profile.PendingRecovery[pet.PetId].Pet.FeedLevel==20)
assert(profile.Food==3 and locked and saves==1)
assert(Feed.HandleRequest(player,"Feed",pet.PetId,1,"basic").AttemptId==result.AttemptId and profile.Food==3)
for _,f in delayed do f() end
assert(not locked and Schema.Validate(profile))
assert(Money.GetRate(player)==expected,"Broken income must equal half the pre-failure rate")
local previous=profile.Money
local paid=Money.Tick(player)
assert(paid==expected*fresh(shared.Config.MoneyConfig).TickSeconds and profile.Money==previous+paid)
multiplier=2;assert(Money.GetRate(player)==expected*2);multiplier=1
local snap=Revive.HandleRequest(player,"Snapshot")
assert(snap.Ok and #snap.Records==1 and snap.Records[1].Income==expected and snap.Records[1].RestoredIncome==expected*2)
local inventory=UI.HandleRequest(player,"Snapshot")
assert(#inventory.BrokenPets==1 and next(inventory.Inventory)==nil)
local Inventory=fresh(client.UI.InventoryModel)
local entry=Inventory.Entries(inventory)["pet:"..pet.PetId]
assert(entry and entry.State=="BROKEN" and entry.Income==expected and not Inventory.CanSlot(entry))
assert(Schema.Validate(persisted) and persisted.PendingRecovery[pet.PetId].AttemptId==result.AttemptId)
profile=assert(Schema.Migrate(persisted))
assert(Money.GetRate(player)==expected,"Reconnect lost recovery income")
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
local env=setmetatable({script=client.Controllers.ReviveController,
	require=function(module)
		if module==client.UI.Purchases then return {Request=function()error("No purchases in test")end} end
		return fresh(module)
	end,
	game={GetService=function(_,name)
		if name=="Players" then return players end
		if name=="ReplicatedStorage" then return {Shared=shared,WaitForChild=function()
			return {InvokeServer=function(_,...)return Revive.HandleRequest(player,...)end} end} end
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
	assert(panel.PetName.Text~="SELECT A BROKEN PET" and panel.Details.Text:find("50%%"),"Automatic selection failed")
	assert(panel.PetPreview.World:FindFirstChildOfClass("Model"),"Broken pet preview missing")
	assert(controller.ShowTab("Exchange") and panel.ExchangePanel.Visible and not panel.Pets.Visible)
	assert(controller.ShowTab("Broken") and panel.Pets[result.AttemptId].Visible)
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

local restored=Revive.HandleRequest(player,"Revive",pet.PetId,result.AttemptId)
assert(restored.Ok and profile.ReviveCharges==0 and profile.Inventory[pet.PetId].FeedLevel==20)
assert(profile.Inventory[pet.PetId].Variant=="Rainbow" and profile.Inventory[pet.PetId].Locked and profile.Food==3)
assert(next(profile.PendingRecovery)==nil and Money.GetRate(player)==0,"Stored revived pet must not keep recovery income")
assert(not Revive.HandleRequest(player,"Revive",pet.PetId,result.AttemptId).Ok and profile.ReviveCharges==0)
local savedPet=profile.Inventory[pet.PetId]
profile.Inventory[pet.PetId]=nil
profile.PendingRecovery[pet.PetId]={Pet=savedPet,AttemptId="expiry-test",ExplodedAt=now-Config.WindowSeconds,FoodSpent=1}
assert(Money.GetRate(player)==0,"Expired recovery still earns")
assert(Revive.HandleRequest(player,"Revive",pet.PetId,"expiry-test").Code=="KeptBase")
assert(profile.Inventory[pet.PetId].FeedLevel==0 and profile.ReviveCharges==0 and Schema.Validate(profile))
print("PASS: explosion, replay, persistence/reload, half income/x2/expiry, inventory, revive identity and no double payout; $2K starter/egg")
if not RECOVERY_HEADLESS then print("PASS: real ReviveController machine cards, preview, tabs and responsive exchange geometry") end
