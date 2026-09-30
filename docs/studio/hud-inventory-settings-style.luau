assert(not game:GetService("RunService"):IsRunning())
local sg=game.StarterGui
local button=sg.FeedYourPetUI.HUD.OpenInventory
local template=sg.IndexUI.Open
-- Preserve the button instance/name so InventoryController bindings remain valid.
for _,child in button:GetChildren() do child:Destroy() end
button.Image="";button.BackgroundTransparency=0;button.BackgroundColor3=template.BackgroundColor3
button.BorderSizePixel=0;button.AutoButtonColor=false
for _,child in template:GetChildren() do
	local copy=child:Clone();copy.Parent=button
end
button.Label.Name="ButtonText"
button.ButtonText.Text="INVENTORY";button.ButtonText.TextSize=22
button.ButtonText.Position=UDim2.fromOffset(4,7);button.ButtonText.Size=UDim2.new(1,-8,1,-14)
button.Icon.Visible=false
button.CanvasGroup.Size=UDim2.fromScale(1,1)
local function fitDecoration(group)
	for _,child in group:GetChildren() do
		if child.Name=="Shine" then child.Size=UDim2.fromScale(.2,1.7)
		elseif child:IsA("ImageLabel") then child.Size=UDim2.fromScale(.85,2) end
	end
end
fitDecoration(button.CanvasGroup)
local settings=sg.SettingsUI.Open
settings.Size=UDim2.fromOffset(72,72)
settings.CanvasGroup.Size=UDim2.fromScale(1,1);fitDecoration(settings.CanvasGroup)
settings.Icon.Image="";settings.Icon.Visible=true;settings.Icon.ScaleType=Enum.ScaleType.Fit
settings.Icon.BackgroundTransparency=1
settings.Icon.Position=UDim2.fromOffset(14,6);settings.Icon.Size=UDim2.fromOffset(44,42)
settings.Icon:SetAttribute("Purpose","Insert your Settings image asset ID here")
settings.Label.Text="SETTING";settings.Label.TextSize=15;settings.Label.TextScaled=false
settings.Label.Position=UDim2.fromOffset(3,48);settings.Label.Size=UDim2.fromOffset(66,21)
return "Inventory matches Index style; Settings is 72px square with blank Icon and bottom SETTING label"
