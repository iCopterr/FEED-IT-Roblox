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
	local lastMoneyAt,lastFoodAt=-math.huge,-math.huge
	local function money(state)
		local timestamp=state.MoneyAt or 0
		if timestamp<lastMoneyAt then return end
		lastMoneyAt=timestamp
		hud.Money.Value.Text=string.format(Config.Text.Money,numberText(state.Money),numberText(state.IncomePerSecond or 0))
	end
	local function food(state)
		local timestamp=state.FoodAt or 0
		if timestamp<lastFoodAt then return end
		lastFoodAt=timestamp
		hud.Food.Value.Text=string.format(Config.Text.Food,numberText(state.Food))
	end
	for _,name in {"PetIncome","FarmUpgradeChanged","FeedPlateUpgradeChanged","ConveyorPurchaseChanged"} do
		ReplicatedStorage:WaitForChild(name).OnClientEvent:Connect(money)
	end
	for _,name in {"Farm","FeedFoodChanged"} do ReplicatedStorage:WaitForChild(name).OnClientEvent:Connect(food) end
	local function resize() hud.UIScale.Scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-20)/1000)) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
	require(script.Parent.InventoryController).Start(gui,function(state) money(state);food(state) end)
	return gui
end
return Controller
