if not game:GetService("RunService"):IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "WanderingVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	local services = script.Parent.Services
	local data = require(services.DataService)
	local pets = require(services.PetService)
	local plots = require(services.PlotService)
	local placement = require(services.PlacementService)
	local wander = require(services.WanderingService)
	local carry = require(services.CarryService)
	local money = require(services.MoneyService)
	local adapter = require(script.Parent.Data.DataStoreAdapter)
	local petModels = require(game.ReplicatedStorage.Shared.PetModels)
	local feedConfig = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
	assert(adapter.IsMemory(), "Memory-only verification")
	local function check(value, name) assert(value, name); table.insert(checks, name) end
	local function waitFor(predicate)
		local deadline = os.clock() + 120
		repeat if predicate() then return end; task.wait(.05) until os.clock() > deadline
		error("Test timed out")
	end
	local players = game:GetService("Players")
	waitFor(function() return #players:GetPlayers() == 2 end)
	local a, b = table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a)
		and a.Character and a.Character:FindFirstChild("RightHand") and game.ReplicatedStorage:FindFirstChild("BuyConveyorEgg") end)
	local root = a.Character.HumanoidRootPart
	root:SetNetworkOwner(nil); root.Anchored = true
	local pet = assert(pets.CreatePet(a, "test_common"))
	local floor = plots.GetPlot(a).Pen.Floor
	local anchor = floor.CFrame:PointToWorldSpace(Vector3.new(-12, floor.Size.Y/2, 0))
	assert(placement.PlacePet(a, pet.PetId, anchor))
	local profile = data.GetData(a)
	local savedPosition = table.clone(profile.Inventory[pet.PetId].PenPosition)
	local model = plots.GetPlot(a).Pen.ActivePets[pet.PetId]
	local initial = model:GetPivot()
	local rate = money.GetRate(a)
	check(wander.IsTracked(model), "Placed pet registered for wandering")
	for _ = 1, 150 do wander.Step(.1) end
	check((model:GetPivot().Position - initial.Position).Magnitude > .1, "Walk/pause cycle moves pet")
	check(profile.Inventory[pet.PetId].PenPosition.X == savedPosition.X and profile.Inventory[pet.PetId].PenPosition.Z == savedPosition.Z,
		"Wandering preserves saved placement anchor")
	check(money.GetRate(a) == rate and rate > 0, "Wandering preserves income rate")
	local current = model:GetPivot()
	assert(placement.Reconcile(a))
	check(model:GetPivot() == current, "Reconciliation does not snap pet home")
	root.CFrame = current + Vector3.new(0, 2, 2)
	local prompt = model:FindFirstChild("PickupPet", true)
	check(not carry.BeginPickup(b, prompt), "Foreign player cannot pause or pick up pet")
	check(carry.BeginPickup(a, prompt), "Pickup begins at live pet position")
	for _ = 1, 100 do wander.Step(.1) end
	check(model:GetPivot() == current, "Pet pauses during pickup hold")
	check(not carry.FinishPickup(a, prompt), "Short hold still rejected")
	assert(carry.BeginPickup(a, prompt)); task.wait(1.05)
	check(carry.FinishPickup(a, prompt), "Full hold picks up wandering pet")
	task.wait()
	check(model.Parent == nil and not wander.IsTracked(model), "Pickup destroys visual and clears wandering")
	check(carry.GetPetId(a) == pet.PetId and money.GetRate(a) == 0, "Held pet retains identity and stops income")
	carry.Unequip(a)
	assert(placement.PlacePet(a, pet.PetId, anchor))
	local repaired = plots.GetPlot(a).Pen.ActivePets[pet.PetId]
	repaired:Destroy(); assert(placement.Reconcile(a))
	check(wander.IsTracked(plots.GetPlot(a).Pen.ActivePets[pet.PetId]), "Visual repair restarts wandering without new pet")
	assert(data.Save(a))
	local read, record = adapter.UpdateAsync("Player_" .. a.UserId, function() return nil end)
	check(read and record.Data.Inventory[pet.PetId].PenPosition.X == savedPosition.X, "Save retains original placement and PetId")
	-- Exercise authored floors on both rotated rows, with grown template clones.
	for _, plot in workspace.PlayerPlots:GetChildren() do
		if not plot:IsA("Model") then continue end
		local testModel = assert(petModels.GetTemplate("test_common")):Clone()
		testModel:ScaleTo(feedConfig.MaxVisualScale)
		local bounds, size = testModel:GetBoundingBox()
		local penFloor = plot.Pen.Floor
		testModel:PivotTo(penFloor.CFrame * CFrame.new(0, penFloor.Size.Y/2 + size.Y/2 + .05, 0) * bounds:ToObjectSpace(testModel:GetPivot()))
		testModel.Parent = plot.Pen
		wander.Track(testModel, penFloor)
		for _ = 1, 800 do
			wander.Step(.1)
			local cf, dimensions = testModel:GetBoundingBox()
			for _, x in {-1, 1} do for _, z in {-1, 1} do
				local corner = penFloor.CFrame:PointToObjectSpace(cf:PointToWorldSpace(Vector3.new(x*dimensions.X/2, 0, z*dimensions.Z/2)))
				assert(math.abs(corner.X) < penFloor.Size.X/2 and math.abs(corner.Z) < penFloor.Size.Z/2, "Fence escape")
			end end
		end
		testModel:Destroy()
		check(true, "Grown pet remains inside " .. plot.Name)
	end
	check(require(script.Parent.Data.PlayerDataSchema).Validate(profile), "Final profile valid")
end, debug.traceback)
testing:EndTest({passed = ok, checks = checks, failure = if ok then nil else tostring(failure)})
