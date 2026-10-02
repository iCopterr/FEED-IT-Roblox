local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks = require(script.Parent.FeedLocks)
local Recovery = require(game.ReplicatedStorage.Shared.RecoveryPets)
local Config = require(game.ReplicatedStorage.Shared.Config.ReviveConfig)
local Commerce = require(script.Parent.CommerceState)
local sessions = {}
local Service = {}

local function exchangeResult(state, data, code, ok)
	return {
		Ok = ok,
		Code = code,
		ReviveCharges = data.ReviveCharges,
		ReviveShards = data.ReviveShards,
		NextExchangeSequence = (state.ExchangeSequence or 0) + 1,
	}
end

local function saveWhileLocked(player, state, data)
	task.spawn(function()
		while sessions[player] == state and DataService.GetData(player) == data do
			local ok, saved, reason = pcall(DataService.Save, player)
			if ok and saved then Locks.Finish(player); return end
			warn("[ReviveService] State save pending:", reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
end

local function nearMachine(player)
	local machine=workspace:FindFirstChild("ReviveMachine")
	local point=machine and machine:FindFirstChild("InteractionPoint")
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	return point~=nil and root~=nil and humanoid~=nil and humanoid.Health>0
		and (root.Position-point.Position).Magnitude<=Config.MachineDistance
end

function Service.HandleRequest(player, action, petId, attemptId)
	if player.Parent ~= Players then return {Ok=false, Code="Loading"} end
	if action ~= "Snapshot" and action ~= "Repair" and action ~= "Revive" and action ~= "Exchange" then
		return {Ok=false, Code="InvalidRequest"}
	end
	local state = sessions[player]
	if not state then state = {}; sessions[player] = state end
	if action == "Exchange" then
		if type(petId) ~= "number" or petId % 1 ~= 0 or petId < 1 then
			return {Ok=false, Code="InvalidRequest"}
		end
		if petId == state.ExchangeSequence and state.LastExchange then
			return table.clone(state.LastExchange)
		end
		if petId ~= (state.ExchangeSequence or 0) + 1 then
			local data = DataService.GetData(player)
			if not data or not Schema.Validate(data) then return {Ok=false, Code="Loading"} end
			return exchangeResult(state, data, "StaleRequest", false)
		end
	end
	local now = os.clock()
	local key = if action == "Snapshot" then "LastSnapshot" else "LastRequest"
	local cooldown = if action == "Snapshot" then Config.SnapshotCooldown else Config.RequestCooldown
	if now - (state[key] or -math.huge) < cooldown then return {Ok=false, Code="Cooldown"} end
	state[key] = now
	local data = DataService.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false, Code="Loading"} end
	if action == "Snapshot" then
		local records = Recovery.List(data)
		return {Ok=true, Records=records, CanRevive=data.ReviveCharges>0, ReviveCharges=data.ReviveCharges,
			ReviveShards=data.ReviveShards, ShardExchangeCost=Config.Shards.ExchangeCost,
			CanExchange=data.ReviveShards>=Config.Shards.ExchangeCost,
			NextExchangeSequence=(state.ExchangeSequence or 0)+1,
			NearMachine=nearMachine(player), RobuxEnabled=false,
			Busy=Locks.IsLocked(player)}
	end
	if action == "Exchange" then
		if not nearMachine(player) then return exchangeResult(state,data,"TooFar",false) end
		if data.ReviveShards < Config.Shards.ExchangeCost then return exchangeResult(state,data,"NotEnoughShards",false) end
		if not Locks.Begin(player,"ReviveShardExchange") then return exchangeResult(state,data,"Busy",false) end
		local oldShards,oldCharges=data.ReviveShards,data.ReviveCharges
		data.ReviveShards-=Config.Shards.ExchangeCost
		data.ReviveCharges+=1
		if not Schema.Validate(data) then
			data.ReviveShards,data.ReviveCharges=oldShards,oldCharges
			Locks.Finish(player)
			return exchangeResult(state,data,"InvalidData",false)
		end
		state.ExchangeSequence=petId
		local result=exchangeResult(state,data,"Exchanged",true)
		state.LastExchange=table.clone(result)
		saveWhileLocked(player,state,data)
		return result
	end
	if type(petId) ~= "string" or #petId == 0 or #petId > 64
		or type(attemptId) ~= "string" or #attemptId == 0 or #attemptId > 64 then
		return {Ok=false, Code="InvalidRequest"}
	end
	local pet = data.Inventory[petId]
	-- Each damage episode has an ID. Later failures while broken keep that ID;
	-- a repair followed by a new break cannot be repaired with an old request.
	if not pet or not pet.Broken then return {Ok=false, Code="Unavailable"} end
	if pet.BreakId ~= attemptId then return {Ok=false, Code="PetChanged"} end
	if Commerce.ReviveReserved(data,petId,attemptId) then return {Ok=false,Code="Busy"} end
	if not nearMachine(player) then return {Ok=false,Code="TooFar"} end
	if not Locks.Begin(player, petId) then return {Ok=false, Code="Busy"} end
	if data.ReviveCharges<1 then
		Locks.Finish(player);return {Ok=false,Code="NoRevive"}
	end
	local oldCharges=data.ReviveCharges
	data.ReviveCharges-=1
	pet.Broken=nil;pet.BreakId=nil
	if not Schema.Validate(data) then
		pet.Broken=true;pet.BreakId=attemptId
		data.ReviveCharges = oldCharges
		Locks.Finish(player)
		return {Ok=false, Code="InvalidData"}
	end
	-- Repair current progress in place. Save both charm and damage state together;
	-- retries never restore an older level or move a placed/held pet.
	saveWhileLocked(player,state,data)
	return {Ok=true, Code="Repaired",PetId=petId, AttemptId=attemptId, FeedLevel=pet.FeedLevel}
end

function Service.Start()
	local point=workspace:WaitForChild("ReviveMachine"):WaitForChild("InteractionPoint")
	local prompt=point:WaitForChild("OpenReviveMachine")
	prompt.MaxActivationDistance=Config.PromptDistance
	prompt.HoldDuration=Config.PromptHoldSeconds
	prompt.ObjectText=Config.StationName
	local remote = Instance.new("RemoteFunction")
	remote.Name = "PrototypeRevive"
	remote.OnServerInvoke = Service.HandleRequest
	remote.Parent = game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
end

return table.freeze(Service)
