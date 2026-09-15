-- Opt-in Studio multiplayer integration test; no production/test-data writes.
local run = game:GetService("RunService")
if not run:IsStudio() then return end
local testing = game:GetService("StudioTestService")
if testing:GetTestArgs() ~= "PlotVerification" then return end
local checks = {}
local ok, failure = xpcall(function()
	assert(run:IsServer(), "Server required")
	local players = game:GetService("Players")
	local plots = require(script.Parent.Services.PlotService)
	local data = require(script.Parent.Services.DataService)
	local function waitFor(predicate, message, seconds)
		local deadline = os.clock() + (seconds or 25)
		repeat
			if predicate() then return end
			task.wait(0.1)
		until os.clock() > deadline
		error(message)
	end
	local function check(value, message)
		assert(value, message)
		table.insert(checks, message)
	end
	waitFor(function() return #players:GetPlayers() == 2 end, "Two players did not join", 120)
	local first, second = table.unpack(players:GetPlayers())
	waitFor(function() return plots.GetPlot(first) and plots.GetPlot(second) and data.IsLoaded(first) and data.IsLoaded(second) end, "Plot/data assignment timed out")
	local a, b = plots.GetPlot(first), plots.GetPlot(second)
	check(a ~= b, "Distinct plots for two players")
	check(a:GetAttribute("OwnerUserId") == first.UserId and b:GetAttribute("OwnerUserId") == second.UserId, "Server ownership matches players")
	check(#workspace.PlayerPlots:GetChildren() >= players.MaxPlayers, "Enough static plots for full server")
	check(first.RespawnLocation == a.Spawn and second.RespawnLocation == b.Spawn, "Personal respawn locations")
	check(#a.Pen.Slots:GetChildren() == 5 and #b.Pen.Slots:GetChildren() == 5, "Exactly five slots per Pen")
	check(plots.GetSlotCapacity(first) == 5 and plots.GetSlotCapacity(second) == 5, "Five active slots after data load")
	for i = 1, 5 do
		check(plots.GetSlotCFrame(first, i) == a.Pen.Slots[tostring(i)].CFrame, "Owned slot " .. i)
	end
	check(plots.GetSlotCFrame(first, 0) == nil and plots.GetSlotCFrame(first, 6) == nil and plots.GetSlotCFrame(first, 1.5) == nil and plots.GetSlotCFrame(first, 0/0) == nil, "Invalid slot indices rejected")
	for _, model in workspace.PlayerPlots:GetChildren() do
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then assert(part.Anchored, "Unanchored plot part") end
		end
		assert(#model.Pen.Fence:GetChildren() == 5, "Fence boundary missing")
	end
	check(true, "All plot geometry anchored and fenced")
	waitFor(function() return first.Character and first.Character:FindFirstChild("HumanoidRootPart") and (first.Character.HumanoidRootPart.Position - a.Spawn.Position).Magnitude < 10 end, "Initial spawn did not reach own plot")
	check(true, "Character arrives at owned plot")
	first:LoadCharacterAsync()
	waitFor(function() return first.Character and first.Character:FindFirstChild("HumanoidRootPart") and (first.Character.HumanoidRootPart.Position - a.Spawn.Position).Magnitude < 10 end, "Respawn did not reach own plot")
	check(plots.GetPlot(first) == a, "Respawn preserves plot ownership")
	second:Kick("Plot verification: testing plot release")
	waitFor(function() return plots.GetPlot(second) == nil and b:GetAttribute("OwnerUserId") == 0 end, "Departing plot was not released")
	check(plots.GetPlot(first) == a, "Leaving frees only departing player's plot")
	testing:AddPlayers(1)
	local replacement
	waitFor(function()
		for _, player in players:GetPlayers() do
			if player ~= first and player ~= second then replacement = player end
		end
		return replacement and plots.GetPlot(replacement) ~= nil
	end, "Replacement player did not join", 120)
	check(plots.GetPlot(replacement) == b, "Next player reuses freed plot")
	check(b:GetAttribute("OwnerUserId") == replacement.UserId, "Reused plot has new owner")
end, debug.traceback)
local result = {passed = ok, checks = checks, failure = if ok then nil else tostring(failure)}
print("PLOT_VERIFICATION " .. game:GetService("HttpService"):JSONEncode(result))
testing:EndTest(result)
