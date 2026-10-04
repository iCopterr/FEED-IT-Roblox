local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config.UIConfig)
local Images = require(Shared.Config.MonetizationImages)
local Format = require(Shared.NumberFormat)
local Layout = require(script.Parent.DeviceLayout)
local TweenService = game:GetService("TweenService")
local Input = game:GetService("UserInputService")
local UI = {}

local function label(parent, name, text, size, position, dimensions)
	local object = Instance.new("TextLabel")
	object.Name, object.Text = name, text
	object.Position, object.Size = position, dimensions
	object.BackgroundTransparency = 1
	object.Font, object.TextSize = Config.Font, size
	object.TextColor3 = Color3.new(1, 1, 1)
	object.TextStrokeColor3, object.TextStrokeTransparency = Config.Palette.TextStroke, 0
	object.TextWrapped = true
	object.Parent = parent
	return object
end

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

function UI.Create(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.DisplayOrder = "OfflineIncomeUI", 190
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local root = Instance.new("Frame")
	root.Name, root.Size, root.BackgroundTransparency = "Viewport", UDim2.fromScale(1, 1), 1
	root.Parent = gui
	local dim = Instance.new("TextButton")
	dim.Name, dim.Text = "Dim", ""
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3, dim.BackgroundTransparency = Color3.fromRGB(17, 10, 30), .3
	dim.AutoButtonColor, dim.Visible = false, false
	dim:SetAttribute("SuppressClickSound", true)
	dim.Parent = gui
	local popup = Instance.new("Frame")
	popup.Name, popup.Size = "Popup", UDim2.fromOffset(560, 420)
	popup.AnchorPoint, popup.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
	popup.BackgroundColor3, popup.Visible = Color3.fromRGB(37, 39, 56), false
	popup.ZIndex = 2
	popup.Parent = gui
	round(popup, 20)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Parent = Config.Palette.TextStroke, 5, popup
	local scale = Instance.new("UIScale")
	scale.Parent = popup
	local texture = Instance.new("ImageLabel")
	texture.Name, texture.Image = "Studs", Config.StudAssetId
	texture.Size, texture.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	texture.ImageTransparency, texture.ScaleType = .87, Enum.ScaleType.Tile
	texture.TileSize = UDim2.fromOffset(60, 60)
	texture.Parent = popup
	round(texture, 20)
	local title = label(popup, "Title", "WELCOME BACK!", 38, UDim2.fromOffset(16, 16), UDim2.fromOffset(528, 50))
	title.TextColor3 = Color3.fromRGB(137, 255, 98)
	label(popup, "Subtitle", "Your pets earned money while you were away", 21,
		UDim2.fromOffset(24, 68), UDim2.fromOffset(512, 32))
	local art = Instance.new("ImageLabel")
	art.Name, art.Image = "Money", Images.MoneyBundle
	art.BackgroundTransparency, art.Size = 1, UDim2.fromOffset(138, 138)
	art.Position, art.Parent = UDim2.fromOffset(211, 102), popup
	local amount = label(popup, "Amount", "$0", 46, UDim2.fromOffset(16, 238), UDim2.fromOffset(528, 57))
	amount.TextColor3 = Color3.fromRGB(128, 255, 75)
	local duration = label(popup, "Duration", "", 19, UDim2.fromOffset(16, 294), UDim2.fromOffset(528, 28))
	local collect = Instance.new("TextButton")
	collect.Name, collect.Text = "Collect", "COLLECT"
	collect.Position, collect.Size = UDim2.fromOffset(65, 338), UDim2.fromOffset(430, 58)
	collect.BackgroundColor3 = Color3.fromRGB(99, 223, 49)
	collect.Font, collect.TextSize = Config.Font, 30
	collect.TextColor3, collect.TextStrokeColor3, collect.TextStrokeTransparency = Color3.new(1,1,1), Config.Palette.TextStroke, 0
	collect:SetAttribute("SuppressClickSound", true)
	collect.Parent = popup
	round(collect, 13)
	local border = stroke:Clone(); border.Thickness = 3; border.Parent = collect
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(150, 220, 100))
	gradient.Rotation, gradient.Parent = 90, collect
	local top = label(gui, "MenuTop", "", 25, UDim2.new(.5, 0, 0, 10), UDim2.new(1, -32, 0, 48))
	top.AnchorPoint, top.Visible, top.ZIndex = Vector2.new(.5, 0), false, 3
	local bottom = label(gui, "MenuBottom", "", 23, UDim2.new(.5, 0, 1, -10), UDim2.new(1, -32, 0, 48))
	bottom.AnchorPoint, bottom.Visible, bottom.ZIndex = Vector2.new(.5, 1), false, 3
	for _,banner in {top, bottom} do
		banner.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize, limit.MinTextSize, limit.Parent = 25, 12, banner
	end
	local function fit()
		local viewport = root.AbsoluteSize
		local lift = Layout.MenuLift(viewport, Input.TouchEnabled)
		scale.Scale = math.max(.1, math.min(1, (viewport.X-32)/560, (viewport.Y-32-2*lift)/420))
		popup.Position = UDim2.new(.5, 0, .5, -lift)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	popup:GetPropertyChangedSignal("Visible"):Connect(function() dim.Visible = popup.Visible end)
	gui.Parent = playerGui
	fit()
	local view = {Gui = gui, Popup = popup, Collect = collect}
	function view.Show(state)
		amount.Text = "$" .. Format.Money(state.PendingMoney)
		local seconds = state.PendingSeconds
		duration.Text = string.format("%dh %dm %ds earned • 24-hour cap", math.floor(seconds/3600), math.floor(seconds/60)%60, seconds%60)
		popup.Visible = true
		collect.Text = "COLLECT"
		fit()
		local target = scale.Scale
		scale.Scale = target * .9
		TweenService:Create(scale, TweenInfo.new(.22, Enum.EasingStyle.Back), {Scale = target}):Play()
	end
	function view.Menu(open, state)
		top.Visible, bottom.Visible = open, open
		if not state then
			top.Text, bottom.Text = "YOUR PETS CAN EARN WHILE YOU'RE AWAY", "Stay offline 10+ minutes • Earn for up to 24 hours"
		elseif state.Rate <= 0 then
			top.Text, bottom.Text = "PLACE PETS IN YOUR PEN TO EARN OFFLINE", "Stay offline 10+ minutes • Earn for up to 24 hours"
		else
			local capacity = state.PendingMoney + state.Rate * math.max(0, state.MaxSeconds-state.PendingSeconds)
			top.Text = "YOUR PETS EARN $" .. Format.Money(state.Rate) .. "/SEC OFFLINE!"
			bottom.Text = "10+ minutes away • Bank up to $" .. Format.Money(capacity) .. " • 24-hour cap"
		end
	end
	return view
end

return UI
