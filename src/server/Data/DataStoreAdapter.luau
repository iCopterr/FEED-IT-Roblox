--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DataConfig = require(ReplicatedStorage.Shared.Config.DataConfig)

type UnknownTable = { [any]: any }
type Transform = (unknown) -> unknown

local DataStoreAdapter = {}

local memoryEntries: { [string]: unknown } = {}
local useMemory = RunService:IsStudio() and not DataConfig.UseDataStoreInStudio
local dataStoreName = if RunService:IsStudio()
	then DataConfig.StudioDataStoreName
	else DataConfig.ProductionDataStoreName
local dataStore = if useMemory then nil else DataStoreService:GetDataStore(dataStoreName)

local function deepClone(value: unknown, seen: UnknownTable?): unknown
	if type(value) ~= "table" then
		return value
	end

	local source = value :: UnknownTable
	local visited = seen or {}
	local existing = visited[source]
	if existing ~= nil then
		return existing
	end

	local result: UnknownTable = {}
	visited[source] = result

	for key, entry in source do
		result[deepClone(key, visited)] = deepClone(entry, visited)
	end

	return result
end

local function retryDelay(attempt: number): number
	local exponentialDelay = DataConfig.RequestRetryBaseSeconds * (2 ^ (attempt - 1))
	local cappedDelay = math.min(exponentialDelay, DataConfig.RequestRetryMaxSeconds)
	return cappedDelay + math.random() * DataConfig.RequestRetryJitterSeconds
end

local function updateMemory(key: string, transform: Transform): (boolean, unknown, string?)
	local success, transformedOrError = pcall(transform, deepClone(memoryEntries[key]))
	if not success then
		return false, nil, tostring(transformedOrError)
	end

	if transformedOrError ~= nil then
		memoryEntries[key] = deepClone(transformedOrError)
	end

	return true, deepClone(memoryEntries[key]), nil
end

function DataStoreAdapter.UpdateAsync(key: string, transform: Transform): (boolean, unknown, string?)
	if useMemory then
		return updateMemory(key, transform)
	end

	local lastError = "DataStore request failed"
	for attempt = 1, DataConfig.RequestMaxAttempts do
		local success, resultOrError = pcall(function()
			return (dataStore :: GlobalDataStore):UpdateAsync(key, transform)
		end)

		if success then
			return true, resultOrError, nil
		end

		lastError = tostring(resultOrError)
		if attempt < DataConfig.RequestMaxAttempts then
			task.wait(retryDelay(attempt))
		end
	end

	return false, nil, lastError
end

function DataStoreAdapter.IsMemory(): boolean
	return useMemory
end

function DataStoreAdapter.GetStoreName(): string
	return dataStoreName
end

return table.freeze(DataStoreAdapter)
