local Config = require(game.ReplicatedStorage.Shared.Config.FeedPlateConfig)
local Number = require(game.ReplicatedStorage.Shared.NumberFormat).Compact
local View = {Number=Number}
function View.Render(gui, state, owner, near, busy, message)
	gui.Level.Text=if state.Level then string.format("LEVEL %d / %d",state.Level,#Config.RiskReduction) else "AVAILABLE FEED PLATE"
	gui.Rate.Text=if state.Reduction then Number(state.Reduction*100).."% LESS EXPLOSION RISK"
		..(if state.NextReduction then "\nNEXT: "..Number(state.NextReduction*100).."% LESS RISK" else "\nMAXIMUM REDUCTION")
		else "Claim this plot to upgrade your plate"
	local available=owner and near and state.Level~=nil and not state.MaxLevel and state.CanAfford and not state.Saving and not busy
	gui.Buy.Active=available==true
	gui.Buy.AutoButtonColor=available==true
	gui.Buy.Selectable=available==true
	gui.Buy.BackgroundColor3=if available then Color3.fromRGB(174,134,230) else Color3.fromRGB(139,138,148)
	gui.Buy.Text=if state.Saving then "SAVING…" else if state.MaxLevel then "MAX LEVEL"
		else if state.Cost then "BUY UPGRADE • "..Number(state.Cost).." MONEY" else "UNAVAILABLE"
	gui.Status.Text=message or (if not owner then "Only this plot's owner can upgrade"
		else if state.Saving then "Waiting for save confirmation…"
		else if not near then "Move closer to buy an upgrade"
		else if busy then "Close menus / wait for Feed to finish"
		else if state.Cost and not state.CanAfford then "Not enough Money — let your pets earn!"
		else "Multiplies base risk; never guarantees survival")
	return available==true
end
return table.freeze(View)
