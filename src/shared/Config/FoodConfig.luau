-- One serving per Feed. Reductions multiply the plate-adjusted risk.
local Config = {
	ServingsPerFeed = 1,
	Order = table.freeze({"basic", "fresh", "hearty", "fortified", "gourmet", "enchanted", "royal"}),
	Types = table.freeze({
		basic = table.freeze({Name="Basic Food", Reduction=0, Price=100, Amount=5, Weight=0, StockLimit=5}),
		fresh = table.freeze({Name="Fresh Food", Reduction=.08, Price=600, Amount=5, Weight=80, StockLimit=1}),
		hearty = table.freeze({Name="Hearty Food", Reduction=.15, Price=2500, Amount=5, Weight=60, StockLimit=1}),
		fortified = table.freeze({Name="Fortified Food", Reduction=.22, Price=8000, Amount=4, Weight=45, StockLimit=1}),
		gourmet = table.freeze({Name="Gourmet Food", Reduction=.30, Price=25000, Amount=3, Weight=30, StockLimit=1}),
		enchanted = table.freeze({Name="Enchanted Food", Reduction=.38, Price=90000, Amount=2, Weight=18, StockLimit=1}),
		royal = table.freeze({Name="Royal Food", Reduction=.45, Price=250000, Amount=2, Weight=10, StockLimit=1}),
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
