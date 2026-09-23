--!strict
-- Mutually exclusive, species-independent rolls reserved once with the egg.
local Config = {}
Config.Tickets = 100_000
Config.Order = table.freeze({"Celestial", "Rainbow", "Shiny", "Normal"})
Config.Types = table.freeze({
	Normal = table.freeze({Tickets=99_889, IncomeMultiplier=1}),
	Shiny = table.freeze({Tickets=100, IncomeMultiplier=2}),
	Rainbow = table.freeze({Tickets=10, IncomeMultiplier=5}),
	Celestial = table.freeze({Tickets=1, IncomeMultiplier=10}),
})
function Config.Pick(ticket: number): string
	assert(ticket==ticket and ticket%1==0 and ticket>=1 and ticket<=Config.Tickets, "Invalid variant ticket")
	local boundary=0
	for _,name in Config.Order do
		boundary+=Config.Types[name].Tickets
		if ticket<=boundary then return name end
	end
	error("Invalid variant weights")
end
function Config.Multiplier(variant: string?): number
	local definition=variant and Config.Types[variant]
	return if definition then definition.IncomeMultiplier else 1
end
function Config.Name(name: string, variant: string?): string
	return if variant and variant~="Normal" then variant.." "..name else name
end
return table.freeze(Config)
