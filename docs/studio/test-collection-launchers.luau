-- Edit-mode real-instance alignment regression. Does not edit authored assets.
assert(not game:GetService("RunService"):IsRunning())
local source=game.StarterPlayer.StarterPlayerScripts.Client.UI.CollectionLaunchers
local factory=assert(loadstring(source.Source))
setfenv(factory,setmetatable({script=source},{__index=getfenv()}))
local Collection=factory()
local screen=Instance.new("ScreenGui");screen.Name="CollectionAlignmentTest";screen.Parent=game.StarterGui
local canvas=Instance.new("Frame");canvas.Parent=screen
local hud=Instance.new("Frame");hud.BackgroundTransparency=1;hud.Size=UDim2.fromScale(1,1);hud.Position=UDim2.fromOffset(0,10);hud.Parent=canvas
local index=game.StarterGui.IndexUI.Open:Clone();index.Parent=canvas
local inventory=game.StarterGui.FeedYourPetUI.HUD.OpenInventory:Clone();inventory.Parent=hud
local shop=game.StarterGui.ShopUI.Open:Clone();shop.Parent=canvas
for _,button in {index,inventory,shop} do
	local extra=button:FindFirstChild("MotionScale");if extra then extra:Destroy() end
end
local cleanup=Collection.Bind(index,inventory,shop,canvas)
local ok,err=xpcall(function()
	local function check()
		task.wait(.15)
		local left=index.AbsolutePosition
		local right=inventory.AbsolutePosition+inventory.AbsoluteSize
		local rowCenter=(left.X+right.X)/2
		assert(math.abs(shop.AbsolutePosition.X+shop.AbsoluteSize.X/2-rowCenter)<1,"Shop not centered above pair")
		assert(math.abs(index.AbsolutePosition.Y+index.AbsoluteSize.Y/2-inventory.AbsolutePosition.Y-inventory.AbsoluteSize.Y/2)<1,"Index/Inventory vertical centers differ")
		assert(inventory.AbsolutePosition.X>=left.X+index.AbsoluteSize.X+7,"Row gap disappeared")
	end
	for _,size in {Vector2.new(390,844),Vector2.new(568,320),Vector2.new(844,390),Vector2.new(1368,630),Vector2.new(1920,1080)} do
		canvas.Size=UDim2.fromOffset(size.X,size.Y)
		index.Position=UDim2.new(0,24,.5,0)
		for _,scale in {.7,1,.96,1.025} do
			index.UIScale.Scale=scale;inventory.UIScale.Scale=scale;shop.UIScale.Scale=scale;check()
		end
		inventory.UIScale.Scale=.72;shop.UIScale.Scale=.68;check()
		hud.Position=UDim2.fromOffset(13,27);check()
	end
end,debug.traceback)
cleanup();screen:Destroy();assert(ok,err)
return "PASS: five viewports, scale/hover changes, unequal button sizes and cross-parent offsets retain aligned centers and gap"
