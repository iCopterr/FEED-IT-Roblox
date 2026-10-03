-- Responsive geometry for existing authored UI only. No duplicate screens/art.
local Layout = {}
local originals = setmetatable({}, {__mode="k"})
local overrides = setmetatable({}, {__mode="k"})
local panelPositions = setmetatable({}, {__mode="k"})
local function set(panel, object, property, value)
	if not object then return end
	local saved = overrides[panel]
	saved[object] = saved[object] or {}
	if saved[object][property] == nil then saved[object][property] = object[property] end
	object[property] = value
end
local function rect(panel, object, x, y, w, h)
	set(panel, object, "Position", UDim2.fromOffset(x,y))
	set(panel, object, "Size", UDim2.fromOffset(w,h))
end
function Layout.Fit(viewport, width, height)
	return math.max(.01, math.min(1, (viewport.X-24)/math.max(1,width), (viewport.Y-24)/math.max(1,height)))
end
function Layout.CompactLandscape(viewport, touchEnabled)
	-- Landscape phones can report either logical or physical pixels. Touch plus
	-- a short logical height or phone-wide aspect separates them from desktops.
	return touchEnabled == true and viewport.X > viewport.Y
		and (viewport.Y <= 720 or viewport.X/viewport.Y >= 1.8)
end
function Layout.LauncherScale(viewport, touchEnabled)
	if Layout.CompactLandscape(viewport, touchEnabled) then return .62 end
	return math.min(1, math.max(.68, math.min(viewport.X/760,viewport.Y/650)))
end
function Layout.LeftLauncherScale(viewport, touchEnabled)
	if touchEnabled then return math.min(.70, Layout.LauncherScale(viewport, false)) end
	return Layout.LauncherScale(viewport, touchEnabled)
end
function Layout.SettingsLauncherScale(viewport, touchEnabled)
	if touchEnabled then return .72 end
	return Layout.LauncherScale(viewport, touchEnabled)
end
function Layout.LeftLauncherGap(viewport, touchEnabled)
	return if Layout.CompactLandscape(viewport, touchEnabled) then 20 else 12
end
function Layout.LeftLauncherOffset(_viewport, touchEnabled)
	return if touchEnabled then 24 else 18
end
function Layout.ShopLauncherOffset(viewport, touchEnabled)
	return Layout.LeftLauncherOffset(viewport, touchEnabled),
		if Layout.CompactLandscape(viewport, touchEnabled) then -90 else -76
end
function Layout.RightLauncherOffset(_viewport, touchEnabled)
	-- ScreenGui already excludes the device's unsafe area. A positive offset
	-- crosses that boundary and ClipToDeviceSafeArea cuts off the buttons.
	return if touchEnabled then -24 else -18
end
function Layout.TravelScale(viewport, touchEnabled)
	local fit = math.min(1, (viewport.X-24)/540)
	return if touchEnabled then math.min(.54, fit) else fit
end
function Layout.MenuLift(viewport, touchEnabled)
	return if touchEnabled then math.min(24, viewport.Y*.06) else 0
end
function Layout.RemotePanelScale(size, touchEnabled)
	local base=if size.X<900 then math.min(Layout.Fit(size,510,440),(size.X-32)/510)
		else math.min(.82,math.max(.45,math.min(size.X*.23/510,size.Y*.34/440)),(size.X-32)/510,(size.Y-40)/440)
	local lift=Layout.MenuLift(size,touchEnabled)
	return math.min(base*.8,Layout.Fit(Vector2.new(size.X,size.Y-2*lift),510,440))
end
function Layout.MoneyScale(viewport, touchEnabled)
	if Layout.CompactLandscape(viewport, touchEnabled) then return .62 end
	return if viewport.X < 760 then .68 else math.min(1, viewport.Y/650)
end
function Layout.BoostBadge(viewport, touchEnabled, jump)
	local scale = if touchEnabled then .8 else 1
	local width, height = 86*scale, 78*scale
	local right, bottom = 18, 14
	if touchEnabled then
		-- Before TouchGui arrives, reserve its usual corner. When it arrives,
		-- use the actual jump bounds (including device/control size changes).
		right = 144
		if jump then
			right = 18
			local left, top = viewport.X-right-width, viewport.Y-bottom-height
			if left < jump.X+jump.Width+10 and viewport.X-right > jump.X-10
				and top < jump.Y+jump.Height+10 and viewport.Y-bottom > jump.Y-10 then
				right = viewport.X-jump.X+10
			end
		end
	end
	right = math.clamp(right, 12, math.max(12, viewport.X-width-12))
	return scale, right, bottom
