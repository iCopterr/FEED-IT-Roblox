--!strict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config.PlacementConfig)
local PetModels = require(game:GetService("ReplicatedStorage").Shared.PetModels)
local PetIncome = require(game:GetService("ReplicatedStorage").Shared.PetIncome)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local WanderingService = require(script.Parent.WanderingService)

type PetData = Schema.PetData
type VisualState = {Plot: Model, Folder: Folder, Pets: {[string]: Model}}
local states: {[Player]: VisualState} = {}
local changed = Instance.new("BindableEvent")
local started = false
local PlacementService = {Changed = changed.Event}

-- Interaction uses the server visual, not the saved initial placement anchor.
function PlacementService.GetLivePetCFrame(player: Player, pet: PetData): CFrame?
	local state = states[player]
	local model = state and state.Pets[pet.PetId]
	if pet.Placed and state and state.Plot == PlotService.GetPlot(player)
		and model and model.Parent == state.Folder then return model:GetPivot() end
	return nil
end

function PlacementService.PauseWandering(player: Player, petId: string, seconds: number)
	local state = states[player]
	local model = state and state.Pets[petId]
	if model then WanderingService.Pause(model, seconds) end
end

function PlacementService.GetPickupCFrame(player: Player, pet: PetData): CFrame?
	local state = states[player]
	local model = state and state.Pets[pet.PetId]
	if PlacementService.GetLivePetCFrame(player, pet) and model then
		return PetModels.GetPickupCFrame(model)
	end
	return nil
end

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
		local origin = assert(PlotService.GetPlacementOrigin(player))
		return PlacementService.ResolvePosition(player, origin:PointToWorldSpace(Vector3.new(pet.PenPosition.X, floor.Size.Y / 2, pet.PenPosition.Z)))
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
	local template = PetModels.GetTemplate(pet.SpeciesId)
	if not template or not template:IsA("Model") or not template.Archivable then return nil, "TemplateUnavailable" end
	local hasPart = false
	for _, descendant in template:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then return nil, "TemplateUnavailable" end
		if descendant:IsA("BasePart") then hasPart = true end
	end
	if not hasPart then return nil, "TemplateUnavailable" end
	local model = template:Clone()
	model:ScaleTo(PetModels.GetScale(pet.SpeciesId,pet.FeedLevel))
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
	require(script.Parent.PetPresentation).Update(model,pet)
	local carryConfig = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = carryConfig.PickupPromptName
	prompt.ActionText, prompt.ObjectText = "Pick up", "Your pet"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = carryConfig.PickupHoldSeconds
	prompt.MaxActivationDistance = carryConfig.PickupDistance
	prompt.RequiresLineOfSight = false
	local body = assert(model:FindFirstChildWhichIsA("BasePart", true))
	local pickupAnchor = Instance.new("Attachment")
	pickupAnchor.Name = "PetPickupAnchor"
	pickupAnchor.CFrame = body.CFrame:ToObjectSpace(PetModels.GetPickupCFrame(model))
	pickupAnchor.Parent = body
	prompt.Parent = pickupAnchor
	model.Parent = state.Folder
	state.Pets[pet.PetId] = model
	WanderingService.Track(model, plot.Pen.Floor)
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
		if state.Pets[id] then require(script.Parent.PetPresentation).Update(state.Pets[id],pet) end
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
	if require(script.Parent.FeedLocks).IsLocked(player, petId) then return false, "Busy" end
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
		local point = assert(PlotService.GetPlacementOrigin(player)):PointToObjectSpace(slot.Position)
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
	if require(script.Parent.FeedLocks).IsLocked(player, petId) then return false, "Busy" end
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

