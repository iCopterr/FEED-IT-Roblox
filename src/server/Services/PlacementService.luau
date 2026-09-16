--!strict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config.PlacementConfig)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)

type PetData = Schema.PetData
type VisualState = {Plot: Model, Folder: Folder, Pets: {[string]: Model}}
local states: {[Player]: VisualState} = {}
local changed = Instance.new("BindableEvent")
local started = false
local PlacementService = {Changed = changed.Event}

function PlacementService.ResolvePosition(player: Player, position: Vector3): CFrame?
	if typeof(position) ~= "Vector3" then return nil end
	for _, n in {position.X, position.Y, position.Z} do
		if n ~= n or math.abs(n) == math.huge then return nil end
	end
	local plot = PlotService.GetPlot(player)
	if not plot then return nil end
	local floor = plot.Pen.Floor
	local point = floor.CFrame:PointToObjectSpace(position)
	if math.abs(point.X) > floor.Size.X / 2 - Config.FenceInset or math.abs(point.Z) > floor.Size.Z / 2 - Config.FenceInset
		or math.abs(point.Y - floor.Size.Y / 2) > Config.SurfaceTolerance then return nil end
	return floor.CFrame * CFrame.new(point.X, floor.Size.Y / 2, point.Z)
end

function PlacementService.GetPetCFrame(player: Player, pet: PetData): CFrame?
	local plot = PlotService.GetPlot(player)
	if pet.PenPosition and plot then
		local floor = plot.Pen.Floor
		return PlacementService.ResolvePosition(player, floor.CFrame:PointToWorldSpace(Vector3.new(pet.PenPosition.X, floor.Size.Y / 2, pet.PenPosition.Z)))
	end
	return if pet.PlotSlot then PlotService.GetSlotCFrame(player, pet.PlotSlot) else nil
end

local function clear(player: Player)
	local state = states[player]
	if state then
		states[player] = nil
		state.Folder:Destroy()
	end
end

local function visualState(player: Player, plot: Model): VisualState
	local current = states[player]
	if current and current.Plot == plot and current.Folder.Parent == plot.Pen then return current end
	clear(player)
	local folder = Instance.new("Folder")
	folder.Name = Config.VisualFolderName
	folder:SetAttribute("OwnerUserId", player.UserId)
	folder.Parent = plot.Pen
	local state: VisualState = {Plot = plot, Folder = folder, Pets = {}}
	states[player] = state
	return state
end

local function prepareVisual(player: Player, pet: PetData, slot: CFrame): (Model?, string?)
	local templates = workspace:FindFirstChild(Config.TemplateFolderName)
	local template = templates and templates:FindFirstChild(pet.SpeciesId)
	if not template or not template:IsA("Model") or not template.Archivable then return nil, "TemplateUnavailable" end
	local hasPart = false
	for _, descendant in template:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then return nil, "TemplateUnavailable" end
		if descendant:IsA("BasePart") then hasPart = true end
	end
	if not hasPart then return nil, "TemplateUnavailable" end
	local model = template:Clone()
	local ok = pcall(function()
		model.Name = pet.PetId
		model:SetAttribute("PetId", pet.PetId)
		model:SetAttribute("OwnerUserId", player.UserId)
		model:SetAttribute("SpeciesId", pet.SpeciesId)
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanTouch = false
			end
		end
		local bounds, size = model:GetBoundingBox()
		local offset = bounds:ToObjectSpace(model:GetPivot())
		model:PivotTo(slot * CFrame.new(0, size.Y / 2 + Config.HeightOffset, 0) * offset)
	end)
	if not ok then model:Destroy(); return nil, "TemplateUnavailable" end
	return model, nil
end

local function install(player: Player, plot: Model, pet: PetData, model: Model)
	local state = visualState(player, plot)
	local previous = state.Pets[pet.PetId]
	model:SetAttribute("PlotSlot", pet.PlotSlot)
	local carryConfig = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = carryConfig.PickupPromptName
	prompt.ActionText, prompt.ObjectText = "Pick up", "Your pet"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = carryConfig.PickupHoldSeconds
	prompt.MaxActivationDistance = carryConfig.PickupDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = model:FindFirstChildWhichIsA("BasePart", true)
	model.Parent = state.Folder
	state.Pets[pet.PetId] = model
	if previous then previous:Destroy() end
end

