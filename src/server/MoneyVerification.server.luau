local run = game:GetService("RunService")
if not run:IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "MoneyVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	local players = game:GetService("Players")
	local data = require(script.Parent.Services.DataService)
	local pets = require(script.Parent.Services.PetService)
	local placement = require(script.Parent.Services.PlacementService)
	local carry = require(script.Parent.Services.CarryService)
	local money = require(script.Parent.Services.MoneyService)
	local plots = require(script.Parent.Services.PlotService)
	local adapter = require(script.Parent.Data.DataStoreAdapter)
	assert(adapter.IsMemory(), "Memory test data only")
	local function waitFor(predicate)
		local deadline = os.clock() + 120
		repeat if predicate() then return end; task.wait(.1) until os.clock() > deadline
		error("Test condition timed out")
	end
	local function check(value, name) assert(value, name); table.insert(checks,name) end
	waitFor(function() return #players:GetPlayers()==2 end)
	local a,b = table.unpack(players:GetPlayers())
	waitFor(function() return data.IsLoaded(a) and data.IsLoaded(b) and plots.GetPlot(a) and plots.GetPlot(b) and a.Character and a.Character:FindFirstChild("RightHand") end)
	local profile = data.GetData(a)
	local common = assert(pets.CreatePet(a,"test_common"))
	local rare = assert(pets.CreatePet(a,"test_rare"))
	local held = assert(pets.CreatePet(a,"test_uncommon"))
	check(money.GetRate(a)==0 and money.Tick(a)==0, "Stored pets earn nothing")
	assert(carry.Equip(a,held.PetId))
	check(money.GetRate(a)==0, "Held pets earn nothing")
	assert(placement.PlacePet(a,common.PetId))
	check(money.GetRate(a)==10, "Placed level-zero Common earns 10 per second")
	local before = profile.Money
	check(money.Tick(a)==10 and profile.Money==before+10, "One-second tick credits exact income")
	before=profile.Money
	for _ = 1,4 do money.Tick(a) end
	check(profile.Money==before+40, "Four one-second ticks credit four seconds of income")
	assert(pets.SetLocked(a,common.PetId,true))
	check(money.GetRate(a)==10, "Locked placed pets still earn")
	assert(placement.PlacePet(a,rare.PetId))
	check(money.GetRate(a)==510, "Placed pet rates add together")
	profile.Inventory[common.PetId].FeedLevel=1
	check(money.GetRate(a)==513, "Feed multiplier applies to income")
	profile.Inventory[common.PetId].FeedLevel=40
	check(money.GetRate(a)==50000500, "Level 40 uses locked GDD multiplier")
	profile.Inventory[common.PetId].FeedLevel=41
	check(money.GetRate(a)==500, "Unbalanced levels are not extrapolated")
	profile.Inventory[common.PetId].FeedLevel=0
	local foreign = assert(pets.CreatePet(b,"test_mythic"))
	assert(placement.PlacePet(b,foreign.PetId))
	check(money.GetRate(a)==510 and money.GetRate(b)==45000, "Income belongs only to each pet owner")
	before=profile.Money
	waitFor(function() return profile.Money>=before+510 end)
	check(true, "Automatic income loop runs")
	assert(placement.PickupPet(a,common.PetId))
	check(money.GetRate(a)==500, "Pickup stops that pet income immediately")
	assert(placement.PickupPet(a,rare.PetId))
	before=profile.Money
	task.wait(2.2)
	check(profile.Money==before and money.GetRate(a)==0, "Empty Pen receives no further ticks")
	local saved = profile.Money
	assert(data.Save(a))
	local read,record=adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
	check(read and record.Data.Money==saved, "Money persists in profile memory save")
	check(require(script.Parent.Data.PlayerDataSchema).Validate(profile), "Final player schema valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
