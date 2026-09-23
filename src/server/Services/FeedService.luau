local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataService = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)
local CarryService = require(script.Parent.CarryService)
local Locks = require(script.Parent.FeedLocks)
local Resolver = require(script.Parent.FeedResolver)
local DebugOverrides = require(script.Parent.DebugFeedOverrides)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local PetConfig = require(game.ReplicatedStorage.Shared.Config.PetConfig)
local Config = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local FoodConfig = require(game.ReplicatedStorage.Shared.Config.FoodConfig)
local Variants = require(game.ReplicatedStorage.Shared.Config.VariantConfig)
local PetIncome = require(game.ReplicatedStorage.Shared.PetIncome)
local FeedService = {}
local sessions = {}
local foodChanged, outcomeChanged
local rng = Random.new()
local function session(player)
	local state = sessions[player]
	if not state then
		state = {Sequence=0, LastAttempt=-math.huge, LastSnapshot=-math.huge}
		sessions[player] = state
	end
	return state
end
local function snapshot(player, state, foodId)
	local data = DataService.GetData(player)
	if player.Parent ~= Players or not data or not Schema.Validate(data) then return {Ok=false, Code="Loading"} end
	local pet, reason = PedestalService.GetFeedPet(player)
	foodId = foodId or "basic"
	local food = FoodConfig.Types[foodId]
	if not food then return {Ok=false, Code="InvalidFood"} end
	local definition = pet and PetConfig.Species[pet.SpeciesId]
	local count = 0
	for _ in data.PendingRecovery do count += 1 end
	local risk = pet and Config.ExplosionChance[pet.FeedLevel+1]
	if risk then risk *= 1-food.Reduction end
	return {
		Foods=FoodConfig.Inventory(data), SpeciesId=pet and pet.SpeciesId,
		FoodId=foodId, FoodName=food.Name, FoodReduction=food.Reduction,
		Ok=pet ~= nil, Code=reason, PetId=pet and pet.PetId,
		PetName=pet and Variants.Name(definition and definition.DisplayName or pet.SpeciesId,pet.Variant),
		Rarity=pet and pet.Rarity, FeedLevel=pet and pet.FeedLevel,
		Food=FoodConfig.Count(data,foodId), FoodAt=os.clock(), Cost=pet and FoodConfig.ServingsPerFeed,
		Risk=risk,
		BaseRisk=pet and Config.ExplosionChance[pet.FeedLevel+1],
		MaxLevel=pet and pet.FeedLevel>=Config.MaxConfiguredLevel,
		Busy=Locks.IsLocked(player), NextSequence=state.Sequence+1,
		PendingRecoveryCount=count, LastOutcome=state.LastResult,
	}
