-- Run with test-broken-pet-local.ps1 -TestPath docs/studio/test-income-merchant.luau
-- Detached profiles; production server/controller sources, no real purchases.
local root=game.ServerScriptService.Server
local shared=game.ReplicatedStorage.Shared
local client=game.StarterPlayer.StarterPlayerScripts.Client
local cache,deps={},{}
local function signal()
	local callbacks={}
	return {Connect=function(_,fn)table.insert(callbacks,fn)end,
		Fire=function(...)for _,fn in callbacks do fn(...)end end}
end
local function node(class)
	local n={ClassName=class,children={}}
	function n:FindFirstChild(name)return self.children[name]end
	return setmetatable(n,{__newindex=function(t,k,v)
		rawset(t,k,v);if k=="Parent" and v then v.children[t.Name]=t end
	end})
end
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
local player=node("Player");player.Name="TestPlayer";rawset(player,"Parent",players)
players.GetPlayers=function()return {player}end
local available,hasPlot,multiplier=true,true,1
local serialized={};local serial=0
local function clone(v)if type(v)~="table" then return v end;local c={};for k,x in v do c[k]=clone(x)end;return c end
local http={JSONEncode=function(_,v)serial+=1;local key="json-"..serial;serialized[key]=clone(v);return key end,
	JSONDecode=function(_,s)return clone(assert(serialized[s]))end}
local fakeGame={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
	if name=="Players" then return players elseif name=="HttpService" then return http end
	return game:GetService(name)
end}
local clock,now=0,100000
local pos=setmetatable({},{__sub=function()return {Magnitude=0}end})
local point={Position=pos,IsA=function()return true end}
local fakeWorkspace={FindFirstChild=function()return {FindFirstChild=function()return point end}end}
player.Character={FindFirstChild=function()return {Position=pos}end,FindFirstChildOfClass=function()return {Health=100}end}
local background={}
local function fresh(module)
	if deps[module] then return deps[module] end
	if cache[module] then return cache[module] end
	local fn=assert(loadstring(module.Source,"@"..module.Name))
	setfenv(fn,setmetatable({script=module,require=fresh,game=fakeGame,workspace=fakeWorkspace,
		os={time=function()return now end,clock=function()clock+=2;return clock end},
		Instance={new=node},task={spawn=function(f)table.insert(background,f)end,wait=function()error("Unexpected background wait")end},
	},{__index=getfenv()}))
	cache[module]=fn();return cache[module]
end
local Schema=fresh(root.Data.PlayerDataSchema)
local profile=Schema.CreateDefault();profile.Money=1e8;profile.Settings.TutorialStep="Done"
local locked=false
deps[root.Services.DataService]={GetData=function()return if available then profile else nil end,Save=function()return true end}
deps[root.Services.PlotService]={GetPlot=function()return if hasPlot then {} else nil end}
deps[root.Services.MonetizationService]={Multiplier=function()return multiplier end}
deps[root.Services.FeedLocks]={IsLocked=function()return locked end,Begin=function()if locked then return false end;locked=true;return true end,Finish=function()locked=false end}
local Money=fresh(root.Services.MoneyService)
local Leaderboard=fresh(root.Services.LeaderboardService)
local MoneyConfig=fresh(shared.Config.MoneyConfig)
local def=fresh(shared.Config.PetConfig).Species.test_rare
local pet={DataVersion=2,PetId="rank-pet",SpeciesId="test_rare",EggId="prototype_egg",Rarity=def.Rarity,
	Variant="Rainbow",Traits={},FeedLevel=3,BaseIncome=def.BaseIncome,Locked=false,Placed=true,PlotSlot=1,CreatedAt=1}
