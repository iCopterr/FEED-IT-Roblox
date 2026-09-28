if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="DebugVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local services=script.Parent.Services
	local debugService=require(services.DebugService)
	local overrides=require(services.DebugFeedOverrides)
	local data=require(services.DataService)
	local pets=require(services.PetService)
	local plots=require(services.PlotService)
	local placement=require(services.PlacementService)
	local carry=require(services.CarryService)
	local feed=require(services.FeedService)
	local locks=require(services.FeedLocks)
	assert(require(script.Parent.Data.DataStoreAdapter).IsMemory())
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local function waitFor(fn)
		local deadline=os.clock()+120
		repeat if fn() then return end;task.wait(.1) until os.clock()>deadline
		error("Timed out")
	end
	local players=game:GetService("Players")
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and a.Character
		and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("PrototypeDebug") end)
	local profile=data.GetData(a)
	local sequence=1
	local function command(action,value,id)
		task.wait(.22)
		local result=debugService.HandleRequest(a,action,value,id,sequence)
		if result.Ok then sequence=result.NextSequence end
		return result
	end
	check(debugService.HandleRequest(a,"Snapshot").Ok,"Debug snapshot available in memory Studio")
	local before=profile.Money
	check(command("AddMoney",1000).Ok and profile.Money==before+1000,"Money grant applied exactly")
	check(debugService.HandleRequest(a,"AddMoney",1000,nil,sequence-1).Ok and profile.Money==before+1000,"Replay does not grant twice")
	check(not debugService.HandleRequest(a,"AddMoney",2000,nil,sequence-1).Ok,"Same sequence with changed payload rejected")
	for _,bad in {-1,0,1.5,math.huge,0/0,1e16,"100"} do
		check(not command("AddFood",bad).Ok,"Invalid currency input rejected: "..tostring(bad))
	end
	check(command("AddFood",1e12).Ok and profile.Food==1e12,"Food grant applied")
	check(not command("AddTokens",1).Ok,"Retired Token grant rejected")
	local ids={}
	for _,species in {"test_common","test_uncommon","test_rare","test_epic","test_legendary","test_mythic"} do
		local result=command("SpawnPet",species)
		check(result.Ok and profile.Inventory[result.PetId].SpeciesId==species,"Spawn "..species)
		table.insert(ids,result.PetId)
		check(debugService.HandleRequest(a,"SpawnPet",species,nil,sequence-1).PetId==result.PetId,"Spawn replay retains identity "..species)
	end
	check(not command("SpawnPet","fake").Ok,"Unknown species rejected")
	local id=ids[1]
	local foreign=assert(pets.CreatePet(b,"test_common"))
	check(not command("SetPetLevel",20,foreign.PetId).Ok,"Foreign pet level rejected")
	check(not command("ForceFeed","Explosion",foreign.PetId).Ok,"Foreign override rejected")
	check(not command("SetPetLevel",41,id).Ok and not command("SetPetLevel",1.5,id).Ok,"Invalid pet levels rejected")
	check(command("SetPetLevel",39,id).Ok and profile.Inventory[id].FeedLevel==39,"Stored pet level set without changing identity")
	check(not command("SetFarmLevel",10).Ok,"Retired farm level command rejected")
	assert(placement.PlacePet(a,id))
	check(command("SetPetLevel",5,id).Code=="PickupFirst","Placed pet level edit requires pickup")
	assert(placement.PickupPet(a,id))
	check(command("ForceFeed","Insane",id).Ok,"One-use Insane override armed")
	check(not feed.HandleRequest(a,"Feed",id,1).Accepted and overrides.Get(a)~=nil,"Invalid Feed does not consume override")
	local root=a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil);root.Anchored=true
	root.CFrame=CFrame.new(plots.GetPlot(a).FeedPlate.Dish.Position+Vector3.new(0,3,6))
	assert(carry.Equip(a,id));assert(carry.PlaceOnPlate(a,id))
	check(command("SetPetLevel",38,id).Ok,"Plate pet level edit supported")
	local scale=plots.GetPlot(a).FeedPlate.PlatePet:GetScale()
	check(math.abs(scale-require(game.ReplicatedStorage.Shared.PetModels).GetScale(profile.Inventory[id].SpeciesId,38))<1e-5,"Plate visual scale updates")
	profile.Food=0;task.wait(.55)
	check(feed.HandleRequest(a,"Feed",id,1).Code=="NotEnoughFood" and overrides.Get(a)~=nil,"Unaffordable Feed retains override")
	assert(command("AddFood",1e12).Ok);task.wait(.55)
	local result=feed.HandleRequest(a,"Feed",id,1)
	check(result.Accepted and result.Critical=="Insane" and result.FeedLevel==40,"Forced Insane uses normal Feed transaction and cap")
	check(overrides.Get(a)==nil,"Accepted Feed consumes override once")
	check(command("AddMoney",100).Code=="Busy","Debug mutation blocked during Feed transaction")
	waitFor(function() return not locks.IsLocked(a) end)
	for i,mode in {"Success","Critical","Mega"} do
		assert(command("SetPetLevel",10,id).Ok)
		assert(command("ForceFeed",mode,id).Ok)
		result=feed.HandleRequest(a,"Feed",id,i+1)
		check(result.Accepted and result.FeedLevel==10+i,"Forced "..mode.." resolves expected gain")
		waitFor(function() return not locks.IsLocked(a) end)
	end
	assert(command("SetPetLevel",0,id).Ok)
	assert(command("ForceFeed","Explosion",id).Ok)
	result=feed.HandleRequest(a,"Feed",id,5)
	check(result.Accepted and result.Code=="Explosion" and result.FeedLevel==0
		and profile.PendingRecovery[id]~=nil and profile.Inventory[id]==nil,
		"Force Explosion offers recovery or level zero even at zero natural risk")
	waitFor(function() return not locks.IsLocked(a) end)
	assert(command("ForceFeed","Critical",ids[2]).Ok)
	check(command("ForceFeed","Clear",ids[2]).Ok and overrides.Get(a)==nil,"Clear restores normal odds")
	check(not command("ForceFeed","Invalid",ids[2]).Ok,"Invalid override mode rejected")
	check(require(script.Parent.Data.PlayerDataSchema).Validate(profile),"Final profile validates")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
