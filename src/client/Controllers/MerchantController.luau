local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Prompts=game:GetService("ProximityPromptService")
local NumberFormat=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Shop=require(ReplicatedStorage.Shared.Config.MerchantConfig)
local Monetization=require(ReplicatedStorage.Shared.Config.MonetizationConfig)
local Purchases=require(script.Parent.Parent.UI.Purchases)
local RarityColors=require(ReplicatedStorage.Shared.Config.InventoryConfig).RarityColors
local Controller={}
local Sounds=require(script.Parent.Parent.Audio.GameSounds)
local Images=require(script.Parent.Parent.UI.IconImages)
local Art=require(script.Parent.Parent.UI.ImageArt)
local foodOrder={}
for index,id in Shop.ItemOrder do foodOrder[id]=index end

local function clockText(seconds)
	seconds=math.max(0,math.ceil(seconds))
	return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end

function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	-- Wait for Roblox's initial StarterGui copy. An early fallback clone can be
	-- replaced by that copy, leaving the controller bound to a detached screen.
	local gui=assert(playerGui:WaitForChild("MerchantUI",30),"MerchantUI missing; check Rojo")
	local panel=gui.Panel
	local state,receivedAt,busy=nil,0,false
	panel.RestockBuy.Active=true
	panel.RestockBuy.ButtonText.Text="REFILL STOCK • "..Monetization.PersonalRestockRobux.." ROBUX"
	panel.RestockBuy:SetAttribute("SuppressClickSound",true)
	panel.RestockBuy.Activated:Connect(function()
		if state then Purchases.Request("Restock",state.RestockId) end
	end)
	local remote=ReplicatedStorage:WaitForChild("PrototypeMerchant")
	local displayed={}
	local robuxStyles={}
	for i=1,3 do
		local buy=panel.Offers["Slot"..i].BuyRobux
		robuxStyles[i]={Background=buy.BackgroundColor3,Image=buy.ImageColor3}
	end
	local pending={}
	local processing=false
	local messages={TutorialBuyEgg="Buy your first Basic Egg before buying food.",TooFar="Move closer to the Mystery Merchant.",NotEnoughMoney="You need more Money.",
		Sold="This food is sold out for you. Wait for restock.",
		Restocked="",Busy="",StaleRequest="",Loading="",Cooldown=""}
	local function render()
		local policyStatus=player:GetAttribute("PaidRandomPolicyStatus")
		local remaining=state and state.RestocksAt-(state.ServerNow+os.clock()-receivedAt) or 0
		panel.Money.Text="YOUR $"..(state and NumberFormat.Money(state.Money) or "—")
		panel.Restock.Text="NEW FOOD IN "..clockText(remaining)
		local items={}
		if state then
			for _,item in state.Items do table.insert(items,item) end
			table.sort(items,function(a,b)
				return (foodOrder[a.ItemId] or math.huge)<(foodOrder[b.ItemId] or math.huge)
			end)
		end
		for i=1,3 do
			local button=panel.Offers["Slot"..i];local item=items[i]
			displayed[i]=item
			if item then
				local definition=Shop.Items[item.ItemId]
				button.ItemName.Text=item.Name
				button.Stock.Text=string.format("X%d stock",item.Remaining)
				button.RarityBadge.Visible=true
				button.RarityBadge.ButtonText.Text=definition.Rarity
				button.RarityBadge.ImageColor3=RarityColors[definition.Rarity]
				button.RarityBadge.BackgroundColor3=RarityColors[definition.Rarity]
				button.Price.Text="$"..NumberFormat.Money(item.Price)
				button.Effect.Text=definition.Effect
				button.Art.Emoji.Text=definition.Icon
				Art.Set(button.Art.Picture,button.Art.Emoji,Images[item.ItemId] or Images.empty)
				button.Active=false;button.AutoButtonColor=false
				button.BuyMoney.Active=not item.Purchased
				button.BuyMoney.ButtonText.Text=if item.Purchased then "SOLD OUT" else "$"..NumberFormat.Money(item.Price)
				button.BuyMoney.ImageColor3=if item.Purchased then Color3.fromRGB(100,100,108) else Color3.fromRGB(78,227,51)
				button.BuyMoney.BackgroundColor3=button.BuyMoney.ImageColor3
				button.BackgroundColor3=if item.Purchased then Color3.fromRGB(62,65,73) else Color3.fromRGB(77,49,37)
				button.Price.TextColor3=if item.Purchased then Color3.fromRGB(175,175,185) else Color3.fromRGB(86,255,74)
			else
				button.ItemName.Text="RESTOCKING…";button.Stock.Text=""
				button.RarityBadge.Visible=false
				button.Price.Text="—";button.Effect.Text="FOOD";button.Art.Emoji.Text="🍽️"
				Art.Set(button.Art.Picture,button.Art.Emoji,Images.empty)
				button.Active=false;button.BackgroundColor3=Color3.fromRGB(62,65,73)
				button.BuyMoney.Active=false;button.BuyMoney.ButtonText.Text="—"
			end
			local product=item and Monetization.FoodProducts[item.ItemId]
			local needsPolicy=item and item.ItemId~="revive"
			local policyAllowed=not needsPolicy or policyStatus=="Allowed"
			local robuxEnabled=product~=nil and not item.Purchased and policyAllowed
			button.BuyRobux.Active=robuxEnabled
			button.BuyRobux.Interactable=robuxEnabled
			button.BuyRobux.AutoButtonColor=robuxEnabled
			button.BuyRobux.ButtonText.Text=if not product then "MONEY ONLY"
				elseif item.Purchased then "SOLD OUT"
				elseif not policyAllowed then (if policyStatus=="Loading" or policyStatus==nil then "CHECKING…" else "UNAVAILABLE")
				else product.Robux.." ROBUX"
			local style=robuxStyles[i]
			button.BuyRobux.ImageColor3=if robuxEnabled then style.Image else Color3.fromRGB(100,100,108)
			button.BuyRobux.BackgroundColor3=if robuxEnabled then style.Background else Color3.fromRGB(100,100,108)
		end
	end
	player:GetAttributeChangedSignal("PaidRandomPolicyStatus"):Connect(render)
	local function refresh()
		if busy then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
		busy=false
		if ok and result.Ok then state=result;receivedAt=os.clock()
		elseif not ok or result.Code~="Cooldown" then panel.Status.Text=if ok then messages[result.Code] or "Unable to load merchant." else "Connection interrupted." end
		render()
	end
	-- One worker serializes clicks; the server remains authoritative for stock,
	-- sequences, affordability and durable-save locks. Never retry a lost reply.
	local function drain()
		if processing then return end
		processing=true
		while #pending>0 and panel.Visible and gui.Parent do
			local request=pending[1]
			if os.clock()>request.Expires then table.remove(pending,1);continue end
			if busy then task.wait(.1);continue end
			local current=state
			if not current or current.Busy then refresh();task.wait(.3);continue end
			local item
			for _,offer in current.Items do if offer.Slot==request.Slot then item=offer;break end end
			if current.RestockId~=request.RestockId or not item or item.ItemId~=request.ItemId or item.Purchased then
				table.remove(pending,1);continue
			end
			busy=true
			local ok,result=pcall(function() return remote:InvokeServer("Purchase",item.Slot,current.RestockId,current.NextSequence) end)
			busy=false
			if ok then Sounds.PurchaseResult(result) end
			if not ok then
				table.clear(pending);panel.Status.Text="Connection interrupted. Check your inventory.";refresh();break
			elseif result.Ok then
				if pending[1]==request then table.remove(pending,1) end
				current.NextSequence=result.NextSequence;current.Money=result.Money
				item.Remaining=result.Remaining;item.Purchased=result.Remaining<=0
				current.Busy=true;panel.Status.Text="";render()
			elseif result.Code~="Busy" and result.Code~="Cooldown" then
				table.clear(pending);panel.Status.Text=messages[result.Code] or "Purchase unavailable."
			end
			task.wait(Shop.RequestCooldown+.05);refresh()
		end
		table.clear(pending);processing=false
	end
	local function closeOthers()
		local main=playerGui:FindFirstChild("FeedYourPetUI")
		if main then main.Inventory.Visible=false;main.FeedPanel.Visible=false end
		for _,name in {"ReviveUI","DebugUI"} do local other=playerGui:FindFirstChild(name);if other then other.Panel.Visible=false end end
	end
	local function show()
		closeOthers();panel.Visible=true;panel.Status.Text="";task.spawn(refresh)
	end
	Prompts.PromptTriggered:Connect(function(prompt,triggeringPlayer)
		if triggeringPlayer and triggeringPlayer~=player then return end
		if prompt.Name=="OpenMysteryMerchant" and prompt:IsDescendantOf(workspace:WaitForChild("MysteryMerchant")) then show() end
	end)
	for i=1,3 do
		panel.Offers["Slot"..i]:SetAttribute("SuppressClickSound",true)
		panel.Offers["Slot"..i].BuyMoney:SetAttribute("SuppressClickSound",true)
		panel.Offers["Slot"..i].BuyRobux:SetAttribute("SuppressClickSound",true)
		panel.Offers["Slot"..i].BuyRobux.Activated:Connect(function()
			local item=displayed[i]
			local policyAllowed=item and (item.ItemId=="revive" or player:GetAttribute("PaidRandomPolicyStatus")=="Allowed")
			if state and item and policyAllowed and not item.Purchased and Monetization.FoodProducts[item.ItemId] then
				Purchases.Request("Food",item.Slot,state.RestockId)
			end
		end)
		panel.Offers["Slot"..i].BuyMoney.Activated:Connect(function()
			local current=state;local item=displayed[i]
			if not current or not item or item.Purchased or not panel.Visible or #pending>=20 then return end
			local count=0
			for _,request in pending do if request.Slot==item.Slot then count+=1 end end
			if count>=item.Remaining then return end
			table.insert(pending,{Slot=item.Slot,ItemId=item.ItemId,RestockId=current.RestockId,Expires=os.clock()+15})
			task.spawn(drain)
		end)
	end
	panel.Close.Activated:Connect(function() require(script.Parent.Parent.UI.Motion).Close(panel) end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		player:SetAttribute("MerchantPanelOpen",panel.Visible)
		if not panel.Visible then table.clear(pending) end
	end)
	local function resize()
		local size=gui.AbsoluteSize
		require(script.Parent.Parent.UI.DeviceLayout).Apply(panel,size,"Merchant")
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize();render();task.spawn(refresh)
	task.spawn(function()
		while gui.Parent do
			local main=playerGui:FindFirstChild("FeedYourPetUI")
			if player:GetAttribute("RevivePanelOpen") or player:GetAttribute("DebugPanelOpen")
				or (main and (main.Inventory.Visible or main.FeedPanel.Visible)) then panel.Visible=false end
			if panel.Visible or os.clock()-receivedAt>=5 then refresh() end
			task.wait(1)
		end
	end)
	return gui
end
return Controller
