--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
-- Legacy validation limits are save-format compatibility, not gameplay balance.
local LEGACY_PROTECTION_CAP = 10
local LEGACY_TOKEN_CAP = 9999
local FoodConfig = require(ReplicatedStorage.Shared.Config.FoodConfig)

export type PetData = {
	DataVersion: number,
	PetId: string,
	SpeciesId: string,
	EggId: string,
	Rarity: string,
	Variant: string,
	Traits: { string },
	FeedLevel: number,
	BaseIncome: number,
	Locked: boolean,
	Placed: boolean,
	PlotSlot: number?,
	PenPosition: {X: number, Z: number}?,
	CreatedAt: number,
}

export type RecoveryData = {Pet: PetData, AttemptId: string, ExplodedAt: number, FoodSpent: number}
export type EggData = {EggId: string, Pet: PetData, StartedAt: number, ReadyAt: number, PricePaid: number,
	HatchSeconds: number, PenPosition: {X: number, Z: number}?}
export type PlayerData = {
	DataVersion: number,
	Money: number,
	Food: number,
	Foods: { [string]: number },
	ReviveCharges: number,
	ReviveShards: number,
	FarmLevel: number,
	FeedPlateLevel: number,
	FarmPower: number,
	MaxPetSlots: number,
	ProtectionTokens: number,
	Tokens: number,
	MerchantRestockId: number,
	MerchantPurchases: { [string]: boolean },
	Inventory: { [string]: PetData },
	PendingRecovery: { [string]: RecoveryData },
	IncubatingEggs: { [string]: EggData },
	PlacedPetIds: { [string]: boolean },
	PetIndex: { [string]: boolean },
	Statistics: { [string]: number },
	Settings: { [string]: boolean | number | string },
}

type UnknownTable = { [any]: any }
type Migration = (UnknownTable) -> (UnknownTable?, string?)

local PlayerDataSchema = {
	CURRENT_VERSION = GameConfig.PlayerDataVersion,
	PET_CURRENT_VERSION = GameConfig.PetDataVersion,
}

-- Add a migration at the version being migrated from before incrementing
-- PlayerDataVersion. For example, migrations[1] upgrades v1 data to v2.
local migrations: { [number]: Migration } = {}

migrations[11] = function(source)
	local result = table.clone(source)
	result.ReviveShards = 0
	return result, nil
end

migrations[10] = function(source)
	local definitions = require(ReplicatedStorage.Shared.Config.PetConfig).Species
	local function updatePet(pet)
		if type(pet) ~= "table" then return nil end
		local copy = table.clone(pet)
		local definition = definitions[copy.SpeciesId]
		if definition then
			copy.Rarity = definition.Rarity
			copy.BaseIncome = definition.BaseIncome
		end
		-- EggId records acquisition provenance. Purchased eggs retain their result,
		-- original price and timer even when that species moves to another pool.
		return copy
	end
	local result = table.clone(source)
	for _,field in {"Inventory", "PendingRecovery", "IncubatingEggs"} do
		if type(source[field]) ~= "table" then return nil, "Invalid roster migration collection: " .. field end
		local entries = {}
		for id,entry in source[field] do
			if type(entry) ~= "table" then return nil, "Invalid roster migration entry" end
			if field == "Inventory" then
				entries[id] = updatePet(entry)
			else
				local copy = table.clone(entry)
				copy.Pet = updatePet(entry.Pet)
				if not copy.Pet then return nil, "Invalid roster migration nested pet" end
				entries[id] = copy
			end
		end
		result[field] = entries
	end
	return result, nil
end

migrations[9] = function(source)
	local result = table.clone(source)
	result.ReviveCharges = 0
	return result, nil
end

migrations[8] = function(source)
	local result = table.clone(source)
	result.Foods = {}
	result.Tokens, result.ProtectionTokens = 0, 0
	result.MerchantRestockId, result.MerchantPurchases = 0, {}
	return result, nil
end

migrations[7] = function(source)
	local result = table.clone(source)
	result.Tokens = GameConfig.StartingTokens
	result.MerchantRestockId = 0
	result.MerchantPurchases = {}
	return result, nil
end

migrations[6] = function(source)
	local result = table.clone(source)
	result.ProtectionTokens = GameConfig.StartingProtectionTokens
	return result, nil
end

