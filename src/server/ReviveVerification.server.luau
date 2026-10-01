if not game:GetService("RunService"):IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "ReviveVerification" then return end
local checks = {}
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
		and a.Character and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("PrototypeRevive") end)
	local root = a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil); root.Anchored = true
	root.CFrame = CFrame.new(plots.GetPlot(a).FeedPlate.Dish.Position + Vector3.new(0,3,6))
	local pet = assert(pets.CreatePet(a,"test_rare"))
	local profile = data.GetData(a)
	local report=Instance.new("RemoteEvent");report.Name="ReviveMachineVerificationReport";report.Parent=game.ReplicatedStorage
	local clientReply
	report.OnServerEvent:Connect(function(who,result) if who==a then clientReply=result end end)
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
		profile.Inventory[pet.PetId]=nil
		profile.PendingRecovery[pet.PetId]=record
		assert(schema.Validate(profile));assert(data.Save(a))
		return record
	end
	local outcome = legacyRecovery()
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
	check(profile.PendingRecovery[pet.PetId] ~= nil and profile.Inventory[pet.PetId] == nil, "Legacy broken recovery remains supported")
	check(not carry.Equip(a,pet.PetId) and not placement.PlacePet(a,pet.PetId), "Broken pet cannot equip or place")
	check(money.GetRate(a) == 0, "Broken pet earns no Money")
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
	check(own.Records[1].ExpiresAt==outcome.ExplodedAt+86400 and own.NearMachine and not own.RobuxEnabled,"24-hour deadline and machine-only disabled Robux snapshot")
	check(own.Records[1].SpeciesId==original.SpeciesId,"Selected pet preview receives species")
	report:FireClient(a,outcome.AttemptId)
	waitFor(function() return clientReply~=nil end)
	check(clientReply.Passed,"Revive Machine client: "..tostring(clientReply.Failure or ""))
	own.Records[1].FeedLevel = 1
	check(profile.PendingRecovery[pet.PetId].Pet.FeedLevel == 20, "Snapshot cannot mutate recovery")
	check(#revive.HandleRequest(b,"Snapshot").Records == 0, "Recovery is private to owner")
	check(not revive.HandleRequest(b,"Revive",pet.PetId,attempt).Ok, "Foreign recovery rejected")
	check(not revive.HandleRequest(a,"Revive",{},attempt).Ok, "Malformed pet ID rejected")
	task.wait(.3)
	check(revive.HandleRequest(a,"Revive",pet.PetId,"wrong-attempt").Code == "PetChanged", "Wrong explosion ID rejected")
	task.wait(.3)
	local result = revive.HandleRequest(a,"Revive",pet.PetId,attempt)
	check(result.Ok and result.FeedLevel == 20 and profile.ReviveCharges==2, "One charm restores previous level, not level one")
	check(profile.PendingRecovery[pet.PetId] == nil and profile.Inventory[pet.PetId].PetId == pet.PetId, "Recovery consumed and original identity restored")
	local restored = profile.Inventory[pet.PetId]
	check(restored.Locked and restored.CreatedAt == original.CreatedAt and restored.SpeciesId == original.SpeciesId
		and restored.Rarity == original.Rarity and restored.Variant == original.Variant and restored.BaseIncome == original.BaseIncome,
		"Identity/stats/lock/creation time preserved")
	check(not restored.Placed and not profile.PlacedPetIds[pet.PetId] and carry.GetPetId(a) == nil, "Revived pet returns to inventory, not automatic placement")
	check(profile.Food == food and profile.Money == beforeMoney, "Revive does not refund Food or charge Money")
	waitFor(function() return not locks.IsLocked(a) end)
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
	check(revive.HandleRequest(a,"Revive",pet.PetId,attempt).Code == "PetChanged" and profile.PendingRecovery[pet.PetId] ~= nil,
		"Delayed old request cannot revive a newer explosion")
	task.wait(.3)
	local replies = {}
	task.spawn(function() replies[1] = revive.HandleRequest(a,"Revive",pet.PetId,newer.AttemptId) end)
		task.spawn(function() replies[2] = revive.HandleRequest(a,"KeepBase",pet.PetId,newer.AttemptId) end)
	waitFor(function() return replies[1] and replies[2] end)
	check((if replies[1].Ok then 1 else 0)+(if replies[2].Ok then 1 else 0) == 1, "Concurrent duplicate requests restore exactly once")
	waitFor(function() return not locks.IsLocked(a) end)
	check(schema.Validate(profile) and schema.Validate(data.GetData(b)), "Final profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok, checks=checks, failure=if ok then nil else tostring(failure)})