end
function FeedService.HandleRequest(player, action, petId, sequence, foodId)
	if player.Parent ~= Players then return {Ok=false, Code="Loading"} end
	if action ~= "Snapshot" and action ~= "Feed" and action ~= "Pickup" then return {Ok=false, Code="InvalidRequest"} end
	local state = session(player)
	local now = os.clock()
	if action == "Snapshot" then
		if now-state.LastSnapshot < .2 then return {Ok=false, Code="Cooldown"} end
		state.LastSnapshot = now
		return snapshot(player, state, foodId)
	end
	if type(petId) ~= "string" or #petId==0 or #petId>64 then return {Ok=false, Code="InvalidRequest"} end
	if action == "Pickup" then
		if Locks.IsLocked(player) then return {Ok=false, Code="Busy"} end
		if now-(state.LastPickup or -math.huge) < .25 then return {Ok=false, Code="Cooldown"} end
		state.LastPickup = now
		local result = snapshot(player, state, foodId)
		if not result.Ok then return result end
		if result.PetId ~= petId then return {Ok=false, Code="PetChanged"} end
		local ok, reason = CarryService.Equip(player, petId)
		return {Ok=ok, Code=if ok then "PickedUp" else reason}
	end
	if type(sequence)~="number" or sequence~=sequence or sequence%1~=0 or sequence<1 or sequence>9007199254740991 then
		return {Ok=false, Code="InvalidRequest"}
	end
	-- Returning the same resolved attempt never rolls or charges again.
	if sequence == state.Sequence and state.LastResult and state.LastResult.PetId == petId then return table.clone(state.LastResult) end
	if sequence <= state.Sequence then return {Ok=false, Code="AlreadyProcessed", NextSequence=state.Sequence+1} end
	if sequence ~= state.Sequence+1 then return {Ok=false, Code="InvalidSequence"} end
	if Locks.IsLocked(player) then return {Ok=false, Code="Busy"} end
	if now-state.LastAttempt < Config.CooldownSeconds then return {Ok=false, Code="Cooldown"} end
	state.LastAttempt = now
	local result = snapshot(player, state, foodId)
	if not result.Ok then return result end
	if result.PetId ~= petId then return {Ok=false, Code="PetChanged"} end
	if result.MaxLevel then return {Ok=false, Code="MaxLevel"} end
	if not result.Cost then return {Ok=false, Code="Unavailable"} end
	if result.Food < result.Cost then result.Ok=false; result.Code="NotEnoughFood"; return result end

	local data = DataService.GetData(player)
	local pet = data.Inventory[petId]
	local before = table.clone(pet)
	before.Traits = table.clone(pet.Traits)
	-- Food and outcome are one non-yielding profile mutation, then one queued
	-- profile save. A failed/ambiguous save NEVER rolls back or rerolls.
	assert(Locks.Begin(player, petId))
	FoodConfig.Add(data,result.FoodId,-result.Cost)
	local forced = DebugOverrides.Resolve(player, petId, pet.FeedLevel)
	local appliedRisk = result.Risk
	local outcome = forced or Resolver.Roll(pet.FeedLevel, state.TestRandom or function() return rng:NextNumber() end, appliedRisk)
	local attemptId = HttpService:GenerateGUID(false)
	if outcome.Code == "Explosion" then
		-- Preserve the pre-failure pet until the owner chooses Revive or level 0.
		-- Only one usable identity may exist; pending pets cannot earn or rebuild.
		data.Inventory[petId] = nil
		data.PendingRecovery[petId] = {Pet=before, AttemptId=attemptId, ExplodedAt=os.time(), FoodSpent=result.Cost}
		outcome.FeedLevel = Config.ExplosionResetLevel
	end
	pet.FeedLevel = outcome.FeedLevel
	if not Schema.Validate(data) then
		FoodConfig.Add(data,result.FoodId,result.Cost)
		pet.FeedLevel = before.FeedLevel
		data.Inventory[petId], data.PendingRecovery[petId] = pet, nil
		Locks.Finish(player)
		return {Ok=false, Code="InvalidData"}
	end
	if forced then DebugOverrides.Consume(player, petId) end
	result.Origin = PedestalService.BeginPresentation(player)
	result.SpeciesId, result.OwnerUserId = pet.SpeciesId, player.UserId
	result.AttemptId, result.OldLevel = attemptId, before.FeedLevel
	result.StartedAt = workspace:GetServerTimeNow()
	result.Code, result.Critical, result.Gain = outcome.Code, outcome.Critical, outcome.Gain
	result.AppliedRisk = appliedRisk
	result.FeedLevel, result.Accepted = outcome.FeedLevel, true
	result.Food, result.FoodAt = FoodConfig.Count(data,result.FoodId), os.clock()
	result.Income = PetIncome(pet,outcome.FeedLevel)
	result.LastOutcome = nil
	state.Sequence = sequence
	result.NextSequence = sequence+1
	state.LastResult = table.clone(result)
	state.TestRandom = nil
	local p = Config.Presentation
	local duration = p.FloatSeconds + p.SpinSeconds + math.max(p.Success.ReturnSeconds,p.MiracleSave.ReturnSeconds,p.Explosion.BurstSeconds+p.Explosion.FadeSeconds)
	local function releaseIfReady()
		if state.Saved and state.PresentationDone and sessions[player]==state then Locks.Finish(player) end
	end
	state.Saved, state.PresentationDone = false, false
	task.delay(duration, function()
		PedestalService.EndPresentation(player, petId, outcome.Code == "Explosion")
		state.PresentationDone = true
		releaseIfReady()
	end)
	-- DataService serializes saves and already retries DataStore failures.
	-- Keep Feed locked until a confirmed save; autosave/leave use the same state.
	task.spawn(function()
		while sessions[player]==state and DataService.GetData(player)==data do
			local ok, saved, reason = pcall(DataService.Save, player)
			if ok and saved then state.Saved=true; releaseIfReady(); return end
			warn("[FeedService] Feed save pending; Feed remains locked:", reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
	if foodChanged then foodChanged:FireClient(player, {Food=FoodConfig.Total(data), FoodAt=result.FoodAt}) end
	if outcomeChanged then
		-- Other players need the visual result, not this player's balance/recovery data.
		outcomeChanged:FireAllClients({Accepted=true, AttemptId=result.AttemptId, OwnerUserId=result.OwnerUserId,
			PetId=petId, SpeciesId=result.SpeciesId, Origin=result.Origin, StartedAt=result.StartedAt,
			OldLevel=result.OldLevel, FeedLevel=result.FeedLevel, Gain=result.Gain,
			Code=result.Code, Critical=result.Critical, Income=result.Income,
			Protected=result.Protected, AppliedRisk=result.AppliedRisk})
	end
	return result
end
-- No remote exposes this. Explicit Studio test + memory-only data are required.
function FeedService.SetTestRandom(player, random)
	assert(game:GetService("RunService"):IsStudio()
		and (game:GetService("StudioTestService"):GetTestArgs()=="FeedVerification"
			or game:GetService("StudioTestService"):GetTestArgs()=="ReviveVerification"
			or game:GetService("StudioTestService"):GetTestArgs()=="FeedPlateUpgradeVerification")
		and require(script.Parent.Parent.Data.DataStoreAdapter).IsMemory(), "Test-only RNG")
	session(player).TestRandom = random
end
function FeedService.Start()
	local request = Instance.new("RemoteFunction")
	request.Name = "PrototypeFeed"
	request.OnServerInvoke = FeedService.HandleRequest
	request.Parent = game.ReplicatedStorage
	foodChanged = Instance.new("RemoteEvent")
	foodChanged.Name = "FeedFoodChanged"
	foodChanged.Parent = game.ReplicatedStorage
	outcomeChanged = Instance.new("RemoteEvent")
	outcomeChanged.Name = "FeedOutcome"
	outcomeChanged.Parent = game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player] = nil; Locks.Finish(player) end)
end
return table.freeze(FeedService)
