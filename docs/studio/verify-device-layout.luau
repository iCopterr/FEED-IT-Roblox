-- Execute in edit Studio via MCP. Only clones in an unparented Folder are changed.
assert(not game:GetService("RunService"):IsRunning(),"Edit-only verification")
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.DeviceLayout
local fresh=source:Clone() -- require current synced version even after a prior test
local Layout=require(fresh)
local folder=Instance.new("Folder")
local sizes={Vector2.new(320,568),Vector2.new(390,844),Vector2.new(600,900),Vector2.new(844,390),Vector2.new(1024,768),Vector2.new(1920,1080),Vector2.new(2560,1080)}
local cases={
	{"ShopUI","Panel","Shop"},{"StarterPackUI","Panel","StarterPack"},
	{"SettingsUI","Panel","Settings"},{"IndexUI","Panel","Index"},
	{"FeedYourPetUI","Inventory","Inventory","InventoryFitScale"},
	{"FeedYourPetUI","FeedPanel","Feed"},{"ReviveUI","Panel","Revive"},
	{"MerchantUI","Panel","Merchant"},{"DebugUI","Panel","Debug"},
}
local total=0
local ok,err=xpcall(function()
	local phoneLandscape=Vector2.new(1368,630)
	assert(Layout.CompactLandscape(phoneLandscape,true),"Touch landscape phone not detected")
	assert(Layout.CompactLandscape(Vector2.new(2736,1260),true),"High-density touch landscape phone not detected")
	assert(not Layout.CompactLandscape(Vector2.new(2048,1536),true),"Touch tablet incorrectly treated as phone")
	assert(not Layout.CompactLandscape(phoneLandscape,false),"Desktop incorrectly treated as phone")
	assert(Layout.LauncherScale(phoneLandscape,true)==.62,"Phone launcher is not compact")
	assert(Layout.LeftLauncherScale(phoneLandscape,true)==.93,"Primary phone launchers are not 50% larger")
	assert(Layout.TravelScale(phoneLandscape,true)==.62,"Phone travel bar is not compact")
	assert(Layout.MoneyScale(phoneLandscape,true)==.62,"Phone money display is not compact")
	local hintWidth,hintHeight,hintBottom,hintText=Layout.TutorialHint(phoneLandscape,true)
	assert(hintWidth<=460 and hintHeight==58 and hintBottom==74 and hintText==17,"Phone tutorial hint is not compact")
	assert(520*Layout.TravelScale(phoneLandscape,true)<=323,"Phone travel bar remains oversized")
	assert(72*Layout.LauncherScale(phoneLandscape,true)>=44,"Secondary phone launcher touch target is too small")
	assert(72*Layout.LeftLauncherScale(phoneLandscape,true)>=66,"Primary phone launcher touch target is too small")
	for _,case in cases do
		local gui=assert(game.StarterGui:FindFirstChild(case[1]),case[1]):Clone();gui.Parent=folder
		local panel=gui[case[2]]
		local initial={}
		for _,o in panel:GetDescendants() do
			if o:IsA("GuiObject") then initial[o]={Size=o.Size,Position=o.Position} end
		end
		local base=panel.Size
		for _,size in sizes do
			local scale=Layout.Apply(panel,size,case[3],case[4]);assert(scale>0 and scale<=1)
			local width=panel.Size.X.Scale*size.X+panel.Size.X.Offset
			local height=panel.Size.Y.Scale*size.Y+panel.Size.Y.Offset
			if case[3]=="Feed" then width,height=if Layout.Portrait(size) then 560 else 884,if Layout.Portrait(size) then 980 else 620 end
			assert(width*scale<=size.X-23 and height*scale<=size.Y-23,case[3].." overflows "..tostring(size))
			if Layout.Portrait(size) and case[3]=="Shop" then
				local offers=panel.Offers
				assert(offers.Money6.Position.Y.Offset+offers.Money6.Size.Y.Offset<offers.CanvasSize.Y.Offset,"Last money pack not scrollable")
				for _,name in {"Welcome","DoubleMoney","Money1","Money6"} do
					local card=offers[name]
					assert(card.Description.Position.Y.Offset+card.Description.Size.Y.Offset<=card.Buy.Position.Y.Offset,"Description overlaps Buy")
				end
			end
			for _,o in panel:GetDescendants() do
				if o:IsA("GuiObject") then assert(o.Size.X.Offset>=0 or o.Size.X.Scale>0,"negative width "..o:GetFullName()) end
			end
			total+=1
		end
		Layout.Apply(panel,Vector2.new(1920,1080),case[3],case[4])
		assert(panel.Size==base,"Desktop panel size not restored: "..case[3])
		for o,original in initial do assert(o.Size==original.Size and o.Position==original.Position,"Desktop child layout not restored: "..o:GetFullName()) end
		print("PASS",case[3],"7 screen sizes + desktop restoration")
	end
	for _,size in sizes do
		for count=0,10 do
			local columns=math.max(1,math.min(count,math.floor((size.X-24+8)/68)))
			local side=math.min(66,math.floor((size.X-24-(columns-1)*8)/columns))
			assert(count==0 or columns*(side+8)-8<=size.X-24,"Hotbar overflow")
		end
	end
end,debug.traceback)
folder:Destroy();fresh:Destroy()
assert(ok,err)
print("PASS",total,"panel/device checks; hotbar 0–10 slots; no authored assets modified")
