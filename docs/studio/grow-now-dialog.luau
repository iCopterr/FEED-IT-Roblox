assert(not game:GetService("RunService"):IsRunning())
local gui=game.StarterGui.PenManagerUI
local panel=gui:FindFirstChild("GrowNow")
for _,child in gui:GetChildren() do if child.Name=="GrowNow" and child~=panel then child:Destroy() end end
if not panel then
	panel=game.StarterGui.MerchantUI.Panel:Clone();panel.Name="GrowNow"
	for _,child in panel:GetChildren() do
		if child:IsA("GuiObject") and not table.find({"PageTexture","PageHeader","Title","Close"},child.Name) then child:Destroy() end
	end
	local summary=panel.Title:Clone();summary.Name="Summary";summary.Parent=panel
	local buy=game.StarterGui.MerchantUI.Panel.Offers.Slot1.BuyRobux:Clone();buy.Name="Buy";buy.Parent=panel
	panel.Parent=gui
end
panel.Size=UDim2.fromOffset(540,240);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
panel.Visible=false;panel.ZIndex=80;panel.Title.Text="GROW NOW"
for _,o in panel:GetDescendants() do if o:IsA("GuiObject") then o.ZIndex=81 end end
panel.Summary.Position=UDim2.fromOffset(20,80);panel.Summary.Size=UDim2.new(1,-40,0,66)
panel.Summary.Text="Finish your egg's hatch time";panel.Summary.TextSize=23;panel.Summary.TextWrapped=true
panel.Buy.AnchorPoint=Vector2.zero;panel.Buy.Position=UDim2.fromOffset(20,166);panel.Buy.Size=UDim2.new(1,-40,0,48)
panel.Buy.Active=false;panel.Buy.AutoButtonColor=false;panel.Buy.ButtonText.Text="GROW NOW • SOON"
panel.Buy.ButtonText.ZIndex=83;panel.Title.ZIndex=83;panel.Close.ZIndex=83;panel.Summary.ZIndex=83
return "Authored disabled Grow Now dialog"
