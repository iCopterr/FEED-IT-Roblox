local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config.UIConfig)
local GuiBootstrap=require(script.Parent.Parent.UI.GuiBootstrap)
local numberText=require(ReplicatedStorage.Shared.NumberFormat).Compact
local Controller={}

function Controller.Start()
	local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui",10)
	assert(playerGui,"PlayerGui did not become available")
	local gui=playerGui:WaitForChild("FeedYourPetUI",3)
	if not gui then gui=GuiBootstrap.Ensure(playerGui,game.StarterGui:WaitForChild("FeedYourPetUI",3)) end
	local hud=gui.HUD
	local travelBusy=false
	for _,destination in {"Base","Merchant"} do
		local button=hud.Travel[destination]
		button.Activated:Connect(function()
			if travelBusy then return end
			travelBusy=true
			button.ButtonText.Text=string.upper(destination)
			local ok,result=pcall(function()
				local remote=ReplicatedStorage:WaitForChild("PrototypeTravel",5)
				assert(remote,"Travel service unavailable")
				return remote:InvokeServer(destination)
			end)
			if ok and result.Ok then
				gui.Inventory.Visible=false;gui.FeedPanel.Visible=false
				for _,name in {"EggUI","MerchantUI","ReviveUI","DebugUI"} do
					local other=playerGui:FindFirstChild(name)
					if other then other.Panel.Visible=false end
				end
			else
				button.ButtonText.Text=if ok and result.Code=="Cooldown" then "WAIT…" else "TRY AGAIN"
				task.delay(.6,function() button.ButtonText.Text=string.upper(destination) end)
			end
			travelBusy=false
		end)
	end
	local lastMoneyAt,lastFoodAt=-math.huge,-math.huge
	local function money(state)
		local timestamp=state.MoneyAt or 0
		if timestamp<lastMoneyAt then return end
		lastMoneyAt=timestamp
		hud.Money.Value.Text=string.format(Config.Text.Money,numberText(state.Money))
	end
	local function food(state)
		local timestamp=state.FoodAt or 0
		if timestamp<lastFoodAt then return end
		lastFoodAt=timestamp
		hud.Food.Value.Text=string.format(Config.Text.Food,numberText(state.Food))
	end
	for _,name in {"PetIncome","FeedPlateUpgradeChanged","ConveyorPurchaseChanged"} do
		ReplicatedStorage:WaitForChild(name).OnClientEvent:Connect(money)
	end
	for _,name in {"FeedFoodChanged"} do ReplicatedStorage:WaitForChild(name).OnClientEvent:Connect(food) end
	local function resize()
		local size=gui.AbsoluteSize
		local narrow=size.X<760
		local scale=if narrow then .68 else math.min(1,size.Y/650)
		hud.UIScale.Scale=1
		-- Keep currency above the mobile hotbar/touch-control area.
		local bottom=if narrow then math.min(190,size.Y*.35) else 22
		hud.Money.Position=UDim2.new(0,18,1,-bottom)
		hud.Food.Position=UDim2.new(0,18,1,-bottom-66*scale)
		hud.Money.UIScale.Scale=scale;hud.Food.UIScale.Scale=scale
		hud.Travel.UIScale.Scale=math.min(1,(size.X-24)/540)
		-- Keep the existing inventory button separate on smaller displays.
		hud.OpenInventory.Position=UDim2.new(1,-18,0,if size.X<1020 then 110*hud.Travel.UIScale.Scale else 12)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
	require(script.Parent.InventoryController).Start(gui,function(state) money(state);food(state) end)
	return gui
end
return Controller
