assert(not game:GetService("RunService"):IsRunning(),"Edit mode only")
local panel=game.StarterGui.MerchantUI.Panel
local travel=game.StarterGui.FeedYourPetUI.HUD.Travel
for i=1,3 do
	local row=panel.Offers["Slot"..i]
	row.Size=UDim2.new(1,-12,0,164)
	row.Active=false;row.AutoButtonColor=false;row.Selectable=false
	row:SetAttribute("SuppressClickSound",true)
	row.ItemName.Position=UDim2.fromOffset(102,8);row.ItemName.Size=UDim2.new(1,-116,0,32)
	row.Stock.Position=UDim2.fromOffset(102,42);row.Stock.Size=UDim2.new(1,-116,0,24)
	row.Effect.Position=UDim2.fromOffset(102,72);row.Effect.Size=UDim2.new(1,-116,0,26)
	row.Price.Visible=false
	for _,spec in {{"BuyMoney","Base",.25,"$—"},{"BuyRobux","Merchant",.75,"ROBUX • SOON"}} do
		local button=row:FindFirstChild(spec[1])
		-- Rojo can temporarily merge a newly exported child with its unmanaged
		-- Studio original. Keep exactly one purchase control of each kind.
		for _,child in row:GetChildren() do
			if child.Name==spec[1] and child~=button then child:Destroy() end
		end
		if not button then button=travel[spec[2]]:Clone();button.Name=spec[1];button.Parent=row end
		-- Teleport art has a second text shadow and fixed-size decoration group.
		-- Keep its visual style, not the baked destination name or original bounds.
		local keptScale
		for _,child in button:GetChildren() do
			if child:IsA("UIScale") and child.Name=="MotionScale" then
				if keptScale then child:Destroy() else keptScale=child end
			end
		end
		for _,child in button:GetDescendants() do
			if child:IsA("TextLabel") and child.Name=="ButtonTextShadow" then child.Visible=false end
			if child:IsA("CanvasGroup") then child.Size=UDim2.fromScale(1,1) end
			if child:IsA("Frame") and child.Name=="Shine" then child.Size=UDim2.fromScale(.184,1.7) end
			if child:IsA("ImageLabel") and child.Name=="ImageLabel" then child.Size=UDim2.fromScale(.772,1.907) end
		end
		button.AnchorPoint=Vector2.new(.5,.5)
		button.Position=UDim2.new(spec[3],if spec[1]=="BuyMoney" then 3 else -3,1,-32)
		button.Size=UDim2.new(.5,-22,0,42)
		button.ButtonText.Text=spec[4];button.ButtonText.TextSize=22
		button.ButtonText.TextScaled=true
		local constraint=button.ButtonText:FindFirstChildOfClass("UITextSizeConstraint")
		if not constraint then constraint=Instance.new("UITextSizeConstraint");constraint.Parent=button.ButtonText end
		constraint.MinTextSize=12;constraint.MaxTextSize=22
		button.ZIndex=row.ZIndex+3;button.ButtonText.ZIndex=button.ZIndex+1
		button.MotionScale.Scale=1;button.Selectable=false
		button:SetAttribute("SuppressClickSound",true)
		if spec[1]=="BuyRobux" then button.Active=false;button.AutoButtonColor=false end
	end
end
panel.Offers.AutomaticCanvasSize=Enum.AutomaticSize.Y
return "Three authored rows now have Money/Robux buttons cloned from teleport style; Robux disabled pending product setup"
