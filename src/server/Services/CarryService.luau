local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config.CarryConfig)
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local PlacementService = require(script.Parent.PlacementService)
local PlacementConfig = require(game.ReplicatedStorage.Shared.Config.PlacementConfig)
local carried, connections = {}, {}
local CarryService = {}

local function living(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 or not root then return nil end
	return character, root
end

function CarryService.Unequip(player)
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
		local slot = PlacementService.GetPetCFrame(player, pet)
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

-- The client supplies an expected ID so delayed clicks cannot place a newly
-- equipped pet. Positions are validated against the server-owned Pen floor.
function CarryService.PlaceAt(player, id, position)
	local state = carried[player]
	local character, root = living(player)
	if not state or id ~= state.Id or character ~= state.Character or state.Model.Parent ~= character then return false, "NotCarrying" end
	local target = PlacementService.ResolvePosition(player, position)
	if not target then return false, "OutsidePen" end
	if (root.Position - target.Position).Magnitude > PlacementConfig.ClickDistance then return false, "TooFar" end
	local ok, reason = PlacementService.PlacePet(player, id, target.Position)
	if ok then CarryService.Unequip(player) end
	return ok, reason
end

function CarryService.Start()
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
	end)
end

return CarryService
