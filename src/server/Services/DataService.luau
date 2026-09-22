--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataConfig = require(ReplicatedStorage.Shared.Config.DataConfig)
local DataStoreAdapter = require(script.Parent.Parent.Data.DataStoreAdapter)
local PlayerDataSchema = require(script.Parent.Parent.Data.PlayerDataSchema)

type PlayerData = PlayerDataSchema.PlayerData
type UnknownTable = { [any]: any }

type StoredSession = {
	ServerId: string,
	SessionId: string,
	PlaceId: number,
	AcquiredAt: number,
	HeartbeatAt: number,
}

type StoredRecord = {
	RecordVersion: number,
	Data: PlayerData,
	Session: StoredSession?,
	LastSessionId: string?,
	LastSavedAt: number,
}

type ActiveSession = {
	Player: Player,
	Data: PlayerData,
	SessionId: string,
	AcquiredAt: number,
	Busy: boolean,
	Idle: BindableEvent,
	Closing: boolean,
	Released: boolean,
}

local DataService = {}

local serverId = if game.JobId ~= "" then game.JobId else `studio-{HttpService:GenerateGUID(false)}`
local activeSessions: { [number]: ActiveSession } = {}
local loadingPlayers: { [number]: boolean } = {}
local started = false
local shuttingDown = false

local function playerKey(userId: number): string
	return `{DataConfig.PlayerKeyPrefix}{userId}`
end

local function isNonNegativeInteger(value: unknown): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value >= 0
		and math.floor(value) == value
end

local function validateStoredSession(value: unknown): (StoredSession?, string?)
	if type(value) ~= "table" then
		return nil, "Session must be a table"
	end

	local session = value :: UnknownTable
	if type(session.ServerId) ~= "string" or session.ServerId == "" then
		return nil, "Session.ServerId must be a non-empty string"
	end
	if type(session.SessionId) ~= "string" or session.SessionId == "" then
		return nil, "Session.SessionId must be a non-empty string"
	end
	if not isNonNegativeInteger(session.PlaceId) then
		return nil, "Session.PlaceId must be a non-negative integer"
	end
	if not isNonNegativeInteger(session.AcquiredAt) then
		return nil, "Session.AcquiredAt must be a non-negative integer timestamp"
	end
	if not isNonNegativeInteger(session.HeartbeatAt) then
		return nil, "Session.HeartbeatAt must be a non-negative integer timestamp"
	end

	return {
		ServerId = session.ServerId,
		SessionId = session.SessionId,
		PlaceId = session.PlaceId,
		AcquiredAt = session.AcquiredAt,
		HeartbeatAt = session.HeartbeatAt,
	}, nil
end

local function decodeRecord(value: unknown): (StoredRecord?, string?)
	if value == nil then
		local data = PlayerDataSchema.CreateDefault()
		return {
			RecordVersion = DataConfig.StoredRecordVersion,
			Data = data,
			Session = nil,
			LastSessionId = nil,
			LastSavedAt = 0,
		}, nil
	end

	if type(value) ~= "table" then
		return nil, "Stored player record must be a table"
	end

	local raw = value :: UnknownTable

	-- Data created before the session wrapper is upgraded in place on load.
	if raw.RecordVersion == nil and raw.DataVersion ~= nil then
		local migratedData, migrationError = PlayerDataSchema.Migrate(raw)
		if migratedData == nil then
			return nil, migrationError
		end

		return {
			RecordVersion = DataConfig.StoredRecordVersion,
			Data = migratedData,
			Session = nil,
			LastSessionId = nil,
			LastSavedAt = 0,
		}, nil
	end

	if raw.RecordVersion ~= DataConfig.StoredRecordVersion then
		return nil, `Unsupported stored record version {tostring(raw.RecordVersion)}`
	end

	local migratedData, migrationError = PlayerDataSchema.Migrate(raw.Data)
	if migratedData == nil then
		return nil, migrationError
	end

	local storedSession: StoredSession? = nil
	if raw.Session ~= nil then
		local sessionError: string?
		storedSession, sessionError = validateStoredSession(raw.Session)
		if storedSession == nil then
			return nil, sessionError
		end
	end

	if raw.LastSessionId ~= nil and (type(raw.LastSessionId) ~= "string" or raw.LastSessionId == "") then
		return nil, "LastSessionId must be nil or a non-empty string"
	end
	if not isNonNegativeInteger(raw.LastSavedAt) then
		return nil, "LastSavedAt must be a non-negative integer timestamp"
	end

	return {
		RecordVersion = DataConfig.StoredRecordVersion,
		Data = migratedData,
		Session = storedSession,
		LastSessionId = raw.LastSessionId,
		LastSavedAt = raw.LastSavedAt,
	}, nil
end

local function ownsStoredSession(storedSession: StoredSession?, sessionId: string): boolean
	return storedSession ~= nil
		and storedSession.ServerId == serverId
		and storedSession.SessionId == sessionId
