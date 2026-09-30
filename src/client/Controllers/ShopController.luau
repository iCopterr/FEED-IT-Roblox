local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Config=require(game.ReplicatedStorage.Shared.Config.MonetizationConfig)
local Numbers=require(game.ReplicatedStorage.Shared.NumberFormat)
local Motion=require(script.Parent.Parent.UI.Motion)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local pg=player:WaitForChild("PlayerGui")
	local gui=assert(pg:WaitForChild("ShopUI",30),"ShopUI missing")
	local panel=gui.Panel
	local others={}
	local function price(card,value)
		card.Buy.ButtonText.Text=tostring(value).." ROBUX • SOON"
		-- IDs alone must never enable purchases before durable receipt fulfillment exists.
		card.Buy.Active=false;card.Buy.AutoButtonColor=false
	end
	price(panel.Offers.Welcome,Config.WelcomePack.Robux)
	price(panel.Offers.DoubleMoney,Config.DoubleMoney.Robux)
	for i,pack in Config.MoneyPacks do
		local card=panel.Offers["Money"..i]
		card.Title.Text="$"..Numbers.Money(pack.Money)
		price(card,pack.Robux)
	end
	gui.Open.Activated:Connect(function()
		if panel.Visible then Motion.Close(panel);return end
		for other in others do if other.Parent then other.Visible=false end end
		panel.Visible=true
	end)
	panel.Close.Activated:Connect(function() Motion.Close(panel) end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function() player:SetAttribute("ShopPanelOpen",panel.Visible) end)
	player:SetAttribute("ShopPanelOpen",false)
	Input.InputBegan:Connect(function(key,processed)
		if not processed and key.KeyCode==Enum.KeyCode.Escape and panel.Visible then Motion.Close(panel) end
	end)
	local function watch(other)
		others[other]=true
		other:GetPropertyChangedSignal("Visible"):Connect(function() if other.Visible then panel.Visible=false end end)
	end
	for _,name in {"FeedYourPetUI","MerchantUI","ReviveUI","DebugUI","IndexUI","PenManagerUI"} do
		task.spawn(function()
			local other=pg:WaitForChild(name,30);if not other then return end
			if name=="FeedYourPetUI" then watch(other.Inventory);watch(other.FeedPanel)
			elseif name=="PenManagerUI" then
				for _,child in other:GetChildren() do if child:IsA("Frame") and child.Name~="Dock" then watch(child) end end
			else watch(other.Panel) end
		end)
	end
	Motion.BindPopup(panel);Motion.BindButton(gui.Open,gui.Open);Motion.BindButton(panel.Close,panel)
	local function resize()
		local size=gui.AbsoluteSize
		panel.UIScale.Scale=math.max(.1,math.min(1,(size.X-24)/880,(size.Y-24)/620))
		local scale=if size.X<760 then .7 else math.min(1,size.Y/650)
		gui.Open.UIScale.Scale=scale
		gui.Open.Position=UDim2.new(0,18,.5,-76*scale)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
end
return Controller
