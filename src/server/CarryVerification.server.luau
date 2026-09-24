local run = game:GetService("RunService")
if not run:IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "CarryVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	local players = game:GetService("Players")
	local data = require(script.Parent.Services.DataService)
	local pets = require(script.Parent.Services.PetService)
	local carry = require(script.Parent.Services.CarryService)
	local plots = require(script.Parent.Services.PlotService)
	local placement = require(script.Parent.Services.PlacementService)
	local ui = require(script.Parent.Services.UIService)
	assert(require(script.Parent.Data.DataStoreAdapter).IsMemory())
	local function waitFor(predicate)
		local deadline = os.clock() + 120
		repeat if predicate() then return end; task.wait(.1) until os.clock() > deadline
		error("Test condition timed out")
	end
	local function check(value, name) assert(value, name); table.insert(checks, name) end
	waitFor(function() return #players:GetPlayers() == 2 end)
	local a, b = table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and a.Character and a.Character:FindFirstChild("HumanoidRootPart") and plots.GetPlot(a) and plots.GetPlot(b) end)
	local plot, other = plots.GetPlot(a), plots.GetPlot(b)
	local pet = assert(pets.CreatePet(a, "test_common"))
	local foreign = assert(pets.CreatePet(b, "test_rare"))
	check(not carry.Equip(a, foreign.PetId) and not carry.Equip(a, {}), "Foreign and malformed equip rejected")
	assert(pets.SetLocked(a, pet.PetId, true))
	check(carry.Equip(a, pet.PetId) and carry.GetPetId(a) == pet.PetId, "Locked owned pet equipped")
	local model = a.Character:FindFirstChild("HeldPet")
	check(model and model:GetAttribute("PetId") == pet.PetId, "Held model retains pet identity")
	local heldBounds, heldSize = model:GetBoundingBox()
	local head = a.Character:FindFirstChild("Head")
	local heldBottom = heldBounds.Position.Y - heldSize.Y / 2
	local headTop = head.Position.Y + head.Size.Y / 2
	check(heldBottom >= headTop + require(game.ReplicatedStorage.Shared.Config.CarryConfig).PetHeadClearance - 0.05
		and (Vector2.new(heldBounds.Position.X, heldBounds.Position.Z) - Vector2.new(head.Position.X, head.Position.Z)).Magnitude < 0.05,
		"Held pet is centered above the player's head")
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then assert(not part.Anchored and not part.CanCollide and part.Massless and part:FindFirstChildOfClass("WeldConstraint")) end
	end
	check(true, "Held model is welded, massless and noncolliding")
	check(carry.Equip(a, pet.PetId) and a.Character:FindFirstChild("HeldPet") == model, "Repeated equip does not duplicate visual")
	local floor = plot.Pen.Floor
	local target = floor.CFrame:PointToWorldSpace(Vector3.new(3.25, floor.Size.Y/2, -2.75))
	local otherTarget = other.Pen.Floor.CFrame:PointToWorldSpace(Vector3.new(0, other.Pen.Floor.Size.Y/2, 0))
	check(not carry.PlaceAt(a, pet.PetId, otherTarget), "Foreign Pen position rejected")
	check(not carry.PlaceAt(a, pet.PetId, {}) and not carry.PlaceAt(a, pet.PetId, Vector3.new(0/0,0,0)), "Malformed and nonfinite coordinates rejected")
	check(not carry.PlaceAt(a, pet.PetId, floor.CFrame:PointToWorldSpace(Vector3.new(100,0,0))), "Outside fence rejected")
	check(not carry.PlaceAt(a, pet.PetId, target + Vector3.new(0,10,0)), "Floating placement rejected")
	check(not carry.PlaceAt(a, foreign.PetId, target), "Stale or foreign held ID rejected")
	a.Character:PivotTo(floor.CFrame * CFrame.new(0,4,100))
	check(not carry.PlaceAt(a, pet.PetId, target), "Distant placement rejected")
	a.Character:PivotTo(floor.CFrame * CFrame.new(0,4,0))
	check(carry.PlaceAt(a, pet.PetId, target), "Held pet placed at clicked coordinates")
	local savedPet = data.GetData(a).Inventory[pet.PetId]
	check(math.abs(savedPet.PenPosition.X-3.25)<.001 and math.abs(savedPet.PenPosition.Z+2.75)<.001, "Exact Pen-local coordinates persisted")
	local visual = plot.Pen.ActivePets[pet.PetId]
	local bounds = visual:GetBoundingBox()
	local localBounds = floor.CFrame:PointToObjectSpace(bounds.Position)
	check(math.abs(localBounds.X-3.25)<.001 and math.abs(localBounds.Z+2.75)<.001, "Visual appears exactly at clicked horizontal spot")
	visual:Destroy()
	check(placement.Reconcile(a) and (placement.GetPetCFrame(a,savedPet).Position-target).Magnitude<.001, "Visual repair retains chosen position")
	local schema = require(script.Parent.Data.PlayerDataSchema)
	local clone = assert(schema.Migrate(data.GetData(a)))
	clone.Inventory[pet.PetId].PenPosition.X = 0
	check(savedPet.PenPosition.X ~= 0, "Position snapshots are isolated")
	assert(data.Save(a))
	local read, record = require(script.Parent.Data.DataStoreAdapter).UpdateAsync("Player_"..a.UserId, function() return nil end)
	check(read and record.Data.Inventory[pet.PetId].PenPosition.X == savedPet.PenPosition.X, "Memory save retains chosen coordinates")
	local legacy = assert(schema.Migrate(data.GetData(a)))
	legacy.DataVersion = 1
	for _, p in legacy.Inventory do p.DataVersion = 1; p.PenPosition = nil end
	local migrated = assert(schema.Migrate(legacy))
	check(migrated.DataVersion == schema.CURRENT_VERSION and migrated.Inventory[pet.PetId].DataVersion == schema.PET_CURRENT_VERSION
		and legacy.DataVersion == 1 and migrated.Inventory[pet.PetId].PetId == pet.PetId,
		"V1 migration preserves IDs without changing input")
	check(not carry.GetPetId(a) and not a.Character:FindFirstChild("HeldPet") and data.GetData(a).Inventory[pet.PetId].Placed, "Placed and held states are exclusive")
	check(not carry.PlaceAt(a, pet.PetId, target), "Duplicate placement rejected")
	a.Character:PivotTo(CFrame.new(target + Vector3.new(0,4,0)))
	local pickupPrompt = plot.Pen.ActivePets[pet.PetId]:FindFirstChildWhichIsA("ProximityPrompt", true)
	check(pickupPrompt and pickupPrompt.KeyboardKeyCode == Enum.KeyCode.E and pickupPrompt.HoldDuration == 1, "Hold-E pickup prompt configured")
	check(not carry.FinishPickup(a, pickupPrompt), "Instant pickup without hold rejected")
	assert(carry.BeginPickup(a, pickupPrompt))
	check(not carry.FinishPickup(a, pickupPrompt), "Short pickup hold rejected")
	assert(carry.BeginPickup(a, pickupPrompt)); carry.CancelPickup(a)
	task.wait(1.1)
	check(not carry.FinishPickup(a, pickupPrompt), "Cancelled pickup hold rejected")
	check(not carry.BeginPickup(b, pickupPrompt), "Other player cannot begin pickup")
	assert(carry.BeginPickup(a, pickupPrompt))
	task.wait(1.1)
	check(carry.FinishPickup(a, pickupPrompt) and not data.GetData(a).Inventory[pet.PetId].Placed, "Held E picks nearby pet into hand")
	check(data.GetData(a).Inventory[pet.PetId].PenPosition == nil, "Pickup clears saved placement coordinates")
	for _ = 1, 5 do local extra = assert(pets.CreatePet(a, "test_common")); assert(placement.PlacePet(a, extra.PetId)) end
	a.Character:PivotTo(plot.Pen.Floor.CFrame * CFrame.new(0,4,0))
	local accepted, code = carry.PlaceAt(a, pet.PetId, target)
	check(not accepted and code == "PenFull" and carry.GetPetId(a) == pet.PetId, "Full Pen leaves pet safely held")
	carry.Unequip(a)
	check(not a.Character:FindFirstChild("HeldPet") and pets.GetPet(a, pet.PetId).Locked, "Unequip preserves locked inventory pet")
	assert(carry.Equip(a, pet.PetId))
	local oldCharacter = a.Character
	a:LoadCharacterAsync()
	waitFor(function() return a.Character and a.Character ~= oldCharacter and a.Character:FindFirstChild("HumanoidRootPart") and not carry.GetPetId(a) end)
	check(not carry.GetPetId(a) and pets.GetPet(a, pet.PetId) ~= nil, "Respawn clears carry without deleting pet")
	task.wait(.3)
	local result = ui.HandleRequest(a, "PlacePet", pet.PetId)
	check(not result.Ok, "Legacy direct placement Remote disabled")
	check(require(script.Parent.Data.PlayerDataSchema).Validate(data.GetData(a)), "Final player schema valid")
	local prompt = plot.Pen.Floor:FindFirstChild("PlaceHeldPet")
	check(prompt == nil, "Old hold-E placement prompt removed")
end, debug.traceback)
testing:EndTest({passed = ok, checks = checks, failure = if ok then nil else tostring(failure)})