end

local function beginOperation(session: ActiveSession): boolean
	while session.Busy do
		session.Idle.Event:Wait()
	end

	if session.Released then
		return false
	end

	session.Busy = true
	return true
end

local function endOperation(session: ActiveSession)
	session.Busy = false
	session.Idle:Fire()
end

local function saveSession(session: ActiveSession, release: boolean): (boolean, string?)
	if not beginOperation(session) then
		return true, nil
	end

	local validSnapshot, validationError = PlayerDataSchema.Migrate(session.Data)
	if validSnapshot == nil then
		endOperation(session)
		return false, `Refusing to save invalid player data: {validationError or "unknown validation error"}`
	end

	local outcome = "request_failed"
	local outcomeError: string? = nil
	local now = os.time()
	local success, _, requestError = DataStoreAdapter.UpdateAsync(playerKey(session.Player.UserId), function(currentValue)
		local record, decodeError = decodeRecord(currentValue)
		if record == nil then
			outcome = "invalid_record"
			outcomeError = decodeError
			return nil
		end

		if release and record.Session == nil and record.LastSessionId == session.SessionId then
			outcome = "already_released"
			return nil
		end

		if not ownsStoredSession(record.Session, session.SessionId) then
			outcome = "lost_session"
			return nil
		end

		record.Data = validSnapshot
		record.LastSavedAt = now
		if release then
			record.Session = nil
			record.LastSessionId = session.SessionId
			outcome = "released"
		else
			(record.Session :: StoredSession).HeartbeatAt = now
			outcome = "saved"
		end

		return record
	end)

	local operationSucceeded = success
		and (outcome == "saved" or outcome == "released" or outcome == "already_released")
	local saveError = requestError or outcomeError
	if not operationSucceeded and saveError == nil then
		saveError = if outcome == "lost_session"
			then "This server no longer owns the player session"
			else `Save ended with status {outcome}`
	end
	if outcome == "lost_session" then
		session.Closing = true
		if session.Player.Parent == Players then
			task.defer(function()
				session.Player:Kick("Your data session moved to another server. Please rejoin.")
			end)
		end
	end

	if operationSucceeded then
		if release then
			session.Released = true
		end
	end

	endOperation(session)
	return operationSucceeded, saveError
end

local function loadPlayer(player: Player)
	if shuttingDown then
		player:Kick("The server is shutting down. Please rejoin.")
		return
	end
	if activeSessions[player.UserId] ~= nil then
		player:Kick("Your data is already loaded on this server.")
		return
	end

	player:SetAttribute("DataLoaded", false)

	local sessionId = HttpService:GenerateGUID(false)
	local acquiredAt = os.time()
	local loadedData: PlayerData? = nil
	local lastError = "Unable to acquire the player data session"

	for acquireAttempt = 1, DataConfig.SessionAcquireAttempts do
		local outcome = "request_failed"
		local outcomeError: string? = nil
		local success, updatedValue, requestError = DataStoreAdapter.UpdateAsync(playerKey(player.UserId), function(currentValue)
			local record, decodeError = decodeRecord(currentValue)
			if record == nil then
				outcome = "invalid_record"
				outcomeError = decodeError
				return nil
			end

			local now = os.time()
			local storedSession = record.Session
			local ownsLock = ownsStoredSession(storedSession, sessionId)
			local lockIsActive = storedSession ~= nil
				and now - storedSession.HeartbeatAt < DataConfig.SessionLockTimeoutSeconds

			if storedSession ~= nil and not ownsLock and lockIsActive then
				outcome = "session_locked"
				return nil
			end

			record.Session = {
				ServerId = serverId,
				SessionId = sessionId,
				PlaceId = game.PlaceId,
				AcquiredAt = acquiredAt,
				HeartbeatAt = now,
			}
			record.LastSavedAt = now
			outcome = "acquired"
			return record
		end)

		if success and outcome == "acquired" then
			local record, decodeError = decodeRecord(updatedValue)
			if record ~= nil and ownsStoredSession(record.Session, sessionId) then
				loadedData = record.Data
				break
			end
			lastError = decodeError or "DataStore did not return the acquired session"
		elseif outcome == "session_locked" then
			lastError = "Your data is active on another server"
		elseif outcome == "invalid_record" then
			lastError = `Stored data is invalid: {outcomeError or "unknown error"}`
			break
		else
			lastError = requestError or outcomeError or `Load ended with status {outcome}`
		end

		if acquireAttempt < DataConfig.SessionAcquireAttempts then
			task.wait(DataConfig.SessionAcquireRetrySeconds)
		end
	end

	if loadedData == nil then
		warn(`[DataService] Load failed for {player.UserId}: {lastError}`)
		player:Kick("We couldn't safely load your data. Please try again.")
		return
	end

	if player.Parent ~= Players or shuttingDown then
		local temporarySession: ActiveSession = {
			Player = player,
			Data = loadedData,
			SessionId = sessionId,
			AcquiredAt = acquiredAt,
			Busy = false,
			Idle = Instance.new("BindableEvent"),
			Closing = true,
			Released = false,
		}
		local released, releaseError = saveSession(temporarySession, true)
		if not released then
			warn(`[DataService] Failed to release abandoned session for {player.UserId}: {releaseError}`)
		end
		temporarySession.Idle:Destroy()
		return
	end

	local activeSession: ActiveSession = {
		Player = player,
		Data = loadedData,
		SessionId = sessionId,
		AcquiredAt = acquiredAt,
		Busy = false,
		Idle = Instance.new("BindableEvent"),
		Closing = false,
		Released = false,
	}
	activeSessions[player.UserId] = activeSession
	player:SetAttribute("DataLoaded", true)
	print(`[DataService] Loaded data for {player.Name} ({player.UserId})`)
