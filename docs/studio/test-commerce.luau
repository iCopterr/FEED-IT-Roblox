-- Run in Studio edit mode. Uses detached profiles and mocked payment/data services.
local root=game.ServerScriptService.Server
local realRequire=require
local Schema=realRequire(root.Data.PlayerDataSchema)
local State=realRequire(root.Services.CommerceState:Clone())
local Config=realRequire(game.ReplicatedStorage.Shared.Config.MonetizationConfig)
local Shop=realRequire(game.ReplicatedStorage.Shared.Config.MerchantConfig)
local profiles={}
local events={}
local function signal(name)
 return {Connect=function(_,callback) events[name]=callback end}
end
local players={PlayerAdded=signal("Joined"),PlayerRemoving=signal("Left")}
local attrs={}
local player={UserId=123,Parent=players,SetAttribute=function(_,k,v)attrs[k]=v end}
players.GetPlayerByUserId=function(_,id)return if id==123 then player else nil end
players.GetPlayers=function()return {} end
local market={PromptProductPurchaseFinished=signal("ProductFinished"),PromptGamePassPurchaseFinished=signal("PassFinished")}
local promptCount=0
market.PromptProductPurchase=function()promptCount+=1 end
market.PromptGamePassPurchase=function()promptCount+=1 end
market.UserOwnsGamePassAsync=function()return true end
local clock=0
local locked=false
local saves,failures=0,0
local persisted
local data=Schema.CreateDefault()
profiles[player]=data
local memory=false
local studio=false
local deps={
 [root.Services.DataService]={
 GetData=function(p)return profiles[p] end,
 IsLoaded=function(p)return profiles[p]~=nil end,
 Save=function(p)
  saves+=1
  if failures>0 then failures-=1;return false end
  persisted=assert(Schema.Migrate(profiles[p]));return true
 end},
 [root.Data.DataStoreAdapter]={IsMemory=function()return memory end},
 [root.Services.FeedLocks]={
 Begin=function()if locked then return false end;locked=true;return true end,
 Finish=function()locked=false end,IsLocked=function()return locked end},
 [root.Services.CommerceState]=State,
}
local env=setmetatable({
 script=root.Services.MonetizationService,
 require=function(module)return deps[module] or realRequire(module) end,
 game={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
  if name=="Players" then return players elseif name=="MarketplaceService" then return market end
  if name=="RunService" then return {IsStudio=function()return studio end} end
  return game:GetService(name)
 end},
 os={time=os.time,clock=function()clock+=2;return clock end},
 task={wait=function()end,spawn=function(f,...)f(...)end},
 Instance={new=function()return {FireClient=function()end} end},
},{__index=getfenv()})
local fn=assert(loadstring(root.Services.MonetizationService.Source))
setfenv(fn,env)
local service=fn()
service.Start()
local function receipt(id,product)
 return service.ProcessReceipt({PlayerId=123,PurchaseId=id,ProductId=product})
end
local yes=Enum.ProductPurchaseDecision.PurchaseGranted
local no=Enum.ProductPurchaseDecision.NotProcessedYet
local function reset()
 data=Schema.CreateDefault();profiles[player]=data;locked=false
end
local cash=Config.MoneyPacks[1]
assert(service.Request(player,"Product",cash.ProductId).Ok)
assert(State.Read(data).Pending.ProductId==cash.ProductId and persisted.Settings.CommerceV1)
assert(not service.Request(player,"Product",cash.ProductId).Ok)
failures=1
assert(receipt("cash-one",cash.ProductId)==yes)
events.ProductFinished(123,cash.ProductId,true)
assert(data.Money==30000 and saves>=3 and not locked)
assert(receipt("cash-one",cash.ProductId)==yes and data.Money==30000)
profiles[player]=assert(Schema.Migrate(persisted));data=profiles[player]
assert(receipt("cash-one",cash.ProductId)==yes and data.Money==30000)
assert(receipt("unknown",999)==no)
assert(service.Request(player,"Product",Config.WelcomePack.ProductId).Ok)
assert(receipt("welcome",Config.WelcomePack.ProductId)==yes)
events.ProductFinished(123,Config.WelcomePack.ProductId,true)
assert(not service.Request(player,"Product",Config.WelcomePack.ProductId).Ok)
assert(data.Foods.hearty==2 and data.Foods.royal==1 and data.ReviveCharges==1)
assert(receipt("welcome",Config.WelcomePack.ProductId)==yes and data.ReviveCharges==1)
assert(receipt("second-welcome",Config.WelcomePack.ProductId)==no)
reset()
assert(service.Request(player,"Product",cash.ProductId).Ok)
events.ProductFinished(123,cash.ProductId,false)
assert(State.Read(data).Pending==nil and data.Money==5000)
memory=true
assert(not service.Request(player,"Product",cash.ProductId).Ok)
assert(receipt("memory",cash.ProductId)==no)
memory=false
-- Studio memory checkout is allowed; published memory checkout stays blocked.
memory=true;studio=true
assert(service.Request(player,"Product",cash.ProductId).Ok)
assert(receipt("studio-memory",cash.ProductId)==yes)
assert(data.Money==30000)
events.ProductFinished(123,cash.ProductId,true)
assert(service.Request(player,"Pass").Ok)
memory=false;studio=false
assert(service.Multiplier(player)==1)
events.PassFinished(player,Config.DoubleMoney.GamePassId,true)
assert(service.Multiplier(player)==2 and attrs.DoubleMoneyOwned)
-- Reserved food shares the same purchase history and remains grantable after rotation.
reset()
local stock=State.RestockId(data,os.time())
local state=State.Read(data)
state.Pending={Kind="Food",ItemId="hearty",Slot=2,Stock=stock,ProductId=Config.FoodProducts.hearty.ProductId}
State.Write(data,state)
assert(State.Reserved(data,stock,2))
assert(receipt("food",Config.FoodProducts.hearty.ProductId)==yes)
assert(data.Foods.hearty==1 and data.MerchantPurchases["2"]==true)
assert(not State.Reserved(data,stock,2))
assert(receipt("food",Config.FoodProducts.hearty.ProductId)==yes and data.Foods.hearty==1)
-- A received food from an old cycle must never overwrite new-cycle purchases.
reset()
data.MerchantRestockId=stock;data.MerchantPurchases["3"]=true
state=State.Read(data)
state.Pending={Kind="Food",ItemId="royal",Slot=2,Stock=stock-1,ProductId=Config.FoodProducts.royal.ProductId}
State.Write(data,state)
assert(receipt("old-food",Config.FoodProducts.royal.ProductId)==yes)
assert(data.Foods.royal==1 and data.MerchantPurchases["3"] and not data.MerchantPurchases["2"])
-- Grow target may already have been collected; payment is acknowledged without extra reward.
reset()
state=State.Read(data);state.Pending={Kind="Grow",EggUid="gone",ProductId=Config.GrowTiers[1].ProductId}
State.Write(data,state)
assert(receipt("grown",Config.GrowTiers[1].ProductId)==yes and data.Money==5000)
assert(Schema.Validate(data))
-- Verify every mapped product has a receipt path (targeted entries need a reservation).
for _,pack in Config.MoneyPacks do
 reset();assert(receipt("pack-"..pack.Id,pack.ProductId)==yes);assert(data.Money==5000+pack.Money)
