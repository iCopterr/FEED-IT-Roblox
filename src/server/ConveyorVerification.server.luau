if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="ConveyorVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local players=game:GetService("Players")
	local data=require(script.Parent.Services.DataService)
	local service=require(script.Parent.Services.ConveyorService)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	local config=require(game.ReplicatedStorage.Shared.Config.ConveyorConfig)
	assert(adapter.IsMemory(),"Memory-only verification")
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local function waitFor(predicate,seconds)
		local deadline=os.clock()+(seconds or 120)
		repeat if predicate() then return end;task.wait(.05) until os.clock()>deadline
		error("Verification timed out")
	end
	local function count(inventory) local n=0;for _ in inventory do n+=1 end;return n end
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and a.Character and b.Character
		and a.Character:FindFirstChild("HumanoidRootPart") and b.Character:FindFirstChild("HumanoidRootPart")
		and game.ReplicatedStorage:FindFirstChild("BuyConveyorPet") end)
	local rootA,rootB=a.Character.HumanoidRootPart,b.Character.HumanoidRootPart
	rootA:SetNetworkOwner(nil);rootB:SetNetworkOwner(nil);rootA.Anchored=true;rootB.Anchored=true
	local profile,other=data.GetData(a),data.GetData(b)
	local folder=workspace.PetConveyor.Offers
	local function near(root,model,offset)
		local alpha=math.clamp((workspace:GetServerTimeNow()-model:GetAttribute("StartedAt"))/config.TravelSeconds,0,1)
		root.CFrame=model:GetAttribute("From"):Lerp(model:GetAttribute("To"),alpha)+Vector3.new(offset or 4,0,0)
	end
	local ids,models={},{}
	local total=0
	for _,entry in config.Offers do total+=entry.Weight end
	check(total==1000 and #config.Offers==6,"Six rarity weights sum to 1000")
	for i,roll in {0,.60,.85,.95,.99,.999} do
		local definition=config.Pick(roll)
		check(definition==config.Offers[i],"Weighted boundary selects "..definition.Rarity)
		local id,model=service.SpawnOffer(roll)
		assert(id,model)
		ids[i],models[i]=id,model
		check(model:GetAttribute("Rarity")==definition.Rarity and model:GetAttribute("Price")==definition.Price,"Offer shows authoritative "..definition.Rarity.." price")
		check(model:FindFirstChild("ConveyorPetLabel",true)~=nil and model:FindFirstChild("BuyConveyorPet",true)~=nil,"Label and buy prompt: "..definition.Rarity)
	end
	check(not pcall(config.Pick,1) and not pcall(config.Pick,0/0),"Invalid RNG input rejected")
	local firstPosition=models[1]:GetPivot().Position
	task.wait(.3);service.Step()
	check((models[1]:GetPivot().Position-firstPosition).Magnitude>.1,"Pets move along belt")
	check(not service.HandlePurchase(a,{}).Ok,"Malformed purchase ID rejected")
	profile.Money=1000
	rootA.CFrame=CFrame.new(1000,5,1000)
	check(service.HandlePurchase(a,ids[1]).Code=="TooFar","Distant purchase rejected")
	task.wait(.3);near(rootA,models[1]);profile.Money=99
	check(service.HandlePurchase(a,ids[1]).Code=="NotEnoughMoney" and profile.Money==99,"Insufficient Money does not charge")
	task.wait(.3);near(rootA,models[1]);profile.Money=1000
	local before=count(profile.Inventory)
	local result=service.HandlePurchase(a,ids[1])
	check(result.Ok and profile.Money==900 and count(profile.Inventory)==before+1,"Purchase atomically pays price and adds one pet")
	local owned=profile.Inventory[result.PetId]
	check(owned.Rarity=="Common" and owned.FeedLevel==0 and not owned.Placed and owned.PetId~=ids[1],"Bought pet has fresh inventory identity and no placement")
	check(models[1].Parent==nil,"Purchased visual removed")
	local replay=service.HandlePurchase(a,ids[1])
	check(replay.PetId==result.PetId and profile.Money==900 and count(profile.Inventory)==before+1,"Duplicate purchase returns same pet without charge")
	other.Money=10000
	check(not service.HandlePurchase(b,ids[1]).Ok and other.Money==10000,"Second player cannot buy sold offer")
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local reloaded=assert(schema.Migrate(record.Data))
	check(read and reloaded.Money==900 and reloaded.Inventory[result.PetId].PetId==result.PetId,"Pet and payment persist together")
	task.wait(.3)
	local raceId,raceModel=service.SpawnOffer(.60)
	assert(raceId,raceModel);near(rootA,raceModel,4);near(rootB,raceModel,-4)
	profile.Money=10000;other.Money=10000
	local results={};local originalA,originalB=count(profile.Inventory),count(other.Inventory)
	task.spawn(function() results[1]=service.HandlePurchase(a,raceId) end)
	task.spawn(function() results[2]=service.HandlePurchase(b,raceId) end)
	waitFor(function() return results[1] and results[2] end)
	check((if results[1].Ok then 1 else 0)+(if results[2].Ok then 1 else 0)==1,"Simultaneous buyers produce exactly one winner")
	check(count(profile.Inventory)+count(other.Inventory)==originalA+originalB+1
		and profile.Money+other.Money==18500,"Race creates one pet and charges only winner")
	task.wait(.3);near(rootA,models[3]);a.Character.Humanoid.Health=0
	local money=profile.Money
	check(not service.HandlePurchase(a,ids[3]).Ok and profile.Money==money,"Dead player cannot buy")
	while #folder:GetChildren()<config.MaxOffers do assert(service.SpawnOffer(.1)) end
	check(service.SpawnOffer(.1)==nil and #folder:GetChildren()==config.MaxOffers,"Offer cap prevents unbounded spawning")
	waitFor(function() return #folder:GetChildren()==0 end,config.TravelSeconds+5)
	check(#folder:GetChildren()==0,"Unsold offers expire and clean up at belt end")
	task.wait(.3)
	check(service.HandlePurchase(b,ids[3]).Code=="Unavailable","Expired offer cannot be bought")
	check(schema.Validate(profile) and schema.Validate(other),"Both final player profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
