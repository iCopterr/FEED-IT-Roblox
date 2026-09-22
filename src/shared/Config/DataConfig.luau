--!strict

local DataConfig = {
	-- Prototype playtests never read or write remote player data.
	MemoryOnly = true,
	ProductionDataStoreName = "FeedYourPet_PlayerData_v1",
	StudioDataStoreName = "FeedYourPet_StudioPlayerData_v1",
	PlayerKeyPrefix = "Player_",
	StoredRecordVersion = 1,

	-- Memory mode is safe by default. Set this to true only when Studio API access
	-- is enabled; Studio still uses the isolated store name above.
	UseDataStoreInStudio = false,

	RequestMaxAttempts = 5,
	RequestRetryBaseSeconds = 1,
	RequestRetryMaxSeconds = 8,
	RequestRetryJitterSeconds = 0.25,

	AutosaveIntervalSeconds = 60,
	SessionLockTimeoutSeconds = 180,
	SessionAcquireAttempts = 3,
	SessionAcquireRetrySeconds = 2,
	ShutdownTimeoutSeconds = 25,
}

return table.freeze(DataConfig)
