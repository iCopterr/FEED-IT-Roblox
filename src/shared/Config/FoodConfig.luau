-- One serving per purchase and Feed. Reductions multiply the base explosion risk.
local Config = {
	ServingsPerFeed = 1,
	Order = table.freeze({"basic", "fresh", "hearty", "fortified", "gourmet", "enchanted", "royal", "blessed"}),
	Types = table.freeze({
		basic = table.freeze({Rarity="Common", Name="Basic Food", Icon="🍗", Reduction=0, Price=100, Amount=1, Weight=0, StockLimit=5}),
		fresh = table.freeze({Rarity="Uncommon", Name="Fresh Food", Icon="🍎", Reduction=.08, Price=600, Amount=1, Weight=80, StockLimit=1}),
		hearty = table.freeze({Rarity="Rare", Name="Hearty Food", Icon="🥩", Reduction=.15, Price=2500, Amount=1, Weight=60, StockLimit=1}),
		fortified = table.freeze({Rarity="Epic", Name="Fortified Food", Icon="🥘", Reduction=.22, Price=8000, Amount=1, Weight=45, StockLimit=1}),
		gourmet = table.freeze({Rarity="Legendary", Name="Gourmet Food", Icon="🍱", Reduction=.30, Price=25000, Amount=1, Weight=30, StockLimit=1}),
		enchanted = table.freeze({Rarity="Mythic", Name="Enchanted Food", Icon="🔮", Reduction=.38, Price=90000, Amount=1, Weight=18, StockLimit=1}),
		royal = table.freeze({Rarity="Fabled", Name="Royal Food", Icon="🍰", Reduction=.45, Price=250000, Amount=1, Weight=10, StockLimit=1}),
		blessed = table.freeze({Rarity="Celestial", Name="Blessed Food", Icon="✨", Reduction=1, GuaranteedSuccess=true, Price=10000000, Amount=1, Weight=.25, StockLimit=1}),
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
