-- One serving per Feed. Reductions multiply the plate-adjusted risk.
local Config = {
	ServingsPerFeed = 1,
	Order = table.freeze({"basic", "hearty", "gourmet", "royal"}),
	Types = table.freeze({
		basic = table.freeze({Name="Basic Food", Reduction=0, Price=100, Amount=5, Weight=0}),
		hearty = table.freeze({Name="Hearty Food", Reduction=.15, Price=2500, Amount=5, Weight=60}),
		gourmet = table.freeze({Name="Gourmet Food", Reduction=.30, Price=25000, Amount=3, Weight=30}),
		royal = table.freeze({Name="Royal Food", Reduction=.45, Price=250000, Amount=2, Weight=10}),
	}),
}

function Config.Count(data, id)
	return if id == "basic" then data.Food else data.Foods[id] or 0
end

function Config.Add(data, id, amount)
	if id == "basic" then data.Food += amount else data.Foods[id] = (data.Foods[id] or 0) + amount end
end

function Config.Total(data)
	local total = data.Food
	for _, amount in data.Foods do total += amount end
	return total
end

function Config.Inventory(data)
	local result = {}
	for _, id in Config.Order do result[id] = Config.Count(data,id) end
	return result
end

return table.freeze(Config)
