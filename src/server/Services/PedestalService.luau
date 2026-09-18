local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Config = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local FeedConfig = require(game.ReplicatedStorage.Shared.Config.FeedConfig)
local PedestalService = {}
local states = {}

function PedestalService.Clear(player, character)
	local state = states[player]
	if character and state and state.Character ~= character then return end
	states[player] = nil
	if state then state.Model:Destroy() end
	player:SetAttribute("FeedPlatePetId", nil)
end

function PedestalService.GetPetId(player)
	return states[player] and states[player].Id
end

function PedestalService.GetFeedPet(player)
	PedestalService.Reconcile(player)
	local state = states[player]
	if not state then return nil, "NoPet" end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if state.Character ~= character or not humanoid or humanoid.Health <= 0 or not root
		or player:GetAttribute("IsFarming") then return nil, "Unavailable" end
	local dish = state.Plate:FindFirstChild("Dish")
	if not dish or not dish:IsA("BasePart") then return nil, "Unavailable" end
	if (root.Position-dish.Position).Magnitude > Config.PlateDistance then return nil, "TooFar" end
	local data = DataService.GetData(player)
	return data and data.Inventory[state.Id], nil
end

function PedestalService.GetPickupTarget(player, prompt)
	local state = states[player]
	local data = DataService.GetData(player)
	local pet = state and data and data.Inventory[state.Id]
	local plot = PlotService.GetPlot(player)
	if not state or prompt ~= state.Prompt or not pet or pet.Placed or not plot
		or state.Plate.Parent ~= plot or state.Model.Parent ~= state.Plate then return nil end
	return state.Id, state.Plate.Dish.Position
end

-- Called only after CarryService verifies this is the currently held pet.
-- Staging is transient: the existing inventory record remains the only pet.
function PedestalService.Place(player, id)
	if require(script.Parent.FeedLocks).IsLocked(player) then return false, "Busy" end
	local data = DataService.GetData(player)
	local plot = PlotService.GetPlot(player)
	local plate = plot and plot:FindFirstChild("FeedPlate")
	local dish = plate and plate:FindFirstChild("Dish")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if states[player] then return false, "PlateOccupied" end
	if not data or not Schema.Validate(data) or not plate or not dish or not dish:IsA("BasePart") then return false, "Unavailable" end
	local pet = data.Inventory[id]
	if not pet or pet.Placed then return false, "NotOwned" end
	if player.Parent ~= Players or not root or not humanoid or humanoid.Health <= 0 or player:GetAttribute("IsFarming") then return false, "Unavailable" end
	if (root.Position - dish.Position).Magnitude > Config.PlateDistance then return false, "TooFar" end
	local templates = workspace:FindFirstChild("PetTemplates")
	local template = templates and templates:FindFirstChild(pet.SpeciesId)
	if not template or not template:IsA("Model") or not template.Archivable then return false, "TemplateUnavailable" end
	for _, item in template:GetDescendants() do
		if item:IsA("LuaSourceContainer") then return false, "TemplateUnavailable" end
	end
	local model = template:Clone()
	model:ScaleTo(FeedConfig.GetScale(pet.FeedLevel))
	local prompt
	local ok = pcall(function()
		local body = assert(model:FindFirstChildWhichIsA("BasePart", true), "Pet has no body")
		model.Name = "PlatePet"
		model:SetAttribute("PetId", id)
		model:SetAttribute("OwnerUserId", player.UserId)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored = true; part.CanCollide = false; part.CanTouch = false end
		end
		local bounds, size = model:GetBoundingBox()
		-- Cylinder axis is local X; orient the pet using the plot, not the dish.
		local target = CFrame.new(dish.Position + Vector3.new(0, dish.Size.X/2 + size.Y/2 + .05, 0)) * plot.Ground.CFrame.Rotation
		model:PivotTo(target * bounds:ToObjectSpace(model:GetPivot()))
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "OpenFeedUI"
		prompt.ActionText, prompt.ObjectText = "Open Feed UI", "Pet on feed plate"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration, prompt.MaxActivationDistance = Config.PickupHoldSeconds, Config.PickupDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = body
		model.Parent = plate
	end)
	if not ok then model:Destroy(); return false, "TemplateUnavailable" end
	states[player] = {Id=id, Model=model, Plate=plate, Prompt=prompt, Character=character}
	player:SetAttribute("FeedPlatePetId", id)
	return true
end

function PedestalService.BeginPresentation(player)
	local state = assert(states[player], "No staged pet")
	state.Animating = true
	state.Transparencies = {}
	for _, part in state.Model:GetDescendants() do
		if part:IsA("BasePart") then state.Transparencies[part]=part.Transparency; part.Transparency=1 end
	end
	state.Prompt.Enabled = false
	return state.Model:GetPivot()
end

function PedestalService.EndPresentation(player, id)
	local state = states[player]
	if not state or state.Id ~= id then return end
	state.Animating = nil
	local data = DataService.GetData(player)
	local pet = data and data.Inventory[id]
	if not pet then PedestalService.Clear(player); return end
	state.Model:ScaleTo(FeedConfig.GetScale(pet.FeedLevel))
	local bounds, size = state.Model:GetBoundingBox()
	local dish = state.Plate.Dish
	local target = CFrame.new(dish.Position + Vector3.new(0,dish.Size.X/2+size.Y/2+.05,0)) * state.Plate.Parent.Ground.CFrame.Rotation
	state.Model:PivotTo(target * bounds:ToObjectSpace(state.Model:GetPivot()))
	for part, transparency in state.Transparencies or {} do
		if part.Parent then part.Transparency = transparency end
	end
	state.Prompt.Enabled = true
end

function PedestalService.Reconcile(player)
	local state = states[player]
	if not state then return end
	local data = DataService.GetData(player)
	local pet = data and data.Inventory[state.Id]
	local plot = PlotService.GetPlot(player)
	if player.Character ~= state.Character or (not pet and not state.Animating) or (pet and pet.Placed) or not plot or state.Plate.Parent ~= plot or state.Model.Parent ~= state.Plate then
		PedestalService.Clear(player)
	end
end

return table.freeze(PedestalService)
