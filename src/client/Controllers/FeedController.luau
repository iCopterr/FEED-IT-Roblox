local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local GuiBootstrap = require(script.Parent.Parent.UI.GuiBootstrap)
local Effects = require(script.Parent.FeedEffects)
local Config = require(ReplicatedStorage.Shared.Config.FeedConfig)
local Foods = require(ReplicatedStorage.Shared.Config.FoodConfig)
local Preview=require(script.Parent.Parent.UI.ItemPreview)
local FoodCard=require(script.Parent.Parent.UI.FoodCard)
local FeedPrompt=require(script.Parent.Parent.UI.FeedPrompt)
local FeedController = {}
local numberText = require(ReplicatedStorage.Shared.NumberFormat).Compact

function FeedController.Start()
	local player = Players.LocalPlayer
	local playerGui = assert(player:WaitForChild("PlayerGui",10), "PlayerGui missing")
	local gui = assert(playerGui:WaitForChild("FeedYourPetUI",30),"FeedYourPetUI missing; check Rojo")
	local panel = assert(gui:WaitForChild("FeedPanel",5), "FeedPanel asset missing; check Rojo")
	local remote = ReplicatedStorage:WaitForChild("PrototypeFeed")
	local selectedFood = "basic"
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
		NotEnoughFood="Not enough Food. Visit the food merchant!", PetChanged="The pet changed. Please try again.",
		AlreadyProcessed="That request was already processed. Refreshing…", Cooldown="Please wait a moment.",
		Loading="Loading player data…", Unavailable="Feeding is unavailable right now.",
		Busy="Feed is animating or saving. Please wait.", MaxLevel="Maximum Feed level reached (40).",
		InvalidFood="Choose a food type from the selector.",
	}
	local function render(state)
		latest = state
		if state.PetId then
			panel.PetName.Text = state.PetName
			panel.PetDetails.Text = string.format("%s  •  Feed Level %d", state.Rarity, state.FeedLevel)
		end
		if state.Food then panel.Food.Text = string.format("FOOD  %s   •   COST  %s", numberText(state.Food), if state.Cost then numberText(state.Cost) else "—") end
		panel.Feed.Text = if state.MaxLevel then "MAX LEVEL 40" else if state.Cost then "FEED  •  "..numberText(state.Cost).." FOOD" else "FEED"
		panel.Notice.Text = if state.MaxLevel then "MAX LEVEL"
			elseif state.FoodId and Foods.Types[state.FoodId].GuaranteedSuccess then "GUARANTEED SUCCESS\nNormal critical chances"
			else string.format("EXPLOSION: %s%%\nFailure → Rescue or Lv.%d",
				numberText((state.Risk or 0)*100),Config.ExplosionResetLevel)
		local canFeed = state.Ok and state.Cost and not state.MaxLevel and not state.Busy
			and state.PetId == player:GetAttribute("FeedPlatePetId") and state.Food >= state.Cost and not busy
		panel.Feed.Active = canFeed == true
		panel.Feed.AutoButtonColor = canFeed == true
		panel.Feed.BackgroundColor3 = if canFeed then Color3.fromRGB(78,227,51) else Color3.fromRGB(100,100,110)
		Preview.Set(panel.PetPreview,if state.SpeciesId then {Kind="Pet",SpeciesId=state.SpeciesId} else nil)
		for _,id in Foods.Order do
			local card=panel.FoodCards.List[id]
			FoodCard.Paint(card,id,(state.Foods or {})[id] or 0,id==selectedFood)
			card.Active=not busy and not state.Busy
		end
		panel.Pickup.Active = state.PetId == player:GetAttribute("FeedPlatePetId") and state.PetId ~= nil and not busy and not state.Busy
	end
	local function refresh()
		if busy then return end
		busy = true
		local expectedId = player:GetAttribute("FeedPlatePetId")
		local ok, result = pcall(function() return remote:InvokeServer("Snapshot",nil,nil,selectedFood) end)
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
		if player:GetAttribute("RevivePanelOpen") or player:GetAttribute("DebugPanelOpen") or player:GetAttribute("MerchantPanelOpen") then return end
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
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if FeedPrompt.CanOpen(prompt,player.UserId,player:GetAttribute("FeedPlatePetId"),root) then show() end
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
	panel.Close.Activated:Connect(function() require(script.Parent.Parent.UI.Motion).Close(panel) end)
	Input.InputBegan:Connect(function(key, processed)
		if not processed and key.KeyCode == Enum.KeyCode.Escape then panel.Visible = false end
	end)
	local function feed(action)
		local state = latest
		if busy or player:GetAttribute("FeedBusy") or not state or not state.Ok or not state.Cost or state.MaxLevel or state.Food < state.Cost
			or state.PetId ~= player:GetAttribute("FeedPlatePetId") then return end
		busy = true; render(state); panel.Status.Text = "Feeding…"
		if Config.Presentation.CloseUIOnAcceptedFeed then panel.Visible=false end
		local ok, result = pcall(function() return remote:InvokeServer(action,state.PetId,state.NextSequence,state.FoodId) end)
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
				local recovered, snapshot = pcall(function() return remote:InvokeServer("Snapshot",nil,nil,selectedFood) end)
				if recovered and snapshot.LastOutcome and snapshot.LastOutcome.NextSequence==state.NextSequence+1 then displayOutcome(snapshot.LastOutcome) end
			end)
		end
	end
	panel.Feed.Activated:Connect(function() feed("Feed") end)
	local function selectFood(id)
		if busy or player:GetAttribute("FeedBusy") then return end
		selectedFood=id
		if latest and latest.Foods then
			local state=table.clone(latest)
			state.FoodId=id;state.FoodName=Foods.Types[id].Name
			state.Food=state.Foods[id] or 0
			state.Risk=(state.BaseRisk or 0)*(1-Foods.Types[id].Reduction)
			render(state)
		else latest=nil;panel.Feed.Active=false;task.spawn(refresh) end
	end
	for _,id in Foods.Order do
		FoodCard.Paint(panel.FoodCards.List[id],id,0,id==selectedFood)
		panel.FoodCards.List[id].Activated:Connect(function() selectFood(id) end)
	end
	FeedController.SelectFood=selectFood
	local angle=0
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not panel.Visible then return end
		local model=panel.PetPreview.World:FindFirstChildOfClass("Model")
		if model then angle=(angle+dt*.65)%(math.pi*2);model:PivotTo(CFrame.Angles(0,angle,0)) end
	end)
	local function resize()
		local scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/816,(gui.AbsoluteSize.Y-48)/620))
		panel.UIScale.Scale=scale
		-- Include the attached sidebar when centering/scaling the whole group.
		panel.Position=UDim2.new(.5,-128*scale,.5,0)
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
