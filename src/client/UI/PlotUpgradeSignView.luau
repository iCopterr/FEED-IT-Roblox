local Config = require(game.ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local Number = require(game.ReplicatedStorage.Shared.NumberFormat).Compact
local View = {Number=Number}
function View.Render(gui, state, owner, near, busy, message)
 gui.Level.Text=if state.Level then string.format("%d / %d PET SLOTS",state.Level,Config.MaxSlots) else "PLOT EXPANSION"
 gui.Rate.Text=if state.NextSlots then string.format("%d → %d ACTIVE PETS",state.Level,state.NextSlots)
  else if state.MaxLevel then "FULL CAPACITY UNLOCKED" else "Claim this plot to unlock more pet slots"
 local available=owner and near and state.Level~=nil and not state.MaxLevel and state.CanAfford and not state.Saving and not busy
 gui.Buy.Active=available==true
 gui.Buy.AutoButtonColor=available==true
 gui.Buy.Selectable=false
 gui.Buy.BackgroundColor3=if available then Color3.fromRGB(114,202,100) else Color3.fromRGB(139,148,138)
 gui.Buy.Text=if state.Saving then "SAVING…" else if state.MaxLevel then "MAX CAPACITY"
  else if state.Cost then "+1 SLOT • $"..Number(state.Cost) else "UNAVAILABLE"
 gui.Status.Text=message or (if not owner then "Only this plot's owner can upgrade"
  else if state.Saving then "Waiting for save confirmation…"
  else if not near then "Move closer to buy an upgrade"
  else if busy then "Close menus / wait for Feed to finish"
  else if state.Cost and not state.CanAfford then "Not enough Money — let your pets earn!"
  else "Keep one more companion in your pen")
 return available==true
end
return table.freeze(View)