end

local function scheduleLoad(player: Player)
	if loadingPlayers[player.UserId] or activeSessions[player.UserId] ~= nil then
		return
	end

	loadingPlayers[player.UserId] = true
	task.spawn(function()
		loadPlayer(player)
		loadingPlayers[player.UserId] = nil

		local currentPlayer = Players:GetPlayerByUserId(player.UserId)
		if currentPlayer ~= nil and currentPlayer ~= player and not shuttingDown then
			scheduleLoad(currentPlayer)
		end
	end)
end

local function closePlayerSession(player: Player)
	local session = activeSessions[player.UserId]
	if session == nil then
		return
	end

	session.Closing = true
	player:SetAttribute("DataLoaded", false)

	local saved, saveError = saveSession(session, true)
	if not saved then
		warn(`[DataService] Final save failed for {player.UserId}: {saveError}`)
	end

	if activeSessions[player.UserId] == session then
		activeSessions[player.UserId] = nil
	end
	session.Idle:Destroy()
end

local function autosaveLoop()
	while not shuttingDown do
		task.wait(DataConfig.AutosaveIntervalSeconds)
		if shuttingDown then
			break
		end

		for _, session in activeSessions do
			if not session.Closing and not session.Released then
				task.spawn(function()
					local saved, saveError = saveSession(session, false)
					if not saved then
						warn(`[DataService] Autosave failed for {session.Player.UserId}: {saveError}`)
					end
				end)
			end
		end
	end
end

local function closeServer()
	if shuttingDown then
		return
	end
	shuttingDown = true

	local sessionsToClose: { ActiveSession } = {}
	for _, session in activeSessions do
		session.Closing = true
		table.insert(sessionsToClose, session)
	end

	local remaining = #sessionsToClose
	if remaining == 0 then
		return
	end

	local allFinished = Instance.new("BindableEvent")
	for _, session in sessionsToClose do
		task.spawn(function()
			local saved, saveError = saveSession(session, true)
			if not saved then
				warn(`[DataService] Shutdown save failed for {session.Player.UserId}: {saveError}`)
			end

			remaining -= 1
			if remaining == 0 then
				allFinished:Fire()
			end
		end)
	end

	local timedOut = false
	local waiting = true
	task.delay(DataConfig.ShutdownTimeoutSeconds, function()
		if waiting then
			timedOut = true
			allFinished:Fire()
		end
	end)
	allFinished.Event:Wait()
	waiting = false
	allFinished:Destroy()

	if timedOut and remaining > 0 then
		warn(`[DataService] Shutdown save timed out with {remaining} session(s) remaining`)
	end
end

function DataService.Start()
	assert(not started, "DataService.Start may only be called once")
	started = true

	Players.PlayerAdded:Connect(scheduleLoad)
	Players.PlayerRemoving:Connect(closePlayerSession)
	game:BindToClose(closeServer)

	for _, player in Players:GetPlayers() do
		scheduleLoad(player)
	end
	task.spawn(autosaveLoop)

	local mode = if DataStoreAdapter.IsMemory() then "session memory" else "DataStore"
	print(`[DataService] Started in {mode} mode ({DataStoreAdapter.GetStoreName()})`)
end

function DataService.IsLoaded(player: Player): boolean
	local session = activeSessions[player.UserId]
	return session ~= nil and not session.Closing and not session.Released
end

function DataService.GetData(player: Player): PlayerData?
	local session = activeSessions[player.UserId]
	if session == nil or session.Closing or session.Released then
		return nil
	end
	return session.Data
end

function DataService.Save(player: Player): (boolean, string?)
	local session = activeSessions[player.UserId]
	if session == nil then
		return false, "Player data is not loaded"
	end
	if session.Closing then
		return false, "Player data session is closing"
	end
	return saveSession(session, false)
end

return table.freeze(DataService)
