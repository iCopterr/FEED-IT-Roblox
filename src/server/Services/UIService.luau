-- Only the caller's display state crosses this boundary. No economy input is accepted.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local PlacementService = require(script.Parent.PlacementService)
local Config = require(ReplicatedStorage.Shared.Config.UIConfig)
local UIService = {}
local lastRequest = {}

function UIService.HandleRequest(player, action, petId, locked)
	local now = os.clock()
	if now - (lastRequest[player] or -math.huge) < Config.RequestCooldown then
		return { Ok = false, Code = "Cooldown" }
	end
	lastRequest[player] = now
	local data = DataService.GetData(player)
	if not data then
		return { Ok = false, Code = "Loading" }
	end
	if action == "SetLocked" then
		if type(petId) ~= "string" or #petId > 64 or type(locked) ~= "boolean" then
			return { Ok = false, Code = "InvalidRequest" }
		end
		local ok = PetService.SetLocked(player, petId, locked)
		return { Ok = ok, Code = if ok then "Updated" else "Rejected" }
	elseif action ~= "Snapshot" then
		if action == "PlacePet" or action == "PickupPet" then
			local ok, code = (if action == "PlacePet" then PlacementService.PlacePet else PlacementService.PickupPet)(player, petId)
			return { Ok = ok, Code = code }
		end
		return { Ok = false, Code = "InvalidRequest" }
	end
	local placedCount = 0
	for _ in data.PlacedPetIds do
		placedCount += 1
	end
	return {
		Ok = true, Money = data.Money, Food = data.Food,
		MaxPetSlots = data.MaxPetSlots, PlacedCount = placedCount,
		Inventory = PetService.GetInventory(player),
	}
end

function UIService.Start()
	local remotes = Instance.new("Folder")
	remotes.Name = "PrototypeUI"
	local request = Instance.new("RemoteFunction")
	request.Name = "Request"
	request.OnServerInvoke = UIService.HandleRequest
	request.Parent = remotes
	remotes.Parent = ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return UIService
