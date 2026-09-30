-- Display only. Never round stored balances, prices or affordability checks.
local NumberFormat = {}
local suffixes = {"", "K", "M", "B", "T"}
local multipliers = {K=1e3, M=1e6, B=1e9, T=1e12}

local function format(value: number, fixedDecimals: boolean): string
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return "—" end
	local scaled, tier = math.abs(value), 1
	while scaled >= 1000 and tier < #suffixes do scaled /= 1000; tier += 1 end
	local rounded = tonumber(string.format("%.2f", scaled)) or 0
	if rounded >= 1000 and tier < #suffixes then rounded /= 1000; tier += 1 end
	local text = string.format("%.2f", rounded)
	if not fixedDecimals then text = text:gsub("0+$", ""):gsub("%.$", "") end
	return (if value < 0 and rounded > 0 then "-" else "") .. text .. suffixes[tier]
end

function NumberFormat.Compact(value: number): string
	return format(value, false)
end

-- Currency/income display only; retain cents (and K/M/B/T) without rounding saves.
function NumberFormat.Money(value: number): string
	return format(value, true)
end

-- Debug text input only; the server still validates numeric bounds/integers.
function NumberFormat.Parse(text: string): number?
	if type(text) ~= "string" then return nil end
	local cleaned = text:match("^%s*(.-)%s*$")
	local value = tonumber(cleaned)
	if not value then
		local digits, suffix = cleaned:match("^([%+%-]?%d*%.?%d+)%s*([kKmMbBtT])$")
		if digits then value = tonumber(digits) * multipliers[string.upper(suffix)] end
	end
	if not value or value ~= value or math.abs(value) == math.huge then return nil end
	return value
end

return table.freeze(NumberFormat)
