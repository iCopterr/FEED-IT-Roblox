-- Authored decoration copied from the actual teleport template, not runtime UI.
assert(not game:GetService("RunService"):IsRunning())
local panel=game.StarterGui.ShopUI.Panel
local template=game.StarterGui.FeedYourPetUI.HUD.Travel.Base.CanvasGroup
local function apply(target)
	local layer=target:FindFirstChild("TeleportShine")
	for _,child in target:GetChildren() do
		if child.Name=="TeleportShine" and child~=layer then child:Destroy() end
	end
	if not layer then
		layer=Instance.new("CanvasGroup");layer.Name="TeleportShine"
		layer.BackgroundTransparency=1;layer.BorderSizePixel=0;layer.Active=false
		layer.Size=UDim2.fromScale(1,1);layer.ClipsDescendants=true;layer.ZIndex=2
		local corner=target:FindFirstChildOfClass("UICorner")
		if corner then corner:Clone().Parent=layer end
		local i=0
		for _,stripe in template:GetChildren() do
			if stripe.Name=="Shine" and stripe:IsA("Frame") then
				i+=1
				local clone=stripe:Clone();clone.Name="Shine"..i
				clone.Size=UDim2.fromScale(.184,1.7)
				clone.ZIndex=2;clone.Active=false;clone.Parent=layer
			end
		end
		layer.Parent=target
	end
	layer.GroupTransparency=.55 -- Larger banners need softer glare than a small HUD button.
	assert(#layer:GetChildren()>=2)
end
apply(panel.PageHeader)
for _,name in {"Welcome","DoubleMoney","Money1","Money2","Money3","Money4","Money5","Money6"} do
	apply(panel.Offers[name])
end
return "Teleport-style diagonal shine authored on header and eight offers"
