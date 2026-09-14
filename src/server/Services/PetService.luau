--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local DataService = require(script.Parent.DataService)
local PlayerDataSchema = require(script.Parent.Parent.Data.PlayerDataSchema)

type PetData = PlayerDataSchema.PetData
type PlayerData = PlayerDataSchema.PlayerData
type SpeciesDefinition = PetConfig.SpeciesDefinition

local PetService = {}

local petAddedEvent = Instance.new("BindableEvent")
local petRemovedEvent = Instance.new("BindableEvent")
local petChangedEvent = Instance.new("BindableEvent")
local started = false

PetService.PetAdded = petAddedEvent.Event
PetService.PetRemoved = petRemovedEvent.Event
PetService.PetChanged = petChangedEvent.Event

local function clonePet(pet: PetData): PetData
	return {
		DataVersion = pet.DataVersion,
		PetId = pet.PetId,
		SpeciesId = pet.SpeciesId,
		EggId = pet.EggId,
		Rarity = pet.Rarity,
		Variant = pet.Variant,
		Traits = table.clone(pet.Traits),
		FeedLevel = pet.FeedLevel,
		BaseIncome = pet.BaseIncome,
		Locked = pet.Locked,
		Placed = pet.Placed,
		PlotSlot = pet.PlotSlot,
		CreatedAt = pet.CreatedAt,
	}
end

