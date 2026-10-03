assert(not game:GetService("RunService"):IsRunning())
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.DeviceLayout:Clone()
local Layout=require(source)
local count=0
for _,entry in {{"ShopUI","Panel","Shop"},{"IndexUI","Panel","Index"},{"SettingsUI","Panel","Settings"},
	{"FeedYourPetUI","Inventory","Inventory","InventoryFitScale"},{"FeedYourPetUI","FeedPanel","Feed"},
	{"MerchantUI","Panel","Merchant"},{"StarterPackUI","Panel","StarterPack"},{"DebugUI","Panel","Debug"},{"ReviveUI","Panel","Revive"}} do
	local gui=game.StarterGui[entry[1]]:Clone();local panel=gui[entry[2]];local home=panel.Position
	if entry[3]=="Revive" then
		local view=game.StarterPlayer.StarterPlayerScripts.Client.UI.ReviveView:Clone()
		require(view).Build(panel);view:Destroy()
	end
	for _,size in {Vector2.new(568,320),Vector2.new(844,390),Vector2.new(1368,630),Vector2.new(390,844)}do
		local scale=Layout.Apply(panel,size,entry[3],entry[4],true)
		local height=if entry[3]=="Feed" and Layout.Portrait(size)then 980 else panel.Size.Y.Offset
		local center=size.Y/2-Layout.MenuLift(size,true)
		assert(center-height*scale/2>=11.9 and center+height*scale/2<=size.Y-12,"Menu clipped: "..entry[3])
		assert(panel.Position.Y.Offset<home.Y.Offset,"Menu was not raised")
		local first=panel.Position;Layout.Apply(panel,size,entry[3],entry[4],true)
		assert(panel.Position==first,"Repeated resize accumulates vertical drift")
		count+=1
	end
	Layout.Apply(panel,Vector2.new(1920,1080),entry[3],entry[4],false)
	assert(panel.Position.Y==home.Y,"Desktop position not restored")
	gui:Destroy()
end
source:Destroy()
return "PASS: "..count.." mobile menu positions stay higher and in bounds; repeat resize and desktop restore"
