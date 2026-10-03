local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(game.ReplicatedStorage.Shared.Config.UIConfig)
local Config = require(game.ReplicatedStorage.Shared.Config.MonetizationConfig)
local Images = require(game.ReplicatedStorage.Shared.Config.MonetizationImages)
local Icons = require(script.Parent.IconImages)
local Layout = require(script.Parent.DeviceLayout)
local Sounds = require(script.Parent.Parent.Audio.GameSounds)

local PurchaseThanks = {}
local queue = {}
local gui, card, cardScale, group, artwork, artworkFallback, rewardName, rewardDetail
local shardBanner, shardImage, shardFallback, shardText, shine, closeButton, awesomeButton
local currentToken = 0
local showing = false
local shineTween

local FONT = UIConfig.Font
local STROKE = UIConfig.Palette.TextStroke

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius)
	value.Parent = parent
	return value
end

local function stroke(parent, color, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color
	value.Thickness = thickness
	value.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	value.Parent = parent
	return value
end

local function text(parent, name, value, size, position, dimensions)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = dimensions
	label.Font = FONT
	label.Text = value
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = size
	label.TextStrokeColor3 = STROKE
	label.TextStrokeTransparency = 0
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function button(parent, name, value, position, dimensions, color)
	local result = Instance.new("TextButton")
	result.Name = name
	result.Position = position
	result.Size = dimensions
	result.BackgroundColor3 = color
	result.AutoButtonColor = false
	result.Font = FONT
	result.Text = value
	result.TextColor3 = Color3.new(1, 1, 1)
	result.TextSize = 28
	result.TextStrokeColor3 = STROKE
	result.TextStrokeTransparency = 0
	result.Parent = parent
	corner(result, 13)
	stroke(result, Color3.fromRGB(24, 16, 35), 4)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(color:Lerp(Color3.new(1,1,1), .2), color:Lerp(Color3.new(0,0,0), .12))
	gradient.Rotation = 90
	gradient.Parent = result
	return result
end

local function fit()
	if not cardScale then return end
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local lift=Layout.MenuLift(viewport,UserInputService.TouchEnabled)
	cardScale.Scale = math.min(1, (viewport.X - 24) / 600, (viewport.Y - 24-2*lift) / 460)
	group.Position=UDim2.new(.5,0,.5,-lift)
end

local function create()
	if gui and gui.Parent then return end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "PurchaseThanksUI"
	gui.DisplayOrder = 180
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = playerGui

	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.BackgroundColor3 = Color3.fromRGB(15, 8, 25)
	dim.BackgroundTransparency = .28
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 1
	dim.Parent = gui

	group = Instance.new("CanvasGroup")
	group.Name = "Popup"
	group.AnchorPoint = Vector2.new(.5, .5)
	group.Position = UDim2.fromScale(.5, .5)
	group.Size = UDim2.fromOffset(600, 460)
	group.BackgroundTransparency = 1
	group.ZIndex = 2
	group.Parent = gui
	cardScale = Instance.new("UIScale")
	cardScale.Parent = group

	card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(39, 40, 57)
	card.ClipsDescendants = true
	card.Parent = group
	corner(card, 20)
	stroke(card, Color3.fromRGB(19, 13, 29), 6)

	local texture = Instance.new("ImageLabel")
	texture.Name = "StudTexture"
	texture.BackgroundTransparency = 1
	texture.Size = UDim2.fromScale(1, 1)
	texture.Image = UIConfig.StudAssetId
	texture.ImageTransparency = .83
	texture.ScaleType = Enum.ScaleType.Tile
	texture.TileSize = UDim2.fromOffset(50, 50)
	texture.ZIndex = 0
	texture.Parent = card

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 92)
	header.BackgroundColor3 = Color3.fromRGB(42, 222, 250)
	header.ZIndex = 2
	header.Parent = card
	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new(Color3.fromRGB(48, 230, 255), Color3.fromRGB(85, 236, 79))
	headerGradient.Rotation = 12
	headerGradient.Parent = header

	local title = text(header, "Title", "THANK YOU!", 42, UDim2.fromOffset(18, 8), UDim2.new(1, -92, 0, 48))
	title.TextXAlignment = Enum.TextXAlignment.Left
	local subtitle = text(header, "Subtitle", "FOR YOUR PURCHASE", 20, UDim2.fromOffset(20, 54), UDim2.new(1, -96, 0, 28))
	subtitle.TextXAlignment = Enum.TextXAlignment.Left

	closeButton = button(header, "Close", "×", UDim2.new(1, -68, 0, 14), UDim2.fromOffset(52, 52), Color3.fromRGB(221, 47, 55))
	closeButton.TextSize = 38

	local rewardCard = Instance.new("Frame")
	rewardCard.Name = "Reward"
	rewardCard.Position = UDim2.fromOffset(22, 110)
	rewardCard.Size = UDim2.fromOffset(556, 198)
	rewardCard.BackgroundColor3 = Color3.fromRGB(73, 78, 102)
	rewardCard.ZIndex = 2
	rewardCard.Parent = card
	corner(rewardCard, 16)
	stroke(rewardCard, Color3.fromRGB(245, 245, 255), 3)

	local artHolder = Instance.new("Frame")
	artHolder.Name = "ArtHolder"
	artHolder.Position = UDim2.fromOffset(10, 10)
	artHolder.Size = UDim2.fromOffset(178, 178)
	artHolder.BackgroundColor3 = Color3.fromRGB(46, 181, 233)
	artHolder.ClipsDescendants = true
	artHolder.ZIndex = 3
	artHolder.Parent = rewardCard
	corner(artHolder, 14)
	stroke(artHolder, STROKE, 3)

	shine = Instance.new("ImageLabel")
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(.5, .5)
	shine.Position = UDim2.fromScale(.5, .5)
	shine.Size = UDim2.fromOffset(244, 244)
	shine.BackgroundTransparency = 1
	shine.Image = Images.ShopShine
	shine.ImageTransparency = .32
	shine.ZIndex = 3
	shine.Parent = artHolder

	artwork = Instance.new("ImageLabel")
	artwork.Name = "Artwork"
	artwork.BackgroundTransparency = 1
	artwork.Position = UDim2.fromOffset(16, 16)
	artwork.Size = UDim2.fromOffset(146, 146)
	artwork.ScaleType = Enum.ScaleType.Fit
	artwork.ZIndex = 4
	artwork.Parent = artHolder
	artworkFallback = text(artHolder, "ArtworkFallback", "🎁", 86, UDim2.fromOffset(16, 16), UDim2.fromOffset(146, 146))
	artworkFallback.ZIndex = 4

	local received = text(rewardCard, "Received", "YOU RECEIVED", 18, UDim2.fromOffset(204, 18), UDim2.fromOffset(332, 28))
	received.TextColor3 = Color3.fromRGB(255, 224, 80)
	received.TextXAlignment = Enum.TextXAlignment.Left
	rewardName = text(rewardCard, "RewardName", "PURCHASE RECEIVED", 32, UDim2.fromOffset(202, 46), UDim2.fromOffset(338, 72))
	rewardName.TextXAlignment = Enum.TextXAlignment.Left
	rewardDetail = text(rewardCard, "RewardDetail", "Added to your account", 19, UDim2.fromOffset(204, 124), UDim2.fromOffset(328, 54))
	rewardDetail.TextColor3 = Color3.fromRGB(215, 222, 239)
	rewardDetail.TextXAlignment = Enum.TextXAlignment.Left

	shardBanner = Instance.new("Frame")
	shardBanner.Name = "ShardBonus"
	shardBanner.Position = UDim2.fromOffset(40, 316)
	shardBanner.Size = UDim2.fromOffset(520, 58)
	shardBanner.BackgroundColor3 = Color3.fromRGB(220, 60, 166)
	shardBanner.ZIndex = 3
	shardBanner.Parent = card
	corner(shardBanner, 14)
	stroke(shardBanner, STROKE, 4)
	local shardGradient = Instance.new("UIGradient")
	shardGradient.Color = ColorSequence.new(Color3.fromRGB(255, 97, 212), Color3.fromRGB(138, 56, 204))
	shardGradient.Parent = shardBanner
	shardImage = Instance.new("ImageLabel")
	shardImage.Name = "ShardIcon"
	shardImage.BackgroundTransparency = 1
	shardImage.Position = UDim2.fromOffset(8, 4)
	shardImage.Size = UDim2.fromOffset(50, 50)
	shardImage.ScaleType = Enum.ScaleType.Fit
	shardImage.Image = Icons.reviveShard
	shardImage.ZIndex = 4
	shardImage.Parent = shardBanner
	shardFallback = text(shardBanner, "ShardFallback", "◆", 43, UDim2.fromOffset(8, 3), UDim2.fromOffset(50, 50))
	shardFallback.TextColor3 = Color3.fromRGB(255, 125, 228)
	shardFallback.ZIndex = 4
	shardText = text(shardBanner, "ShardText", "+1 REPAIR SHARD", 25, UDim2.fromOffset(64, 7), UDim2.fromOffset(442, 44))
	shardText.ZIndex = 4

	awesomeButton = button(card, "Awesome", "AWESOME!", UDim2.fromOffset(156, 338), UDim2.fromOffset(288, 72), Color3.fromRGB(51, 211, 78))
	awesomeButton.ZIndex = 3

	local camera = workspace.CurrentCamera
	if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()

	shineTween = TweenService:Create(shine, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
	closeButton.Activated:Connect(function() PurchaseThanks.Close() end)
	awesomeButton.Activated:Connect(function() PurchaseThanks.Close() end)
	dim.Activated:Connect(function() PurchaseThanks.Close() end)
end

local function moneyText(amount)
	if amount >= 1000000 then return string.format("$%.1fM", amount / 1000000):gsub("%.0M", "M") end
	if amount >= 1000 then return string.format("$%.0fK", amount / 1000) end
	return "$" .. tostring(amount)
end

local function content(payload)
	local image, fallback, name, detail = "", "🎁", tostring(payload.Reward or "PURCHASE RECEIVED"), "Added to your account"
	if payload.Kind == "Food" then
		image = Icons[payload.ItemId] or ""
		fallback = if payload.ItemId == "revive" then "💖" else "🍖"
		name = "1× " .. name
		detail = if payload.Shards and payload.Shards > 0 then "Food and bonus shards received!" else "Ready in your inventory"
	elseif payload.Kind == "Money" then
		name = moneyText(payload.Amount or 0) .. " MONEY"
		fallback = "💵"
		for index, pack in Config.MoneyPacks do
			if pack.ProductId == payload.ProductId then
				image = ({Images.MoneyPocket, Images.MoneyPouch, Images.MoneyBundle, Images.MoneyChest, Images.MoneyVault, Images.MoneyTreasury})[index] or ""
				break
			end
		end
	elseif payload.Kind == "Welcome" then
		image = Images.WelcomePack; fallback = "🎁"
		detail = string.format("%d Hearty • %d Royal • %d Repair Charm", payload.Hearty or 0, payload.Royal or 0, payload.Revive or 0)
	elseif payload.Kind == "Pass" then
		image = Images.DoubleMoney; fallback = "×2"
		detail = "Your pet income is now doubled!"
	elseif payload.Kind == "Grow" then
		image = Images.GrowNow; fallback = "🥚"; detail = "Your egg can hatch now"
	elseif payload.Kind == "GrowAll" then
		image = Images.GrowAll; fallback = "🥚"; detail = string.format("%d egg%s finished growing", payload.Amount or 0, payload.Amount == 1 and "" or "s")
	elseif payload.Kind == "Restock" then
		image = Images.Restock; fallback = "🔄"; detail = "Your personal offers are full again"
	elseif payload.Kind == "Revive" then
		image = Images.Revive; fallback = "💖"; detail = "Your pet is repaired • Full income restored"
	end
	return image, fallback, name, detail
end

local function present(payload)
	create()
	local image, fallback, name, detail = content(payload)
	artwork.Image = image
	artwork.Visible = image ~= ""
	artworkFallback.Text = fallback
	artworkFallback.Visible = image == ""
	rewardName.Text = name
	rewardDetail.Text = detail
	local shards = tonumber(payload.Shards) or 0
	shardBanner.Visible = shards > 0
	awesomeButton.Position = UDim2.fromOffset(156, if shards > 0 then 390 else 338)
	awesomeButton.Size = UDim2.fromOffset(288, if shards > 0 then 50 else 72)
	if shards > 0 then
		shardText.Text = string.format("BONUS  +%d REPAIR SHARD%s", shards, shards == 1 and "" or "S")
		shardImage.Visible = Icons.reviveShard ~= ""
		shardFallback.Visible = Icons.reviveShard == ""
	end
	gui.Enabled = true
	group.GroupTransparency = 1
	cardScale.Scale *= .82
	shine.Rotation = 0
	shineTween:Play()
	TweenService:Create(group, TweenInfo.new(.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
	TweenService:Create(cardScale, TweenInfo.new(.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = cardScale.Scale / .82}):Play()
	Sounds.Play("Buy")
	currentToken += 1
	local token = currentToken
	task.delay(8, function()
		if showing and token == currentToken then PurchaseThanks.Close() end
	end)
end

local function nextItem()
	if showing or #queue == 0 then return end
	showing = true
	present(table.remove(queue, 1))
end

function PurchaseThanks.Show(payload)
	if type(payload) ~= "table" then return end
	table.insert(queue, table.clone(payload))
	nextItem()
end

function PurchaseThanks.Close()
	if not showing or not gui then return end
	showing = false
	currentToken += 1
	shineTween:Pause()
	group.GroupTransparency = 1
	gui.Enabled = false
	nextItem()
end

function PurchaseThanks.GetGui()
	create()
	return gui
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape then PurchaseThanks.Close() end
end)

return PurchaseThanks
