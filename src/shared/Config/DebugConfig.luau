return table.freeze({
	RequestCooldown = 0.2,
	MaxGrant = 1e15,
	MaxBalance = 4e15,
	MaxSpawnedInventory = 200,
	DefaultGrant = 1000000,
	RefreshSeconds = 1,
	Modes = table.freeze({"Success", "Critical", "Mega", "Insane", "Explosion", "Clear"}),
})
