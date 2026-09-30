-- Display quotes only until Developer Products and durable receipt fulfillment exist.
local Config={
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
