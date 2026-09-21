-- Prototype mystery merchant. All values are iteration-friendly, not final balance.
local Config = {
	RestockSeconds = 30 * 60,
	StockSlots = 3,
	RequestCooldown = .25,
	PurchaseDistance = 14,
	SaveRetrySeconds = 5,
	FarmDropInterval = 60,
	FarmDropChance = .10,
	FarmDropAmount = 1,
	TokenCap = 9999,
	ItemOrder = table.freeze({"food_pouch","food_crate","food_vault","guardian_charm"}),
	Items = table.freeze({
		food_pouch = table.freeze({DisplayName="Food Pouch",Description="+500 Food",Price=1,Weight=40,RewardType="Food",Amount=500}),
		food_crate = table.freeze({DisplayName="Food Crate",Description="+5K Food",Price=3,Weight=30,RewardType="Food",Amount=5000}),
		food_vault = table.freeze({DisplayName="Food Vault",Description="+25K Food",Price=7,Weight=20,RewardType="Food",Amount=25000}),
		guardian_charm = table.freeze({DisplayName="Guardian Charm",Description="+1 Protection Token",Price=5,Weight=10,RewardType="Protection",Amount=1}),
	}),
}

function Config.GetRestockId(timestamp: number): number
	return math.floor(timestamp / Config.RestockSeconds)
end

function Config.GetStock(restockId: number): {string}
	assert(type(restockId)=="number" and restockId%1==0 and restockId>=0,"Invalid restock")
	local random=Random.new(restockId % 2147483647)
	local pool=table.clone(Config.ItemOrder)
	local stock={}
	for _=1,math.min(Config.StockSlots,#pool) do
		local total=0
		for _,id in pool do total+=Config.Items[id].Weight end
		local roll=random:NextNumber()*total
		local cursor,index=0,1
		for i,id in pool do cursor+=Config.Items[id].Weight;if roll<cursor then index=i;break end end
		table.insert(stock,table.remove(pool,index))
	end
	return stock
end

return table.freeze(Config)
