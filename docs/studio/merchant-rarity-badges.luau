assert(not game:GetService("RunService"):IsRunning(),"Edit mode only")
local panel=game.StarterGui.MerchantUI.Panel
for i=1,3 do
	local row=panel.Offers["Slot"..i]
	row.Effect.BackgroundTransparency=1
	row.Effect.TextXAlignment=Enum.TextXAlignment.Left
	row.Effect.Position=UDim2.fromOffset(102,42)
	row.Effect.Size=UDim2.new(1,-116,0,24)
	row.Effect.TextSize=18
	for _,s in row.Effect:GetChildren() do
		if s:IsA("UIStroke") and s.ApplyStrokeMode==Enum.ApplyStrokeMode.Border then s.Enabled=false end
	end
	row.Stock.Position=UDim2.fromOffset(102,73)
	row.Stock.Size=UDim2.new(1,-286,0,24)
	row.Stock.Text="X0 stock";row.Stock.TextSize=18
	local badge=row:FindFirstChild("RarityBadge")
	for _,child in row:GetChildren() do if child.Name=="RarityBadge" and child~=badge then child:Destroy() end end
	if not badge then badge=row.BuyRobux:Clone();badge.Name="RarityBadge";badge.Parent=row end
	badge.AnchorPoint=Vector2.new(1,0)
	badge.Position=UDim2.new(1,-14,0,70);badge.Size=UDim2.fromOffset(152,28)
	badge.Active=false;badge.AutoButtonColor=false;badge.Selectable=false
	badge.ImageColor3=Color3.fromRGB(135,151,168);badge.BackgroundColor3=badge.ImageColor3
	for _,child in badge:GetChildren() do
		if child:IsA("UIGradient") then child.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(200,200,200)) end
	end
	badge.ButtonText.Text="Common";badge.ButtonText.TextSize=18
	local limit=badge.ButtonText:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then limit.MinTextSize=12;limit.MaxTextSize=18 end
	badge.MotionScale.Scale=1
end
return "Risk text aligned with name, no background; stock simplified; teleport-style rarity badges authored"
