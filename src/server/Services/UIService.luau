-- Only the caller's display state crosses this boundary. No economy input is accepted.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)
local PetService = require(script.Parent.PetService)
local CarryService = require(script.Parent.CarryService)
local MoneyService = require(script.Parent.MoneyService)
local PedestalService = require(script.Parent.PedestalService)
local Config = require(ReplicatedStorage.Shared.Config.UIConfig)
local EggConfig = require(ReplicatedStorage.Shared.Config.EggConfig)
local Locks = require(script.Parent.FeedLocks)
local UIService = {}
local lastRequest = {}
local lastSnapshot = {}

function UIService.HandleRequest(player, action, petId, locked)
	local now = os.clock()
	local throttle = if action == "Snapshot" then lastSnapshot else lastRequest
	if now - (throttle[player] or -math.huge) < Config.RequestCooldown then
		return { Ok = false, Code = "Cooldown" }
	end
	throttle[player] = now
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
		if action=="PickupRemote" then
			if type(petId)~="string" or #petId==0 or #petId>64 then return {Ok=false,Code="InvalidRequest"} end
			if Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
			local pet=data.Inventory[petId]
			if not pet or not pet.Placed then return {Ok=false,Code="Unavailable"} end
			local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health<=0 then return {Ok=false,Code="CharacterUnavailable"} end
			local ok,code=require(script.Parent.PlacementService).PickupPet(player,petId)
			return {Ok=ok,Code=if ok then "PickedUp" else code}
		end
		if action == "PlaceHeldPet" then
			local ok, code = CarryService.PlaceAt(player, petId, locked)
			return { Ok = ok, Code = code }
		elseif action == "EquipPet" then
			if type(petId) == "string" and data.Inventory[petId] and (data.Inventory[petId].Placed or PedestalService.GetPetId(player) == petId) then
				return { Ok = false, Code = "HoldToPickup" }
			end
			local ok, code = CarryService.Equip(player, petId)
			return { Ok = ok, Code = code }
		elseif action == "PlaceOnPlate" then
			local ok, code = CarryService.PlaceOnPlate(player, petId)
			return { Ok = ok, Code = code }
		elseif action == "UnequipPet" then
			return { Ok = CarryService.Unequip(player) }
		end
		return { Ok = false, Code = "InvalidRequest" }
	end
	local placedCount = 0
	local eggs = {}
	for uid, egg in data.IncubatingEggs do
		local definition = EggConfig.Definitions[egg.EggId]
		-- Never expose the reserved hatch result to the inventory client.
		table.insert(eggs, {EggUid=uid, EggId=egg.EggId, Name=definition and definition.DisplayName or egg.EggId,
			StartedAt=egg.StartedAt, ReadyAt=egg.ReadyAt, Placed=egg.PenPosition~=nil})
	end
	for _ in data.PlacedPetIds do
		placedCount += 1
	end
	return {
		Foods = require(game.ReplicatedStorage.Shared.Config.FoodConfig).Inventory(data),
		Ok = true, Money = data.Money, Food = require(game.ReplicatedStorage.Shared.Config.FoodConfig).Total(data),
		MaxPetSlots = data.MaxPetSlots, PlacedCount = placedCount,
		Inventory = PetService.GetInventory(player),
		Eggs = eggs, ServerNow = os.time(), Busy = Locks.IsLocked(player),
		CarriedEggUid = CarryService.GetEggId(player),
		CarriedPetId = CarryService.GetPetId(player),
		FeedPlatePetId = PedestalService.GetPetId(player),
		IncomePerSecond = MoneyService.GetRate(player),
		MoneyAt = os.clock(),
		FoodAt = os.clock(),
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
		lastSnapshot[player] = nil
	end)
end

return UIService
