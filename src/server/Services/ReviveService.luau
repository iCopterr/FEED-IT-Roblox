local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks = require(script.Parent.FeedLocks)
local MoneyService = require(script.Parent.MoneyService)
local PetConfig = require(game.ReplicatedStorage.Shared.Config.PetConfig)
local Config = require(game.ReplicatedStorage.Shared.Config.ReviveConfig)
local Commerce = require(script.Parent.CommerceState)
local FeedConfig = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local Variants = require(game.ReplicatedStorage.Shared.Config.VariantConfig)
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

local function expiresAt(record)
	return record.ExplodedAt + Config.WindowSeconds
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
	if action ~= "Snapshot" and action ~= "Revive" and action ~= "KeepBase" and action ~= "Exchange" then
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
		local records = {}
		for id, record in data.PendingRecovery do
			local pet = record.Pet
			local definition = PetConfig.Species[pet.SpeciesId]
			table.insert(records, {PetId=id, AttemptId=record.AttemptId, SpeciesId=pet.SpeciesId, Variant=pet.Variant,
				PetName=Variants.Name(if definition then definition.DisplayName else pet.SpeciesId,pet.Variant),
				Rarity=pet.Rarity, FeedLevel=pet.FeedLevel, Income=MoneyService.GetPetRate(pet),
				ExplodedAt=record.ExplodedAt, ExpiresAt=expiresAt(record), FoodSpent=record.FoodSpent})
		end
		table.sort(records, function(a,b)
			if a.ExplodedAt ~= b.ExplodedAt then return a.ExplodedAt > b.ExplodedAt end
			return a.PetId < b.PetId
		end)
		return {Ok=true, Records=records, CanRevive=data.ReviveCharges>0, ReviveCharges=data.ReviveCharges,
			ReviveShards=data.ReviveShards, ShardExchangeCost=Config.Shards.ExchangeCost,
			CanExchange=data.ReviveShards>=Config.Shards.ExchangeCost,
			NextExchangeSequence=(state.ExchangeSequence or 0)+1,
			NearMachine=nearMachine(player), RobuxEnabled=false,
			ServerNow=os.time(), ResetLevel=FeedConfig.ExplosionResetLevel, Busy=Locks.IsLocked(player)}
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
	local record = data.PendingRecovery[petId]
	-- Bind to the explosion, not only PetId: an old click cannot revive a later
	-- explosion of the same pet. Consuming the record is the durable replay guard.
	if not record then return {Ok=false, Code="Unavailable"} end
	if record.AttemptId ~= attemptId then return {Ok=false, Code="PetChanged"} end
	if Commerce.ReviveReserved(data,petId,attemptId) then return {Ok=false,Code="Busy"} end
	local expired = os.time() >= expiresAt(record)
	if expired then action = "KeepBase" end
	-- Expired pets return to base without travel; restoring growth requires the machine.
	if not expired and not nearMachine(player) then return {Ok=false,Code="TooFar"} end
	if not Locks.Begin(player, petId) then return {Ok=false, Code="Busy"} end
	if action=="Revive" and data.ReviveCharges<1 then
		Locks.Finish(player);return {Ok=false,Code="NoRevive"}
	end
	local oldCharges=data.ReviveCharges
	if action=="Revive" then data.ReviveCharges-=1 end
	local restored = table.clone(record.Pet)
	restored.Traits = table.clone(record.Pet.Traits)
	if record.Pet.PenPosition then restored.PenPosition = table.clone(record.Pet.PenPosition) end
	if action == "KeepBase" then restored.FeedLevel = FeedConfig.ExplosionResetLevel end
	data.PendingRecovery[petId] = nil
	data.Inventory[petId] = restored
	if not Schema.Validate(data) then
		data.Inventory[petId] = nil
		data.PendingRecovery[petId] = record
		data.ReviveCharges = oldCharges
		Locks.Finish(player)
		return {Ok=false, Code="InvalidData"}
	end
	-- Both decisions consume this offer. No Food refund, new identity, placement
	-- or automatic Feed. KeepBase is irreversible, including after a reconnect.
	-- Save the inventory/recovery transition together; never roll it back after
	-- an ambiguous write. Feed/placement/pickup remain locked until confirmation.
	saveWhileLocked(player,state,data)
	return {Ok=true, Expired=expired, Code=if action=="KeepBase" then "KeptBase" else "Revived",
		PetId=petId, AttemptId=attemptId, FeedLevel=restored.FeedLevel}
end

function Service.Start()
	local point=workspace:WaitForChild("ReviveMachine"):WaitForChild("InteractionPoint")
	local prompt=point:WaitForChild("OpenReviveMachine")
	prompt.MaxActivationDistance=Config.PromptDistance
	prompt.HoldDuration=Config.PromptHoldSeconds
	local remote = Instance.new("RemoteFunction")
	remote.Name = "PrototypeRevive"
	remote.OnServerInvoke = Service.HandleRequest
	remote.Parent = game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
	-- Expiry is server-owned and keeps the same deadline across reconnects.
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local data = DataService.GetData(player)
				if data and not Locks.IsLocked(player) then
					for id, record in data.PendingRecovery do
						if os.time() >= expiresAt(record) and not Commerce.ReviveReserved(data,id,record.AttemptId) then
							-- Client request spam cannot postpone automatic expiry.
							if sessions[player] then sessions[player].LastRequest = nil end
							Service.HandleRequest(player,"KeepBase",id,record.AttemptId)
							break
						end
					end
				end
			end
			task.wait(.25)
		end
	end)
end

return table.freeze(Service)