migrations[5] = function(source)
	if type(source.IncubatingEggs) ~= "table" then return nil, "Invalid legacy eggs" end
	local result = table.clone(source)
	result.IncubatingEggs = {}
	for id, egg in source.IncubatingEggs do
		if type(egg) ~= "table" or type(egg.StartedAt) ~= "number" or type(egg.ReadyAt) ~= "number" then
			return nil, "Invalid legacy egg timer"
		end
		local copy = table.clone(egg)
		-- Existing purchased timers keep their progress; placement never rerolls a result.
		copy.HatchSeconds = egg.ReadyAt - egg.StartedAt
		copy.PenPosition = nil
		result.IncubatingEggs[id] = copy
	end
	return result, nil
end

migrations[4] = function(source)
	local result = table.clone(source)
	result.IncubatingEggs = {}
	return result, nil
end

migrations[3] = function(source)
	local result = table.clone(source)
	result.FeedPlateLevel = GameConfig.StartingFeedPlateLevel
	return result, nil
end

migrations[2] = function(source)
	local result = table.clone(source)
	result.PendingRecovery = {}
	return result, nil
end

-- Keep legacy slot locations until the player moves that pet. Never mutate the
-- stored input during migration; validation below rejects malformed records.
migrations[1] = function(source)
	if type(source.Inventory) ~= "table" then return nil, "Invalid legacy inventory" end
	local result = table.clone(source)
	result.Inventory = {}
	for id, pet in source.Inventory do
		if type(pet) ~= "table" or pet.DataVersion ~= 1 then return nil, "Invalid legacy pet version" end
		local copy = table.clone(pet)
		copy.DataVersion = 2
		result.Inventory[id] = copy
	end
	return result, nil
end

local function isFiniteNumber(value: unknown): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function isNonNegativeNumber(value: unknown): boolean
	return isFiniteNumber(value) and (value :: number) >= 0
end

local function isNonNegativeInteger(value: unknown): boolean
	return isNonNegativeNumber(value) and math.floor(value :: number) == value
end

local function isPositiveInteger(value: unknown): boolean
	return isNonNegativeInteger(value) and (value :: number) > 0
end

local function isNonEmptyString(value: unknown): boolean
	return type(value) == "string" and value ~= ""
end

local function validateStringArray(value: unknown, path: string): (boolean, string?)
	if type(value) ~= "table" then
		return false, `{path} must be an array`
	end

	local entryCount = 0
	local seenValues: { [string]: boolean } = {}

	for key, entry in value :: UnknownTable do
		if type(key) ~= "number" or not isPositiveInteger(key) then
			return false, `{path} contains a non-array key`
		end

		if not isNonEmptyString(entry) then
			return false, `{path}[{key}] must be a non-empty string`
		end

		if seenValues[entry] then
			return false, `{path} contains duplicate value {entry}`
		end

		seenValues[entry] = true
		entryCount += 1
	end

	for index = 1, entryCount do
		if (value :: UnknownTable)[index] == nil then
			return false, `{path} must not contain gaps`
		end
	end

	return true, nil
end

local function validatePetData(value: unknown, path: string): (boolean, string?)
	if type(value) ~= "table" then
		return false, `{path} must be a table`
	end

	local pet = value :: UnknownTable

	if pet.DataVersion ~= GameConfig.PetDataVersion then
		return false, `{path}.DataVersion must be {GameConfig.PetDataVersion}`
	end

	for _, fieldName in { "PetId", "SpeciesId", "EggId", "Rarity", "Variant" } do
		if not isNonEmptyString(pet[fieldName]) then
			return false, `{path}.{fieldName} must be a non-empty string`
		end
	end

	local traitsAreValid, traitsError = validateStringArray(pet.Traits, `{path}.Traits`)
	if not traitsAreValid then
		return false, traitsError
	end

	if not isNonNegativeInteger(pet.FeedLevel) then
		return false, `{path}.FeedLevel must be a non-negative integer`
	end

	if not isNonNegativeNumber(pet.BaseIncome) then
		return false, `{path}.BaseIncome must be a non-negative finite number`
	end

	if type(pet.Locked) ~= "boolean" then
		return false, `{path}.Locked must be a boolean`
	end

	if type(pet.Placed) ~= "boolean" then
		return false, `{path}.Placed must be a boolean`
	end

	if pet.PlotSlot ~= nil and not isPositiveInteger(pet.PlotSlot) then
		return false, `{path}.PlotSlot must be nil or a positive integer`
	end

	if pet.Placed and pet.PlotSlot == nil then
		return false, `{path}.PlotSlot is required when the pet is placed`
	end

	if not pet.Placed and pet.PlotSlot ~= nil then
		return false, `{path}.PlotSlot must be nil when the pet is not placed`
	end

	if not isNonNegativeInteger(pet.CreatedAt) then
		return false, `{path}.CreatedAt must be a non-negative integer timestamp`
	end
	if pet.PenPosition ~= nil then
		if not pet.Placed or type(pet.PenPosition) ~= "table" then return false, `{path}.PenPosition requires a placed pet` end
		if not isFiniteNumber(pet.PenPosition.X) or not isFiniteNumber(pet.PenPosition.Z) then return false, `{path}.PenPosition must be finite` end
		for key in pet.PenPosition do
			if key ~= "X" and key ~= "Z" then return false, `{path}.PenPosition has an unknown field` end
		end
	end

	return true, nil
