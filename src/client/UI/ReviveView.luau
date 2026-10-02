local View={}
local function rect(object,x,y,w,h)
	object.AnchorPoint=Vector2.zero
	object.Position=UDim2.fromOffset(x,y);object.Size=UDim2.fromOffset(w,h)
end
local function rounded(object,radius)
	local corner=object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",object)
	corner.CornerRadius=UDim.new(0,radius)
end
function View.Build(panel)
	panel.Title.Text="PET REPAIR STATION"
	rounded(panel,16);panel.ClipsDescendants=true
	panel.Title.Size=UDim2.fromOffset(350,48)
	panel.Pets.ScrollingDirection=Enum.ScrollingDirection.Y
	-- ScreenGui uses sibling stacking: raise the list above PageTexture too,
	-- not just its cards, so background art cannot cover the list's subtree.
	panel.Pets.ZIndex=3
	panel.Pets.AutomaticCanvasSize=Enum.AutomaticSize.Y
	panel.Pets.ScrollBarThickness=5
	local padding=panel.Pets:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding",panel.Pets)
	padding.PaddingTop=UDim.new(0,8);padding.PaddingBottom=UDim.new(0,8)
	padding.PaddingLeft=UDim.new(0,8);padding.PaddingRight=UDim.new(0,12)
	panel.Pets.PetTemplate.Size=UDim2.new(1,-4,0,98)
	panel.Pets.PetTemplate.TextWrapped=true;panel.Pets.PetTemplate.TextSize=19
	rounded(panel.Pets.PetTemplate,10)
	local brokenTab=panel.Revive:Clone()
	brokenTab.Name="BrokenTab";brokenTab.Text="BROKEN PETS";rect(brokenTab,370,16,162,36)
	brokenTab.ZIndex=7;rounded(brokenTab,8);brokenTab.Parent=panel
	local exchangeTab=panel.Revive:Clone()
	exchangeTab.Name="ExchangeTab";exchangeTab.Text="SHARD EXCHANGE";rect(exchangeTab,540,16,180,36)
	exchangeTab.ZIndex=7;rounded(exchangeTab,8);exchangeTab.Parent=panel
	local exchange=panel.Pets:Clone()
	exchange.Name="ExchangePanel";rect(exchange,16,84,768,376)
	exchange.Visible=false;exchange.ScrollingEnabled=false;exchange.ScrollBarThickness=0
	exchange.AutomaticCanvasSize=Enum.AutomaticSize.None;exchange.CanvasSize=UDim2.fromOffset(0,0)
	for _,child in exchange:GetChildren() do
		if child:IsA("GuiObject") or child:IsA("UIGridStyleLayout") or child:IsA("UIPadding") then child:Destroy() end
	end
	rounded(exchange,12);exchange.Parent=panel
	local function label(template,name,text,x,y,w,h,size)
		local object=template:Clone();object.Name=name;object.Text=text
		rect(object,x,y,w,h);object.TextSize=size;object.TextXAlignment=Enum.TextXAlignment.Center
		object.TextYAlignment=Enum.TextYAlignment.Center;object.TextWrapped=true;object.ZIndex=5
		object.Parent=exchange;return object
	end
	label(panel.PetName,"ShardTitle","REPAIR SHARDS",24,12,720,40,30)
	local shard=panel.Robux.ProductIcon:Clone()
	shard.Name="ShardIcon";shard.Image="rbxassetid://82838242551952";rect(shard,202,66,132,132)
	shard.BackgroundTransparency=1;shard.ScaleType=Enum.ScaleType.Fit;shard.ZIndex=5;shard.Parent=exchange
	label(panel.PetName,"ExchangeArrow","→",346,110,76,42,38)
	local icon=shard:Clone()
	icon.Name="RewardIcon";icon.Image="rbxassetid://133373414506019";rect(icon,434,66,132,132);icon.Parent=exchange
	label(panel.Details,"ShardBalance","YOUR SHARDS • 0",24,208,720,38,26)
	label(panel.Notice,"Description","100 SHARDS = 1 REPAIR CHARM\nEarn shards with Robux food purchases",24,250,720,44,18)
	local button=panel.Revive:Clone()
	button.Name="Exchange";button.Text="EXCHANGE • 100 SHARDS";rect(button,163,304,442,48)
	button.ZIndex=5;rounded(button,10);button.Parent=exchange
	label(panel.Notice,"CharmCount","OWNED REPAIR CHARMS • 0",24,356,720,20,16)
	return brokenTab,exchangeTab,exchange
end
return View
