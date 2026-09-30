assert(not game:GetService("RunService"):IsRunning())
local sg=game.StarterGui
local index=sg.IndexUI.Open
local inventory=sg.FeedYourPetUI.HUD.OpenInventory
for _,button in {index,inventory} do
	button.Size=UDim2.fromOffset(72,72)
	button.CanvasGroup.Size=UDim2.fromScale(1,1)
	for _,o in button.CanvasGroup:GetChildren() do
		if o.Name=="Shine" then o.Size=UDim2.fromScale(.2,1.7) end
	end
	button.Icon.Visible=true;button.Icon.ScaleType=Enum.ScaleType.Fit
	button.Icon.Position=UDim2.fromOffset(14,6);button.Icon.Size=UDim2.fromOffset(44,42)
	local label=button:FindFirstChild("Label") or button.ButtonText
	label.TextScaled=false;label.TextSize=if button==index then 15 else 12
	label.Position=UDim2.fromOffset(3,48);label.Size=UDim2.fromOffset(66,21)
	label.TextXAlignment=Enum.TextXAlignment.Center
end
-- Reuse the existing uploaded pet inventory icon.
inventory.Icon.Image="rbxassetid://108650929244773"
index.Position=UDim2.new(0,18,.5,0)
inventory.AnchorPoint=index.AnchorPoint
inventory.Position=UDim2.new(0,102,.5,0)
local top=index.AbsolutePosition-sg.FeedYourPetUI.HUD.AbsolutePosition
inventory.Position=UDim2.fromOffset(top.X+index.AbsoluteSize.X+12,top.Y+index.AbsoluteSize.Y*inventory.AnchorPoint.Y)
return "Index and Inventory 72x72 side by side, equal Y, 12px gap"