end
function Layout.TutorialHint(viewport, touchEnabled)
	if Layout.CompactLandscape(viewport, touchEnabled) then
		return math.min(460, viewport.X*.45), 58, 74, 17
	end
	local width = math.min(560, viewport.X-24)
	return width, if width<450 then 82 else 66, 110, 21
end
function Layout.Portrait(viewport)
	return viewport.X < 700 and viewport.Y > viewport.X
end
local function offer(panel, card, width, y, pack)
	rect(panel,card,8,y,width,if pack then 360 else 294)
	for _,child in card:GetChildren() do
		if child.Name=="Artwork" then rect(panel,child,(width-160)/2,12,160,140)
		elseif child.Name=="Title" then
			rect(panel,child,12,154,width-24,40);set(panel,child,"TextSize",26)
		elseif child.Name=="Description" then
			rect(panel,child,12,if pack then 198 else 194,width-24,if pack then 88 else 26);set(panel,child,"TextSize",22)
		end
	end
	rect(panel,card.Buy,16,if pack then 298 else 228,width-32,50)
end

function Layout.Apply(panel, viewport, kind, scaleName, touchEnabled)
	if viewport.X<=0 or viewport.Y<=0 then return end
	if touchEnabled==nil then touchEnabled=game:GetService("UserInputService").TouchEnabled end
	local lift=Layout.MenuLift(viewport,touchEnabled)
	local fitViewport=Vector2.new(viewport.X,viewport.Y-2*lift)
	if not panelPositions[panel] then panelPositions[panel]=panel.Position end
	if not originals[panel] then originals[panel]=panel.Size;overrides[panel]={} end
	local portrait = Layout.Portrait(viewport)
	if not portrait then
		for object,properties in overrides[panel] do
			if object.Parent then for key,value in properties do object[key]=value end end
		end
		overrides[panel]={}
		-- Preserve subsequent owner-authored desktop size edits too.
		originals[panel]=panel.Size
	end
	local base=originals[panel]
	local width=base.X.Scale*viewport.X+base.X.Offset
	local height=base.Y.Scale*viewport.Y+base.Y.Offset
	if portrait and kind=="Settings" then
		width,height=460,610
		for _,name in {"MusicVolume","SFXVolume","ShowOtherPets","ShowOwnPets"} do
			local row=panel[name]
			rect(panel,row.Title,16,8,390,40);set(panel,row.Title,"TextSize",28)
			if row:FindFirstChild("Slider") then
				rect(panel,row.Description,16,48,290,26);set(panel,row.Description,"TextSize",20)
				rect(panel,row.Value,300,46,104,28)
				rect(panel,row.Slider,24,82,374,24)
			else rect(panel,row.Toggle,222,52,180,50) end
		end
	elseif portrait and (kind=="Shop" or kind=="StarterPack") then
		width,height=460,if kind=="Shop" then 720 else 484
		local offers=panel.Offers
		if kind=="StarterPack" then
			rect(panel,offers,18,88,424,378);offer(panel,offers.Welcome,408,8,true)
		else
			offer(panel,offers.Welcome,408,58,true)
			offer(panel,offers.DoubleMoney,408,488,true)
			for i=1,6 do
				local card=offers["Money"..i]
				offer(panel,card,408,920+(i-1)*310,false)
			end
			for _,child in offers:GetChildren() do
				local y=({FeaturedHeading=4,PassesHeading=432,MoneyHeading=864})[child.Name]
				if y then rect(panel,child,8,y,408,46) end
			end
			set(panel,offers,"CanvasSize",UDim2.fromOffset(0,2780))
		end
	elseif portrait and kind=="Feed" then
		width,height=560,980
		-- Put food below the pet instead of shrinking an 884px-wide two-panel group.
		rect(panel,panel.FoodCards,0,636,560,344)
		rect(panel,panel.FoodCards.List,20,70,520,250)
		set(panel,panel.FoodCards.Hint,"Visible",false)
	elseif portrait and kind=="Index" then
		width,height=540,930
		rect(panel,panel.Title,18,10,440,50);set(panel,panel.Title,"TextSize",32)
		rect(panel,panel.Close,478,13,44,44)
		rect(panel,panel.Categories,16,84,508,86)
		set(panel,panel.Categories.Layout,"FillDirection",Enum.FillDirection.Horizontal)
		set(panel,panel.Categories,"ScrollingDirection",Enum.ScrollingDirection.X)
		set(panel,panel.Categories,"CanvasSize",UDim2.fromOffset(1080,0))
		rect(panel,panel.CategoryName,16,182,508,36)
		rect(panel,panel.Pets,16,228,508,390)
		rect(panel,panel.Detail,16,632,508,246)
		local d=panel.Detail
		rect(panel,d.Preview,10,12,200,210)
		for _,entry in {{"ItemName",12,58},{"Rarity",74,30},{"Level",110,28},{"Income",148,37},{"Source",192,36}} do
			rect(panel,d[entry[1]],218,entry[2],278,entry[3])
		end
		rect(panel,panel.Progress,16,890,508,28)
	elseif portrait and kind=="Inventory" then
		width,height=560,900
		local p=panel.Panel.Layout
		rect(panel,p.Title,18,12,410,40);set(panel,p.Title,"TextSize",30)
		rect(panel,p.PenSlots,382,66,155,30)
		rect(panel,p.Search,18,66,350,40)
		for i,name in {"All","Pet","Egg","Food"} do rect(panel,p[name],18+(i-1)*78,118,70,48) end
		rect(panel,p.Sort,336,118,206,48)
		rect(panel,p.Pets,18,182,524,370)
		rect(panel,p.EmptyState,30,270,500,90)
		rect(panel,p.Details,18,568,524,308)
		local d=p.Details
		rect(panel,d.Preview,12,12,200,168)
		rect(panel,d.ItemName,220,12,288,50)
		rect(panel,d.Stats,220,68,288,112)
		rect(panel,d.Lock,12,190,200,48);rect(panel,d.Pin,224,190,288,48)
		rect(panel,d.Equip,12,248,500,48)
	elseif portrait and kind=="Revive" then
		width,height=540,930
		rect(panel,panel.PageHeader,0,0,width,66);rect(panel,panel.PageTexture,0,0,width,height)
		rect(panel,panel.Title,18,8,450,48);set(panel,panel.Title,"TextSize",32)
		rect(panel,panel.Close,486,12,40,40)
		rect(panel,panel.BrokenTab,16,74,246,44);rect(panel,panel.ExchangeTab,278,74,246,44)
		rect(panel,panel.Pets,16,130,508,218);rect(panel,panel.Empty,20,190,500,80)
		rect(panel,panel.PetPreview,16,360,508,200)
		rect(panel,panel.PetName,16,568,508,42)
		rect(panel,panel.Details,16,616,508,58)
		rect(panel,panel.Notice,16,680,508,32)
		rect(panel,panel.Revive,16,722,508,56);rect(panel,panel.Robux,16,788,508,56)
		rect(panel,panel.Status,16,854,508,38)
		local exchange=panel.ExchangePanel
		rect(panel,exchange,16,130,508,714)
		rect(panel,exchange.ShardTitle,20,24,468,48)
		rect(panel,exchange.ShardIcon,64,98,150,150)
		rect(panel,exchange.ExchangeArrow,220,152,68,42)
		rect(panel,exchange.RewardIcon,294,98,150,150)
		rect(panel,exchange.ShardBalance,20,278,468,52)
		rect(panel,exchange.Description,20,344,468,76)
		rect(panel,exchange.Exchange,32,442,444,62)
		rect(panel,exchange.CharmCount,20,520,468,32)
	end
	if portrait and kind~="Feed" then set(panel,panel,"Size",UDim2.fromOffset(width,height)) end
	local scale=Layout.Fit(fitViewport,width,height)
	local scaleObject=panel:FindFirstChild(scaleName or "UIScale")
	if scaleObject then
		-- Some Studio exports contain duplicate UIScales; only one owns fitting.
		for _,child in panel:GetChildren() do if child:IsA("UIScale") then child.Scale=if child==scaleObject then scale else 1 end end
	end
	if kind=="Feed" then
		if not portrait then scale=Layout.Fit(fitViewport,884,620);scaleObject.Scale=scale end
		panel.Position=UDim2.new(.5,if portrait then 0 else -162*scale,.5,(if portrait then -180*scale else 0)-lift)
	else
		panel.Position=panelPositions[panel]-UDim2.fromOffset(0,lift)
	end
	return scale
end
return Layout
