-- Display quotes only until Developer Products and durable receipt fulfillment exist.
local Config={
	WelcomePack=table.freeze({Robux=9,ProductId=0,OncePerPlayer=true,Hearty=2,Royal=1,Revive=1}),
	DoubleMoney=table.freeze({Robux=249,GamePassId=0,Multiplier=2}), -- Pet income only.
	MoneyPacks=table.freeze({
		table.freeze({Id="pocket",Robux=19,Money=25_000,ProductId=0}),
		table.freeze({Id="pouch",Robux=49,Money=100_000,ProductId=0}),
		table.freeze({Id="bundle",Robux=99,Money=300_000,ProductId=0}),
		table.freeze({Id="chest",Robux=249,Money=1_500_000,ProductId=0}),
		table.freeze({Id="vault",Robux=499,Money=5_000_000,ProductId=0}),
		table.freeze({Id="treasury",Robux=799,Money=10_000_000,ProductId=0}),
	}),
	PersonalRestockRobux=39,
	GrowAllCapRobux=199,
	GrowTiers=table.freeze({
		table.freeze({Seconds=60,Robux=29}),table.freeze({Seconds=600,Robux=39}),
		table.freeze({Seconds=1800,Robux=59}),table.freeze({Seconds=3600,Robux=79}),
		table.freeze({Seconds=10800,Robux=119}),table.freeze({Seconds=math.huge,Robux=149}),
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
	return math.min(Config.GrowAllCapRobux,total),count
end
return table.freeze(Config)