-- Rebuild the active roster from authoritative income. Pets already selected
-- keep their hand-placed positions; only newly selected pets use free slot
-- markers. Transiently carried or staged pets are supplied as exclusions by
-- UIService so this remote convenience action cannot steal them from the
-- player's current interaction.
function PlacementService.EquipBest(player: Player, excluded: {[string]: boolean}?): (boolean, string?, number?)
	if require(script.Parent.FeedLocks).IsLocked(player) then return false, "Busy" end
	if player.Parent ~= Players then return false, "Loading" end
	local data = DataService.GetData(player)
	local plot = PlotService.GetPlot(player)
	if not data or not plot then return false, "Loading" end
	if not Schema.Validate(data) then return false, "InvalidData" end

	local candidates: {PetData} = {}
	for id, pet in data.Inventory do
		-- An already placed pet always remains eligible. This makes the operation
		-- resilient if a transient exclusion changes immediately before the call.
		if pet.Placed or not (excluded and excluded[id]) then table.insert(candidates, pet) end
	end
	if #candidates == 0 then return true, "NoAvailablePets", 0 end
	table.sort(candidates, function(a, b)
		local aIncome, bIncome = PetIncome(a), PetIncome(b)
		if aIncome ~= bIncome then return aIncome > bIncome end
		if a.FeedLevel ~= b.FeedLevel then return a.FeedLevel > b.FeedLevel end
		if a.CreatedAt ~= b.CreatedAt then return a.CreatedAt < b.CreatedAt end
		return a.PetId < b.PetId
	end)

	local winners: {[string]: boolean} = {}
	local capacity = PlotService.GetSlotCapacity(player)
	for index = 1, math.min(capacity, #candidates) do winners[candidates[index].PetId] = true end

	local retainedSlots: {[number]: boolean} = {}
	local added, removed = {}, {}
	for id in data.PlacedPetIds do
		if winners[id] then
			local slot = data.Inventory[id].PlotSlot
			if slot then retainedSlots[slot] = true end
		else
			table.insert(removed, id)
		end
	end
	for id in winners do if not data.PlacedPetIds[id] then table.insert(added, id) end end
	if #added == 0 and #removed == 0 then return true, "NoChange", 0 end

	table.sort(added, function(a, b)
		local aPet, bPet = data.Inventory[a], data.Inventory[b]
		local aIncome, bIncome = PetIncome(aPet), PetIncome(bPet)
		if aIncome ~= bIncome then return aIncome > bIncome end
		return a < b
	end)
	local assigned: {[string]: number} = {}
	local nextSlot = 1
	for _, id in added do
		while retainedSlots[nextSlot] do nextSlot += 1 end
		if nextSlot > capacity then return false, "PenFull" end
		assigned[id] = nextSlot
		retainedSlots[nextSlot] = true
	end

	-- Prepare every new visual before touching player data. A missing template
	-- therefore leaves the previous roster completely intact.
	local prepared: {[string]: Model} = {}
	for _, id in added do
		local slot = PlotService.GetSlotCFrame(player, assigned[id])
		if not slot then
			for _, model in prepared do model:Destroy() end
			return false, "InvalidSlot"
		end
		local model, reason = prepareVisual(player, data.Inventory[id], slot)
		if not model then
			for _, other in prepared do other:Destroy() end
			return false, reason
		end
		prepared[id] = model
	end

	local beforePlaced = table.clone(data.PlacedPetIds)
	local before: {[string]: {Placed: boolean, PlotSlot: number?, PenPosition: {X: number, Z: number}?}} = {}
	for id, pet in data.Inventory do
		before[id] = {Placed=pet.Placed, PlotSlot=pet.PlotSlot,
			PenPosition=if pet.PenPosition then table.clone(pet.PenPosition) else nil}
		if winners[id] then
			if not pet.Placed then
				pet.Placed, pet.PlotSlot, pet.PenPosition = true, assigned[id], nil
			end
			data.PlacedPetIds[id] = true
		elseif pet.Placed then
			pet.Placed, pet.PlotSlot, pet.PenPosition = false, nil, nil
			data.PlacedPetIds[id] = nil
		end
	end

	local function rollback()
		data.PlacedPetIds = table.clone(beforePlaced)
		for id, saved in before do
			local pet = data.Inventory[id]
			pet.Placed, pet.PlotSlot = saved.Placed, saved.PlotSlot
			pet.PenPosition = if saved.PenPosition then table.clone(saved.PenPosition) else nil
		end
		for _, model in prepared do model:Destroy() end
		PlacementService.Reconcile(player)
	end
	if not Schema.Validate(data) then rollback(); return false, "PlacementFailed" end

	local installed = pcall(function()
		local state = states[player]
		for _, id in removed do
			if state and state.Pets[id] then state.Pets[id]:Destroy(); state.Pets[id] = nil end
		end
		for _, id in added do install(player, plot, data.Inventory[id], prepared[id]) end
	end)
	if not installed then rollback(); return false, "PlacementFailed" end
	for _, id in removed do changed:Fire(player, id, false) end
	for _, id in added do changed:Fire(player, id, true) end
	return true, "Equipped", #added
end

function PlacementService.Start()
	assert(not started, "PlacementService already started")
	started = true
	WanderingService.Start()
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
