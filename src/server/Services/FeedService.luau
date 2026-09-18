local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local PedestalService = require(script.Parent.PedestalService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local PetConfig = require(game.ReplicatedStorage.Shared.Config.PetConfig)
local FeedService = {}
-- Temporary consumption-only prototype; no Feed config requested yet.
local FOOD_COST = 1
local FEED_COOLDOWN = 0.5
local sessions = {}
local foodChanged

local function session(player)
	local state = sessions[player]
	if not state then
		state = {Sequence=0, LastAttempt=-math.huge, LastSnapshot=-math.huge}
		sessions[player] = state
	end
	return state
end

local function snapshot(player, state)
	local data = DataService.GetData(player)
	if player.Parent ~= Players or not data or not Schema.Validate(data) then return {Ok=false, Code="Loading"} end
	local pet, reason = PedestalService.GetFeedPet(player)
	local definition = pet and PetConfig.Species[pet.SpeciesId]
	return {
		Ok=pet ~= nil, Code=reason, PetId=pet and pet.PetId,
		PetName=pet and (definition and definition.DisplayName or pet.SpeciesId),
		Rarity=pet and pet.Rarity, FeedLevel=pet and pet.FeedLevel,
		Food=data.Food, FoodAt=os.clock(), Cost=FOOD_COST, NextSequence=state.Sequence+1,
	}
end

function FeedService.HandleRequest(player, action, petId, sequence)
	if player.Parent ~= Players then return {Ok=false, Code="Loading"} end
	if action ~= "Snapshot" and action ~= "Feed" then return {Ok=false, Code="InvalidRequest"} end
	local state = session(player)
	local now = os.clock()
	if action == "Snapshot" then
		if now-state.LastSnapshot < .2 then return {Ok=false, Code="Cooldown"} end
		state.LastSnapshot = now
		return snapshot(player, state)
	end
	if type(petId) ~= "string" or #petId==0 or #petId>64 or type(sequence)~="number"
		or sequence~=sequence or sequence%1~=0 or sequence<1 or sequence>9007199254740991 then
		return {Ok=false, Code="InvalidRequest"}
	end
	-- Sequence survives plate swaps for this player session; stale/replayed
	-- requests never consume twice, even after another feed has completed.
	if sequence <= state.Sequence then return {Ok=false, Code="AlreadyProcessed", NextSequence=state.Sequence+1} end
	if sequence ~= state.Sequence+1 then return {Ok=false, Code="InvalidSequence"} end
	if now-state.LastAttempt < FEED_COOLDOWN then return {Ok=false, Code="Cooldown"} end
	state.LastAttempt = now
	local result = snapshot(player, state)
	if not result.Ok then return result end
	if result.PetId ~= petId then return {Ok=false, Code="PetChanged"} end
	if result.Food < FOOD_COST then result.Ok=false; result.Code="NotEnoughFood"; return result end
	local data = DataService.GetData(player)
	-- No yielding between validation, deduction and replay protection. Neither
	-- client values nor presentation decide cost, ownership, or inventory changes.
	data.Food -= FOOD_COST
	state.Sequence = sequence
	result.Food, result.FoodAt = data.Food, os.clock()
	result.NextSequence, result.Code = state.Sequence+1, "Consumed"
	if foodChanged then foodChanged:FireClient(player, {Food=result.Food, FoodAt=result.FoodAt}) end
	return result
end

function FeedService.Start()
	local request = Instance.new("RemoteFunction")
	request.Name = "PrototypeFeed"
	request.OnServerInvoke = FeedService.HandleRequest
	request.Parent = game.ReplicatedStorage
	foodChanged = Instance.new("RemoteEvent")
	foodChanged.Name = "FeedFoodChanged"
	foodChanged.Parent = game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
end

return table.freeze(FeedService)
