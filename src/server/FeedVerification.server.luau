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
	local feed=require(script.Parent.Services.FeedService)
	local adapter=require(script.Parent.Data.DataStoreAdapter)
	assert(adapter.IsMemory(),"Memory data only")
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local function waitFor(predicate)
		local deadline=os.clock()+120
		repeat if predicate() then return end;task.wait(.1) until os.clock()>deadline
		error("Test timed out")
	end
	local function attempt(player,id,sequence)
		task.wait(.55)
		return feed.HandleRequest(player,"Feed",id,sequence)
	end
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b=table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and a.Character
		and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("PrototypeFeed") end)
	local profile=data.GetData(a)
	local pet=assert(pets.CreatePet(a,"test_common"))
	local foreign=assert(pets.CreatePet(b,"test_rare"))
	local invalid=feed.HandleRequest(a,"Feed",{},1)
	check(not invalid.Ok and invalid.Code=="InvalidRequest","Malformed pet ID rejected")
	check(not feed.HandleRequest(a,"Feed",pet.PetId,0/0).Ok,"NaN sequence rejected")
	check(not feed.HandleRequest(a,"AwardFood",pet.PetId,1).Ok,"Unknown action rejected")
	check(not attempt(a,pet.PetId,1).Ok,"Cannot feed inventory pet")
	local root=a.Character.HumanoidRootPart;root:SetNetworkOwner(nil)
	local dish=plots.GetPlot(a).FeedPlate.Dish
	root.CFrame=CFrame.new(dish.Position+Vector3.new(0,3,6))
	assert(carry.Equip(a,pet.PetId));assert(carry.PlaceOnPlate(a,pet.PetId))
	local state=feed.HandleRequest(a,"Snapshot")
	check(state.Ok and state.PetId==pet.PetId and state.Cost>0,"Snapshot gives own staged pet and server cost")
	local cost=state.Cost
	profile.Food=cost*3
	local oldMoney,oldLevel,oldIncome=profile.Money,profile.Inventory[pet.PetId].FeedLevel,profile.Inventory[pet.PetId].BaseIncome
	check(not attempt(a,foreign.PetId,1).Ok and profile.Food==cost*3,"Foreign pet cannot spend caller Food")
	check(not attempt(b,pet.PetId,1).Ok,"Other player cannot feed your staged pet")
	local result=attempt(a,pet.PetId,1)
	check(result.Ok and profile.Food==cost*2,"Feed deducts exactly server cost")
	check(result.NextSequence==2 and result.FoodAt~=nil,"Response provides next sequence and authoritative balance")
	check(not feed.HandleRequest(a,"Feed",pet.PetId,1).Ok and profile.Food==cost*2,"Duplicate request cannot consume twice")
	check(not feed.HandleRequest(a,"Feed",pet.PetId,2).Ok and profile.Food==cost*2,"Rapid new request rejected by cooldown")
	check(not attempt(a,pet.PetId,100).Ok,"Future sequence rejected")
	profile.Food=0
	result=attempt(a,pet.PetId,2)
	check(not result.Ok and result.Code=="NotEnoughFood" and profile.Food==0,"Insufficient Food never goes negative")
	profile.Food=cost*2
	assert(pets.SetLocked(a,pet.PetId,true))
	result=attempt(a,pet.PetId,2)
	check(result.Ok and profile.Food==cost,"Next valid Feed consumes once")
	check(not attempt(a,pet.PetId,1).Ok and profile.Food==cost,"Older replay remains rejected after later Feed")
	check(profile.Money==oldMoney and profile.Inventory[pet.PetId].FeedLevel==oldLevel
		and profile.Inventory[pet.PetId].BaseIncome==oldIncome and profile.Inventory[pet.PetId].Locked,"Only Food changes; pet stats and lock preserved")
	root.CFrame+=Vector3.new(50,0,0)
	result=attempt(a,pet.PetId,3)
	check(not result.Ok and result.Code=="TooFar" and profile.Food==cost,"Distant feeding rejected")
	root.CFrame=CFrame.new(dish.Position+Vector3.new(0,3,6))
	assert(carry.Equip(a,pet.PetId))
	check(not attempt(a,pet.PetId,3).Ok and profile.Food==cost,"Pickup invalidates stale Feed request")
	assert(carry.PlaceOnPlate(a,pet.PetId))
	a.Character.Humanoid.Health=0
	check(not attempt(a,pet.PetId,3).Ok and profile.Food==cost,"Dead character cannot feed")
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	check(read and record.Data.Food==cost,"Consumed balance persists through memory save")
	check(require(script.Parent.Data.PlayerDataSchema).Validate(profile),"Final schema valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
