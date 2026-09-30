local Config = require(game.ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local Number = require(game.ReplicatedStorage.Shared.NumberFormat).Money
local View = {Number=Number}
function View.Render(gui, state, owner, near, busy, message)
 gui.Title.Text="UPGRADE PEN"
 gui.Level.Text=if state.NextSlots then string.format("LEVEL %d → LEVEL %d",state.Level,state.NextSlots)
  else if state.MaxLevel and state.Level then string.format("LEVEL %d • MAX",state.Level) else "LEVEL —"
 gui.Rate.Text="";gui.Rate.Visible=false
 local available=owner and near and state.Level~=nil and not state.MaxLevel and state.CanAfford and not state.Saving and not busy
 gui.Buy.Active=available==true
 gui.Buy.AutoButtonColor=available==true
 gui.Buy.Selectable=false
 gui.Buy.BackgroundColor3=if available then Color3.fromRGB(114,202,100) else Color3.fromRGB(139,148,138)
 gui.Buy.Text=if state.Saving then "SAVING…" else if state.MaxLevel then "MAX LEVEL"
  else if state.Cost then "BUY • $"..Number(state.Cost) else "UNAVAILABLE"
 gui.Status.Text="";gui.Status.Visible=false
 return available==true
end
return table.freeze(View)
