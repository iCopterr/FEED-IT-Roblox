local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataService = require(script.Parent.DataService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks = require(script.Parent.FeedLocks)
local MoneyService = require(script.Parent.MoneyService)
local PetConfig = require(game.ReplicatedStorage.Shared.Config.PetConfig)
local Config = require(game.ReplicatedStorage.Shared.Config.ReviveConfig)
local sessions = {}
local Service = {}

function Service.HandleRequest(player, action, petId, attemptId)
	if player.Parent ~= Players then return {Ok=false, Code="Loading"} end
	if action ~= "Snapshot" and action ~= "Revive" then return {Ok=false, Code="InvalidRequest"} end
	local state = sessions[player]
	if not state then state = {}; sessions[player] = state end
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
			table.insert(records, {PetId=id, AttemptId=record.AttemptId,
				PetName=if definition then definition.DisplayName else pet.SpeciesId,
				Rarity=pet.Rarity, FeedLevel=pet.FeedLevel, Income=MoneyService.GetPetRate(pet),
				ExplodedAt=record.ExplodedAt, FoodSpent=record.FoodSpent})
		end
		table.sort(records, function(a,b)
			if a.ExplodedAt ~= b.ExplodedAt then return a.ExplodedAt > b.ExplodedAt end
			return a.PetId < b.PetId
		end)
		return {Ok=true, Records=records, CanRevive=RunService:IsStudio(), Busy=Locks.IsLocked(player)}
	end
	-- The server gate is unconditional. A client flag/config cannot enable free
	-- recovery in a published game; paid receipts are deliberately out of scope.
	if not RunService:IsStudio() then return {Ok=false, Code="StudioOnly"} end
	if type(petId) ~= "string" or #petId == 0 or #petId > 64
		or type(attemptId) ~= "string" or #attemptId == 0 or #attemptId > 64 then
		return {Ok=false, Code="InvalidRequest"}
	end
	local record = data.PendingRecovery[petId]
	-- Bind to the explosion, not only PetId: an old click cannot revive a later
	-- explosion of the same pet. Consuming the record is the durable replay guard.
	if not record then return {Ok=false, Code="Unavailable"} end
	if record.AttemptId ~= attemptId then return {Ok=false, Code="PetChanged"} end
	if not Locks.Begin(player, petId) then return {Ok=false, Code="Busy"} end
	local restored = table.clone(record.Pet)
	restored.Traits = table.clone(record.Pet.Traits)
	if record.Pet.PenPosition then restored.PenPosition = table.clone(record.Pet.PenPosition) end
	data.PendingRecovery[petId] = nil
	data.Inventory[petId] = restored
	if not Schema.Validate(data) then
		data.Inventory[petId] = nil
		data.PendingRecovery[petId] = record
		Locks.Finish(player)
		return {Ok=false, Code="InvalidData"}
	end
	-- No Food refund, new PetId, level reset, placement, or automatic Feed.
	-- Save the inventory/recovery transition together; never roll it back after
	-- an ambiguous write. Feed/placement/pickup remain locked until confirmation.
	task.spawn(function()
		while sessions[player] == state and DataService.GetData(player) == data do
			local ok, saved, reason = pcall(DataService.Save, player)
			if ok and saved then Locks.Finish(player); return end
			warn("[ReviveService] Recovery save pending:", reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
	return {Ok=true, Code="Revived", PetId=petId, AttemptId=attemptId, FeedLevel=restored.FeedLevel}
end

function Service.Start()
	local remote = Instance.new("RemoteFunction")
	remote.Name = "PrototypeRevive"
	remote.OnServerInvoke = Service.HandleRequest
	remote.Parent = game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)
end

return table.freeze(Service)
