-- Explicit opt-in only; disposable Studio players and memory storage.
local run = game:GetService("RunService")
if not run:IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "PlacementVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	local players = game:GetService("Players")
	local dataService = require(script.Parent.Services.DataService)
	local pets = require(script.Parent.Services.PetService)
	local placement = require(script.Parent.Services.PlacementService)
	local plots = require(script.Parent.Services.PlotService)
	local schema = require(script.Parent.Data.PlayerDataSchema)
	local adapter = require(script.Parent.Data.DataStoreAdapter)
	assert(adapter.IsMemory(), "Memory data required")
	local function waitFor(predicate)
		local deadline = os.clock() + 120
		repeat if predicate() then return end; task.wait(.1) until os.clock() > deadline
		error("Player/test condition timed out")
	end
	local function check(value, name)
		assert(value, name); table.insert(checks, name)
	end
	waitFor(function() return #players:GetPlayers() == 2 end)
	local a, b = table.unpack(players:GetPlayers())
	waitFor(function() return dataService.IsLoaded(a) and dataService.IsLoaded(b) and plots.GetPlot(a) and plots.GetPlot(b) end)
	local data, plot = dataService.GetData(a), plots.GetPlot(a)
	local ids = {}
	for i = 1, 6 do ids[i] = assert(pets.CreatePet(a, "test_common")).PetId end
	local foreign = assert(pets.CreatePet(b, "test_rare")).PetId
	check(not placement.PlacePet(a, foreign) and not placement.PickupPet(a, foreign), "Foreign pet rejected for both actions")
	check(not placement.PlacePet(a, {}) and not placement.PickupPet(a, string.rep("x", 65)), "Invalid arguments rejected")
	for i = 1, 5 do
		check(placement.PlacePet(a, ids[i]) and data.Inventory[ids[i]].PlotSlot == i, "First-free slot " .. i)
	end
	local accepted, code = placement.PlacePet(a, ids[6])
	check(not accepted and code == "PenFull" and not data.Inventory[ids[6]].Placed, "Sixth active pet rejected without mutation")
	check(placement.PlacePet(a, ids[1]) and #plot.Pen.ActivePets:GetChildren() == 5, "Repeat placement is idempotent")
	check(not pets.RemovePet(a, ids[1]), "Placed pet cannot be deleted")
	local before = pets.GetPet(a, ids[1])
	assert(pets.SetLocked(a, ids[1], true))
	check(placement.PickupPet(a, ids[1]) and placement.PickupPet(a, ids[1]), "Locked pickup and repeated pickup succeed")
	local after = pets.GetPet(a, ids[1])
	check(after.PetId == before.PetId and after.CreatedAt == before.CreatedAt and after.FeedLevel == before.FeedLevel and after.Locked and not after.Placed and after.PlotSlot == nil and not data.PlacedPetIds[ids[1]], "Pickup preserves identity, lock and progression")
	check(#plot.Pen.ActivePets:GetChildren() == 4, "Pickup removes only one visual")
	check(placement.PlacePet(a, ids[6]) and data.Inventory[ids[6]].PlotSlot == 1, "Freed slot reused")
	assert(placement.PickupPet(a, ids[6]))
	local template = workspace.PetTemplates.test_common
	template.Name = "UnavailableDuringTest"
	local missing, reason = placement.PlacePet(a, ids[1])
	template.Name = "test_common"
	check(not missing and reason == "TemplateUnavailable" and not data.Inventory[ids[1]].Placed, "Missing template does not commit placement")
	check(placement.PlacePet(a, ids[1]), "Locked pet can be placed")
	plot.Pen.ActivePets:Destroy()
	check(placement.Reconcile(a) and #plot.Pen.ActivePets:GetChildren() == 5, "Saved placement rebuilds missing visuals")
	for _, model in plot.Pen.ActivePets:GetChildren() do
		assert(model:GetAttribute("OwnerUserId") == a.UserId and model:GetAttribute("PetId") == model.Name)
		local bounds = model:GetBoundingBox()
		assert((bounds.Position - plots.GetSlotCFrame(a, model:GetAttribute("PlotSlot")).Position).Magnitude < 3)
	end
	check(true, "Visual identities and positions match owned slots")
	check(schema.Validate(data), "Complete player schema remains valid")
	assert(dataService.Save(a))
	local read, record = adapter.UpdateAsync("Player_" .. a.UserId, function() return nil end)
	check(read and record.Data.Inventory[ids[1]].Placed and record.Data.Inventory[ids[1]].Locked and record.Data.Inventory[ids[1]].PetId == ids[1], "Memory save retains identity, placement and lock")
	local clone = assert(schema.Migrate(record.Data))
	check(clone.Inventory[ids[1]].PlotSlot == data.Inventory[ids[1]].PlotSlot and clone.Inventory[ids[1]] ~= data.Inventory[ids[1]], "Reload migration preserves placement with isolated records")
	local ui = require(script.Parent.Services.UIService)
	local function request(action, id)
		for _ = 1, 20 do
			task.wait(.3)
			local response = ui.HandleRequest(a, action, id)
			if response.Code ~= "Cooldown" then return response end
		end
		error("Request remained throttled")
	end
	check(not request("PickupPet", ids[1]).Ok and not request("PlacePet", ids[1]).Ok, "Legacy placement remotes disabled; carry prompt required")
	check(not request("EquipPet", foreign).Ok and not request("EquipPet", {}).Ok, "Remote handler rejects foreign and malformed input")
	local snapshot = request("Snapshot")
	check(snapshot.Ok and snapshot.PlacedCount == 5 and snapshot.Inventory[ids[1]].Placed, "UI snapshot reflects authoritative placement")
	check(ui.HandleRequest(a, "PickupPet", ids[1]).Code == "Cooldown", "Remote spam is throttled")
	snapshot.Inventory[ids[1]].Placed = false
	check(data.Inventory[ids[1]].Placed, "UI snapshot cannot mutate placement")
	a:Kick("Placement verification: release check")
	waitFor(function() return plots.GetPlot(a) == nil and not plot.Pen:FindFirstChild("ActivePets") end)
	check(data.Inventory[ids[1]].Placed, "Departure clears visuals without erasing saved placement")
	testing:AddPlayers(1)
	local replacement
	waitFor(function()
		for _, p in players:GetPlayers() do if p ~= a and p ~= b then replacement = p end end
		return replacement and dataService.IsLoaded(replacement) and plots.GetPlot(replacement)
	end)
	assert(placement.Reconcile(replacement))
	check(plots.GetPlot(replacement) == plot and #plot.Pen.ActivePets:GetChildren() == 0, "New owner receives empty plot")
end, debug.traceback)
local result = {passed = ok, checks = checks, failure = if ok then nil else tostring(failure)}
print("PLACEMENT_VERIFICATION " .. game:GetService("HttpService"):JSONEncode(result))
testing:EndTest(result)
