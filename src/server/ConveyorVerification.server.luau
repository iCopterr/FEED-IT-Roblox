if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="ConveyorVerification" and testing:GetTestArgs()~="EggVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local services=script.Parent.Services
	local data=require(services.DataService)
	local conveyor=require(services.ConveyorService)
	local eggs=require(services.EggService)
	local locks=require(services.FeedLocks)
	local pets=require(services.PetService)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	local config=require(game.ReplicatedStorage.Shared.Config.EggConfig)
	local beltConfig=require(game.ReplicatedStorage.Shared.Config.ConveyorConfig)
	assert(adapter.IsMemory(),"Memory-only verification")
	local function check(v,n) assert(v,n);table.insert(checks,n) end
	local function waitFor(f,seconds)
		local deadline=os.clock()+(seconds or 90)
		repeat if f() then return end;task.wait(.05) until os.clock()>deadline
		error("Verification timed out")
	end
	local function count(t) local n=0;for _ in t do n+=1 end;return n end
	local legacy=schema.CreateDefault();legacy.DataVersion=4;legacy.IncubatingEggs=nil;legacy.Money=12345;legacy.FeedPlateLevel=7
	local migrated=assert(schema.Migrate(legacy))
	check(migrated.DataVersion==5 and next(migrated.IncubatingEggs)==nil and legacy.IncubatingEggs==nil
		and migrated.Money==12345 and migrated.FeedPlateLevel==7,"v4 migration adds isolated egg inventory without resetting progress")
	for i,roll in {0,.401,.651,.831,.931,.981} do
		check(config.Pick("prototype_egg",roll)==config.Definitions.prototype_egg.Results[i].SpeciesId,"Weighted pet result "..i)
	end
	check(not pcall(config.Pick,"prototype_egg",1) and not pcall(config.Pick,"prototype_egg",0/0),"Invalid result RNG rejected")
	local players=game:GetService("Players")
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and a.Character and b.Character
		and a.Character:FindFirstChild("HumanoidRootPart") and b.Character:FindFirstChild("HumanoidRootPart")
		and game.ReplicatedStorage:FindFirstChild("BuyConveyorEgg") and game.ReplicatedStorage:FindFirstChild("PrototypeEgg") end)
	local profile,other=data.GetData(a),data.GetData(b)
	local rootA,rootB=a.Character.HumanoidRootPart,b.Character.HumanoidRootPart
	rootA:SetNetworkOwner(nil);rootB:SetNetworkOwner(nil);rootA.Anchored=true;rootB.Anchored=true
	local function near(root,model,offset)
		local alpha=math.clamp((workspace:GetServerTimeNow()-model:GetAttribute("StartedAt"))/beltConfig.TravelSeconds,0,1)
		root.CFrame=model:GetAttribute("From"):Lerp(model:GetAttribute("To"),alpha)+Vector3.new(offset or 4,0,0)
	end
	local id,model=conveyor.SpawnOffer(0);assert(id,model)
	check(model:GetAttribute("EggId")=="prototype_egg" and model:GetAttribute("SpeciesId")==nil,"Conveyor shows egg not preselected pet")
	check(model:GetAttribute("Price")==5000 and model:FindFirstChild("BuyConveyorEgg",true)~=nil,"Egg price and purchase prompt authored")
	local start=model:GetPivot().Position;task.wait(.3);conveyor.Step()
	check((model:GetPivot().Position-start).Magnitude>.1,"Egg moves along conveyor")
	check(not conveyor.HandlePurchase(a,{}).Ok,"Malformed purchase rejected")
	rootA.CFrame=CFrame.new(1000,5,1000)
	check(conveyor.HandlePurchase(a,id).Code=="TooFar","Distant purchase rejected")
	task.wait(.3);near(rootA,model);profile.Money=4999
	check(conveyor.HandlePurchase(a,id).Code=="NotEnoughMoney" and profile.Money==4999,"Unaffordable egg does not charge")
	task.wait(.3);near(rootA,model);profile.Money=20000
	local inventoryCount=count(profile.Inventory)
	local result=conveyor.HandlePurchase(a,id)
	check(result.Ok and profile.Money==15000 and count(profile.Inventory)==inventoryCount and count(profile.IncubatingEggs)==1,"Purchase charges once and reserves egg, not usable pet")
	local uid=result.EggUid;local egg=profile.IncubatingEggs[uid];local petId=egg.Pet.PetId
	check(egg.ReadyAt-egg.StartedAt==10 and egg.Pet.FeedLevel==0 and egg.Pet.EggId=="prototype_egg","Timer and source egg persisted")
	check(result.PetId==nil and result.Rarity==nil and model.Parent==nil,"Purchase hides result and consumes world offer")
	local replay=conveyor.HandlePurchase(a,id)
	check(replay.EggUid==uid and profile.Money==15000 and count(profile.IncubatingEggs)==1,"Purchase retry cannot charge or create egg twice")
	other.Money=20000
	check(not conveyor.HandlePurchase(b,id).Ok and other.Money==20000,"Sold egg cannot be bought by second player")
	waitFor(function() return not locks.IsLocked(a) end)
	local snapshot=eggs.HandleRequest(a,"Snapshot")
	check(snapshot.Ok and #snapshot.Eggs==1 and snapshot.Eggs[1].Pet==nil and snapshot.Eggs[1].PetId==nil
		and snapshot.Eggs[1].SpeciesId==nil,"Snapshot reveals countdown but not reserved pet")
	check(#eggs.HandleRequest(b,"Snapshot").Eggs==0,"Egg inventory private to owner")
	check(eggs.HandleRequest(a,"Hatch",{}).Code=="InvalidRequest","Malformed hatch rejected")
	check(eggs.HandleRequest(a,"Buy","prototype_egg").Code=="InvalidRequest","No unvalidated direct purchase remote")
	check(eggs.HandleRequest(b,"Hatch",uid).Code=="Unavailable","Foreign hatch rejected")
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="NotReady","Early hatch rejected")
	check(not pets.GetPet(a,petId),"Unhatched pet is not usable")
	local extraId,extraModel=conveyor.SpawnOffer(0);assert(extraId,extraModel)
	task.wait(.3);near(rootA,extraModel)
	check(conveyor.HandlePurchase(a,extraId).Code=="IncubatorFull" and profile.Money==15000 and extraModel.Parent~=nil,"Full incubator does not charge or consume offer")
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local loaded=assert(schema.Migrate(record.Data))
	check(read and loaded.IncubatingEggs[uid].ReadyAt==egg.ReadyAt and loaded.IncubatingEggs[uid].Pet.PetId==petId
		and loaded.Money==15000,"Reload retains payment timer and exact reserved result")
	loaded.IncubatingEggs[uid].Pet.Traits[1]="clone"
	check(#egg.Pet.Traits==0,"Egg clone isolation")
	local invalid=assert(schema.Migrate(profile));invalid.Inventory[petId]=invalid.IncubatingEggs[uid].Pet
	check(not schema.Validate(invalid),"Cannot duplicate reserved pet into inventory")
	invalid=assert(schema.Migrate(profile));invalid.IncubatingEggs[uid].ReadyAt=-1
	check(not schema.Validate(invalid),"Malformed timer rejected")
	invalid=assert(schema.Migrate(profile));invalid.IncubatingEggs["duplicate"]=invalid.IncubatingEggs[uid]
	check(not schema.Validate(invalid),"Cannot reserve same pet in two eggs")
	waitFor(function() return os.time()>=egg.ReadyAt end,15)
	task.wait(.3);assert(locks.Begin(a,"test"))
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="Busy","Hatch respects shared transaction lock")
	locks.Finish(a);task.wait(.3)
	local hatched=eggs.HandleRequest(a,"Hatch",uid)
	check(hatched.Ok and hatched.PetId==petId and count(profile.Inventory)==inventoryCount+1
		and profile.IncubatingEggs[uid]==nil,"Ready egg atomically becomes original reserved pet")
	check(profile.PetIndex[egg.Pet.SpeciesId] and profile.Inventory[petId].EggId=="prototype_egg","Hatch updates index and preserves source")
	local again=eggs.HandleRequest(a,"Hatch",uid)
	check(again.PetId==petId and count(profile.Inventory)==inventoryCount+1 and profile.Money==15000,"Hatch replay cannot duplicate or charge")
	waitFor(function() return not locks.IsLocked(a) end)
	assert(data.Save(a));read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	loaded=assert(schema.Migrate(record.Data))
	check(read and loaded.Inventory[petId]~=nil and loaded.IncubatingEggs[uid]==nil,"Claimed egg cannot reappear after reload")
	local raceId,raceModel=conveyor.SpawnOffer(0);assert(raceId,raceModel)
	task.wait(.3);near(rootA,raceModel,4);near(rootB,raceModel,-4)
	profile.Money=20000;other.Money=20000
	local results={}
	task.spawn(function() results[1]=conveyor.HandlePurchase(a,raceId) end)
	task.spawn(function() results[2]=conveyor.HandlePurchase(b,raceId) end)
	waitFor(function() return results[1] and results[2] end)
	check((if results[1].Ok then 1 else 0)+(if results[2].Ok then 1 else 0)==1,"Two buyers get exactly one winner")
	check(profile.Money+other.Money==35000 and count(profile.IncubatingEggs)+count(other.IncubatingEggs)==1,"Purchase race charges and reserves once")
	local folder=workspace.PetConveyor.Offers
	while #folder:GetChildren()<beltConfig.MaxOffers do assert(conveyor.SpawnOffer(0)) end
	check(conveyor.SpawnOffer(0)==nil,"World offer cap enforced")
	waitFor(function() return #folder:GetChildren()==0 end,beltConfig.TravelSeconds+5)
	check(#folder:GetChildren()==0,"Unsold eggs expire and clean up")
	task.wait(.3)
	check(conveyor.HandlePurchase(b,extraId).Code=="Unavailable","Expired offer cannot charge")
	check(schema.Validate(profile) and schema.Validate(other),"Both final schemas valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
