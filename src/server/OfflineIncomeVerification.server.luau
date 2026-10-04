if not game:GetService("RunService"):IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "OfflineIncomeVerification" then return end
local data = require(script.Parent.Services.DataService)
local service = require(script.Parent.Services.OfflineIncomeService)
local collectTrace = {}
local originalCollect = service.Collect
service.Collect = function(player)
	local profile = data.GetData(player)
	local entry = {Before = profile and profile.OfflineEarnings.PendingMoney}
	table.insert(collectTrace, entry)
	local result = originalCollect(player)
	entry.Result = result
	return result
end
assert(require(script.Parent.Data.DataStoreAdapter).IsMemory(), "Memory-only verification")
local report = Instance.new("RemoteEvent")
report.Name = "OfflineIncomeVerificationReport"
report.Parent = game.ReplicatedStorage
local finished = false
report.OnServerEvent:Connect(function(player, result)
	if finished then return end
	finished = true
	result.collectTrace = collectTrace
	local profile = data.GetData(player)
	if result.passed and (not profile or profile.Money ~= 38000 or profile.OfflineEarnings.PendingMoney ~= 0) then
		result.passed = false; result.failure = "Collection did not credit exact fixture balance"
	end
	testing:EndTest(result)
end)
local function seed(player)
	local seeded = false
	local function ready()
		if seeded or not data.IsLoaded(player) then return end
		seeded = true
		local profile = data.GetData(player)
		profile.Money = 2000
		profile.OfflineEarnings.PendingMoney = 36000
		profile.OfflineEarnings.PendingSeconds = 3600
		profile.Settings.TutorialStep = "Complete"
		report:SetAttribute("Seeded", true)
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(ready)
	ready()
end
game.Players.PlayerAdded:Connect(seed)
for _,player in game.Players:GetPlayers() do seed(player) end
task.delay(240, function()
	if not finished then finished = true; testing:EndTest({passed=false,failure="Offline UI test timed out"}) end
end)