end

local function validateBooleanMap(value: unknown, path: string): (boolean, string?)
	if type(value) ~= "table" then
		return false, `{path} must be a table`
	end

	for key, entry in value :: UnknownTable do
		if not isNonEmptyString(key) then
			return false, `{path} keys must be non-empty strings`
		end

		if entry ~= true then
			return false, `{path}.{key} must be true when present`
		end
	end

	return true, nil
end

local function validateNumberMap(value: unknown, path: string): (boolean, string?)
	if type(value) ~= "table" then
		return false, `{path} must be a table`
	end

	for key, entry in value :: UnknownTable do
		if not isNonEmptyString(key) then
			return false, `{path} keys must be non-empty strings`
		end

		if not isNonNegativeNumber(entry) then
			return false, `{path}.{key} must be a non-negative finite number`
		end
	end

	return true, nil
end

local function validateSettings(value: unknown): (boolean, string?)
	if type(value) ~= "table" then
		return false, "Settings must be a table"
	end

	for key, entry in value :: UnknownTable do
		if not isNonEmptyString(key) then
			return false, "Settings keys must be non-empty strings"
		end

		local entryType = type(entry)
		if entryType ~= "boolean" and entryType ~= "number" and entryType ~= "string" then
			return false, `Settings.{key} must be a boolean, number, or string`
		end

		if entryType == "number" and not isFiniteNumber(entry) then
			return false, `Settings.{key} must be finite`
		end
	end

	return true, nil
end

local function clonePetData(pet: PetData): PetData
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
		PenPosition = if pet.PenPosition then table.clone(pet.PenPosition) else nil,
		CreatedAt = pet.CreatedAt,
	}
end

local function clonePlayerData(data: PlayerData): PlayerData
	local eggs: {[string]: EggData} = {}
	for id, egg in data.IncubatingEggs do
		eggs[id] = {EggId=egg.EggId,Pet=clonePetData(egg.Pet),StartedAt=egg.StartedAt,
			ReadyAt=egg.ReadyAt,PricePaid=egg.PricePaid,HatchSeconds=egg.HatchSeconds,
			PenPosition=if egg.PenPosition then table.clone(egg.PenPosition) else nil}
	end
	local recovery: {[string]: RecoveryData} = {}
	for id, record in data.PendingRecovery do
		recovery[id] = {Pet=clonePetData(record.Pet), AttemptId=record.AttemptId,
			ExplodedAt=record.ExplodedAt, FoodSpent=record.FoodSpent}
	end
	local inventory: { [string]: PetData } = {}
	for petId, pet in data.Inventory do
		inventory[petId] = clonePetData(pet)
	end

	return {
		DataVersion = data.DataVersion,
		Money = data.Money,
		Food = data.Food,
		Foods = table.clone(data.Foods),
		ReviveCharges = data.ReviveCharges,
		ReviveShards = data.ReviveShards,
		FarmLevel = data.FarmLevel,
		FeedPlateLevel = data.FeedPlateLevel,
		FarmPower = data.FarmPower,
		MaxPetSlots = data.MaxPetSlots,
		ProtectionTokens = data.ProtectionTokens,
		Tokens = data.Tokens,
		MerchantRestockId = data.MerchantRestockId,
		MerchantPurchases = table.clone(data.MerchantPurchases),
		Inventory = inventory,
		PendingRecovery = recovery,
		IncubatingEggs = eggs,
		PlacedPetIds = table.clone(data.PlacedPetIds),
		PetIndex = table.clone(data.PetIndex),
		Statistics = table.clone(data.Statistics),
		Settings = table.clone(data.Settings),
	}
end

function PlayerDataSchema.CreateDefault(): PlayerData
	return {
		DataVersion = GameConfig.PlayerDataVersion,
		Money = GameConfig.StartingMoney,
		Food = GameConfig.StartingFood,
		Foods = {},
		ReviveCharges = 0,
		ReviveShards = 0,
		FarmLevel = GameConfig.StartingFarmLevel,
		FeedPlateLevel = GameConfig.StartingFeedPlateLevel,
		FarmPower = GameConfig.StartingFarmPower,
		MaxPetSlots = GameConfig.StartingMaxPetSlots,
		ProtectionTokens = GameConfig.StartingProtectionTokens,
		Tokens = GameConfig.StartingTokens,
		MerchantRestockId = 0,
		MerchantPurchases = {},
		Inventory = {},
		PendingRecovery = {},
		IncubatingEggs = {},
		PlacedPetIds = {},
		PetIndex = {},
		Statistics = {},
		-- Only genuinely new profiles enroll. Migration preserves older settings
		-- and balances, so reconnects/legacy players never receive another grant.
		Settings = {TutorialStep="BuyEgg"},
	}
