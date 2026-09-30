local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local CarryController = {}
local Notice=require(script.Parent.Parent.UI.Notifications)

function CarryController.Start()
	require(script.Parent.Parent.UI.CarryPose).Start()
	local player = Players.LocalPlayer
	local remote = game.ReplicatedStorage:WaitForChild("PrototypeUI"):WaitForChild("Request")
	local eggRemote = game.ReplicatedStorage:WaitForChild("PrototypeEgg")
	local busy = false
	local function click(screenPosition)
		if player:GetAttribute("IndexPanelOpen") or player:GetAttribute("RevivePanelOpen") or player:GetAttribute("DebugPanelOpen") or player:GetAttribute("MerchantPanelOpen") then return end
		local gui = player.PlayerGui:FindFirstChild("FeedYourPetUI")
		if busy or (gui and (gui.Inventory.Visible or (gui:FindFirstChild("FeedPanel") and gui.FeedPanel.Visible))) then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		-- Input coordinates include the top bar; avoid applying the GUI inset twice.
		local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local plots = workspace:FindFirstChild("PlayerPlots")
		local plot
		if plots then
			for _, candidate in plots:GetChildren() do
				if candidate:GetAttribute("OwnerUserId") == player.UserId then plot = candidate; break end
			end
		end
		if not plot then return end
		-- Giant pets can cover the pen. Placement clicks should still reach its
		-- floor instead of being swallowed by a wing or tentacle overhead.
		local excluded = if player.Character then {player.Character} else {}
		if plots then
			for _, candidate in plots:GetChildren() do
				local pen = candidate:FindFirstChild("Pen")
				local pets = pen and pen:FindFirstChild("ActivePets")
				if pets then table.insert(excluded, pets) end
			end
		end
		params.FilterDescendantsInstances = excluded
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
		if not hit then return end
		local action, id, position
		if hit.Instance == plot.Pen.Floor and player:GetAttribute("CarriedEggUid") then
			action, id, position = "Place", player:GetAttribute("CarriedEggUid"), hit.Position
		elseif hit.Instance == plot.Pen.Floor and player:GetAttribute("CarriedPetId") then
			action, id, position = "PlaceHeldPet", player:GetAttribute("CarriedPetId"), hit.Position
		elseif plot:FindFirstChild("FeedPlate") and hit.Instance:IsDescendantOf(plot.FeedPlate) and player:GetAttribute("CarriedPetId") then
			action, id = "PlaceOnPlate", player:GetAttribute("CarriedPetId")
		else return end
		busy = true
		local request = if action == "Place" then eggRemote else remote
		local ok, response = pcall(function() return request:InvokeServer(action, id, position) end)
		-- HUD polling shares the request throttle. A rejected request has no effect.
		if ok and response.Code == "Cooldown" then
			task.wait(.3)
			ok, response = pcall(function() return request:InvokeServer(action, id, position) end)
		end
		if ok and response.Ok then
			local inventory=require(script.Parent.InventoryController)
			if inventory.Placed then inventory.Placed(if action=="Place" then "Egg" else "Pet",id) end
			if action=="Place" then Notice.Show("Egg is now in your pen!",Color3.fromRGB(161,255,101))
			elseif action=="PlaceHeldPet" then Notice.Show("Pet is now in your pen!",Color3.fromRGB(161,255,101)) end
		end
		if (not ok or not response.Ok) and gui then
			Notice.Show(if action=="Place" and ok and response.Code=="Busy" then "Saving your egg. Please try again shortly."
				elseif action=="Place" then "Move closer and click inside your own fenced Pen."
				elseif ok and response.Code == "PenFull" then "Your pen is full."
				elseif ok and response.Code == "PlateOccupied" then "Your feed plate already has a pet. Open the feed UI to pick it up."
				else "Move closer to your own Pen or feed plate and try again.")
		end
		task.wait(.3)
		busy = false
	end
	Input.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			click(Input:GetMouseLocation())
		end
	end)
	Input.TouchTapInWorld:Connect(function(position, processed)
		if not processed then click(position) end
	end)
	task.spawn(function()
		local plots = workspace:WaitForChild("PlayerPlots")
		while true do
			local gui = player.PlayerGui:FindFirstChild("FeedYourPetUI")
			for _, prompt in plots:GetDescendants() do
				if prompt:IsA("ProximityPrompt") and (prompt.Name == "PickupPet" or prompt.Name == "OpenFeedUI" or prompt.Name == "HatchEgg") then
					local model = prompt:FindFirstAncestorOfClass("Model")
					prompt.Enabled = model:GetAttribute("OwnerUserId") == player.UserId
						and (prompt.Name ~= "HatchEgg" or model:GetAttribute("HatchReady") == true)
						and not player:GetAttribute("RevivePanelOpen")
						and not player:GetAttribute("DebugPanelOpen")
						and not player:GetAttribute("MerchantPanelOpen")
						and not player:GetAttribute("IndexPanelOpen")
						and not (prompt.Name=="OpenFeedUI" and player:GetAttribute("FeedBusy"))
						and not (gui and (gui.Inventory.Visible or (gui:FindFirstChild("FeedPanel") and gui.FeedPanel.Visible)))
				end
			end
			task.wait(.2)
		end
	end)
end

return CarryController
