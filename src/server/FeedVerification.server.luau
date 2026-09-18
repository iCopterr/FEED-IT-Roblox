if not game:GetService("RunService"):IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "FeedVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	local players=game:GetService("Players")
	local data=require(script.Parent.Services.DataService)
	local pets=require(script.Parent.Services.PetService)
	local plots=require(script.Parent.Services.PlotService)
	local carry=require(script.Parent.Services.CarryService)
	local placement=require(script.Parent.Services.PlacementService)
	local feed=require(script.Parent.Services.FeedService)
	local resolver=require(script.Parent.Services.FeedResolver)
	local locks=require(script.Parent.Services.FeedLocks)
	local schema=require(script.Parent.Data.PlayerDataSchema)
	local config=require(game.ReplicatedStorage.Shared.Config.FeedConfig)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	assert(adapter.IsMemory(),"Memory data only")
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local function waitFor(predicate)
		local deadline=os.clock()+120
		repeat if predicate() then return end;task.wait(.1) until os.clock()>deadline
		error("Test timed out")
	end
	local function random(values)
		local i=0
		return function() i+=1;assert(values[i]~=nil,"Extra RNG roll");return values[i] end
	end
	for _, case in {{0,.1,"Normal",1},{0,.945,"Critical",2},{17,.995,"Mega",20},{38,.9995,"Insane",40},{39,.945,"Critical",40}} do
		local result=resolver.Roll(case[1],random({.99,case[2]}))
		check(result.Critical==case[3] and result.FeedLevel==case[4],"Deterministic "..case[3].." at "..case[1])
	end
	check(resolver.Roll(20,random({0,0})).Code=="MiracleSave","Miracle skips Critical")
	check(resolver.Roll(20,random({0,.5})).Code=="Explosion","Explosion skips Critical")
	check(not pcall(resolver.Roll,40,random({})),"Level 40 cannot feed or roll")
	for level=36,39 do
		for _, roll in {.1,.945,.995,.9995} do
			check(resolver.Roll(level,random({.99,roll})).FeedLevel<=40,"Cap level "..level.." roll "..roll)
		end
	end
	local legacy=schema.CreateDefault();legacy.DataVersion=2;legacy.PendingRecovery=nil
	local migrated=assert(schema.Migrate(legacy))
	check(migrated.DataVersion==schema.CURRENT_VERSION and migrated.FeedPlateLevel==1 and next(migrated.PendingRecovery)==nil and legacy.PendingRecovery==nil,"v2 migration adds isolated recovery map and default plate level")
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and a.Character
		and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("FeedOutcome") end)
	local profile=data.GetData(a)
	local pet=assert(pets.CreatePet(a,"test_common"))
	local foreign=assert(pets.CreatePet(b,"test_rare"))
	check(not feed.HandleRequest(a,"Feed",{},1).Ok,"Malformed ID rejected")
	check(not feed.HandleRequest(a,"Feed",pet.PetId,0/0).Ok,"NaN sequence rejected")
	check(not feed.HandleRequest(a,"AwardFood",pet.PetId,1).Ok,"Unknown action rejected")
	check(not feed.HandleRequest(a,"Feed",pet.PetId,1).Ok,"Cannot feed inventory pet")
	local root=a.Character.HumanoidRootPart;root:SetNetworkOwner(nil)
	local dish=plots.GetPlot(a).FeedPlate.Dish
	local function near() root.CFrame=CFrame.new(dish.Position+Vector3.new(0,3,6)) end
	near()
	assert(carry.Equip(a,pet.PetId));assert(carry.PlaceOnPlate(a,pet.PetId))
	local state=feed.HandleRequest(a,"Snapshot")
	check(state.Ok and state.Cost==30 and state.Risk==0,"Own staged snapshot uses configured target cost and risk")
	profile.Food=1e12
	local function attempt(sequence,values)
		waitFor(function() return not locks.IsLocked(a) end)
		task.wait(.55);near()
		feed.SetTestRandom(a,random(values))
		return feed.HandleRequest(a,"Feed",pet.PetId,sequence)
	end
	task.wait(.55)
	check(not feed.HandleRequest(a,"Feed",foreign.PetId,1).Ok,"Foreign ID rejected")
	check(not feed.HandleRequest(b,"Feed",pet.PetId,1).Ok,"Other player cannot feed your pet")
	local before=profile.Food
	local result=attempt(1,{.99,.1})
	check(result.Accepted and result.FeedLevel==1 and profile.Food==before-30,"Normal Feed charges once and grows")
	check(result.Income==13 and profile.Inventory[pet.PetId].BaseIncome==10,"Income multiplier changes without overwriting base income")
	local replay=feed.HandleRequest(a,"Feed",pet.PetId,1)
	check(replay.AttemptId==result.AttemptId and profile.Food==before-30,"Replay returns identical outcome without charge")
	check(feed.HandleRequest(a,"Feed",pet.PetId,2).Code=="Busy","New feed blocked during animation/save")
	check(not feed.HandleRequest(a,"Pickup",pet.PetId).Ok,"UI pickup blocked during Feed")
	check(not carry.Equip(a,pet.PetId),"Direct equip blocked during Feed")
	check(not placement.PlacePet(a,pet.PetId,Vector3.zero),"Direct placement blocked during Feed")
	check(not pets.RemovePet(a,pet.PetId),"Removal blocked during Feed")
	waitFor(function() return not locks.IsLocked(a) end)
	local actualScale=plots.GetPlot(a).FeedPlate.PlatePet:GetScale()
	check(math.abs(actualScale-config.GetScale(1))<1e-5,"Surviving plate model grows ("..actualScale..")")
	profile.Inventory[pet.PetId].FeedLevel=38
	result=attempt(2,{.99,.9995})
	check(result.Critical=="Insane" and result.Gain==2 and result.FeedLevel==40,"Actual Insane Feed clamps gain at 40")
	waitFor(function() return not locks.IsLocked(a) end)
	task.wait(.55)
	before=profile.Food
	check(feed.HandleRequest(a,"Feed",pet.PetId,3).Code=="MaxLevel" and profile.Food==before,"Level 40 rejects before charge")
	profile.Inventory[pet.PetId].FeedLevel=20
	assert(pets.SetLocked(a,pet.PetId,true))
	before=profile.Food
	result=attempt(3,{0,0})
	check(result.Code=="MiracleSave" and profile.Inventory[pet.PetId].FeedLevel==20
		and profile.Food==before-config.GetFoodCost(21,"Common"),"Miracle retains level but consumes Food")
	waitFor(function() return not locks.IsLocked(a) end)
	before=profile.Food
	result=attempt(4,{0,.5})
	local recovery=profile.PendingRecovery[pet.PetId]
	check(result.Code=="Explosion" and not profile.Inventory[pet.PetId] and recovery~=nil,"Explosion quarantines pet outside usable inventory")
	check(recovery.Pet.PetId==pet.PetId and recovery.Pet.FeedLevel==20 and recovery.Pet.Locked
		and recovery.FoodSpent==config.GetFoodCost(21,"Common"),"Recovery preserves identity, pre-failure stats, lock and spent Food")
	check(profile.Food==before-recovery.FoodSpent,"Failed Food remains consumed")
	waitFor(function() return not locks.IsLocked(a) end)
	check(a:GetAttribute("FeedPlatePetId")==nil and not plots.GetPlot(a).FeedPlate:FindFirstChild("PlatePet"),"Exploded plate clears after presentation")
	check(not carry.Equip(a,pet.PetId) and not placement.PlacePet(a,pet.PetId,Vector3.zero),"Quarantined pet cannot equip or place")
	check(not pets.RemovePet(a,pet.PetId),"Quarantined pet cannot be permanently removed")
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	check(read and record.Data.Food==profile.Food and record.Data.PendingRecovery[pet.PetId].AttemptId==result.AttemptId,"Atomic memory save includes spent Food and recovery")
	local loaded=assert(schema.Migrate(record.Data))
	check(loaded.Inventory[pet.PetId]==nil and loaded.PendingRecovery[pet.PetId].Pet.FeedLevel==20,"Reload cannot restore exploded pet to inventory")
	loaded.PendingRecovery[pet.PetId].Pet.Traits[1]="clone-test"
	check(#profile.PendingRecovery[pet.PetId].Pet.Traits==0,"Recovery clone has independent nested pet data")
	local bad=assert(schema.Migrate(profile));bad.Inventory[pet.PetId]=bad.PendingRecovery[pet.PetId].Pet
	check(not schema.Validate(bad),"Schema rejects duplicate identity across recovery and inventory")
	check(schema.Validate(profile),"Final profile schema valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
