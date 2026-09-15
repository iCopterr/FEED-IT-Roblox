--!strict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config.PlotConfig)
local DataService = require(script.Parent.DataService)

type Plot = { Model: Model, Spawn: SpawnLocation, Owner: Player?, Connection: RBXScriptConnection? }
local plots: {Plot} = {}
local owned: {[Player]: Plot} = {}
local started = false
local PlotService = {}

local function sign(plot: Plot, text: string)
	local label = plot.Model.OwnerSign.SignGui.OwnerText :: TextLabel
	label.Text = text
end

local function moveCharacter(player: Player, plot: Plot, character: Model)
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", Config.CharacterWaitSeconds)
		if root and owned[player] == plot and player.Character == character and player.Parent == Players then
			character:PivotTo(plot.Spawn.CFrame + Config.CharacterOffset)
		end
	end)
end

local function assign(player: Player)
	if owned[player] or player.Parent ~= Players then return end
	local available: Plot? = nil
	for _, plot in plots do
		if not plot.Owner then available = plot; break end
	end
	if not available then
		player:Kick("No free plot is available. Please join another server.")
		return
	end
	local plot = available
	plot.Owner = player
	owned[player] = plot
	plot.Model:SetAttribute("OwnerUserId", player.UserId)
	player:SetAttribute("PlotId", plot.Model:GetAttribute("PlotId"))
	player.RespawnLocation = plot.Spawn
	sign(plot, player.DisplayName .. "'s Pen" .. string.char(10) .. Config.SlotCount .. " active slots")
	plot.Connection = player.CharacterAdded:Connect(function(character) moveCharacter(player, plot, character) end)
	if player.Character then moveCharacter(player, plot, player.Character) end
end

local function release(player: Player)
	local plot = owned[player]
	if not plot then return end
	owned[player] = nil
	if plot.Connection then plot.Connection:Disconnect(); plot.Connection = nil end
	if player.RespawnLocation == plot.Spawn then player.RespawnLocation = nil end
	player:SetAttribute("PlotId", nil)
	plot.Owner = nil
	plot.Model:SetAttribute("OwnerUserId", 0)
	sign(plot, "Available Plot • " .. Config.SlotCount .. " slots")
	-- Persistent placement belongs to player data, never to this reusable world plot.
end

function PlotService.Start()
	assert(not started, "PlotService already started")
	-- Geometry is authored in Workspace. This service only assigns ownership.
	local folder = workspace:FindFirstChild(Config.FolderName)
	assert(folder and folder:IsA("Folder"), "Workspace.PlayerPlots is missing")
	local models = folder:GetChildren()
	table.sort(models, function(a, b) return a.Name < b.Name end)
	for index, model in models do
		assert(model:IsA("Model"), "PlayerPlots must contain plot Models only")
		assert(model:FindFirstChild("Spawn") and model.Spawn:IsA("SpawnLocation"), "Plot spawn missing")
		assert(model:FindFirstChild("Pen") and model.Pen:FindFirstChild("Slots"), "Pen slots missing")
		assert(#model.Pen.Slots:GetChildren() == Config.SlotCount, "Plot must have exactly five slots")
		for slotIndex = 1, Config.SlotCount do
			local slot = model.Pen.Slots:FindFirstChild(tostring(slotIndex))
			assert(slot and slot:IsA("BasePart"), "Plot slot missing: " .. slotIndex)
		end
		assert(model:FindFirstChild("OwnerSign") and model.OwnerSign:FindFirstChild("SignGui") and model.OwnerSign.SignGui:FindFirstChild("OwnerText"), "Plot owner sign missing")
	end
	assert(#models >= Players.MaxPlayers, "Add enough Workspace plots for the server player limit")
	for index, model in models do
		model:SetAttribute("PlotId", index)
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("SlotCapacity", Config.SlotCount)
		local plot: Plot = {Model = model :: Model, Spawn = model.Spawn :: SpawnLocation}
		table.insert(plots, plot)
		sign(plot, "Available Plot • " .. Config.SlotCount .. " slots")
	end
	started = true
	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do assign(player) end
end

function PlotService.GetPlot(player: Player): Model?
	local plot = owned[player]
	return if plot then plot.Model else nil
end

function PlotService.GetSlotCapacity(player: Player): number
	local data = DataService.GetData(player)
	if not owned[player] or not data then return 0 end
	return math.min(Config.SlotCount, data.MaxPetSlots)
end

function PlotService.GetSlotCFrame(player: Player, slotIndex: number): CFrame?
	if type(slotIndex) ~= "number" or slotIndex % 1 ~= 0 or slotIndex < 1 or slotIndex > PlotService.GetSlotCapacity(player) then return nil end
	local plot = owned[player]
	if not plot then return nil end
	local slot = plot.Model.Pen.Slots:FindFirstChild(tostring(slotIndex)) :: BasePart?
	return if slot then slot.CFrame else nil
end

return table.freeze(PlotService)
