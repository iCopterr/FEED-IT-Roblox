local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local PlacementService = require(script.Parent.PlacementService)
local PlacementConfig = require(game.ReplicatedStorage.Shared.Config.PlacementConfig)
local PlotService = require(script.Parent.PlotService)
local PedestalService = require(script.Parent.PedestalService)
local PetModels = require(game.ReplicatedStorage.Shared.PetModels)
local carried, connections = {}, {}
local pickupHolds = {}
local CarryService = {}

local function living(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 or not root then return nil end
	return character, root
end

function CarryService.Unequip(player)
	pickupHolds[player] = nil
	local state = carried[player]
	carried[player] = nil
	if state then state.Model:Destroy() end
	player:SetAttribute("CarriedPetId", nil)
	player:SetAttribute("CarriedEggUid", nil)
	return true
end

function CarryService.GetPetId(player)
	local state = carried[player]
	return if state and not state.Egg then state.Id else nil
end

function CarryService.GetEggId(player)
	local state = carried[player]
	local character = living(player)
	return if state and state.Egg and state.Character == character and state.Model.Parent == character then state.Id else nil
end

local function equip(player, id, isEgg)
	if require(script.Parent.FeedLocks).IsLocked(player, id) then return false, "Busy" end
	if type(id) ~= "string" or #id == 0 or #id > 64 then return false, "InvalidRequest" end
	local data = DataService.GetData(player)
	local egg = isEgg and data and data.IncubatingEggs[id]
	local pet = if isEgg then egg else data and data.Inventory[id]
	if not pet then return false, "NotOwned" end
	if isEgg and egg.PenPosition then return false, "AlreadyPlaced" end
	local character, root = living(player)
	local attachment = character and character:FindFirstChild("Head")
	if not attachment or not attachment:IsA("BasePart") then return false, "CharacterUnavailable" end
	if carried[player] and carried[player].Id == id and carried[player].Egg == isEgg and carried[player].Model.Parent == character then return true end
	if pet.Placed then
		local slot = PlacementService.GetPickupCFrame(player, pet)
		if not slot or (root.Position - slot.Position).Magnitude > Config.PickupDistance then return false, "TooFar" end
	end
	local definition = isEgg and require(game.ReplicatedStorage.Shared.Config.EggConfig).Definitions[egg.EggId]
	local templates = if isEgg then workspace:FindFirstChild("EggTemplates") else nil
	local template = if isEgg then templates and templates:FindFirstChild(definition and definition.TemplateName or egg.EggId)
		else PetModels.GetTemplate(pet.SpeciesId)
	if not template or not template:IsA("Model") or not template.Archivable then return false, "TemplateUnavailable" end
	for _, part in template:GetDescendants() do
		if part:IsA("LuaSourceContainer") then return false, "TemplateUnavailable" end
	end
	local model = template:Clone()
	local prepared = pcall(function()
		local modelRoot = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		assert(modelRoot, "Template has no parts")
		model.Name = if isEgg then "HeldEgg" else "HeldPet"
		model:SetAttribute(if isEgg then "EggUid" else "PetId", id)
		model:SetAttribute("OwnerUserId", player.UserId)
		if isEgg then
			model:SetAttribute("Variant", egg.Pet.Variant)
			game:GetService("CollectionService"):AddTag(model,"VariantEggVisual")
		end
		local heldScale = Config.HeldScale
		if not isEgg then heldScale *= PetModels.GetScale(pet.SpeciesId,pet.FeedLevel) end
		model:ScaleTo(heldScale)
		local bounds, size = model:GetBoundingBox()
		local clearance = if isEgg then Config.EggHeadClearance else Config.PetHeadClearance
		local targetBounds = attachment.CFrame * CFrame.new(0, attachment.Size.Y / 2 + clearance + size.Y / 2, 0)
		model:PivotTo(targetBounds * bounds:ToObjectSpace(model:GetPivot()))
		if not isEgg then
			local petHumanoid = model:FindFirstChildOfClass("Humanoid")
			if petHumanoid then petHumanoid:Destroy() end
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
				if isEgg then
					local weld = Instance.new("WeldConstraint")
					weld.Name = "CarryWeld"
					weld.Part0, weld.Part1 = attachment, part
					weld.Parent = part
				end
			end
		end
		if not isEgg then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryWeld"
			weld.Part0, weld.Part1 = attachment, modelRoot
			weld.Parent = modelRoot
		end
		model.Parent = character
		if not isEgg then require(script.Parent.PetPresentation).Update(model,pet) end
	end)
	if not prepared then model:Destroy(); return false, "TemplateUnavailable" end
	-- All potentially failing visual preparation precedes the persisted mutation.
	local ok, reason = true, nil
	if not isEgg then ok, reason = PlacementService.PickupPet(player, id) end
	if not ok then model:Destroy(); return false, reason end
	CarryService.Unequip(player)
	if PedestalService.GetPetId(player) == id then PedestalService.Clear(player) end
	carried[player] = {Id = id, Model = model, Character = character, Egg = isEgg}
	player:SetAttribute(if isEgg then "CarriedEggUid" else "CarriedPetId", id)
	return true
end

function CarryService.Equip(player, id) return equip(player, id, false) end
function CarryService.EquipEgg(player, id) return equip(player, id, true) end

-- The client supplies an expected ID so delayed clicks cannot place a newly
-- equipped pet. Positions are validated against the server-owned Pen floor.
function CarryService.PlaceAt(player, id, position)
	local state = carried[player]
	local character, root = living(player)
	if not state or state.Egg or id ~= state.Id or character ~= state.Character or state.Model.Parent ~= character then return false, "NotCarrying" end
	local target = PlacementService.ResolvePosition(player, position)
	if not target then return false, "OutsidePen" end
	if (root.Position - target.Position).Magnitude > PlacementConfig.ClickDistance then return false, "TooFar" end
	local ok, reason = PlacementService.PlacePet(player, id, target.Position)
	if ok then CarryService.Unequip(player) end
	return ok, reason
end

function CarryService.PlaceOnPlate(player, id)
	local state = carried[player]
	local character = living(player)
	if not state or state.Egg or id ~= state.Id or character ~= state.Character or state.Model.Parent ~= character then return false, "NotCarrying" end
	local ok, reason = PedestalService.Place(player, id)
	if ok then CarryService.Unequip(player) end
	return ok, reason
end

local function pickupTarget(player, prompt)
	if typeof(prompt) ~= "Instance" or not prompt:IsA("ProximityPrompt") or prompt.Name ~= Config.PickupPromptName or not prompt.Enabled then return nil end
	local plot = PlotService.GetPlot(player)
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not plot or not model or model.Parent ~= plot.Pen:FindFirstChild("ActivePets") then return nil end
	local data = DataService.GetData(player)
	local pet = data and data.Inventory[model.Name]
	local character, root = living(player)
	if not character or not pet or not pet.Placed then return nil end
	local cf = PlacementService.GetPickupCFrame(player, pet)
	if not cf or (root.Position - cf.Position).Magnitude > Config.PickupDistance then return nil end
	return pet.PetId, character
end

function CarryService.BeginPickup(player, prompt)
	local id, character = pickupTarget(player, prompt)
	if not id then pickupHolds[player] = nil; return false end
	pickupHolds[player] = {Id = id, Character = character, Prompt = prompt, Started = os.clock()}
	PlacementService.PauseWandering(player, id, Config.PickupHoldSeconds + 3)
	return true
end

function CarryService.CancelPickup(player)
	pickupHolds[player] = nil
end

function CarryService.FinishPickup(player, prompt)
	local hold = pickupHolds[player]
	pickupHolds[player] = nil
	local id, character = pickupTarget(player, prompt)
	if not hold or hold.Prompt ~= prompt or id ~= hold.Id or character ~= hold.Character then return false, "InvalidHold" end
	local elapsed = os.clock() - hold.Started
	if elapsed < Config.PickupHoldSeconds - .1 or elapsed > Config.PickupHoldSeconds + 3 then return false, "InvalidHold" end
	return CarryService.Equip(player, id)
end

function CarryService.Start()
	local prompts = game:GetService("ProximityPromptService")
	prompts.PromptButtonHoldBegan:Connect(function(prompt, player)
		if prompt.Name == Config.PickupPromptName then CarryService.BeginPickup(player, prompt) end
	end)
	prompts.PromptButtonHoldEnded:Connect(function(prompt, player)
		local hold = pickupHolds[player]
		if hold and hold.Prompt == prompt then
			task.delay(.15, function() if pickupHolds[player] == hold then CarryService.CancelPickup(player) end end)
		end
	end)
	prompts.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name == Config.PickupPromptName then CarryService.FinishPickup(player, prompt) end
	end)
	local function bind(player)
		connections[player] = player.CharacterRemoving:Connect(function(character)
			PedestalService.Clear(player, character)
			-- Deferred removal of an old character must not clear a newer equip.
			if carried[player] and carried[player].Character == character then CarryService.Unequip(player) end
		end)
	end
	Players.PlayerAdded:Connect(bind)
	for _, player in Players:GetPlayers() do bind(player) end
	Players.PlayerRemoving:Connect(function(player)
		PedestalService.Clear(player)
		CarryService.Unequip(player)
		if connections[player] then connections[player]:Disconnect(); connections[player] = nil end
	end)
	PetService.PetRemoved:Connect(function(player, pet)
		if PedestalService.GetPetId(player) == pet.PetId then PedestalService.Clear(player) end
		if CarryService.GetPetId(player) == pet.PetId then CarryService.Unequip(player) end
	end)
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do PedestalService.Reconcile(player) end
		for player, hold in pickupHolds do
			local id, character = pickupTarget(player, hold.Prompt)
			if id ~= hold.Id or character ~= hold.Character or os.clock() - hold.Started > Config.PickupHoldSeconds + 3 then pickupHolds[player] = nil end
		end
		for player, state in carried do
			local character = living(player)
			local data = DataService.GetData(player)
			local pet = data and (if state.Egg then data.IncubatingEggs[state.Id] else data.Inventory[state.Id])
			if character ~= state.Character or state.Model.Parent ~= character or not pet or pet.Placed or (state.Egg and pet.PenPosition) then
				CarryService.Unequip(player)
			elseif not state.Egg then
				require(script.Parent.PetPresentation).Update(state.Model,pet)
			end
		end
	end)
end

return CarryService
