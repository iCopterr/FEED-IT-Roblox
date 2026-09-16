if not game:GetService("RunService"):IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "FarmVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	local players = game:GetService("Players")
	local data = require(script.Parent.Services.DataService)
	local plots = require(script.Parent.Services.PlotService)
	local farm = require(script.Parent.Services.FarmService)
	local carry = require(script.Parent.Services.CarryService)
	local pets = require(script.Parent.Services.PetService)
	local adapter = require(script.Parent.Data.DataStoreAdapter)
	assert(adapter.IsMemory(), "Memory test data only")
	local function waitFor(predicate, seconds)
		local deadline = os.clock() + (seconds or 120)
		repeat if predicate() then return end; task.wait(.05) until os.clock() > deadline
		error("Test condition timed out")
	end
	local function check(value, name) assert(value, name); table.insert(checks, name) end
	waitFor(function() return #players:GetPlayers() == 2 end)
	local a, b = table.unpack(players:GetPlayers())
	waitFor(function()
		return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and plots.GetPlot(b)
			and a.Character and a.Character:FindFirstChild("RightHand")
			and b.Character and b.Character:FindFirstChild("HumanoidRootPart") and game.ReplicatedStorage:FindFirstChild("Farm")
	end)
	local profile = data.GetData(a)
	local root = a.Character.HumanoidRootPart
	local humanoid = a.Character.Humanoid
	local own, foreign = plots.GetPlot(a).Farm, plots.GetPlot(b).Farm
	local originalAutoRotate = humanoid.AutoRotate
	-- Keep server-driven test teleports authoritative, independent of client physics.
	root:SetNetworkOwner(nil)
	local function move(point) root.CFrame = point.CFrame + Vector3.new(0,3,0) end
	check(farm.GetRate(a) == 2, "Level-one rate is 2 Food/sec")
	check(not farm.Enter(a), "Distant entry rejected")
	move(foreign.WorkPoint)
	check(not farm.Enter(a), "Another player's farm rejected")
	local before, otherFood = profile.Food, data.GetData(b).Food
	task.wait(1.2)
	check(profile.Food == before, "No passive Food")
	check(not farm.IsFarming(a) and not a:GetAttribute("IsFarming"),
		"Foreign farm did not capture player: "..tostring(root.Position).." own="..tostring(own.WorkPoint.Position))
	local pet = assert(pets.CreatePet(a, "test_common"))
	assert(carry.Equip(a, pet.PetId))
	move(own.WorkPoint)
	check(farm.Enter(a), "Nearby owner enters")
	check(root.Anchored and a:GetAttribute("IsFarming"), "Character held at work point")
	check(not carry.GetPetId(a) and profile.Inventory[pet.PetId] ~= nil, "Held pet preserved in inventory")
	check(not carry.Equip(a, pet.PetId), "Equip blocked while farming")
	check(not farm.Enter(a), "Duplicate entry rejected")
	for _=1,20 do farm.Step(a) end
	check(profile.Food == before, "Repeated calls cannot advance payout")
	waitFor(function() return profile.Food > before end, 5)
	check(profile.Food == before + 2, "Automatic tick pays exactly 2 Food")
	check(data.GetData(b).Food == otherFood, "Only owner receives Food")
	check(not farm.HandleRequest(a, "Award", 999999), "Unknown remote action rejected")
	check(farm.HandleRequest(a, "Exit"), "Exit request accepted")
	check(not root.Anchored and humanoid.AutoRotate == originalAutoRotate and not a:GetAttribute("IsFarming"), "Controls restored")
	check((root.Position-own.ExitPoint.Position).Magnitude < 5, "Character moved outside")
	before = profile.Food
	check(not farm.Enter(a), "No immediate recapture")
	task.wait(1.3)
	check(profile.Food == before, "Exit stops Food")
	move(own.WorkPoint); farm.Step(a)
	check(farm.IsFarming(a), "Proximity automatically enters")
	farm.Exit(a, false); farm.Step(a)
	check(not farm.IsFarming(a), "Must leave area to rearm")
	move(own.ExitPoint); farm.Step(a); move(own.WorkPoint); farm.Step(a)
	check(farm.IsFarming(a), "Leaving area rearms entry")
	root.CFrame += Vector3.new(20,0,0); farm.Step(a)
	check(not farm.IsFarming(a) and not root.Anchored, "Displacement cancels and unlocks")
	farm.Step(a); move(own.WorkPoint); farm.Step(a)
	check(farm.IsFarming(a), "Reentry after cleanup")
	before = profile.Food
	humanoid.Health = 0
	waitFor(function() return not farm.IsFarming(a) end, 5)
	task.wait(1.1)
	check(not root.Anchored and profile.Food == before, "Death stops Food and unlocks")
	assert(data.Save(a))
	local read, record = adapter.UpdateAsync("Player_"..a.UserId, function() return nil end)
	check(read and record.Data.Food == profile.Food, "Food persists in memory save")
	check(require(script.Parent.Data.PlayerDataSchema).Validate(profile), "Final schema valid")
end, debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
