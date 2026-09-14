-- Opt-in integration test: StudioTestService:ExecutePlayModeAsync("PetVerification").
-- Production and ordinary Studio sessions never run these mutations.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "PetVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	assert(RunService:IsServer(), "Server context required")
	local dataService = require(script.Parent.Services.DataService)
	local pets = require(script.Parent.Services.PetService)
	local schema = require(script.Parent.Data.PlayerDataSchema)
	assert(require(script.Parent.Data.DataStoreAdapter).IsMemory(), "Memory data required")
	local player
	local deadline = os.clock() + 20
	repeat
		player = game:GetService("Players"):GetPlayers()[1]
		if player and dataService.IsLoaded(player) then break end
		task.wait(0.1)
	until os.clock() >= deadline
	assert(player and dataService.IsLoaded(player), "Player data load timed out")
	local function check(value, name)
		assert(value, name)
		table.insert(checks, name)
	end
	local first = assert(pets.CreatePet(player, "test_common"))
	local second = assert(pets.CreatePet(player, "test_common"))
	local id = first.PetId
	check(id ~= second.PetId and #id == 36 and #second.PetId == 36, "Unique GUIDs for same species")
	check(first.Rarity == "Common" and first.BaseIncome == 10 and first.FeedLevel == 0, "Authoritative creation defaults")
	first.PetId = "changed"
	first.Traits[1] = "changed"
	local read = assert(pets.GetPet(player, id))
	check(read.PetId == id and #read.Traits == 0, "Create snapshot isolation")
	read.Locked = true
	read.Traits[1] = "changed"
	check(not pets.GetPet(player, id).Locked and #pets.GetPet(player, id).Traits == 0, "Read snapshot isolation")
	local inventory = assert(pets.GetInventory(player))
	inventory[id] = nil
	check(pets.GetPet(player, id) ~= nil, "Inventory snapshot isolation")
	check(pets.SetLocked(player, id, true) and pets.GetPet(player, id).Locked, "Lock pet")
	check(pets.SetLocked(player, id, true), "Repeated lock succeeds")
	local removed, reason = pets.RemovePet(player, id)
	check(removed == nil and reason == "Locked pets cannot be removed" and pets.GetPet(player, id) ~= nil, "Locked removal rejected without loss")
	check(pets.SetLocked(player, id, false) and not pets.GetPet(player, id).Locked, "Unlock pet")
	removed = pets.RemovePet(player, id)
	check(removed and removed.PetId == id and pets.GetPet(player, id) == nil, "Remove preserves returned identity and clears inventory")
	check(pets.RemovePet(player, id) == nil, "Duplicate removal rejected")
	check(pets.GetPet(player, second.PetId) ~= nil, "Other pet unaffected")
	check(pets.CreatePet(player, "not_a_species") == nil, "Unknown species rejected")
	check(not pets.SetLocked(player, second.PetId, "true"), "Invalid lock type rejected")
	assert(pets.RemovePet(player, second.PetId))
	check(schema.Validate(dataService.GetData(player)), "Final player schema valid")
end, debug.traceback)
local result = {passed = ok, checks = checks, failure = if ok then nil else tostring(failure)}
print("PET_VERIFICATION " .. game:GetService("HttpService"):JSONEncode(result))
testing:EndTest(result)