-- Rebuild only presentation from authoritative data. Never change saved placement
-- during loading, visual repair, respawn, or a player's departure.
function PlacementService.Reconcile(player: Player): (boolean, string?)
	local data = DataService.GetData(player)
	local plot = PlotService.GetPlot(player)
	if player.Parent ~= Players or not data or not plot then clear(player); return false, "Loading" end
	if not Schema.Validate(data) then clear(player); return false, "InvalidData" end
	local state = visualState(player, plot)
	for id, model in state.Pets do
		local pet = data.Inventory[id]
		if not pet or not pet.Placed or model.Parent ~= state.Folder or model:GetAttribute("PlotSlot") ~= pet.PlotSlot then
			model:Destroy()
			state.Pets[id] = nil
		end
	end
	for id in data.PlacedPetIds do
		local pet = data.Inventory[id]
		if not state.Pets[id] then
			local slot = PlacementService.GetPetCFrame(player, pet)
			if not slot then return false, "InvalidSlot" end
			local model, reason = prepareVisual(player, pet, slot)
			if not model then return false, reason end
			install(player, plot, pet, model)
		end
	end
	return true, nil
end

local function context(player: Player, petId: string): (Schema.PlayerData?, Model?, PetData?, string?)
	if player.Parent ~= Players then return nil, nil, nil, "Loading" end
	if type(petId) ~= "string" or #petId == 0 or #petId > Config.MaxPetIdLength then return nil, nil, nil, "InvalidRequest" end
	local data = DataService.GetData(player)
	local plot = PlotService.GetPlot(player)
	if not data or not plot then return nil, nil, nil, "Loading" end
	if not Schema.Validate(data) then return nil, nil, nil, "InvalidData" end
	local pet = data.Inventory[petId]
	if not pet then return nil, nil, nil, "NotOwned" end
	return data, plot, pet, nil
end

function PlacementService.PlacePet(player: Player, petId: string, position: Vector3?): (boolean, string?)
	local data, plot, pet, reason = context(player, petId)
	if not data or not plot or not pet then return false, reason end
	if pet.Placed then return PlacementService.Reconcile(player) end
	local occupied: {[number]: boolean} = {}
	for id in data.PlacedPetIds do
		local index = data.Inventory[id].PlotSlot
		if index then occupied[index] = true end
	end
	local index: number? = nil
	for candidate = 1, PlotService.GetSlotCapacity(player) do
		if not occupied[candidate] then index = candidate; break end
	end
	if not index then return false, "PenFull" end
	local slot = if position ~= nil then PlacementService.ResolvePosition(player, position) else PlotService.GetSlotCFrame(player, index)
	if not slot then return false, "InvalidSlot" end
	-- Prepare the actual template before committing any player-data changes.
	local model, visualError = prepareVisual(player, pet, slot)
	if not model then return false, visualError end
	pet.Placed, pet.PlotSlot = true, index
	if position ~= nil then
		local point = plot.Pen.Floor.CFrame:PointToObjectSpace(slot.Position)
		pet.PenPosition = {X = point.X, Z = point.Z}
	end
	data.PlacedPetIds[petId] = true
	local valid = Schema.Validate(data)
	local installed = valid and pcall(install, player, plot, pet, model)
	if not installed then
		pet.Placed, pet.PlotSlot = false, nil
		pet.PenPosition = nil
		data.PlacedPetIds[petId] = nil
		model:Destroy()
		return false, "PlacementFailed"
	end
	changed:Fire(player, petId, true)
	return true, nil
end

function PlacementService.PickupPet(player: Player, petId: string): (boolean, string?)
	local data, _, pet, reason = context(player, petId)
	if not data or not pet then return false, reason end
	if not pet.Placed then return true, nil end
	local previousSlot = pet.PlotSlot
	local previousPosition = pet.PenPosition
	pet.Placed, pet.PlotSlot = false, nil
	pet.PenPosition = nil
	data.PlacedPetIds[petId] = nil
	if not Schema.Validate(data) then
		pet.Placed, pet.PlotSlot = true, previousSlot
		pet.PenPosition = previousPosition
		data.PlacedPetIds[petId] = true
		return false, "PlacementFailed"
	end
	local state = states[player]
	if state and state.Pets[petId] then
		state.Pets[petId]:Destroy()
		state.Pets[petId] = nil
	end
	changed:Fire(player, petId, false)
	return true, nil
end

function PlacementService.Start()
	assert(not started, "PlacementService already started")
	started = true
	Players.PlayerRemoving:Connect(clear)
	-- Handles asynchronous data loading and repairs a missing visual without
	-- needing to reload the profile or duplicate a pet record.
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(PlacementService.Reconcile, player)
				if not ok then warn("[PlacementService] Visual reconciliation failed: " .. tostring(err)) end
			end
			task.wait(Config.ReconcileSeconds)
		end
	end)
end

return table.freeze(PlacementService)
