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
	local carry=require(services.CarryService)
	local plots=require(services.PlotService)
	local visuals=require(services.EggVisuals)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	local config=require(game.ReplicatedStorage.Shared.Config.EggConfig)
	local petModels=require(game.ReplicatedStorage.Shared.PetModels)
	local beltConfig=require(game.ReplicatedStorage.Shared.Config.ConveyorConfig)
	assert(adapter.IsMemory(),"Memory-only verification")
	local function check(v,n) assert(v,n);table.insert(checks,n) end
	local variants=require(game.ReplicatedStorage.Shared.Config.VariantConfig)
	local income=require(game.ReplicatedStorage.Shared.PetIncome)
	local counts={Normal=0,Shiny=0,Rainbow=0,Celestial=0}
	for ticket=1,variants.Tickets do counts[variants.Pick(ticket)]+=1 end
	for name,definition in variants.Types do
		check(counts[name]==definition.Tickets,"Exact hatch variant weight "..name)
		check(income({BaseIncome=10,FeedLevel=0,Variant=name})==10*definition.IncomeMultiplier,"Variant income "..name)
	end
	check(not pcall(variants.Pick,0) and not pcall(variants.Pick,100001) and not pcall(variants.Pick,0/0),"Invalid variant tickets rejected")
	local function waitFor(f,seconds)
		local deadline=os.clock()+(seconds or 90)
		repeat if f() then return end;task.wait(.05) until os.clock()>deadline
		error("Verification timed out")
	end
	local function count(t) local n=0;for _ in t do n+=1 end;return n end
	local legacy=schema.CreateDefault();legacy.DataVersion=4;legacy.IncubatingEggs=nil;legacy.Money=12345;legacy.FeedPlateLevel=7
	local migrated=assert(schema.Migrate(legacy))
	check(migrated.DataVersion==schema.CURRENT_VERSION and next(migrated.IncubatingEggs)==nil and legacy.IncubatingEggs==nil
		and migrated.Money==12345 and migrated.FeedPlateLevel==7,"v4 migration adds isolated egg inventory without resetting progress")
	for i,roll in {0,.361,.651,.831,.941,.991} do
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
	check(variants.Types[egg.Pet.Variant]~=nil,"Purchase reserves a configured variant")
	-- Memory-only fixture guarantees rare-result persistence coverage without grinding.
	egg.Pet.Variant="Celestial"
	check(egg.StartedAt==0 and egg.ReadyAt==0 and egg.HatchSeconds==10 and not egg.PenPosition
		and egg.Pet.FeedLevel==0 and egg.Pet.EggId=="prototype_egg","New egg stores duration but timer waits for placement")
	check(result.PetId==nil and result.Rarity==nil and model.Parent==nil,"Purchase hides result and consumes world offer")
	local replay=conveyor.HandlePurchase(a,id)
	check(replay.EggUid==uid and profile.Money==15000 and count(profile.IncubatingEggs)==1,"Purchase retry cannot charge or create egg twice")
	other.Money=20000
	check(not conveyor.HandlePurchase(b,id).Ok and other.Money==20000,"Sold egg cannot be bought by second player")
	waitFor(function() return not locks.IsLocked(a) end)
	check(carry.GetEggId(a)==uid and not carry.GetPetId(a) and a.Character:FindFirstChild("HeldEgg"),"Bought egg held when hands are free")
	local snapshot=eggs.HandleRequest(a,"Snapshot")
	check(snapshot.Ok and #snapshot.Eggs==1 and snapshot.Eggs[1].Pet==nil and snapshot.Eggs[1].PetId==nil
		and snapshot.Eggs[1].SpeciesId==nil,"Snapshot reveals countdown but not reserved pet")
	check(#eggs.HandleRequest(b,"Snapshot").Eggs==0,"Egg inventory private to owner")
	check(eggs.HandleRequest(a,"Hatch",{}).Code=="InvalidRequest","Malformed hatch rejected")
	check(eggs.HandleRequest(a,"Buy","prototype_egg").Code=="InvalidRequest","No unvalidated direct purchase remote")
	check(eggs.HandleRequest(b,"Hatch",uid).Code=="Unavailable","Foreign hatch rejected")
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="NotPlaced","Unplaced egg cannot hatch")
	local floor=plots.GetPlot(a).Pen.Floor
	local position=floor.CFrame:PointToWorldSpace(Vector3.new(3,floor.Size.Y/2,2))
	check(eggs.HandleRequest(b,"Place",uid,position).Code=="Unavailable","Foreign egg cannot be placed")
	check(eggs.HandleRequest(a,"Place",uid,Vector3.new(0/0,0,0)).Code=="OutsidePen","Nonfinite egg placement rejected")
	task.wait(.3)
	check(eggs.HandleRequest(a,"Place",uid,Vector3.new(1000,0,1000)).Code=="OutsidePen","Outside Pen placement rejected")
	task.wait(.3);rootA.CFrame=CFrame.new(1000,5,1000)
	check(eggs.HandleRequest(a,"Place",uid,position).Code=="TooFar","Distant egg placement rejected")
	carry.Unequip(a);task.wait(.3)
	check(eggs.HandleRequest(a,"Place",uid,position).Code=="NotCarrying","Egg must actually be held to place")
	check(eggs.HandleRequest(a,"Equip",uid).Ok and carry.GetEggId(a)==uid,"Stored egg can be equipped")
	check(not carry.PlaceOnPlate(a,uid) and not carry.PlaceAt(a,uid,position),"Egg cannot use pet or feed plate placement")
	rootA.CFrame=CFrame.new(position+Vector3.new(0,4,4));task.wait(.3)
	local placed=eggs.HandleRequest(a,"Place",uid,position)
	check(placed.Ok and egg.StartedAt>0 and egg.ReadyAt-egg.StartedAt==10,"Placement starts configured incubation timer")
	check(math.abs(egg.PenPosition.X-3)<.001 and math.abs(egg.PenPosition.Z-2)<.001
		and not carry.GetEggId(a) and not a.Character:FindFirstChild("HeldEgg"),"Exact local position persisted and hands released")
	local worldEgg=plots.GetPlot(a).Pen:FindFirstChild("Egg_"..uid)
	check(worldEgg and worldEgg:GetAttribute("EggUid")==uid and worldEgg:FindFirstChild("ConveyorPetLabel",true),"Placed authored egg clone and countdown label exist")
	local readyAt=egg.ReadyAt
	waitFor(function() return not locks.IsLocked(a) end);task.wait(.3)
	check(eggs.HandleRequest(a,"Place",uid,position).Code=="AlreadyPlaced" and egg.ReadyAt==readyAt,"Placement replay cannot restart incubation")
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="NotReady","Early placed hatch rejected")
	visuals.Clear(a);visuals.Reconcile(a,profile)
	check(plots.GetPlot(a).Pen:FindFirstChild("Egg_"..uid)~=nil and egg.ReadyAt==readyAt,"Visual reconstruction preserves timer and identity")
	local old=assert(schema.Migrate(profile));old.DataVersion=5
	old.IncubatingEggs[uid].HatchSeconds=nil;old.IncubatingEggs[uid].PenPosition=nil
	local upgraded=assert(schema.Migrate(old))
	check(upgraded.IncubatingEggs[uid].ReadyAt==readyAt and upgraded.IncubatingEggs[uid].Pet.PetId==petId
		and upgraded.IncubatingEggs[uid].HatchSeconds==10 and old.IncubatingEggs[uid].HatchSeconds==nil,"v5 migration preserves paid timer and result without changing source")
	check(not pets.GetPet(a,petId),"Unhatched pet is not usable")
	local extraId,extraModel=conveyor.SpawnOffer(0);assert(extraId,extraModel)
	task.wait(.3);near(rootA,extraModel)
	local extraPurchase=conveyor.HandlePurchase(a,extraId)
	check(extraPurchase.Ok and profile.Money==10000 and count(profile.IncubatingEggs)==2 and extraModel.Parent==nil,
		"Player can buy another egg while the first egg is still incubating")
	waitFor(function() return not locks.IsLocked(a) end)
	carry.Unequip(a)
	-- Remove the extra fixture so the remaining hatch/reload assertions stay isolated.
	profile.IncubatingEggs[extraPurchase.EggUid]=nil
	profile.Money=15000
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local loaded=assert(schema.Migrate(record.Data))
	check(read and loaded.IncubatingEggs[uid].ReadyAt==egg.ReadyAt and loaded.IncubatingEggs[uid].Pet.PetId==petId
		and loaded.IncubatingEggs[uid].PenPosition.X==egg.PenPosition.X and loaded.Money==15000,"Reload retains placement payment timer and exact reserved result")
	loaded.IncubatingEggs[uid].PenPosition.X=999
	check(loaded.IncubatingEggs[uid].Pet.Variant=="Celestial","Reserved variant survives save/load")
	check(egg.PenPosition.X~=999,"Saved egg position clone is isolated")
	loaded.IncubatingEggs[uid].Pet.Traits[1]="clone"
	check(#egg.Pet.Traits==0,"Egg clone isolation")
	local invalid=assert(schema.Migrate(profile));invalid.Inventory[petId]=invalid.IncubatingEggs[uid].Pet
	check(not schema.Validate(invalid),"Cannot duplicate reserved pet into inventory")
	invalid=assert(schema.Migrate(profile));invalid.IncubatingEggs[uid].ReadyAt=-1
	check(not schema.Validate(invalid),"Malformed timer rejected")
	invalid=assert(schema.Migrate(profile));invalid.IncubatingEggs["duplicate"]=invalid.IncubatingEggs[uid]
	check(not schema.Validate(invalid),"Cannot reserve same pet in two eggs")
	invalid=assert(schema.Migrate(profile));invalid.IncubatingEggs[uid].PenPosition.X=math.huge
	check(not schema.Validate(invalid),"Nonfinite saved egg position rejected")
	invalid=assert(schema.Migrate(profile));invalid.IncubatingEggs[uid].HatchSeconds=11
	check(not schema.Validate(invalid),"Inconsistent saved duration rejected")
	waitFor(function() return os.time()>=egg.ReadyAt end,15)
	task.wait(.3);assert(locks.Begin(a,"test"))
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="Busy","Hatch respects shared transaction lock")
	locks.Finish(a);task.wait(.3)
	rootA.CFrame=CFrame.new(1000,5,1000)
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="TooFar","Ready egg cannot hatch from a distance")
	rootA.CFrame=CFrame.new(position+Vector3.new(0,4,4));task.wait(.3)
	visuals.Reconcile(a,profile)
	local hatchPrompt=visuals.GetModel(a,uid):FindFirstChild(config.HatchPromptName,true)
	check(hatchPrompt and hatchPrompt.Enabled and hatchPrompt.KeyboardKeyCode==Enum.KeyCode.E
		and hatchPrompt.HoldDuration==0,"Ready egg has instant E hatch interaction")
	local hatched
	local hatchStart=os.clock()
	task.spawn(function() hatched=eggs.HandleRequest(a,"Hatch",uid) end)
	task.wait(.4)
	check(profile.Inventory[petId]==nil and profile.IncubatingEggs[uid]==egg
		and carry.GetPetId(a)~=petId,"Pet remains reserved during hatch animation")
	check(eggs.HandleRequest(a,"Hatch",uid).Code=="Busy","Duplicate hatch during reveal is blocked")
	waitFor(function() return hatched~=nil end)
	local hatchTiming=require(game.ReplicatedStorage.Shared.Config.HatchAnimationConfig)
	check(os.clock()-hatchStart>=hatchTiming.BurstAt+hatchTiming.PetRevealSeconds+hatchTiming.PetDissolveSeconds+hatchTiming.CollectSeconds,
		"Pet grant waits until reward light arrival")
	-- Manual E route remains covered above and by the later tier hatches.
	check(hatched.Ok and hatched.PetId==petId and count(profile.Inventory)==inventoryCount+1
		and profile.IncubatingEggs[uid]==nil,"Ready egg atomically becomes original reserved pet")
	check(profile.PetIndex[egg.Pet.SpeciesId] and profile.Inventory[petId].EggId=="prototype_egg","Hatch updates index and preserves source")
	local again=eggs.HandleRequest(a,"Hatch",uid)
	check(again.Variant=="Celestial" and profile.Inventory[petId].Variant=="Celestial","Hatch replay preserves variant")
	check(again.PetId==petId and count(profile.Inventory)==inventoryCount+1 and profile.Money==15000,"Hatch replay cannot duplicate or charge")
	waitFor(function() return not locks.IsLocked(a) end)
	check(not profile.Inventory[petId].Placed and not profile.PlacedPetIds[petId]
		and carry.GetPetId(a)==petId and not plots.GetPlot(a).Pen:FindFirstChild("Egg_"..uid),"Hatched pet returns to player hands, not Pen, and egg visual is removed")
	assert(data.Save(a));read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	loaded=assert(schema.Migrate(record.Data))
	check(read and loaded.Inventory[petId]~=nil and loaded.IncubatingEggs[uid]==nil,"Claimed egg cannot reappear after reload")
	-- New tiers exercise the same paid conveyor -> carry -> place -> hatch path.
	for _,tier in {{Id="advanced_egg",Roll=.8},{Id="elite_egg",Roll=.96},{Id="master_egg",Roll=.985},{Id="supreme_egg",Roll=.998},{Id="ultimate_egg",Roll=.9995}} do
		local definition=config.Definitions[tier.Id]
		local total=0;for _,entry in definition.Results do total+=entry.Weight end
		local cursor=0
		for _,entry in definition.Results do
			check(config.Pick(tier.Id,(cursor+entry.Weight/2)/total)==entry.SpeciesId,"Weighted result "..entry.SpeciesId)
			check(petModels.GetTemplate(entry.SpeciesId)~=nil,"Authored model "..entry.SpeciesId)
			cursor+=entry.Weight
		end
		carry.Unequip(a)
		local offerId,offerModel=conveyor.SpawnOffer(tier.Roll);assert(offerId,offerModel)
		check(offerModel:GetAttribute("EggId")==tier.Id,"Conveyor offers "..tier.Id)
		profile.Money=definition.Price+123
		task.wait(.3);near(rootA,offerModel)
		local bought=conveyor.HandlePurchase(a,offerId)
		check(bought.Ok and profile.Money==123,"Configured price charged for "..tier.Id)
		waitFor(function() return not locks.IsLocked(a) end)
		local reserved=profile.IncubatingEggs[bought.EggUid]
		rootA.CFrame=CFrame.new(position+Vector3.new(0,4,4))
		task.wait(.3)
		check(eggs.HandleRequest(a,"Place",bought.EggUid,position).Ok,"Place reused egg model "..tier.Id)
		check(reserved.ReadyAt-reserved.StartedAt==definition.HatchSeconds,"Configured timer "..tier.Id)
		waitFor(function() return not locks.IsLocked(a) end)
		-- Memory-only fixture fast-forwards the timer; production still waits the full duration.
		reserved.ReadyAt=os.time()-1;reserved.StartedAt=reserved.ReadyAt-reserved.HatchSeconds
		check(schema.Validate(profile),"New tier validates for save "..tier.Id)
		task.wait(.3)
		if tier.Id=="elite_egg" then rootA.CFrame=CFrame.new(0,8,-170) end
		local result=eggs.HandleRequest(a,if tier.Id=="elite_egg" then "HatchRemote" else "Hatch",bought.EggUid)
		if tier.Id=="elite_egg" then
			-- Both request routes share one cached result and transaction.
			rootA.CFrame=CFrame.new(0,8,-170)
			check(eggs.HandleRequest(a,"HatchRemote",bought.EggUid).PetId==result.PetId,"Remote/manual hatch replay shares cached result")
		end
		check(result.Ok and result.PetId==reserved.Pet.PetId,"Hatch preserves reserved identity "..tier.Id)
		waitFor(function() return not locks.IsLocked(a) end)
		check(carry.GetPetId(a)==result.PetId and profile.Inventory[result.PetId].EggId==tier.Id,"New pet held using reused model "..tier.Id)
		assert(data.Save(a))
		local saved,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
		check(saved and schema.Migrate(record.Data).Inventory[result.PetId]~=nil,"New pet survives save/load "..tier.Id)
	end
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
