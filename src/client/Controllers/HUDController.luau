local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config.UIConfig)
local GuiBootstrap=require(script.Parent.Parent.UI.GuiBootstrap)
local Motion=require(script.Parent.Parent.UI.Motion)
local numberText=require(ReplicatedStorage.Shared.NumberFormat).Money
local Controller={}

function Controller.Start()
	local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui",10)
	assert(playerGui,"PlayerGui did not become available")
	local gui=playerGui:WaitForChild("FeedYourPetUI",3)
	if not gui then gui=GuiBootstrap.Ensure(playerGui,game.StarterGui:WaitForChild("FeedYourPetUI",3)) end
	local hud=gui.HUD
	Motion.BindButton(hud.OpenInventory,hud)
	local travelBusy=false
	for _,destination in {"Base","Merchant"} do
		local button=hud.Travel[destination]
		Motion.BindButton(button,hud.Travel)
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
				for _,name in {"MerchantUI","ReviveUI","DebugUI","IndexUI"} do
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
	local lastMoneyAt=-math.huge
	local function money(state)
		local timestamp=state.MoneyAt or 0
		if timestamp<lastMoneyAt then return end
		lastMoneyAt=timestamp
		hud.Money.Value.Text=string.format(Config.Text.Money,numberText(state.Money))
	end
	for _,name in {"PetIncome","ConveyorPurchaseChanged","PlotUpgradeChanged"} do
		ReplicatedStorage:WaitForChild(name).OnClientEvent:Connect(money)
	end
	local function resize()
		local size=gui.AbsoluteSize
		local narrow=size.X<760
		local scale=if narrow then .68 else math.min(1,size.Y/650)
		hud.UIScale.Scale=1
		-- Keep currency above the mobile hotbar/touch-control area.
		local bottom=if narrow then math.min(190,size.Y*.35) else 22
		hud.Money.Position=UDim2.new(0,18,1,-bottom)
		hud.Money.UIScale.Scale=scale
		hud.Travel.UIScale.Scale=math.min(1,(size.X-24)/540)
		-- Keep the existing inventory button separate on smaller displays.
		hud.OpenInventory.Position=UDim2.new(1,-18,0,if size.X<1020 then 110*hud.Travel.UIScale.Scale else 12)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
	require(script.Parent.InventoryController).Start(gui,money)
	return gui
end
return Controller
