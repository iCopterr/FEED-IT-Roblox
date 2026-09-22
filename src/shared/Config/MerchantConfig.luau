-- Money food shop: Basic is always available; two personal offers per restock.
local Food = require(script.Parent.FoodConfig)
local items = {}
for id, food in Food.Types do
	items[id] = table.freeze({DisplayName=food.Name, Description=string.format("%d servings • %d%% less risk",food.Amount,math.round(food.Reduction*100)),
		Price=food.Price, Weight=food.Weight, RewardType="Food", Amount=food.Amount})
end
local Config = {
	RestockSeconds=30*60, StockSlots=3, RequestCooldown=.25, PurchaseDistance=14, SaveRetrySeconds=5,
	-- Deprecated schema-only cap; Tokens are not granted or spent.
	TokenCap=9999,
	ItemOrder=table.freeze({"basic","hearty","gourmet","royal"}),
	Items=table.freeze(items),
}
function Config.GetRestockId(timestamp) return math.floor(timestamp/Config.RestockSeconds) end
function Config.GetStock(restockId)
	assert(type(restockId)=="number" and restockId%1==0 and restockId>=0,"Invalid restock")
	local rng=Random.new(restockId%2147483647)
	local stock,pool={"basic"},{"hearty","gourmet","royal"}
	for _=2,Config.StockSlots do
		local total=0
		for _,id in pool do total+=items[id].Weight end
		local roll,cursor,index=rng:NextNumber()*total,0,1
		for i,id in pool do cursor+=items[id].Weight;if roll<cursor then index=i;break end end
		table.insert(stock,table.remove(pool,index))
	end
	return stock
end
return table.freeze(Config)
