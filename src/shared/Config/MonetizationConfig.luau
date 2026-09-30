-- Display quotes only until Developer Products and durable receipt fulfillment exist.
local Config={
	WelcomePack=table.freeze({Robux=9,ProductId=3715613361,OncePerPlayer=true,Hearty=2,Royal=1,Revive=1}),
	DoubleMoney=table.freeze({Robux=249,GamePassId=2003036427,Multiplier=2}), -- Pet income only.
	MoneyPacks=table.freeze({
		table.freeze({Id="pocket",Robux=19,Money=25_000,ProductId=3715613401}),
		table.freeze({Id="pouch",Robux=49,Money=100_000,ProductId=3715613464}),
		table.freeze({Id="bundle",Robux=99,Money=300_000,ProductId=3715613484}),
		table.freeze({Id="chest",Robux=249,Money=1_500_000,ProductId=3715613515}),
		table.freeze({Id="vault",Robux=499,Money=5_000_000,ProductId=3715613549}),
		table.freeze({Id="treasury",Robux=799,Money=10_000_000,ProductId=3715613645}),
	}),
	PersonalRestockRobux=39, PersonalRestockProductId=3715614035,
	DirectReviveRobux=149, DirectReviveProductId=3715614444,
	GrowAllProductId=3715614413,
	FoodProducts=table.freeze({
		fresh=table.freeze({Robux=5,ProductId=3715613696}),
		hearty=table.freeze({Robux=9,ProductId=3715613731}),
		fortified=table.freeze({Robux=15,ProductId=3715613772}),
		gourmet=table.freeze({Robux=25,ProductId=3715613805}),
		enchanted=table.freeze({Robux=39,ProductId=3715613859}),
		royal=table.freeze({Robux=59,ProductId=3715613895}),
		revive=table.freeze({Robux=79,ProductId=3715613933}),
		blessed=table.freeze({Robux=149,ProductId=3715613991}),
	}),
	GrowAllCapRobux=199,
	GrowTiers=table.freeze({
		table.freeze({Seconds=60,Robux=29,ProductId=3715614197}),table.freeze({Seconds=600,Robux=39,ProductId=3715614227}),
		table.freeze({Seconds=1800,Robux=59,ProductId=3715614271}),table.freeze({Seconds=3600,Robux=79,ProductId=3715614304}),
		table.freeze({Seconds=10800,Robux=119,ProductId=3715614348}),table.freeze({Seconds=math.huge,Robux=149,ProductId=3715614380}),
	}),
}
function Config.GrowPrice(seconds)
	if type(seconds)~="number" or seconds~=seconds or seconds<=0 then return 0 end
	for _,tier in Config.GrowTiers do if seconds<=tier.Seconds then return tier.Robux end end
	return 0
end
function Config.GrowAllQuote(eggs,now)
	local count,total=0,0
	for _,egg in eggs do
		if egg.Placed and egg.ReadyAt>now then
			count+=1;total+=Config.GrowPrice(egg.ReadyAt-now)
		end
	end
	return if count>0 then Config.GrowAllCapRobux else 0,count
end
return table.freeze(Config)
