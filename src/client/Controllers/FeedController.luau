local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local GuiBootstrap = require(script.Parent.Parent.UI.GuiBootstrap)
local FeedController = {}

function FeedController.Start()
	local player = Players.LocalPlayer
	local playerGui = assert(player:WaitForChild("PlayerGui",10), "PlayerGui missing")
	local gui = playerGui:WaitForChild("FeedYourPetUI",3)
		or GuiBootstrap.Ensure(playerGui, game:GetService("StarterGui"):WaitForChild("FeedYourPetUI",3))
	local panel = assert(gui:WaitForChild("FeedPanel",5), "FeedPanel asset missing; check Rojo")
	local open = gui:WaitForChild("FeedOpen",5)
	local remote = ReplicatedStorage:WaitForChild("PrototypeFeed")
	local latest, busy
	local observedId = nil
	local messages = {
		NoPet="Place a pet on your feed plate first.", TooFar="Move closer to your feed plate.",
		NotEnoughFood="Not enough Food. Visit your farm!", PetChanged="The pet changed. Please try again.",
		AlreadyProcessed="That request was already processed. Refreshing…", Cooldown="Please wait a moment.",
		Loading="Loading player data…", Unavailable="Feeding is unavailable right now.",
	}
	local function render(state)
		latest = state
		if state.PetId then
			panel.PetName.Text = state.PetName
			panel.PetDetails.Text = string.format("%s  •  Feed Level %d", state.Rarity, state.FeedLevel)
		end
		if state.Food then panel.Food.Text = string.format("FOOD  %g   •   COST  %g", state.Food, state.Cost) end
		panel.Feed.Text = if state.Cost then string.format("FEED  •  %g FOOD", state.Cost) else "FEED"
		local canFeed = state.Ok and state.PetId == player:GetAttribute("FeedPlatePetId") and state.Food >= state.Cost and not busy
		panel.Feed.Active = canFeed == true
		panel.Feed.AutoButtonColor = canFeed == true
		panel.Feed.BackgroundColor3 = if canFeed then Color3.fromRGB(112,219,89) else Color3.fromRGB(114,111,127)
	end
	local function refresh()
		if busy then return end
		busy = true
		local expectedId = player:GetAttribute("FeedPlatePetId")
		local ok, result = pcall(function() return remote:InvokeServer("Snapshot") end)
		busy = false
		if expectedId ~= player:GetAttribute("FeedPlatePetId") then return end
		if ok and result.Code ~= "Cooldown" then
			render(result)
			if not result.Ok then panel.Status.Text = messages[result.Code] or "Unable to load feeding state." end
		elseif not ok then
			latest = nil; panel.Feed.Active = false; panel.Status.Text = "Connection error. Retrying…"
		end
	end
	local function show()
		panel.Visible = true
		gui.Inventory.Visible = false
		panel.Status.Text = ""
		latest = nil; panel.Feed.Active = false
		task.spawn(refresh)
	end
	local function plateChanged()
		local id = player:GetAttribute("FeedPlatePetId")
		open.Visible = id ~= nil
		if id ~= observedId then
			observedId = id; latest = nil
			if id then show() else panel.Visible = false end
		end
	end
	open.Activated:Connect(show)
	panel.Close.Activated:Connect(function() panel.Visible = false end)
	Input.InputBegan:Connect(function(key, processed)
		if not processed and key.KeyCode == Enum.KeyCode.Escape then panel.Visible = false end
	end)
	panel.Feed.Activated:Connect(function()
		local state = latest
		if busy or not state or not state.Ok or state.Food < state.Cost
			or state.PetId ~= player:GetAttribute("FeedPlatePetId") then return end
		busy = true; render(state); panel.Status.Text = "Feeding…"
		local ok, result = pcall(function() return remote:InvokeServer("Feed",state.PetId,state.NextSequence) end)
		busy = false
		if state.PetId ~= player:GetAttribute("FeedPlatePetId") then return end
		if ok then
			render(result)
			panel.Status.Text = if result.Ok then string.format("Consumed %g Food. Pet stats unchanged.",result.Cost)
				else messages[result.Code] or "Request rejected. Refreshing…"
		else
			latest = nil; panel.Feed.Active = false
			panel.Status.Text = "Connection interrupted. Refreshing before another Feed."
		end
	end)
	local function resize()
		panel.UIScale.Scale = math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/520,(gui.AbsoluteSize.Y-130)/440))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	player:GetAttributeChangedSignal("FeedPlatePetId"):Connect(plateChanged)
	resize(); plateChanged()
	task.spawn(function()
		while gui.Parent do
			if panel.Visible then refresh() end
			task.wait(.5)
		end
	end)
	return gui
end

return FeedController
