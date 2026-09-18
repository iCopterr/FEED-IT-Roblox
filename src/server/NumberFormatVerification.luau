-- Read-only checks runnable through Studio MCP in Edit mode.
local Verification = {}
function Verification.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local format = require(game.ReplicatedStorage.Shared.NumberFormat)
	local checks = {}
	local function check(value, name) assert(value, name); table.insert(checks,name) end
	for _, case in {
		{0,"0"},{12,"12"},{12.5,"12.5"},{40.25,"40.25"},{999,"999"},
		{1000,"1K"},{1250,"1.25K"},{999990,"999.99K"},{999999,"1M"},
		{1e6,"1M"},{1.25e6,"1.25M"},{1e9,"1B"},{2.5e9,"2.5B"},
		{1e12,"1T"},{1.25e12,"1.25T"},{1e15,"1000T"},{4e15,"4000T"},
		{-1250,"-1.25K"},{-.001,"0"},{999.999,"1K"},{999999999,"1B"},
		{999999999999,"1T"},{math.huge,"—"},{-math.huge,"—"},{0/0,"—"},
	} do check(format.Compact(case[1])==case[2], "Format "..tostring(case[1]).." -> "..case[2]) end
	for _,case in {{"1K",1000},{" 1.25m ",1250000},{"2B",2e9},{"1000T",1e15},
		{".5K",500},{"1e6",1e6},{"123",123},{"-2k",-2000}} do
		check(format.Parse(case[1])==case[2],"Parse "..case[1])
	end
	for _,value in {"", "oops", "1KK", "1Qa", "1e999", "K", "1M2"} do
		check(format.Parse(value)==nil,"Reject "..value)
	end
	local view = require(game.StarterPlayer.StarterPlayerScripts.Client.UI.FarmSignView)
	local gui={Level={},Rate={},Buy={},Status={}}
	view.Render(gui,{Level=9,Rate=10000,NextRate=30000,Cost=1e15,CanAfford=true},true,true,false)
	check(gui.Rate.Text=="10K FOOD / SEC\nNEXT: 30K FOOD / SEC","Farm current/next rates compact")
	check(gui.Buy.Text=="BUY UPGRADE • 1000T MONEY","Farm price uses T rather than Qa/scientific notation")
	check(gui.Level.Text=="LEVEL 9 / 10","Small levels remain unchanged")
	check(game.StarterGui.DebugUI.Panel.Amount.Text=="1M","Authored debug input defaults to 1M")
	return {passed=true, checks=checks}
end
return table.freeze(Verification)
