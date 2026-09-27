-- Money consumables shop: Basic is always offered; two personal specials rotate.
local Food = require(script.Parent.FoodConfig)
local Revive = require(script.Parent.ReviveConfig).Shop
local order = table.clone(Food.Order)
table.insert(order, Revive.Id)
local items = {}
for id, food in Food.Types do
	items[id] = table.freeze({DisplayName=food.Name, Icon=food.Icon,
		Effect=if food.GuaranteedSuccess then "100% SUCCESS" else string.format("-%d%% RISK",math.round(food.Reduction*100)),
		Description=if food.GuaranteedSuccess then "1 food • guaranteed success; normal critical chances"
			else string.format("1 food • %d%% less risk",math.round(food.Reduction*100)),
		Price=food.Price, Weight=food.Weight, RewardType="Food", Amount=food.Amount, StockLimit=food.StockLimit})
end
items[Revive.Id] = Revive
local Config = {
	OpenHoldSeconds=.125,
	RestockSeconds=5*60, StockSlots=3, RequestCooldown=.25, PurchaseDistance=14, SaveRetrySeconds=5,
	ItemOrder=table.freeze(order),
	Items=table.freeze(items),
}
function Config.GetRestockId(timestamp) return math.floor(timestamp/Config.RestockSeconds) end
function Config.GetStock(restockId)
	assert(type(restockId)=="number" and restockId%1==0 and restockId>=0,"Invalid restock")
	local rng=Random.new(restockId%2147483647)
	local stock,pool={"basic"},{}
	for _,id in Config.ItemOrder do if id~="basic" then table.insert(pool,id) end end
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
