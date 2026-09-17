local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.Config.UIConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local Stud = require(script.Parent.Parent.UI.Stud)
local GuiBootstrap = require(script.Parent.Parent.UI.GuiBootstrap)
local Text, Palette = Config.Text, Config.Palette
local HUDController = {}

local function numberText(value)
	local formatted = string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
	local digits, decimals = formatted:match("^(%d+)(.*)$")
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return grouped .. decimals
end

function HUDController.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
	assert(playerGui, "PlayerGui did not become available")
	local gui = playerGui:WaitForChild("FeedYourPetUI", 3)
	if not gui then
		local template = game:GetService("StarterGui"):WaitForChild("FeedYourPetUI", 3)
		gui = GuiBootstrap.Ensure(playerGui, template)
	end
	local hud = gui:WaitForChild("HUD")
	local hudScale = hud:WaitForChild("UIScale")
	local moneyLabel = hud:WaitForChild("Money"):WaitForChild("Value")
	local lastMoneyAt = -math.huge
	local function updateMoney(state)
		local timestamp = state.MoneyAt or 0
		if timestamp < lastMoneyAt then return end
		lastMoneyAt = timestamp
		-- Payouts already arrive once per second; another timer adds visible lag.
		moneyLabel.Text = string.format(Text.Money, numberText(state.Money), numberText(state.IncomePerSecond or 0))
	end
	ReplicatedStorage:WaitForChild("PetIncome").OnClientEvent:Connect(updateMoney)
	local foodLabel = hud:WaitForChild("Food"):WaitForChild("Value")
	local lastFoodAt = -math.huge
	local function updateFood(state)
		local timestamp = state.FoodAt or 0
		if timestamp < lastFoodAt then return end
		lastFoodAt = timestamp
		foodLabel.Text = string.format(Text.Food, numberText(state.Food))
	end
	game.ReplicatedStorage:WaitForChild("Farm").OnClientEvent:Connect(updateFood)
	local open = hud:WaitForChild("OpenInventory")
	local modal = gui:WaitForChild("Inventory")
	local modalScale = modal:WaitForChild("UIScale")
	local layout = modal:WaitForChild("Panel"):WaitForChild("Layout")
	local title = layout:WaitForChild("Title")
	local close = layout:WaitForChild("Close")
	local list = layout:WaitForChild("Pets")
	local cardTemplate = list:WaitForChild("PetCardTemplate")
	local empty = layout:WaitForChild("EmptyState")
	local detail = layout:WaitForChild("PetDetails")
	local lock = layout:WaitForChild("LockPet")
	local place = layout:WaitForChild("PlacePet")
	local slots = layout:WaitForChild("PenSlots")
	local status = layout:WaitForChild("Status")
	modal.Visible = false
	cardTemplate.Visible = false
	local snapshot, selectedId, remote
	local busy = false
	local signature = ""
	local cards = {}
	local function updateSelection()
		local pet = snapshot and snapshot.Inventory[selectedId]
		lock.Visible = pet ~= nil
		place.Visible = pet ~= nil
		if pet then
			place.ButtonText.Text = if snapshot.CarriedPetId == pet.PetId then Text.Unequip elseif pet.Placed or snapshot.FeedPlatePetId == pet.PetId then Text.Pickup else Text.Equip
			local definition = PetConfig.Species[pet.SpeciesId]
			detail.Text = string.format(Text.Details, definition and definition.DisplayName or pet.SpeciesId,
				pet.Rarity, pet.Variant, pet.FeedLevel, numberText(pet.BaseIncome), if snapshot.FeedPlatePetId == pet.PetId then "On feed plate" elseif pet.Placed then Text.Placed else Text.Stored)
			lock.ButtonText.Text = if pet.Locked then Text.Unlock else Text.Lock
		else
			detail.Text = Text.Select
		end
		for id, card in cards do
			Stud.Tint(card, if id == selectedId then Palette.Selected else Palette.Card)
		end
	end
	local function render(state)
		snapshot = state
		updateMoney(state)
		updateFood(state)
		slots.Text = string.format(Text.Slots, state.PlacedCount, state.MaxPetSlots)
		local pets, parts = {}, {}
		for _, pet in state.Inventory do table.insert(pets, pet) end
		table.sort(pets, function(a, b)
			if a.CreatedAt == b.CreatedAt then return a.PetId < b.PetId end
			return a.CreatedAt > b.CreatedAt
		end)
		for _, pet in pets do
			table.insert(parts, pet.PetId .. ":" .. tostring(pet.Locked) .. ":" .. pet.FeedLevel)
		end
		local nextSignature = table.concat(parts, "|")
		if nextSignature ~= signature then
			signature = nextSignature
			for _, card in cards do card:Destroy() end
			table.clear(cards)
			for index, pet in pets do
				local definition = PetConfig.Species[pet.SpeciesId]
				local card = cardTemplate:Clone()
				card.Name = pet.PetId
				card.Visible = true
				card.ButtonText.Text = string.format(Text.Card,
					definition and definition.DisplayName or pet.SpeciesId, pet.Rarity, pet.FeedLevel,
					if pet.Locked then Text.Locked else Text.Unlocked)
				card.Parent = list
				card.LayoutOrder = index
				cards[pet.PetId] = card
				card.Activated:Connect(function() selectedId = pet.PetId; updateSelection() end)
			end
		end
		title.Text = string.format(Text.Title, #pets)
		empty.Text = Text.Empty
		empty.Visible = #pets == 0
		updateSelection()
	end
	open.Activated:Connect(function() modal.Visible = not modal.Visible end)
	close.Activated:Connect(function() modal.Visible = false end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape then modal.Visible = false end
	end)
	lock.Activated:Connect(function()
		local pet = snapshot and snapshot.Inventory[selectedId]
		if busy or not remote or not pet then return end
		busy = true
		status.Text = Text.Saving
		local ok, result = pcall(function() return remote:InvokeServer("SetLocked", pet.PetId, not pet.Locked) end)
		status.Text = if ok and result.Ok then "" else Text.LockError
		-- Do not change local pet data before an authoritative snapshot arrives.
		task.wait(Config.RequestCooldown)
		busy = false
	end)
	place.Activated:Connect(function()
		local pet = snapshot and snapshot.Inventory[selectedId]
		if busy or not remote or not pet then return end
		if pet.Placed or snapshot.FeedPlatePetId == pet.PetId then status.Text = "Walk to your pet and hold E to pick it up."; return end
		busy = true
		status.Text = Text.Saving
		local ok, result = pcall(function()
			return remote:InvokeServer(if snapshot.CarriedPetId == pet.PetId then "UnequipPet" else "EquipPet", pet.PetId)
		end)
		status.Text = if ok and result.Ok then "" elseif ok and result.Code == "TooFar" then Text.PickupTooFar else Text.PlacementError
		if ok and result.Ok and snapshot.CarriedPetId ~= pet.PetId then modal.Visible = false end
		task.wait(Config.RequestCooldown)
		if ok and result.Ok then
			local refreshed, state = pcall(function() return remote:InvokeServer("Snapshot") end)
			if refreshed and state.Ok then render(state) end
			task.wait(Config.RequestCooldown)
		end
		busy = false
	end)
	local function resize()
		local size = gui.AbsoluteSize
		hudScale.Scale = math.min(1, (size.X - 20) / 1000)
		modalScale.Scale = math.min(1, (size.X - 20) / 1000, (size.Y - 130 * hudScale.Scale) / 800)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	task.spawn(function()
		remote = ReplicatedStorage:WaitForChild("PrototypeUI"):WaitForChild("Request")
		while gui.Parent do
			if not busy then
				busy = true
				local ok, state = pcall(function() return remote:InvokeServer("Snapshot") end)
				if ok and state.Ok then
					render(state)
					status.Text = ""
				else
					status.Text = if ok and state.Code == "Loading" then Text.Loading else Text.Retry
				end
				task.wait(Config.RequestCooldown)
				busy = false
			end
			task.wait(Config.SnapshotInterval)
		end
	end)
	return gui
end

return HUDController
