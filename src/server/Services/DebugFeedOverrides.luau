local RunService = game:GetService("RunService")
local Adapter = require(script.Parent.Parent.Data.DataStoreAdapter)
local Config = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local modes = require(game.ReplicatedStorage.Shared.Config.DebugConfig).Modes
local pending = {}
local Overrides = {}

function Overrides.Enabled()
	return RunService:IsStudio() and Adapter.IsMemory()
end

function Overrides.Arm(player, petId, mode)
	if not Overrides.Enabled() or not table.find(modes, mode) then return false end
	pending[player] = if mode == "Clear" then nil else {PetId=petId, Mode=mode}
	return true
end

function Overrides.Get(player)
	local entry = pending[player]
	return if Overrides.Enabled() and entry then table.clone(entry) else nil
end

-- Only FeedService calls this, after ordinary ownership/cost/state validation.
-- No RNG/config changes persist or affect another player/pet.
function Overrides.Resolve(player, petId, level)
	local entry = Overrides.Get(player)
	if not entry or entry.PetId ~= petId then return nil end
	if entry.Mode == "Explosion" then return {Code="Explosion", FeedLevel=level, Gain=0} end
	local id = if entry.Mode == "Success" then "Normal" else entry.Mode
	for _, result in Config.CriticalResults do
		if result.Id == id then
			local final = math.min(Config.MaxConfiguredLevel, level + result.LevelGain)
			return {Code="Success", Critical=id, FeedLevel=final, Gain=final-level}
		end
	end
	return nil
end

function Overrides.Consume(player, petId)
	if pending[player] and pending[player].PetId == petId then pending[player] = nil end
end

game:GetService("Players").PlayerRemoving:Connect(function(player) pending[player] = nil end)
return table.freeze(Overrides)
