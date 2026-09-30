-- Edit-time only. Keep purchase controls and controller paths intact.
assert(not game:GetService("RunService"):IsRunning())
local p=game.StarterGui.ShopUI.Panel
local list=p.Offers
p.Size=UDim2.fromOffset(880,620)
p.PageHeader.ImageColor3=Color3.fromRGB(108,255,65)
p.PageHeader.BackgroundColor3=Color3.fromRGB(80,222,40)
p.Title.Text="SHOP";p.Title.TextSize=40
list.Position=UDim2.fromOffset(18,84);list.Size=UDim2.new(1,-36,1,-102)
list.Active=true;list.ScrollingEnabled=true;list.ClipsDescendants=true
list.ScrollBarThickness=7;list.ScrollBarImageColor3=Color3.fromRGB(146,229,97)
list.CanvasSize=UDim2.fromOffset(0,1080);list.CanvasPosition=Vector2.zero
local function section(name,text,y,color)
	local label=list:FindFirstChild(name)
	if not label then label=p.Title:Clone();label.Name=name;label.Parent=list end
	label.Position=UDim2.fromOffset(8,y);label.Size=UDim2.fromOffset(816,46)
	label.Text=text;label.TextSize=32;label.TextColor3=color;label.TextXAlignment=Enum.TextXAlignment.Center
end
section("FeaturedHeading","— FEATURED —",4,Color3.fromRGB(255,225,60))
section("PassesHeading","— PASSES —",294,Color3.fromRGB(255,225,60))
section("MoneyHeading","— MONEY —",536,Color3.fromRGB(110,255,80))
local function art(card,pos,size)
	local image=card:FindFirstChild("Artwork")
	if not image then image=Instance.new("ImageLabel");image.Name="Artwork";image.Parent=card end
	image.Image="";image.BackgroundTransparency=1;image.Position=pos;image.Size=size
	image.ScaleType=Enum.ScaleType.Fit;image.ZIndex=3
	image:SetAttribute("Purpose","Reserved artwork: set Image to an uploaded asset ID")
end
local function style(card,color)
	card.BackgroundColor3=color
	local gradient=card:FindFirstChild("OfferGradient") or Instance.new("UIGradient")
	gradient.Name="OfferGradient";gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(155,178,158))
	gradient.Rotation=25;gradient.Parent=card
	card.Buy.BackgroundColor3=Color3.fromRGB(85,240,32)
	for _,o in card.Buy:GetDescendants() do
		if o:IsA("UIGradient") then o.Color=ColorSequence.new(Color3.fromRGB(164,255,63),Color3.fromRGB(40,202,16)) end
	end
	card.Buy.Active=false;card.Buy.ButtonText.TextSize=24
end
local w=list.Welcome
w.Position=UDim2.fromOffset(8,58);w.Size=UDim2.fromOffset(816,220)
style(w,Color3.fromRGB(163,73,238))
w.Title.Position=UDim2.fromOffset(284,20);w.Title.Size=UDim2.fromOffset(516,44);w.Title.TextSize=30
w.Description.Position=UDim2.fromOffset(284,74);w.Description.Size=UDim2.fromOffset(516,64)
w.Description.Text="2 Hearty • 1 Royal • 1 Revive Charm\nOnce per player"
w.Buy.Position=UDim2.fromOffset(498,154);w.Buy.Size=UDim2.fromOffset(300,48)
art(w,UDim2.fromOffset(18,18),UDim2.fromOffset(250,184))
local d=list.DoubleMoney
d.Position=UDim2.fromOffset(8,348);d.Size=UDim2.fromOffset(816,172)
style(d,Color3.fromRGB(255,210,61))
d.Title.Position=UDim2.fromOffset(200,20);d.Title.Size=UDim2.fromOffset(340,48);d.Title.TextSize=36
d.Description.Position=UDim2.fromOffset(200,76);d.Description.Size=UDim2.fromOffset(340,70)
d.Description.Text="Double pet income\nPermanent"
d.Buy.Position=UDim2.fromOffset(554,66);d.Buy.Size=UDim2.fromOffset(244,56)
art(d,UDim2.fromOffset(18,14),UDim2.fromOffset(164,144))
for i=1,6 do
	local c=list["Money"..i]
	c.Position=UDim2.fromOffset(8+((i-1)%3)*276,590+math.floor((i-1)/3)*240)
	c.Size=UDim2.fromOffset(264,224);style(c,Color3.fromRGB(90,231,76))
	c.Title.Position=UDim2.fromOffset(12,12);c.Title.Size=UDim2.fromOffset(240,40);c.Title.TextSize=32
	c.Description.Visible=false
	c.Buy.Position=UDim2.fromOffset(12,166);c.Buy.Size=UDim2.fromOffset(240,44)
	c.Buy.ButtonText.TextSize=22
	art(c,UDim2.fromOffset(20,58),UDim2.fromOffset(224,100))
end
p.Visible=false
return "Shop redesigned: pinned green header, three sections, 3x2 money grid and blank Artwork slots"
