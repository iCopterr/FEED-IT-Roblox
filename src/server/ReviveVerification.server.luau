if not game:GetService("RunService"):IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "ReviveVerification" then return end
local checks = {}
local clientDiagnostics
local remoteTrace={}
local ok, failure = xpcall(function()
	local services = script.Parent.Services
	local data = require(services.DataService)
	local pets = require(services.PetService)
	local plots = require(services.PlotService)
	local carry = require(services.CarryService)
	local placement = require(services.PlacementService)
	local foodConfig = require(game.ReplicatedStorage.Shared.Config.FoodConfig)
	local revive = require(services.ReviveService)
	local locks = require(services.FeedLocks)
	local feed = require(services.FeedService)
	local plate = require(services.PedestalService)
	local money = require(services.MoneyService)
	local adapter = require(script.Parent.Data.DataStoreAdapter)
	local schema = require(script.Parent.Data.PlayerDataSchema)
	assert(adapter.IsMemory(), "Memory-only verification")
	local function check(value, name) assert(value, name); table.insert(checks, name) end
	local function waitFor(predicate)
		local deadline = os.clock() + 120
		repeat if predicate() then return end; task.wait(.1) until os.clock() > deadline
		error("Test timed out")
	end
	local players = game:GetService("Players")
	waitFor(function() return #players:GetPlayers() == 2 end)
	local a,b = table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a)
		and a.Character and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("PrototypeRevive")
		and game.ReplicatedStorage:FindFirstChild("PrototypeUI") end)
	local remoteCount=0
	for _,r in game.ReplicatedStorage:GetChildren()do if r.Name=="PrototypeRevive" then remoteCount+=1 end end
	check(remoteCount==1,"Repair startup reuses the authored remote without duplication")
	revive.Start()
	local restartCount=0
	for _,r in game.ReplicatedStorage:GetChildren()do if r.Name=="PrototypeRevive" then restartCount+=1 end end
	check(restartCount==1,"Repeated repair startup is idempotent")
	local root = a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil); root.Anchored = true
	root.CFrame = CFrame.new(plots.GetPlot(a).FeedPlate.Dish.Position + Vector3.new(0,3,6))
	local pet = assert(pets.CreatePet(a,"test_rare"))
	local profile = data.GetData(a)
	local report=Instance.new("RemoteEvent");report.Name="ReviveMachineVerificationReport";report.Parent=game.ReplicatedStorage
	local clientReply,clientReady
	report.OnServerEvent:Connect(function(who,result)
		if who~=a then return end
		if result.Stage then
			table.insert(remoteTrace,result)
			if result.Stage=="Ready" then clientReady=true end
		else clientReply=result end
	end)
	local remote=game.ReplicatedStorage.PrototypeRevive
	local handler=revive.HandleRequest
	remote.OnServerInvoke=function(who,action,...)
		local r=handler(who,action,...)
		if who==a then table.insert(remoteTrace,{Action=action,Ok=r.Ok,Code=r.Code,Count=r.Records and #r.Records}) end
		return r
	end
	waitFor(function()return clientReady end)
	profile.Inventory[pet.PetId].FeedLevel = 20
	assert(pets.SetLocked(a,pet.PetId,true))
	local original = pets.GetPet(a,pet.PetId)
	profile.Food = 1e12
	profile.ReviveCharges = 2
	profile.ReviveShards = 200
	local beforeFood, beforeMoney = profile.Food, profile.Money
	check(revive.HandleRequest(a,"Exchange",1).Code=="TooFar","Shard exchange requires the Revive Machine")
	task.wait(.3)
	local function legacyRecovery()
		-- Fixture for a record saved under the previous broken-pet rule.
		-- Existing saves must retain the same recovery choices as new failures.
		local record={Pet=pets.GetPet(a,pet.PetId),
			AttemptId=game:GetService("HttpService"):GenerateGUID(false),
			ExplodedAt=os.time(),FoodSpent=foodConfig.ServingsPerFeed}
		profile.Food-=record.FoodSpent
		profile.Inventory[pet.PetId].Broken=true
		profile.Inventory[pet.PetId].BreakId=record.AttemptId
		assert(schema.Validate(profile));assert(data.Save(a))
		return record
	end
	-- Exercise the real failure path, not just a manually damaged fixture.
	assert(carry.Equip(a,pet.PetId));assert(carry.PlaceOnPlate(a,pet.PetId))
	assert(require(services.DebugFeedOverrides).Arm(a,pet.PetId,"Explosion"))
	local outcome = feed.HandleRequest(a,"Feed",pet.PetId,1,"basic")
	check(outcome.Accepted and outcome.Code=="Explosion" and outcome.Broken,"Real Feed returns authoritative damage state")
	check(not plate.GetPetId(a) and a:GetAttribute("FeedPlatePetId")==nil
		and not plots.GetPlot(a).FeedPlate:FindFirstChild("PlatePet"),"Explosion immediately removes pet and prompt from plate")
	check(profile.Inventory[pet.PetId].PetId==pet.PetId and not profile.Inventory[pet.PetId].Placed
		and profile.Inventory[pet.PetId].FeedLevel==20,"Explosion returns same pet and level to stored inventory")
	check(feed.HandleRequest(a,"Feed",pet.PetId,1,"basic").AttemptId==outcome.AttemptId
		and profile.Food==beforeFood-1,"Explosion replay never charges Food twice")
	waitFor(function() return not locks.IsLocked(a) end)
	check(not plate.GetPetId(a) and not plots.GetPlot(a).FeedPlate:FindFirstChild("PlatePet"),"Animation completion never restores broken plate model")
	local denied=feed.HandleRequest(a,"Feed",pet.PetId,2,"basic")
	check(denied.Code=="Broken" and profile.Food==beforeFood-1 and profile.Inventory[pet.PetId].FeedLevel==20,
		"Forged broken Feed is rejected without consuming Food or changing level")
	check(revive.HandleRequest(a,"Revive",pet.PetId,outcome.AttemptId).Code=="TooFar","Cannot revive away from machine")
	task.wait(.3)
	root.CFrame=workspace.ReviveMachine.InteractionPoint.CFrame+Vector3.new(0,3,0)
	local exchange=revive.HandleRequest(a,"Exchange",1)
	check(exchange.Ok and exchange.Code=="Exchanged" and profile.ReviveShards==100 and profile.ReviveCharges==3,
		"100 shards exchange for exactly one Revive Charm")
	local replay=revive.HandleRequest(a,"Exchange",1)
	check(replay.Ok and profile.ReviveShards==100 and profile.ReviveCharges==3 and replay.NextExchangeSequence==2,
		"Repeated exchange sequence replays without another charge")
	check(revive.HandleRequest(a,"Exchange",3).Code=="StaleRequest" and profile.ReviveShards==100,
		"Out-of-order exchange sequence is rejected")
	waitFor(function() return not locks.IsLocked(a) end)
	task.wait(.3)
	local attempt = outcome.AttemptId
	check(profile.Inventory[pet.PetId].Broken and profile.PendingRecovery[pet.PetId] == nil, "Broken pet remains a usable identity")
	check(carry.Equip(a,pet.PetId),"Broken pet can equip")
	local held=a.Character.HeldPet
	check(held:GetAttribute("Broken") and held:FindFirstChild("BrokenRim")
		and held.PrimaryPart:FindFirstChild("BrokenSmokeAnchor"),"Held broken pet has soot outline and smoke")
	local canPlate,plateReason=carry.PlaceOnPlate(a,pet.PetId)
	check(not canPlate and plateReason=="Broken" and carry.GetPetId(a)==pet.PetId,"Broken plate placement rejected without losing held pet")
	carry.Unequip(a)
	check(placement.PlacePet(a,pet.PetId),"Broken pet can place")
	check(money.GetRate(a) == money.GetPetRate(original)*require(game.ReplicatedStorage.Shared.Config.ReviveConfig).BrokenIncomeMultiplier, "Placed broken pet earns configured reduced income")
	assert(placement.PickupPet(a,pet.PetId))
	assert(locks.Begin(a,"test-busy"))
	check(revive.HandleRequest(a,"Revive",pet.PetId,attempt).Code == "Busy", "Revive respects shared transaction lock")
	locks.Finish(a)
	waitFor(function() return not locks.IsLocked(a) end)
	local food = profile.Food
	check(food < beforeFood, "Failed Food consumed")
	local own = revive.HandleRequest(a,"Snapshot")
	check(own.Ok and own.CanRevive and own.ReviveCharges==3 and own.ReviveShards==100 and own.ShardExchangeCost==100
		and own.CanExchange and own.NextExchangeSequence==2 and #own.Records == 1 and own.Records[1].FeedLevel == 20,
		"Owner sees recovery and shard exchange balances")
	check(own.Records[1].ExpiresAt==nil and own.NearMachine,"Repair has no deadline")
	check(own.Records[1].SpeciesId==original.SpeciesId,"Selected pet preview receives species")
	check(own.Records[1].Broken and own.Records[1].AttemptId==outcome.AttemptId,"Repair list contains actual Feed explosion episode")
	report:FireClient(a,outcome.AttemptId)
	waitFor(function() return clientReply~=nil end)
	clientDiagnostics=clientReply.Diagnostics
	check(clientReply.Passed,"Revive Machine client: "..tostring(clientReply.Failure or ""))
	own.Records[1].FeedLevel = 1
	check(profile.Inventory[pet.PetId].FeedLevel == 20, "Snapshot cannot mutate pet")
	check(#revive.HandleRequest(b,"Snapshot").Records == 0, "Recovery is private to owner")
	check(not revive.HandleRequest(b,"Revive",pet.PetId,attempt).Ok, "Foreign recovery rejected")
	check(not revive.HandleRequest(a,"Revive",{},attempt).Ok, "Malformed pet ID rejected")
	task.wait(.3)
	check(revive.HandleRequest(a,"Revive",pet.PetId,"wrong-attempt").Code == "PetChanged", "Wrong explosion ID rejected")
	task.wait(.3)
	local result = revive.HandleRequest(a,"Revive",pet.PetId,attempt)
	check(result.Ok and result.FeedLevel == 20 and profile.ReviveCharges==2, "One charm restores previous level, not level one")
	check(not profile.Inventory[pet.PetId].Broken and profile.Inventory[pet.PetId].PetId == pet.PetId, "Repair clears damage on original identity")
	local restored = profile.Inventory[pet.PetId]
	check(restored.Locked and restored.CreatedAt == original.CreatedAt and restored.SpeciesId == original.SpeciesId
		and restored.Rarity == original.Rarity and restored.Variant == original.Variant and restored.BaseIncome == original.BaseIncome,
		"Identity/stats/lock/creation time preserved")
	check(not restored.Placed and not profile.PlacedPetIds[pet.PetId] and carry.GetPetId(a) == nil, "Revived pet returns to inventory, not automatic placement")
	check(profile.Food == food and profile.Money >= beforeMoney, "Revive does not refund Food or charge Money; recovery may earn income")
	waitFor(function() return not locks.IsLocked(a) end)
	check(carry.Equip(a,pet.PetId) and not a.Character.HeldPet:FindFirstChild("BrokenRim")
		and not a.Character.HeldPet.PrimaryPart:FindFirstChild("BrokenSmokeAnchor"),"Repaired pet appearance returns to normal")
	carry.Unequip(a)
	root.CFrame=CFrame.new(plots.GetPlot(a).FeedPlate.Dish.Position+Vector3.new(0,3,6))
	check(plate.Place(a,pet.PetId),"Repaired pet can return to feed plate")
	plate.Clear(a)
	root.CFrame=workspace.ReviveMachine.InteractionPoint.CFrame+Vector3.new(0,3,0)
	task.wait(.3)
	check(not revive.HandleRequest(a,"Revive",pet.PetId,attempt).Ok and profile.Inventory[pet.PetId] == restored, "Repeated request cannot duplicate or replace pet")
	assert(data.Save(a))
	local read, record = adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	local loaded = assert(schema.Migrate(record.Data))
	check(read and loaded.Inventory[pet.PetId].FeedLevel == 20 and loaded.PendingRecovery[pet.PetId] == nil and loaded.Food == food,
		"Reloaded save contains restored pet, consumed recovery and spent Food")
	local newer = legacyRecovery()
	waitFor(function() return not locks.IsLocked(a) end)
	check(newer.AttemptId ~= attempt, "Second explosion has distinct recovery identity")
	-- The fixture has no Feed animation delay; wait out the prior request's
	-- cooldown so this assertion exercises the attempt-ID guard specifically.
	task.wait(.3)
	check(revive.HandleRequest(a,"Revive",pet.PetId,attempt).Code == "PetChanged" and profile.Inventory[pet.PetId].Broken,
		"Delayed old request cannot revive a newer explosion")
	task.wait(.3)
	local replies = {}
	task.spawn(function() replies[1] = revive.HandleRequest(a,"Revive",pet.PetId,newer.AttemptId) end)
		task.spawn(function() replies[2] = revive.HandleRequest(a,"Repair",pet.PetId,newer.AttemptId) end)
	waitFor(function() return replies[1] and replies[2] end)
	check((if replies[1].Ok then 1 else 0)+(if replies[2].Ok then 1 else 0) == 1, "Concurrent duplicate requests restore exactly once")
	waitFor(function() return not locks.IsLocked(a) end)
	check(schema.Validate(profile) and schema.Validate(data.GetData(b)), "Final profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok, checks=checks, diagnostics=clientDiagnostics, trace=remoteTrace, failure=if ok then nil else tostring(failure)})
