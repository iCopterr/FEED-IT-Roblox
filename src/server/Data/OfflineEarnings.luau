local Config = require(game.ReplicatedStorage.Shared.Config.OfflineIncomeConfig)
local PetIncome = require(game.ReplicatedStorage.Shared.PetIncome)
local Earnings = {}

function Earnings.Rate(data)
	local rate = 0
	for id in data.PlacedPetIds do
		local pet = data.Inventory[id]
		if pet and pet.Placed then rate += PetIncome(pet) end
	end
	return if rate == rate and rate < math.huge then rate else 0
end

-- Called ONLY inside the successful session-acquisition UpdateAsync callback.
-- Timestamp and pending reward are persisted together with the acquired lock.
function Earnings.Accrue(data, now)
	local state = data.OfflineEarnings
	local elapsed = if state.CheckpointAt > 0 then math.max(0, now - state.CheckpointAt) else 0
	-- Short reconnects do not bank time toward the threshold. Once one offline
	-- session reaches ten minutes, its complete duration qualifies.
	local seconds = if elapsed >= Config.MinimumSeconds then
		math.min(elapsed, math.max(0, Config.MaxSeconds - state.PendingSeconds)) else 0
	local amount = seconds * Earnings.Rate(data)
	if amount > 0 and amount + state.PendingMoney < math.huge then
		state.PendingMoney += amount
		state.PendingSeconds += seconds
	end
	state.CheckpointAt = math.max(now, state.CheckpointAt)
end

-- No yields: balance and pending reward must always be in the same save snapshot.
function Earnings.Collect(data)
	local state = data.OfflineEarnings
	local amount = state.PendingMoney
	if amount <= 0 or data.Money + amount >= math.huge then return 0 end
	data.Money += amount
	state.PendingMoney, state.PendingSeconds = 0, 0
	return amount
end

return table.freeze(Earnings)