profile.Inventory[pet.PetId]=pet;profile.PlacedPetIds[pet.PetId]=true
assert(Schema.Validate(profile))
local rate=fresh(shared.PetIncome)(pet)
Leaderboard.Start();Leaderboard.Start()
local stats=assert(player:FindFirstChild("leaderstats"));local score=assert(stats:FindFirstChild("Money/s"))
assert(score.ClassName=="NumberValue" and score:FindFirstChild("IsPrimary").Value==true and score.Value==rate)
assert(#background==1,"Leaderboard started twice")
multiplier=2;Leaderboard.Update(player)
assert(score.Value==rate and Money.GetRate(player)==rate*2,"Paid multiplier affected rank")
local balance=profile.Money;assert(Money.Tick(player)==rate*2*MoneyConfig.TickSeconds)
assert(profile.Money==balance+rate*2*MoneyConfig.TickSeconds,"Payout lost x2")
pet.Broken=true;pet.BreakId="episode";Leaderboard.Update(player)
assert(score.Value==rate*.1,"Broken penalty missing from rank")
pet.FeedLevel=4;Leaderboard.Update(player);assert(score.Value==fresh(shared.PetIncome)(pet))
pet.Broken=nil;pet.BreakId=nil;Leaderboard.Update(player);assert(score.Value==fresh(shared.PetIncome)(pet))
profile.PlacedPetIds={};pet.Placed=false;pet.PlotSlot=nil;Leaderboard.Update(player);assert(score.Value==0)
profile.PlacedPetIds[pet.PetId]=true;pet.Placed=true;pet.PlotSlot=1
for _,reason in {"loading","plot"} do
	available=reason~="loading";hasPlot=reason~="plot";Leaderboard.Update(player);assert(score.Value==0)
end
available=true;hasPlot=true
rawset(player,"Parent",nil);Leaderboard.Update(player);assert(score.Value==0);rawset(player,"Parent",players)
print("PASS: native leaderstats, numeric primary stat, no x2 rank bonus, x2 payouts unchanged, damage/repair/upgrades/removal/loading/plot")

local State=fresh(root.Services.CommerceState)
local Shop=fresh(shared.Config.MerchantConfig)
local Merchant=fresh(root.Services.MerchantService)
local stock,_,items=State.Stock(profile,now)
local slot=2;local itemId=items[slot];local item=Shop.Items[itemId]
local before=Merchant.HandleRequest(player,"Snapshot").Items[slot]
assert(before.Remaining==1 and not before.Purchased and not before.Reserved)
local intent={Kind="Food",ItemId=itemId,Stock=stock,Slot=slot,ProductId=1}
local state=State.Read(profile);state.Pending=intent;State.Write(profile,state)
local reserved=Merchant.HandleRequest(player,"Snapshot").Items[slot]
assert(reserved.Remaining==1 and not reserved.Purchased and reserved.Reserved,"Open prompt displayed sold-out stock")
local beforeMoney=profile.Money
local attempt=Merchant.HandleRequest(player,"Purchase",slot,stock,1)
assert(not attempt.Ok and attempt.Code=="PurchasePending" and profile.Money==beforeMoney,"Money bypassed paid reservation")
state.Pending=nil;State.Write(profile,state)
local canceled=Merchant.HandleRequest(player,"Snapshot").Items[slot]
assert(canceled.Remaining==1 and not canceled.Purchased and not canceled.Reserved)
state.Pending=intent;State.Write(profile,state)
assert(State.Grant(profile,state,intent,now));state.Pending=nil;State.Write(profile,state)
local bought=Merchant.HandleRequest(player,"Snapshot").Items[slot]
assert(bought.Remaining==0 and bought.Purchased and not bought.Reserved,"Fulfilled food was not sold out")
assert(Merchant.HandleRequest(player,"Purchase",slot,stock,1).Code=="Sold")
now+=Shop.RestockSeconds
local rotated=Merchant.HandleRequest(player,"Snapshot").Items[slot]
assert(rotated.Remaining==1 and not rotated.Purchased)
print("PASS: prompt reserves without reducing displayed stock, money race blocked, cancel restores availability, fulfillment consumes stock, rotation")

-- Exercise actual merchant render/handlers using minimal UI/signal doubles.
local attrs={PaidRandomPolicyStatus="Allowed"}
player.GetAttribute=function(_,k)return attrs[k]end
player.SetAttribute=function(_,k,v)attrs[k]=v end
player.GetAttributeChangedSignal=function()return signal()end
local function ui()
	local o={Activated=signal(),ButtonText={},ImageColor3={},BackgroundColor3={},Parent=true,Visible=true}
	o.SetAttribute=function()end;o.GetPropertyChangedSignal=function()return signal()end
	return o
end
local panel=ui();panel.Offers={};panel.Status={};panel.Money={};panel.Restock={};panel.RestockBuy=ui();panel.Close=ui()
for i=1,3 do
	local row=ui();row.BuyRobux=ui();row.BuyMoney=ui();row.ItemName={};row.Stock={};row.RarityBadge=ui()
	row.Price={};row.Effect={};row.Art={Emoji={},Picture={}};panel.Offers["Slot"..i]=row
end
local gui=ui();gui.Panel=panel
local pg={WaitForChild=function()return gui end,FindFirstChild=function()return nil end}
player.WaitForChild=function()return pg end;players.LocalPlayer=player
local snapshot=Merchant.HandleRequest(player,"Snapshot")
local remote={InvokeServer=function()return snapshot end}
local storage={Shared=shared,WaitForChild=function(_,name)if name=="Shared" then return {WaitForChild=function(_,key)return shared[key]end}end;return remote end}
local tasks={};local purchases=0
local overrides={
	[client.UI.Purchases]={Request=function()purchases+=1 end},
	[client.UI.IconImages]={},[client.UI.ImageArt]={Set=function()end},[client.UI.DeviceLayout]={Apply=function()end},
}
-- The local source bundler omits Audio; supply its path only for dependency lookup.
client.Audio=client.Audio or {};client.Audio.GameSounds=client.Audio.GameSounds or {}
overrides[client.Audio.GameSounds]={PurchaseResult=function()end}
local fn=assert(loadstring(client.Controllers.MerchantController.Source))
setfenv(fn,setmetatable({script=client.Controllers.MerchantController,require=function(m)return overrides[m] or fresh(m)end,
	game={ReplicatedStorage=storage,GetService=function(_,name)
		if name=="Players" then return players elseif name=="ReplicatedStorage" then return storage
		elseif name=="ProximityPromptService" then return {PromptTriggered=signal()} end;return game:GetService(name)
	end},task={spawn=function(f)table.insert(tasks,f)end},os={clock=function()return clock end},
},{__index=getfenv()}))
fn().Start();local refresh=tasks[1];table.clear(tasks);refresh()
local row
for i=1,3 do if panel.Offers["Slot"..i].ItemName.Text==snapshot.Items[2].Name then row=panel.Offers["Slot"..i] end end
assert(row and row.BuyMoney.Active and row.BuyRobux.Active)
local normalColor=row.BuyRobux.ImageColor3
snapshot.Items[2].Reserved=true;refresh()
assert(row.Stock.Text=="X1 stock" and row.BuyMoney.ButtonText.Text~="SOLD OUT" and row.BuyRobux.ButtonText.Text~="SOLD OUT")
assert(not row.BuyMoney.Active and not row.BuyRobux.Active and row.BuyRobux.ImageColor3==normalColor)
row.BuyRobux.Activated.Fire();row.BuyMoney.Activated.Fire();assert(purchases==0 and #tasks==0)
snapshot.Items[2].Reserved=false;refresh();assert(row.BuyMoney.Active and row.BuyRobux.Active)
snapshot.Items[2].Purchased=true;snapshot.Items[2].Remaining=0;refresh()
assert(row.Stock.Text=="X0 stock" and row.BuyMoney.ButtonText.Text=="SOLD OUT" and row.BuyRobux.ButtonText.Text=="SOLD OUT")
print("PASS: real merchant UI retains stock/price/colors during reservation, blocks repeat clicks, cancel enables, receipt shows SOLD OUT")