end
for _,tier in Config.GrowTiers do
 reset()
 local s=State.Read(data);s.Pending={Kind="Grow",EggUid="already-collected",ProductId=tier.ProductId}
 State.Write(data,s)
 assert(receipt("grow-"..tier.Robux,tier.ProductId)==yes)
 assert(receipt("grow-"..tier.Robux,tier.ProductId)==yes and data.Money==5000)
end
reset()
local pet={DataVersion=realRequire(game.ReplicatedStorage.Shared.Config.GameConfig).PetDataVersion,
 PetId="receipt-pet",SpeciesId="test_common",EggId="prototype_egg",Rarity="Common",Variant="Normal",
 Traits={},FeedLevel=12,BaseIncome=10,Locked=false,Placed=false,CreatedAt=1}
data.PendingRecovery[pet.PetId]={Pet=pet,AttemptId="explosion",ExplodedAt=1,FoodSpent=1}
local s=State.Read(data);s.Pending={Kind="Revive",PetId=pet.PetId,AttemptId="explosion",ProductId=Config.DirectReviveProductId}
State.Write(data,s)
assert(State.ReviveReserved(data,pet.PetId,"explosion"))
assert(receipt("revive",Config.DirectReviveProductId)==yes)
assert(data.Inventory[pet.PetId].FeedLevel==12 and data.PendingRecovery[pet.PetId]==nil)
assert(data.ReviveCharges==0 and data.Food==0)
assert(receipt("revive",Config.DirectReviveProductId)==yes)
assert(Schema.Validate(data))
reset()
pet.FeedLevel=0
data.IncubatingEggs.e={EggId="prototype_egg",Pet=pet,StartedAt=os.time()-1,ReadyAt=os.time()+500,
 HatchSeconds=501,PricePaid=4900,PenPosition={X=0,Z=0}}
s=State.Read(data);s.Pending={Kind="GrowAll",Eggs={"e"},ProductId=Config.GrowAllProductId}
State.Write(data,s)
assert(receipt("all",Config.GrowAllProductId)==yes)
assert(data.IncubatingEggs.e.ReadyAt<=os.time() and data.Inventory[pet.PetId]==nil)
assert(Schema.Validate(data))
reset()
local sourceStock=State.RestockId(data,os.time())
local sourceOffers=Shop.GetStock(sourceStock)
s=State.Read(data);s.Pending={Kind="Restock",SourceStockId=sourceStock,ProductId=Config.PersonalRestockProductId}
State.Write(data,s)
assert(receipt("restock",Config.PersonalRestockProductId)==yes)
local personal,expires,refilled=State.Stock(data,os.time())
assert(personal>=1000000000 and data.MerchantRestockId==personal)
assert(expires==os.time()+Shop.RestockSeconds and table.concat(refilled,"|")==table.concat(sourceOffers,"|"))
assert(receipt("restock",Config.PersonalRestockProductId)==yes and State.RestockId(data,os.time())==personal)
local _,_,_,personalSource=State.Stock(data,os.time())
s=State.Read(data);s.Pending={Kind="Restock",SourceStockId=personalSource,ProductId=Config.PersonalRestockProductId}
State.Write(data,s)
assert(receipt("restock-again",Config.PersonalRestockProductId)==yes)
local personalAgain,_,refilledAgain=State.Stock(data,os.time())
assert(personalAgain>personal and table.concat(refilledAgain,"|")==table.concat(sourceOffers,"|"))
for id,product in Config.FoodProducts do
 reset()
 s=State.Read(data);s.Pending={Kind="Food",ItemId=id,Slot=2,Stock=State.RestockId(data,os.time()),ProductId=product.ProductId}
 State.Write(data,s)
 assert(receipt("food-"..id,product.ProductId)==yes)
 assert(receipt("food-"..id,product.ProductId)==yes)
 assert(if id=="revive" then data.ReviveCharges==1 else data.Foods[id]==1)
 assert(Schema.Validate(data))
end
print("PASS: all 24 products; duplicate/rejoin receipts, save retries, welcome once, cancellation, pass entitlement, food reservations/rotation, grow no-op/timers, expired reserved revive, personal restock, profile validation.")

