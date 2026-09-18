local Config = require(game.ReplicatedStorage.Shared.Config.FarmConfig)
local View = {}
function View.Number(value)
	for _,unit in {{1e15,"Qa"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}} do
		if value>=unit[1] then return string.format("%.3g%s",value/unit[1],unit[2]) end
	end
	return string.format("%g",value)
end
function View.Render(gui, state, owner, near, busy, message)
	gui.Level.Text=if state.Level then string.format("LEVEL %d / %d",state.Level,#Config.FoodPerSecond) else "AVAILABLE FARM"
	gui.Rate.Text=if state.Rate then View.Number(state.Rate).." FOOD / SEC"
		..(if state.NextRate then "\nNEXT: "..View.Number(state.NextRate).." FOOD / SEC" else "\nMAXIMUM PRODUCTION") else "Claim this plot to start farming"
	local available=owner and near and state.Level~=nil and not state.MaxLevel and state.CanAfford and not state.Saving and not busy
	gui.Buy.Active=available==true
	gui.Buy.AutoButtonColor=available==true
	gui.Buy.Selectable=available==true
	gui.Buy.BackgroundColor3=if available then Color3.fromRGB(128,222,100) else Color3.fromRGB(139,148,137)
	gui.Buy.Text=if state.Saving then "SAVING…" else if state.MaxLevel then "MAX LEVEL"
		else if state.Cost then "BUY UPGRADE • "..View.Number(state.Cost).." MONEY" else "UNAVAILABLE"
	gui.Status.Text=message or (if not owner then "Only this plot's owner can upgrade"
		else if state.Saving then "Waiting for save confirmation…"
		else if not near then "Move closer to buy an upgrade"
		else if state.Cost and not state.CanAfford then "Not enough Money — let your pets earn!"
		else "Food is produced only while farming")
	return available==true
end
return table.freeze(View)
