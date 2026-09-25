local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Prompts=game:GetService("ProximityPromptService")
local NumberFormat=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Foods=require(ReplicatedStorage.Shared.Config.FoodConfig)
local Controller={}
local foodOrder={}
for index,id in Foods.Order do foodOrder[id]=index end

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
	local remote=ReplicatedStorage:WaitForChild("PrototypeMerchant")
	local state,receivedAt,busy=nil,0,false
	local displayed={}
	local messages={TooFar="Move closer to the Mystery Merchant.",NotEnoughMoney="You need more Money.",
		Sold="This food is sold out for you. Wait for restock.",
		Restocked="The merchant restocked. Refreshing…",Busy="Another purchase is saving.",
		StaleRequest="Shop state changed. Refreshing…",Loading="Loading your Money…",Cooldown="Please wait."}
	local function render()
		local remaining=state and state.RestocksAt-(state.ServerNow+os.clock()-receivedAt) or 0
		panel.Money.Text="YOUR $"..(state and NumberFormat.Compact(state.Money) or "—")
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
				local food=Foods.Types[item.ItemId]
				button.ItemName.Text=item.Name
				button.Stock.Text=if item.Purchased then "SOLD OUT"
					else string.format("×%d FOOD  •  %d/%d STOCK",item.Amount,item.Remaining,item.StockLimit)
				button.Price.Text="$"..NumberFormat.Compact(item.Price)
				button.Effect.Text=string.format("-%d%% RISK",math.round(food.Reduction*100))
				button.Art.Emoji.Text=food.Icon
				button.Art.Emoji.Visible=button.Art.Picture.Image==""
				button.Active=not item.Purchased and not state.Busy and not busy
				button.AutoButtonColor=button.Active
				button.BackgroundColor3=if item.Purchased then Color3.fromRGB(62,65,73) else Color3.fromRGB(77,49,37)
				button.Price.TextColor3=if item.Purchased then Color3.fromRGB(175,175,185) else Color3.fromRGB(86,255,74)
				button.Effect.BackgroundColor3=if item.Purchased then Color3.fromRGB(100,100,108) else Color3.fromRGB(74,132,211)
			else
				button.ItemName.Text="RESTOCKING…";button.Stock.Text="Please wait"
				button.Price.Text="—";button.Effect.Text="FOOD";button.Art.Emoji.Text="🍽️"
				button.Active=false;button.BackgroundColor3=Color3.fromRGB(62,65,73)
			end
		end
	end
	local function refresh()
		if busy then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
		busy=false
		if ok and result.Ok then state=result;receivedAt=os.clock()
		elseif not ok or result.Code~="Cooldown" then state=nil;panel.Status.Text=if ok then messages[result.Code] or "Unable to load merchant." else "Connection interrupted." end
		render()
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
		panel.Offers["Slot"..i].Activated:Connect(function()
			local current=state;local item=displayed[i]
			if busy or not item or item.Purchased or current.Busy then return end
			busy=true;render();panel.Status.Text="Buying…"
			local ok,result=pcall(function() return remote:InvokeServer("Purchase",item.Slot,current.RestockId,current.NextSequence) end)
			busy=false
			if ok and result.Ok then panel.Status.Text="Bought "..result.Name.."!" else panel.Status.Text=if ok then messages[result.Code] or "Purchase rejected." else "Reply lost. Refreshing before retry." end
			state=nil;refresh()
		end)
	end
	panel.Close.Activated:Connect(function() require(script.Parent.Parent.UI.Motion).Close(panel) end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function() player:SetAttribute("MerchantPanelOpen",panel.Visible) end)
	local function resize()
		local size=gui.AbsoluteSize
		panel.UIScale.Scale=math.max(.1,math.min(1,(size.X-24)/540,(size.Y-24)/510))
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
