local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local GuiBootstrap = require(script.Parent.Parent.UI.GuiBootstrap)
local Effects = require(script.Parent.FeedEffects)
local Config = require(ReplicatedStorage.Shared.Config.FeedConfig)
local FeedController = {}

function FeedController.Start()
	local player = Players.LocalPlayer
	local playerGui = assert(player:WaitForChild("PlayerGui",10), "PlayerGui missing")
	local gui = playerGui:WaitForChild("FeedYourPetUI",3)
		or GuiBootstrap.Ensure(playerGui, game:GetService("StarterGui"):WaitForChild("FeedYourPetUI",3))
	local panel = assert(gui:WaitForChild("FeedPanel",5), "FeedPanel asset missing; check Rojo")
	local remote = ReplicatedStorage:WaitForChild("PrototypeFeed")
	local latest, busy
	local observedId = nil
	local function displayOutcome(result)
		if not result or not result.Accepted then return end
		local own = result.OwnerUserId == player.UserId
		if own then panel.Visible=false; latest=nil end
		Effects.Play(result, if own then gui else nil)
	end
	ReplicatedStorage:WaitForChild("FeedOutcome").OnClientEvent:Connect(displayOutcome)
	local messages = {
		NoPet="Place a pet on your feed plate first.", TooFar="Move closer to your feed plate.",
		NotEnoughFood="Not enough Food. Visit your farm!", PetChanged="The pet changed. Please try again.",
		AlreadyProcessed="That request was already processed. Refreshing…", Cooldown="Please wait a moment.",
		Loading="Loading player data…", Unavailable="Feeding is unavailable right now.",
		Busy="Feed is animating or saving. Please wait.", MaxLevel="Maximum Feed level reached (40).",
	}
	local function render(state)
		latest = state
		if state.PetId then
			panel.PetName.Text = state.PetName
			panel.PetDetails.Text = string.format("%s  •  Feed Level %d", state.Rarity, state.FeedLevel)
		end
		if state.Food then panel.Food.Text = string.format("FOOD  %g   •   COST  %s", state.Food, if state.Cost then string.format("%g",state.Cost) else "—") end
		panel.Feed.Text = if state.MaxLevel then "MAX LEVEL 40" else if state.Cost then string.format("FEED  •  %g FOOD", state.Cost) else "FEED"
		panel.Notice.Text = if state.MaxLevel then "LEVEL 40 REACHED\nYou can pick up your pet below."
			else string.format("EXPLOSION RISK: %g%% • MIRACLE SAVE: %g%%\nFood is spent on every attempt. Critical gains stop at 40.",(state.Risk or 0)*100,Config.MiracleSaveChance*100)
		local canFeed = state.Ok and state.Cost and not state.MaxLevel and not state.Busy
			and state.PetId == player:GetAttribute("FeedPlatePetId") and state.Food >= state.Cost and not busy
		panel.Feed.Active = canFeed == true
		panel.Feed.AutoButtonColor = canFeed == true
		panel.Feed.BackgroundColor3 = if canFeed then Color3.fromRGB(112,219,89) else Color3.fromRGB(114,111,127)
		panel.Pickup.Active = state.PetId == player:GetAttribute("FeedPlatePetId") and state.PetId ~= nil and not busy and not state.Busy
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
		if player:GetAttribute("RevivePanelOpen") then return end
		if player:GetAttribute("FeedBusy") then return end
		panel.Visible = true
		gui.Inventory.Visible = false
		panel.Status.Text = ""
		latest = nil; panel.Feed.Active = false
		task.spawn(refresh)
	end
	local function plateChanged()
		local id = player:GetAttribute("FeedPlatePetId")
		if id ~= observedId then
			observedId = id; latest = nil
			if id then show() else panel.Visible = false end
		end
	end
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, triggeringPlayer)
		if triggeringPlayer and triggeringPlayer ~= player then return end
		if prompt.Name ~= "OpenFeedUI" then return end
		local model = prompt:FindFirstAncestorOfClass("Model")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local body = prompt.Parent
		if model and model:GetAttribute("OwnerUserId") == player.UserId
			and model:GetAttribute("PetId") == player:GetAttribute("FeedPlatePetId")
			and root and body:IsA("BasePart") and (root.Position-body.Position).Magnitude <= prompt.MaxActivationDistance+1 then show() end
	end)
	panel.Pickup.Activated:Connect(function()
		local id = player:GetAttribute("FeedPlatePetId")
		if busy or player:GetAttribute("FeedBusy") or not id then return end
		busy = true; panel.Pickup.Active = false; panel.Feed.Active = false
		panel.Status.Text = "Picking up…"
		local ok, result = pcall(function() return remote:InvokeServer("Pickup",id) end)
		busy = false
		if ok and result.Ok then panel.Visible = false; latest = nil
		else panel.Status.Text = if ok then messages[result.Code] or "Unable to pick up pet." else "Connection error. Try again." end
	end)
	panel.Close.Activated:Connect(function() panel.Visible = false end)
	Input.InputBegan:Connect(function(key, processed)
		if not processed and key.KeyCode == Enum.KeyCode.Escape then panel.Visible = false end
	end)
	panel.Feed.Activated:Connect(function()
		local state = latest
		if busy or player:GetAttribute("FeedBusy") or not state or not state.Ok or not state.Cost or state.MaxLevel or state.Food < state.Cost
			or state.PetId ~= player:GetAttribute("FeedPlatePetId") then return end
		busy = true; render(state); panel.Status.Text = "Feeding…"
		if Config.Presentation.CloseUIOnAcceptedFeed then panel.Visible=false end
		local ok, result = pcall(function() return remote:InvokeServer("Feed",state.PetId,state.NextSequence) end)
		busy = false
		if ok and result.Accepted then
			displayOutcome(result)
		elseif ok then
			if state.PetId ~= player:GetAttribute("FeedPlatePetId") then return end
			panel.Visible=true; latest=nil; panel.Feed.Active=false
			panel.Status.Text = messages[result.Code] or "Request rejected. Refreshing…"
		else
			latest = nil; panel.Feed.Active = false
			panel.Visible=true
			panel.Status.Text = "Connection interrupted. Refreshing before another Feed."
			-- Recover the server result instead of issuing a new attempt after an ambiguous reply.
			task.delay(.5,function()
				local recovered, snapshot = pcall(function() return remote:InvokeServer("Snapshot") end)
				if recovered and snapshot.LastOutcome and snapshot.LastOutcome.NextSequence==state.NextSequence+1 then displayOutcome(snapshot.LastOutcome) end
			end)
		end
	end)
	local function resize()
		panel.UIScale.Scale = math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/520,(gui.AbsoluteSize.Y-130)/510))
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
