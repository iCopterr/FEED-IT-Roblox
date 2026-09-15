local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local PlacementService = require(script.Parent.PlacementService)
local PlotService = require(script.Parent.PlotService)
local carried, holds, connections = {}, {}, {}
local CarryService = {}

local function living(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 or not root then return nil end
	return character, root
end

function CarryService.Unequip(player)
	holds[player] = nil
	local state = carried[player]
	carried[player] = nil
	if state then state.Model:Destroy() end
	player:SetAttribute("CarriedPetId", nil)
	return true
end

function CarryService.GetPetId(player)
	return carried[player] and carried[player].Id
end

function CarryService.Equip(player, id)
	if type(id) ~= "string" or #id == 0 or #id > 64 then return false, "InvalidRequest" end
	local data = DataService.GetData(player)
	local pet = data and data.Inventory[id]
	if not pet then return false, "NotOwned" end
	local character, root = living(player)
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	if not hand or not hand:IsA("BasePart") then return false, "CharacterUnavailable" end
	if carried[player] and carried[player].Id == id and carried[player].Model.Parent == character then return true end
	if pet.Placed then
		local slot = PlotService.GetSlotCFrame(player, pet.PlotSlot)
		if not slot or (root.Position - slot.Position).Magnitude > Config.PickupDistance then return false, "TooFar" end
	end
	local templates = workspace:FindFirstChild("PetTemplates")
	local template = templates and templates:FindFirstChild(pet.SpeciesId)
	if not template or not template:IsA("Model") or not template.Archivable then return false, "TemplateUnavailable" end
	for _, part in template:GetDescendants() do
		if part:IsA("LuaSourceContainer") then return false, "TemplateUnavailable" end
	end
	local model = template:Clone()
	local prepared = pcall(function()
		assert(model:FindFirstChildWhichIsA("BasePart", true), "Template has no parts")
		model.Name = "HeldPet"
		model:SetAttribute("PetId", id)
		model:SetAttribute("OwnerUserId", player.UserId)
		model:ScaleTo(Config.HeldScale)
		local bounds = model:GetBoundingBox()
		model:PivotTo(hand.CFrame * Config.HandOffset * bounds:ToObjectSpace(model:GetPivot()))
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = hand, part
				weld.Parent = part
			end
		end
		model.Parent = character
	end)
	if not prepared then model:Destroy(); return false, "TemplateUnavailable" end
	-- All potentially failing visual preparation precedes the persisted mutation.
	local ok, reason = PlacementService.PickupPet(player, id)
	if not ok then model:Destroy(); return false, reason end
	CarryService.Unequip(player)
	carried[player] = {Id = id, Model = model, Character = character}
	player:SetAttribute("CarriedPetId", id)
	return true
end

local function canPlace(player, plot)
	local state = carried[player]
	local data = DataService.GetData(player)
	local pet = state and data and data.Inventory[state.Id]
	local character, root = living(player)
	if not state or not pet or pet.Placed or character ~= state.Character or state.Model.Parent ~= character then return false end
	if PlotService.GetPlot(player) ~= plot then return false end
	local floor = plot and plot:FindFirstChild("Pen") and plot.Pen:FindFirstChild("Floor")
	return floor ~= nil and (root.Position - floor.Position).Magnitude <= Config.PlaceDistance
end

function CarryService.BeginHold(player, plot)
	if not canPlace(player, plot) then holds[player] = nil; return false, "TooFar" end
	-- A repeated begin must not restart or accelerate an existing hold.
	if not holds[player] then holds[player] = {Plot = plot, Id = carried[player].Id, Started = os.clock()} end
	return true
end

function CarryService.CancelHold(player)
	holds[player] = nil
end

function CarryService.FinishHold(player, plot)
	local hold = holds[player]
	holds[player] = nil
	if not hold or hold.Plot ~= plot or not canPlace(player, plot) or carried[player].Id ~= hold.Id then return false, "InvalidHold" end
	local elapsed = os.clock() - hold.Started
	if elapsed < Config.HoldSeconds - Config.HoldTolerance or elapsed > Config.HoldExpirySeconds then return false, "InvalidHold" end
	local ok, reason = PlacementService.PlacePet(player, hold.Id)
	if ok then CarryService.Unequip(player) end
	return ok, reason
end

function CarryService.Start()
	local feedback = Instance.new("RemoteEvent")
	feedback.Name = "CarryFeedback"
	feedback.Parent = game.ReplicatedStorage
	for _, plot in workspace.PlayerPlots:GetChildren() do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = Config.PromptName
		prompt.ActionText, prompt.ObjectText = "Place pet", "Your Pen"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = Config.HoldSeconds
		prompt.MaxActivationDistance = Config.PlaceDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = plot.Pen.Floor
		prompt.PromptButtonHoldBegan:Connect(function(player) CarryService.BeginHold(player, plot) end)
		prompt.PromptButtonHoldEnded:Connect(function(player)
			local hold = holds[player]
			-- Triggered and HoldEnded can arrive together; allow completion first.
			task.delay(.15, function() if holds[player] == hold then CarryService.CancelHold(player) end end)
		end)
		prompt.Triggered:Connect(function(player)
			local ok, code = CarryService.FinishHold(player, plot)
			feedback:FireClient(player, ok, code)
		end)
	end
	local function bind(player)
		connections[player] = player.CharacterRemoving:Connect(function(character)
			-- Deferred removal of an old character must not clear a newer equip.
			if carried[player] and carried[player].Character == character then CarryService.Unequip(player) end
		end)
	end
	Players.PlayerAdded:Connect(bind)
	for _, player in Players:GetPlayers() do bind(player) end
	Players.PlayerRemoving:Connect(function(player)
		CarryService.Unequip(player)
		if connections[player] then connections[player]:Disconnect(); connections[player] = nil end
	end)
	PetService.PetRemoved:Connect(function(player, pet)
		if CarryService.GetPetId(player) == pet.PetId then CarryService.Unequip(player) end
	end)
	RunService.Heartbeat:Connect(function()
		for player, state in carried do
			local character = living(player)
			local data = DataService.GetData(player)
			local pet = data and data.Inventory[state.Id]
			if character ~= state.Character or state.Model.Parent ~= character or not pet or pet.Placed then
				CarryService.Unequip(player)
			end
		end
		for player, hold in holds do
			if not canPlace(player, hold.Plot) or os.clock() - hold.Started > Config.HoldExpirySeconds then holds[player] = nil end
		end
	end)
end

return CarryService
