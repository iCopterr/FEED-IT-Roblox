local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Configs = game.ReplicatedStorage.Shared.Config
local Pack = require(Configs.MonetizationConfig).WelcomePack
local Tutorial = require(Configs.TutorialConfig)
local Images = require(Configs.MonetizationImages)
local UI = script.Parent.Parent.UI
local Offer = require(UI.StarterPackOffer)
local Motion = require(UI.Motion)
local Purchases = require(UI.Purchases)
local Shine = require(UI.ShopShine)
local GuiBootstrap = require(UI.GuiBootstrap)
local Controller = {}
local started = false
local pages = {
	ShopUI = {"Panel"}, SettingsUI = {"Panel"}, IndexUI = {"Panel"},
	FeedYourPetUI = {"Inventory", "FeedPanel"}, MerchantUI = {"Panel"},
	ReviveUI = {"Panel"}, DebugUI = {"Panel"}, ConveyorUI = {"Panel"},
}

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gate = Offer.new(Tutorial.Completed)
	local connections = {}
	local function connect(signal, callback)
		table.insert(connections, signal:Connect(callback))
	end
	local function observe() gate:Observe(player:GetAttribute("TutorialStep"), os.clock()) end
	connect(player:GetAttributeChangedSignal("TutorialStep"), observe)
	observe()
	local pg = player:WaitForChild("PlayerGui")
	local gui = GuiBootstrap.Wait(pg, game:GetService("StarterGui"), "StarterPackUI")
	if not gui then
		for _,connection in connections do connection:Disconnect() end
		return
	end
	local panel = gui.Panel
	local card = panel.Offers.Welcome
	local buy = card.Buy
	panel.Visible = false
	card.Artwork.Image = Images.WelcomePack
	card.Description.Text = string.format("%d Hearty Food + %d Royal Food\n%d Revive Charm\nOnce per player", Pack.Hearty, Pack.Royal, Pack.Revive)
	buy.ButtonText.Text = "BUY • " .. tostring(Pack.Robux) .. " ROBUX"
	buy:SetAttribute("SuppressClickSound", true)
	Motion.BindPopup(panel)
	Motion.BindButton(panel.Close, panel)
	Motion.BindButton(buy, card)
	Shine.Bind(gui)
	connect(panel.Close.Activated, function() Motion.Close(panel) end)
	connect(buy.Activated, function()
		if panel.Visible and player:GetAttribute("WelcomePackOwned") == false then
			-- Explicit player action only; cancellation leaves the offer available.
			Purchases.Request("Product", Pack.ProductId)
		end
	end)
	connect(player:GetAttributeChangedSignal("WelcomePackOwned"), function()
		if player:GetAttribute("WelcomePackOwned") == true then panel.Visible = false end
	end)
	connect(Input.InputBegan, function(key, processed)
		if not processed and key.KeyCode == Enum.KeyCode.Escape and panel.Visible then Motion.Close(panel) end
	end)
	local others = {}
	local function watch(screen)
		local names = pages[screen.Name]
		local function add(other)
			if not other:IsA("GuiObject") or others[other] then return end
			others[other] = true
			connect(other:GetPropertyChangedSignal("Visible"), function()
				if other.Visible then panel.Visible = false end
			end)
		end
		if screen.Name == "PenManagerUI" then
			for _,child in screen:GetChildren() do if child:IsA("Frame") and child.Name ~= "Dock" then add(child) end end
		elseif names then
			for _,name in names do local other = screen:FindFirstChild(name); if other then add(other) end end
		end
	end
	connect(pg.ChildAdded, watch)
	for _,screen in pg:GetChildren() do watch(screen) end
	local function resize()
		local size = gui.AbsoluteSize
		panel.UIScale.Scale = math.max(.1, math.min(1, (size.X - 24) / 760, (size.Y - 24) / 386))
	end
	connect(gui:GetPropertyChangedSignal("AbsoluteSize"), resize)
	resize()
	local elapsed = 0
	connect(RunService.Heartbeat, function(dt)
		elapsed += dt
		if elapsed < .1 or gate.Consumed then return end
		elapsed = 0
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not gui.Enabled then return end
		if gate:Take(os.clock(), player:GetAttribute("WelcomePackOwned"), player:GetAttribute("FeedBusy"), humanoid and humanoid.Health > 0) then
			for other in others do if other.Parent then other.Visible = false end end
			panel.Visible = true
		end
	end)
	connect(gui.Destroying, function()
		for _,connection in connections do connection:Disconnect() end
	end)
end

return Controller