local function getPlayerData(player: Player): (PlayerData?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "Player data is not loaded"
	end
	return data, nil
end

local function getSpeciesDefinition(speciesId: string): (SpeciesDefinition?, string?)
	if speciesId == "" then
		return nil, "SpeciesId must not be empty"
	end

	local definition = PetConfig.Species[speciesId]
	if definition == nil then
		return nil, `Unknown SpeciesId {speciesId}`
	end
	return definition, nil
end

local function generateUniquePetId(data: PlayerData): string?
	for _ = 1, PetConfig.PetIdGenerationAttempts do
		local petId = HttpService:GenerateGUID(false)
		if data.Inventory[petId] == nil then
			return petId
		end
	end
	return nil
end

local function validateMutation(data: PlayerData): (boolean, string?)
	local isValid, validationError = PlayerDataSchema.Validate(data)
	if not isValid then
		return false, validationError or "Player data validation failed"
	end
	return true, nil
end

local function validateConfig()
	local speciesCount = 0
	local rarityCount: { [string]: number } = {}

	for speciesId, definition in PetConfig.Species do
		assert(speciesId == definition.SpeciesId, `PetConfig key {speciesId} does not match SpeciesId`)
		assert(definition.EggId == PetConfig.PrototypeEggId, `Species {speciesId} is not in the prototype Egg`)

		local expectedIncome = PetConfig.RarityBaseIncome[definition.Rarity]
		assert(expectedIncome ~= nil, `Species {speciesId} has unknown rarity {definition.Rarity}`)
		assert(definition.BaseIncome == expectedIncome, `Species {speciesId} has incorrect BaseIncome`)

		speciesCount += 1
		rarityCount[definition.Rarity] = (rarityCount[definition.Rarity] or 0) + 1
	end

	assert(speciesCount == 6, "Prototype PetConfig must contain exactly six species")
	for rarity in PetConfig.RarityBaseIncome do
		assert(rarityCount[rarity] == 1, `Prototype PetConfig must contain one {rarity} species`)
	end
end

function PetService.Start()
	assert(not started, "PetService.Start may only be called once")
	validateConfig()
	started = true
	print(`[PetService] Started with six prototype species`)
end

function PetService.CreatePet(player: Player, speciesId: string): (PetData?, string?)
	if type(speciesId) ~= "string" then
		return nil, "SpeciesId must be a string"
	end

	local data, dataError = getPlayerData(player)
	if data == nil then
		return nil, dataError
	end

	local definition, definitionError = getSpeciesDefinition(speciesId)
	if definition == nil then
		return nil, definitionError
	end

	local petId = generateUniquePetId(data)
	if petId == nil then
		return nil, "Unable to generate a unique PetId"
	end

	local pet: PetData = {
		DataVersion = GameConfig.PetDataVersion,
		PetId = petId,
		SpeciesId = definition.SpeciesId,
		EggId = definition.EggId,
		Rarity = definition.Rarity,
		Variant = PetConfig.DefaultVariant,
		Traits = {},
		FeedLevel = 0,
		BaseIncome = definition.BaseIncome,
		Locked = false,
		Placed = false,
		PlotSlot = nil,
		CreatedAt = os.time(),
	}

	local previousIndexValue = data.PetIndex[speciesId]
	data.Inventory[petId] = pet
	data.PetIndex[speciesId] = true

	local isValid, validationError = validateMutation(data)
	if not isValid then
		data.Inventory[petId] = nil
		data.PetIndex[speciesId] = previousIndexValue
		return nil, `Pet creation failed validation: {validationError}`
	end

	local snapshot = clonePet(pet)
	petAddedEvent:Fire(player, snapshot)
	return snapshot, nil
end

function PetService.GetPet(player: Player, petId: string): (PetData?, string?)
	if type(petId) ~= "string" or petId == "" then
		return nil, "PetId must be a non-empty string"
	end

	local data, dataError = getPlayerData(player)
	if data == nil then
		return nil, dataError
	end

	local pet = data.Inventory[petId]
	if pet == nil then
		return nil, "Pet does not exist in this player's inventory"
	end
	return clonePet(pet), nil
end

function PetService.GetInventory(player: Player): ({ [string]: PetData }?, string?)
	local data, dataError = getPlayerData(player)
	if data == nil then
		return nil, dataError
	end

	local inventory: { [string]: PetData } = {}
	for petId, pet in data.Inventory do
		inventory[petId] = clonePet(pet)
	end
	return inventory, nil
end

function PetService.SetLocked(player: Player, petId: string, locked: boolean): (boolean, string?)
	if type(petId) ~= "string" or petId == "" then
		return false, "PetId must be a non-empty string"
	end
	if type(locked) ~= "boolean" then
		return false, "Locked must be a boolean"
	end

	local data, dataError = getPlayerData(player)
	if data == nil then
		return false, dataError
	end

	local pet = data.Inventory[petId]
	if pet == nil then
		return false, "Pet does not exist in this player's inventory"
	end
	if pet.Locked == locked then
		return true, nil
	end

	local previousValue = pet.Locked
	pet.Locked = locked
	local isValid, validationError = validateMutation(data)
	if not isValid then
		pet.Locked = previousValue
		return false, `Pet lock change failed validation: {validationError}`
	end

	petChangedEvent:Fire(player, clonePet(pet), "Locked")
	return true, nil
end

function PetService.RemovePet(player: Player, petId: string): (PetData?, string?)
	-- This is permanent inventory removal for ordinary flows such as selling.
	-- Explosion must use its future pending-recovery transaction instead.
	if type(petId) ~= "string" or petId == "" then
		return nil, "PetId must be a non-empty string"
	end

	local data, dataError = getPlayerData(player)
	if data == nil then
		return nil, dataError
	end

	local pet = data.Inventory[petId]
	if pet == nil then
		return nil, "Pet does not exist in this player's inventory"
	end
	if pet.Locked then
		return nil, "Locked pets cannot be removed"
	end
	if pet.Placed or data.PlacedPetIds[petId] then
		return nil, "Placed pets must be picked up before removal"
	end

	data.Inventory[petId] = nil
	local isValid, validationError = validateMutation(data)
	if not isValid then
		data.Inventory[petId] = pet
		return nil, `Pet removal failed validation: {validationError}`
	end

	local snapshot = clonePet(pet)
	petRemovedEvent:Fire(player, snapshot)
	return snapshot, nil
end

return table.freeze(PetService)
