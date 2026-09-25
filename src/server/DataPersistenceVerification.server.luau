-- Opt-in Studio integration coverage for the production player-record shape.
-- Studio still uses process-local memory, so this can never touch live data.
if not game:GetService("RunService"):IsStudio() then return end

local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "DataPersistenceVerification" then return end

local checks = {}
local ok, failure = xpcall(function()
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local DataConfig = require(game.ReplicatedStorage.Shared.Config.DataConfig)
	local adapter = require(script.Parent.Data.DataStoreAdapter)
	local schema = require(script.Parent.Data.PlayerDataSchema)
	local dataService = require(script.Parent.Services.DataService)

	local function check(value: boolean, name: string)
		assert(value, name)
		table.insert(checks, name)
	end

	check(DataConfig.MemoryOnly == false, "Published persistence is enabled")
	check(DataConfig.UseDataStoreInStudio == false, "Studio remote persistence is opt-in")
	check(adapter.IsMemory(), "Studio verification uses isolated memory")
	check(adapter.GetStoreName() == DataConfig.StudioDataStoreName, "Studio store name is isolated")
	check(DataConfig.ProductionDataStoreName ~= DataConfig.StudioDataStoreName, "Production and Studio stores differ")

	local player: Player? = nil
	local deadline = os.clock() + 30
	repeat
		player = Players:GetPlayers()[1]
		if player and dataService.IsLoaded(player) then break end
		task.wait(0.1)
	until os.clock() >= deadline
	assert(player and dataService.IsLoaded(player), "Player data load timed out")

	local data = assert(dataService.GetData(player))
	data.Money = 123456
	data.Food = 4
	data.Foods.fresh = 3
	data.MaxPetSlots = 7
	data.Settings.PersistenceVerification = true
	data.Statistics.PersistenceSaves = 1
	check(schema.Validate(data), "Current gameplay data validates before save")

	local saved, saveError = dataService.Save(player)
	assert(saved, saveError)
	check(saved, "Explicit save succeeds")

	local key = `{DataConfig.PlayerKeyPrefix}{player.UserId}`
	local readSucceeded, storedValue, readError = adapter.UpdateAsync(key, function()
		return nil
	end)
	assert(readSucceeded, readError)
	assert(type(storedValue) == "table", "Stored record is missing")

	local stored = storedValue :: any
	check(stored.RecordVersion == DataConfig.StoredRecordVersion, "Stored envelope version matches")
	check(type(stored.Session) == "table" and type(stored.Session.SessionId) == "string", "Active session lease is stored")
	check(type(stored.LastSavedAt) == "number" and stored.LastSavedAt > 0, "Save timestamp is stored")
	check(stored.Data.Money == 123456 and stored.Data.Food == 4, "Currencies round-trip")
	check(stored.Data.Foods.fresh == 3, "Typed food inventory round-trips")
	check(stored.Data.MaxPetSlots == 7, "Plot capacity round-trips")
	check(stored.Data.Settings.PersistenceVerification == true, "Settings round-trip")
	check(stored.Data.Statistics.PersistenceSaves == 1, "Statistics round-trip")
	check(schema.Validate(stored.Data), "Stored gameplay payload validates")

	stored.Data.Money = 0
	local rereadSucceeded, rereadValue = adapter.UpdateAsync(key, function()
		return nil
	end)
	assert(rereadSucceeded and type(rereadValue) == "table")
	check((rereadValue :: any).Data.Money == 123456, "Stored reads are copy-isolated")

	local cancelledSucceeded = adapter.UpdateAsync(key, function(current)
		assert(type(current) == "table")
		local currentRecord = current :: any
		currentRecord.Data.Money = 1
		return nil
	end)
	assert(cancelledSucceeded)
	local finalReadSucceeded, finalValue = adapter.UpdateAsync(key, function()
		return nil
	end)
	assert(finalReadSucceeded and type(finalValue) == "table")
	check((finalValue :: any).Data.Money == 123456, "Cancelled update cannot mutate stored data")

	local encoded = HttpService:JSONEncode((finalValue :: any).Data)
	check(#encoded > 0, "Player payload is DataStore-serializable")
end, debug.traceback)

local result = {
	passed = ok,
	checks = checks,
	failure = if ok then nil else tostring(failure),
}
print("DATA_PERSISTENCE_VERIFICATION " .. game:GetService("HttpService"):JSONEncode(result))
testing:EndTest(result)
