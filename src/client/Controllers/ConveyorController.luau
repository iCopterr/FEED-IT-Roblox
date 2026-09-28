local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.Config.ConveyorConfig)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local gui=playerGui:WaitForChild("ConveyorUI",3)
	if not gui then gui=game.StarterGui:WaitForChild("ConveyorUI"):Clone();gui.Parent=playerGui end
	local remote=game.ReplicatedStorage:WaitForChild("BuyConveyorEgg")
	local conveyor=workspace:WaitForChild("PetConveyor")
	local offers=conveyor:WaitForChild("Offers")
	local busy=false
	local messageToken=0
	local messages={NotEnoughMoney="Not enough Money for this egg.",Unavailable="That egg was bought or reached the end.",
		TooFar="Move closer to the egg.",Saving="",Busy="",Loading="",Cooldown=""}
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt,triggeringPlayer)
		if triggeringPlayer and triggeringPlayer~=player then return end
		if busy or prompt.Name~="BuyConveyorEgg" then return end
		local model=prompt:FindFirstAncestorOfClass("Model")
		if not model or model.Parent~=offers then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer(model:GetAttribute("OfferId")) end)
		busy=false
		messageToken+=1;local token=messageToken
		gui.Message.Text=if ok and result.Ok then "Egg bought! It is in your inventory."
			else if ok then messages[result.Code] or "Purchase rejected. No egg bought."
			else "Connection interrupted. Check your inventory before trying again."
		gui.Message.Visible=gui.Message.Text~=""
		task.delay(3,function() if token==messageToken then gui.Message.Visible=false end end)
	end)
	local treads={}
	for _,part in conveyor.Treads:GetChildren() do treads[part]=conveyor.Deck.CFrame:ToObjectSpace(part.CFrame) end
	local connection
	connection=RunService.RenderStepped:Connect(function()
		if not conveyor.Parent then connection:Disconnect();return end
		local now=workspace:GetServerTimeNow()
		-- Local interpolation only; server calculates purchase range and expiry.
		for _,model in offers:GetChildren() do
			local from,to,start=model:GetAttribute("From"),model:GetAttribute("To"),model:GetAttribute("StartedAt")
			if from and to and start then model:PivotTo(from:Lerp(to,math.clamp((now-start)/Config.TravelSeconds,0,1))) end
			local prompt=model:FindFirstChild("BuyConveyorEgg",true)
			local modal=playerGui:FindFirstChild("FeedYourPetUI")
			if prompt then prompt.Enabled=not busy and not player:GetAttribute("DebugPanelOpen") and not player:GetAttribute("RevivePanelOpen") and not player:GetAttribute("MerchantPanelOpen") and not player:GetAttribute("IndexPanelOpen") and not (modal and (modal.Inventory.Visible or modal.FeedPanel.Visible)) end
		end
		local length=conveyor.Deck.Size.Z
		local travel=now*(conveyor.Finish.Position-conveyor.Start.Position).Magnitude/Config.TravelSeconds
		for part,initial in treads do
			if part.Parent then
				local z=(initial.Z+travel+length/2)%length-length/2
				part.CFrame=conveyor.Deck.CFrame*CFrame.new(initial.X,initial.Y,z)*initial.Rotation
			end
		end
	end)
end
return Controller
