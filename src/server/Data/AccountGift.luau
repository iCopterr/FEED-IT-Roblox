--!strict
local Config = require(script.Parent.Parent.Config.AccountGiftConfig)
local Schema = require(script.Parent.PlayerDataSchema)
local Food = require(game.ReplicatedStorage.Shared.Config.FoodConfig)
type PlayerData = Schema.PlayerData
local Gift = {}
local MAX_SAFE_INTEGER = 9007199254740991

function Gift.Apply(data: PlayerData, userId: number): (PlayerData, boolean)
	if not Config.UserIds[userId] or data.Settings[Config.ClaimKey] == true then
		return data, false
	end
	-- Acquisition operates on a detached record. Rewards and their durable claim
	-- marker commit in the same UpdateAsync; retries/rejoins never add them twice.
	local draft = assert(Schema.Migrate(data))
	assert(draft.ReviveCharges <= MAX_SAFE_INTEGER-Config.RepairCharms, "Repair gift balance overflow")
	for _,id in Food.Order do
		assert(Food.Count(draft,id) <= MAX_SAFE_INTEGER-Config.FoodEach, "Food gift balance overflow")
		Food.Add(draft,id,Config.FoodEach)
	end
	draft.ReviveCharges += Config.RepairCharms
	draft.Settings[Config.ClaimKey] = true
	assert(Schema.Validate(draft))
	return draft, true
end

return table.freeze(Gift)
