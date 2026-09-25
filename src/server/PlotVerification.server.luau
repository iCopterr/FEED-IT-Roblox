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
	check(a.OwnerSign.SignGui.OwnerText.Text==first.DisplayName and a.OwnerSign.SignGui.OwnerImage.Visible
		and a.OwnerSign.SignGui.OwnerImage.Image:find(tostring(first.UserId),1,true),"Owned plot shows player picture and name")
	check(#workspace.PlayerPlots:GetChildren() == 6, "Exactly six static plots")
	local left, right = 0, 0
	for _, model in workspace.PlayerPlots:GetChildren() do
		if model.Ground.Position.X < 0 then left += 1 else right += 1 end
		assert(math.abs(model.Ground.Position.X) == 66 and model.Ground.Size == Vector3.new(80,1,80), "Larger plots must preserve center lane")
		assert(model.Pen.Floor.Size.X == 60 and model.Pen.Floor.Size.Z == 44, "Expanded Pen dimensions")
		assert(model.FeedPlate.Base.PlateGui.Label.Text=="FEED PLATE","Feed plate uses title-only label")
	end
	check(left == 3 and right == 3, "Three plots per side with center conveyor lane")
	check(first.RespawnLocation == a.Spawn and second.RespawnLocation == b.Spawn, "Personal respawn locations")
	check(#a.Pen.Slots:GetChildren() == 10 and #b.Pen.Slots:GetChildren() == 10, "Ten authored markers per Pen")
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
	local baseFence=b.Pen.Fence.Back.Color
	data.GetData(second).MaxPetSlots=10
	plots.GetPlot(second)
	check(b.Ground.Size.Z==120 and b.Pen.Fence.Back.Color~=baseFence,"Loaded capacity applies rear expansion and color")
	second:Kick("Plot verification: testing plot release")
	waitFor(function() return plots.GetPlot(second) == nil and b:GetAttribute("OwnerUserId") == 0 end, "Departing plot was not released")
	check(b.OwnerSign.SignGui.OwnerText.Text=="AVAILABLE" and not b.OwnerSign.SignGui.OwnerImage.Visible
		and b.OwnerSign.SignGui.OwnerImage.Image=="","Released plot clears owner portrait")
	check(plots.GetPlot(first) == a, "Leaving frees only departing player's plot")
	check(b.Ground.Size.Z==80 and b.Pen.Floor.Size.Z==44 and b.Pen.Fence.Back.Color==baseFence,"Leaving resets plot size and fence color")
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
	check(b.OwnerSign.SignGui.OwnerText.Text==replacement.DisplayName and b.OwnerSign.SignGui.OwnerImage.Visible
		and b.OwnerSign.SignGui.OwnerImage.Image:find(tostring(replacement.UserId),1,true),"Reused plot shows replacement owner")
	waitFor(function() return data.IsLoaded(replacement) end,"Replacement data not loaded")
	plots.GetPlot(replacement)
	check(b.Ground.Size.Z==80 and plots.GetSlotCapacity(replacement)==5,"New owner does not inherit old expansion")
end, debug.traceback)
local result = {passed = ok, checks = checks, failure = if ok then nil else tostring(failure)}
print("PLOT_VERIFICATION " .. game:GetService("HttpService"):JSONEncode(result))
testing:EndTest(result)
