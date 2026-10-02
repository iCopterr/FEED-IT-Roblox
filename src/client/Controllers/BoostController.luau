local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Bootstrap = require(script.Parent.Parent.UI.GuiBootstrap)
local Images = require(game.ReplicatedStorage.Shared.Config.MonetizationImages)
local Layout = require(script.Parent.Parent.UI.DeviceLayout)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Bootstrap.Wait(playerGui, game:GetService("StarterGui"), "BoostUI")
	if not gui then return end
	started = true
	local badge = gui.MoneyBoost
	badge.Icon.Image = Images.DoubleMoney
	local connections = {}
	local function connect(signal, callback)
		table.insert(connections, signal:Connect(callback))
	end
	local function render()
		-- Same server-replicated eligibility as the payout multiplier. Ownership
		-- alone is not an active boost while policy is loading/restricted.
		badge.Visible = player:GetAttribute("DoubleMoneyOwned") == true
			and player:GetAttribute("PaidRandomPolicyStatus") == "Allowed"
	end
	local jump
	local function resize()
		local rect
		if jump and jump.Parent and jump.Visible then
			rect = {X=jump.AbsolutePosition.X-gui.AbsolutePosition.X,
				Y=jump.AbsolutePosition.Y-gui.AbsolutePosition.Y,
				Width=jump.AbsoluteSize.X, Height=jump.AbsoluteSize.Y}
		end
		local scale, right, bottom = Layout.BoostBadge(gui.AbsoluteSize, Input.TouchEnabled, rect)
		badge.UIScale.Scale = scale
		badge.Position = UDim2.new(1, -right, 1, -bottom)
	end
	local function bindJump(object)
		if object.Name ~= "JumpButton" or not object:IsA("GuiObject") or jump == object then return end
		jump = object
		connect(object:GetPropertyChangedSignal("AbsolutePosition"), resize)
		connect(object:GetPropertyChangedSignal("AbsoluteSize"), resize)
		connect(object:GetPropertyChangedSignal("Visible"), resize)
		resize()
	end
	connect(player:GetAttributeChangedSignal("DoubleMoneyOwned"), render)
	connect(player:GetAttributeChangedSignal("PaidRandomPolicyStatus"), render)
	connect(gui:GetPropertyChangedSignal("AbsoluteSize"), resize)
	connect(Input:GetPropertyChangedSignal("TouchEnabled"), resize)
	connect(playerGui.DescendantAdded, bindJump)
	for _, object in playerGui:GetDescendants() do bindJump(object) end
	gui.Destroying:Connect(function()
		for _, connection in connections do connection:Disconnect() end
		started = false
	end)
	render();resize()
	return gui
end

return Controller
