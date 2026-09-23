local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.MoneyConfig)
local PetIncome = require(game.ReplicatedStorage.Shared.PetIncome)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local MoneyService = {}
local started = false
local payoutEvent

function MoneyService.GetPetRate(pet)
	-- Levels above 40 are unbalanced; never extrapolate an economy curve.
	return PetIncome(pet)
end

function MoneyService.GetRate(player)
	local data = DataService.GetData(player)
	if player.Parent ~= Players or not data or not PlotService.GetPlot(player) or not Schema.Validate(data) then return 0 end
	local rate = 0
	for id in data.PlacedPetIds do
		local pet = data.Inventory[id]
		if pet and pet.Placed then rate += MoneyService.GetPetRate(pet) end
	end
	return if rate < math.huge then rate else 0
end

-- Server-only fixed tick: callers/clients cannot supply an amount or elapsed time.
function MoneyService.Tick(player)
	local data = DataService.GetData(player)
	if not data then return 0 end
	local rate = MoneyService.GetRate(player)
	local amount = rate * Config.TickSeconds
	local nextMoney = data.Money + amount
	if amount <= 0 or nextMoney ~= nextMoney or nextMoney == math.huge then return 0 end
	data.Money = nextMoney
	if payoutEvent then
		local entries = {}
		for id in data.PlacedPetIds do
			local petAmount = MoneyService.GetPetRate(data.Inventory[id]) * Config.TickSeconds
			if petAmount > 0 then table.insert(entries, {PetId = id, Amount = petAmount}) end
		end
		payoutEvent:FireClient(player, {Money = nextMoney, IncomePerSecond = rate, MoneyAt = os.clock(), Pets = entries})
	end
	return amount
end

function MoneyService.Start()
	assert(not started, "MoneyService already started")
	started = true
	payoutEvent = Instance.new("RemoteEvent")
	payoutEvent.Name = "PetIncome"
	payoutEvent.Parent = game.ReplicatedStorage
	task.spawn(function()
		while true do
			task.wait(Config.TickSeconds)
			for _, player in Players:GetPlayers() do MoneyService.Tick(player) end
		end
	end)
end

return table.freeze(MoneyService)