end

function PlayerDataSchema.ValidatePet(value: unknown): (boolean, string?)
	return validatePetData(value, "Pet")
end

function PlayerDataSchema.Validate(value: unknown): (boolean, string?)
	if type(value) ~= "table" then
		return false, "PlayerData must be a table"
	end

	local data = value :: UnknownTable

	if data.DataVersion ~= GameConfig.PlayerDataVersion then
		return false, `DataVersion must be {GameConfig.PlayerDataVersion}`
	end

	if not isNonNegativeNumber(data.Money) then
		return false, "Money must be a non-negative finite number"
	end

	if not isNonNegativeNumber(data.Food) then
		return false, "Food must be a non-negative finite number"
	end
	if not isNonNegativeInteger(data.ReviveCharges) then return false, "ReviveCharges must be a non-negative integer" end
	if not isNonNegativeInteger(data.ReviveShards) then return false, "ReviveShards must be a non-negative integer" end
	if type(data.Foods) ~= "table" then return false, "Foods must be a map" end
	for id, amount in data.Foods do
		if id == "basic" or not FoodConfig.Types[id] or not isNonNegativeInteger(amount) then
			return false, "Invalid food inventory"
		end
	end

	if not isPositiveInteger(data.FarmLevel) then
		return false, "FarmLevel must be a positive integer"
	end
	if not isPositiveInteger(data.FeedPlateLevel) then
		return false, "FeedPlateLevel must be a positive integer"
	end

	if not isNonNegativeNumber(data.FarmPower) then
		return false, "FarmPower must be a non-negative finite number"
	end

	if not isPositiveInteger(data.MaxPetSlots) then
		return false, "MaxPetSlots must be a positive integer"
	end
	if not isNonNegativeInteger(data.ProtectionTokens) or data.ProtectionTokens > LEGACY_PROTECTION_CAP then
		return false, `ProtectionTokens must be an integer from 0 to {LEGACY_PROTECTION_CAP}`
	end
	if not isNonNegativeInteger(data.Tokens) or data.Tokens > LEGACY_TOKEN_CAP then
		return false, `Tokens must be an integer from 0 to {LEGACY_TOKEN_CAP}`
	end
	if not isNonNegativeInteger(data.MerchantRestockId) then return false, "MerchantRestockId must be a non-negative integer" end
	local purchasesValid,purchasesError=validateBooleanMap(data.MerchantPurchases,"MerchantPurchases")
	if not purchasesValid then return false,purchasesError end

	if type(data.Inventory) ~= "table" then
		return false, "Inventory must be a PetId-keyed table"
	end

	local inventory = data.Inventory :: UnknownTable
	for petId, pet in inventory do
		if not isNonEmptyString(petId) then
			return false, "Inventory keys must be non-empty PetId strings"
		end

		local petIsValid, petError = validatePetData(pet, `Inventory.{petId}`)
		if not petIsValid then
			return false, petError
		end

		if (pet :: UnknownTable).PetId ~= petId then
			return false, `Inventory key {petId} does not match the pet's PetId`
		end
	end

	if type(data.PendingRecovery) ~= "table" then return false, "PendingRecovery must be a map" end
	for id, record in data.PendingRecovery do
		if not isNonEmptyString(id) or type(record) ~= "table" then return false, "Invalid recovery record" end
		local valid, reason = validatePetData(record.Pet, `PendingRecovery.{id}.Pet`)
		if not valid then return false, reason end
		if record.Pet.PetId ~= id or inventory[id] ~= nil or record.Pet.Placed then
			return false, "Recovery pets must be unique, inactive and outside Inventory"
		end
		if not isNonEmptyString(record.AttemptId) or not isNonNegativeInteger(record.ExplodedAt)
			or not isNonNegativeNumber(record.FoodSpent) then return false, "Invalid recovery metadata" end
	end
	if type(data.IncubatingEggs) ~= "table" then return false, "IncubatingEggs must be a map" end
	local reservedPets = {}
	for id, egg in data.IncubatingEggs do
		if not isNonEmptyString(id) or type(egg) ~= "table" or not isNonEmptyString(egg.EggId) then
			return false, "Invalid incubating egg"
		end
		local valid, reason = validatePetData(egg.Pet, `IncubatingEggs.{id}.Pet`)
		if not valid then return false, reason end
		local petId = egg.Pet.PetId
		if egg.Pet.Placed or egg.Pet.FeedLevel ~= 0 or egg.Pet.EggId ~= egg.EggId
			or inventory[petId] ~= nil or data.PendingRecovery[petId] ~= nil or reservedPets[petId] then
			return false, "Incubating pet must be unique, base-level and inactive"
		end
		if not isNonNegativeInteger(egg.StartedAt) or not isNonNegativeInteger(egg.ReadyAt)
			or egg.ReadyAt < egg.StartedAt or not isNonNegativeNumber(egg.PricePaid) then
			return false, "Invalid egg timer/payment"
		end
		reservedPets[petId] = true
		if not isNonNegativeInteger(egg.HatchSeconds)
			or (egg.StartedAt == 0 and egg.ReadyAt ~= 0)
			or (egg.StartedAt > 0 and egg.ReadyAt - egg.StartedAt ~= egg.HatchSeconds) then
			return false, "Invalid egg incubation duration"
		end
		if egg.PenPosition ~= nil then
			if type(egg.PenPosition) ~= "table" or not isFiniteNumber(egg.PenPosition.X)
				or not isFiniteNumber(egg.PenPosition.Z) or egg.StartedAt == 0 then
				return false, "Invalid egg placement"
			end
		end
	end
	local placedIdsAreValid, placedIdsError = validateBooleanMap(data.PlacedPetIds, "PlacedPetIds")
	if not placedIdsAreValid then
		return false, placedIdsError
	end

	local placedPetIds = data.PlacedPetIds :: UnknownTable
	local usedPlotSlots: { [number]: string } = {}
	local placedCount = 0

	for petId in placedPetIds do
		local pet = inventory[petId]
		if pet == nil then
			return false, `PlacedPetIds contains missing pet {petId}`
		end

		if not pet.Placed then
			return false, `PlacedPetIds contains unplaced pet {petId}`
		end

		local plotSlot = pet.PlotSlot :: number
		if plotSlot > data.MaxPetSlots then
			return false, `Pet {petId} uses PlotSlot above MaxPetSlots`
		end

		if usedPlotSlots[plotSlot] ~= nil then
			return false, `Pets {usedPlotSlots[plotSlot]} and {petId} share PlotSlot {plotSlot}`
		end

		usedPlotSlots[plotSlot] = petId
		placedCount += 1
	end

	for petId, pet in inventory do
		if pet.Placed and placedPetIds[petId] ~= true then
			return false, `Placed pet {petId} is missing from PlacedPetIds`
		end
	end

	if placedCount > data.MaxPetSlots then
		return false, "Placed pet count exceeds MaxPetSlots"
	end

	local petIndexIsValid, petIndexError = validateBooleanMap(data.PetIndex, "PetIndex")
	if not petIndexIsValid then
		return false, petIndexError
	end

	local statisticsAreValid, statisticsError = validateNumberMap(data.Statistics, "Statistics")
	if not statisticsAreValid then
		return false, statisticsError
	end

	local settingsAreValid, settingsError = validateSettings(data.Settings)
	if not settingsAreValid then
		return false, settingsError
	end

	return true, nil
end

function PlayerDataSchema.Migrate(value: unknown): (PlayerData?, string?)
	if value == nil then
		return PlayerDataSchema.CreateDefault(), nil
	end

	if type(value) ~= "table" then
		return nil, "Cannot migrate non-table PlayerData"
	end

	local workingData = value :: UnknownTable
	if not isNonNegativeInteger(workingData.DataVersion) then
		return nil, "PlayerData has no valid DataVersion"
	end

	local version = workingData.DataVersion :: number
	if version > GameConfig.PlayerDataVersion then
		return nil, `PlayerData version {version} is newer than supported version {GameConfig.PlayerDataVersion}`
	end

	while version < GameConfig.PlayerDataVersion do
		local migration = migrations[version]
		if migration == nil then
			return nil, `No migration exists from PlayerData version {version}`
		end

		local migratedData, migrationError = migration(workingData)
		if migratedData == nil then
			return nil, migrationError or `Migration from version {version} failed`
		end

		workingData = migratedData
		version += 1
		workingData.DataVersion = version
	end

	local isValid, validationError = PlayerDataSchema.Validate(workingData)
	if not isValid then
		return nil, validationError
	end

	return clonePlayerData(workingData :: PlayerData), nil
end

return table.freeze(PlayerDataSchema)
