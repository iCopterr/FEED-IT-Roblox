--!strict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config.PlotConfig)
local DataService = require(script.Parent.DataService)
local Appearance = require(script.Parent.PlotAppearance)

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
	sign(plot, player.DisplayName .. "'s Pen")
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
	plot.Model:SetAttribute("SlotCapacity", Config.StartingSlots)
	Appearance.Apply(plot.Model, Config.StartingSlots)
	sign(plot, "Available Plot • " .. Config.StartingSlots .. " slots")
	-- Persistent placement belongs to player data, never to this reusable world plot.
end

function PlotService.Start()
	assert(not started, "PlotService already started")
	-- Geometry is authored in Workspace; ownership selects its expansion tier.
	local folder = workspace:FindFirstChild(Config.FolderName)
	assert(folder and folder:IsA("Folder"), "Workspace.PlayerPlots is missing")
	local models = folder:GetChildren()
	table.sort(models, function(a, b) return a.Name < b.Name end)
	for index, model in models do
		assert(model:IsA("Model"), "PlayerPlots must contain plot Models only")
		assert(model:FindFirstChild("Spawn") and model.Spawn:IsA("SpawnLocation"), "Plot spawn missing")
		assert(model:FindFirstChild("Pen") and model.Pen:FindFirstChild("Slots"), "Pen slots missing")
		assert(#model.Pen.Slots:GetChildren() == Config.SlotCount, "Plot markers must match maximum capacity")
		for slotIndex = 1, Config.SlotCount do
			local slot = model.Pen.Slots:FindFirstChild(tostring(slotIndex))
			assert(slot and slot:IsA("BasePart"), "Plot slot missing: " .. slotIndex)
		end
		assert(model:FindFirstChild("OwnerSign") and model.OwnerSign:FindFirstChild("SignGui") and model.OwnerSign.SignGui:FindFirstChild("OwnerText"), "Plot owner sign missing")
	end
	assert(#models == Config.PlayerCapacity, "Workspace must contain exactly six player plots")
	if Players.MaxPlayers ~= Config.PlayerCapacity then
		warn("Set this place's Maximum Players to 6 in Creator Dashboard; plot capacity is six.")
	end
	for index, model in models do
		model:SetAttribute("PlotId", index)
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("SlotCapacity", Config.StartingSlots)
		local plot: Plot = {Model = model :: Model, Spawn = model.Spawn :: SpawnLocation}
		Appearance.Capture(model)
		Appearance.Apply(model, Config.StartingSlots)
		table.insert(plots, plot)
		sign(plot, "Available Plot • " .. Config.StartingSlots .. " slots")
	end
	started = true
	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do assign(player) end
end

function PlotService.GetPlot(player: Player): Model?
	local plot = owned[player]
	if plot then
		local data = DataService.GetData(player)
		Appearance.Apply(plot.Model, if data then data.MaxPetSlots else Config.StartingSlots)
	end
	return if plot then plot.Model else nil
end

-- Persisted coordinates retain the ORIGINAL floor origin as its rear expands.
-- This also preserves old saved positions without migrating pet/egg records.
function PlotService.GetPlacementOrigin(player: Player): CFrame?
	local plot = PlotService.GetPlot(player)
	return if plot then Appearance.GetOrigin(plot) else nil
end

function PlotService.GetSlotCapacity(player: Player): number
	local data = DataService.GetData(player)
	if not owned[player] or not data then return 0 end
	Appearance.Apply(owned[player].Model, data.MaxPetSlots)
	return math.min(Config.SlotCount, data.MaxPetSlots)
end

function PlotService.RefreshSign(player: Player)
	local plot = owned[player]
	if not plot then return end
	local capacity = PlotService.GetSlotCapacity(player)
	plot.Model:SetAttribute("SlotCapacity", capacity)
	sign(plot, player.DisplayName .. "'s Pen\n" .. capacity .. " active slots")
end

function PlotService.GetSlotCFrame(player: Player, slotIndex: number): CFrame?
	if type(slotIndex) ~= "number" or slotIndex % 1 ~= 0 or slotIndex < 1 or slotIndex > PlotService.GetSlotCapacity(player) then return nil end
	local plot = owned[player]
	if not plot then return nil end
	local slot = plot.Model.Pen.Slots:FindFirstChild(tostring(slotIndex)) :: BasePart?
	return if slot then slot.CFrame else nil
end

return table.freeze(PlotService)
