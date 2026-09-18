local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local CarryController = {}

function CarryController.Start()
	local player = Players.LocalPlayer
	local remote = game.ReplicatedStorage:WaitForChild("PrototypeUI"):WaitForChild("Request")
	local busy = false
	local function click(screenPosition)
		if player:GetAttribute("RevivePanelOpen") then return end
		local gui = player.PlayerGui:FindFirstChild("FeedYourPetUI")
		if busy or (gui and (gui.Inventory.Visible or (gui:FindFirstChild("FeedPanel") and gui.FeedPanel.Visible))) then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		-- Input coordinates include the top bar; avoid applying the GUI inset twice.
		local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = if player.Character then {player.Character} else {}
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
		if not hit then return end
		local plots = workspace:FindFirstChild("PlayerPlots")
		local plot
		if plots then
			for _, candidate in plots:GetChildren() do
				if candidate:GetAttribute("OwnerUserId") == player.UserId then plot = candidate; break end
			end
		end
		if not plot then return end
		local action, id, position
		if hit.Instance == plot.Pen.Floor and player:GetAttribute("CarriedPetId") then
			action, id, position = "PlaceHeldPet", player:GetAttribute("CarriedPetId"), hit.Position
		elseif plot:FindFirstChild("FeedPlate") and hit.Instance:IsDescendantOf(plot.FeedPlate) and player:GetAttribute("CarriedPetId") then
			action, id = "PlaceOnPlate", player:GetAttribute("CarriedPetId")
		else return end
		busy = true
		local ok, response = pcall(function() return remote:InvokeServer(action, id, position) end)
		-- HUD polling shares the request throttle. A rejected request has no effect.
		if ok and response.Code == "Cooldown" then
			task.wait(.3)
			ok, response = pcall(function() return remote:InvokeServer(action, id, position) end)
		end
		if (not ok or not response.Ok) and gui then
			gui.Inventory.Visible = true
			gui.Inventory.Panel.Layout.Status.Text = if ok and response.Code == "PenFull" then "Your Pen is full (5 pets)." elseif ok and response.Code == "PlateOccupied" then "Your feed plate already has a pet. Hold E near it to pick it up." else "Move closer to your own Pen or feed plate and try again."
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
				if prompt:IsA("ProximityPrompt") and (prompt.Name == "PickupPet" or prompt.Name == "OpenFeedUI") then
					local model = prompt:FindFirstAncestorOfClass("Model")
					prompt.Enabled = model:GetAttribute("OwnerUserId") == player.UserId
						and not player:GetAttribute("RevivePanelOpen")
						and not (prompt.Name=="OpenFeedUI" and player:GetAttribute("FeedBusy"))
						and not (gui and (gui.Inventory.Visible or (gui:FindFirstChild("FeedPanel") and gui.FeedPanel.Visible)))
				end
			end
			task.wait(.2)
		end
	end)
end

return CarryController
