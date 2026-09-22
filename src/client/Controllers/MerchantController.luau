local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Prompts=game:GetService("ProximityPromptService")
local NumberFormat=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Controller={}

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
	local messages={TooFar="Move closer to the Mystery Merchant.",NotEnoughMoney="You need more Money.",
		Sold="You already bought this offer. Wait for restock.",
		Restocked="The merchant restocked. Refreshing…",Busy="Another purchase is saving.",
		StaleRequest="Shop state changed. Refreshing…",Loading="Loading your Money…",Cooldown="Please wait."}
	local function render()
		local remaining=state and state.RestocksAt-(state.ServerNow+os.clock()-receivedAt) or 0
		panel.Money.Text="YOUR MONEY: $"..(state and NumberFormat.Compact(state.Money) or "—")
		panel.Restock.Text="NEW STOCK IN "..clockText(remaining)
		for i=1,3 do
			local button=panel["Slot"..i];local item=state and state.Items[i]
			if item then
				button.Text=if item.Purchased then item.Name.."\n"..item.Description.."\nSOLD"
					else string.format("%s\n%s\nBUY • $%s",item.Name,item.Description,NumberFormat.Compact(item.Price))
				button.Active=not item.Purchased and not state.Busy and not busy
				button.AutoButtonColor=button.Active
				button.BackgroundColor3=if item.Purchased then Color3.fromRGB(91,87,102) else Color3.fromRGB(117,73,163)
			else button.Text="RESTOCKING…";button.Active=false end
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
		for _,name in {"EggUI","ReviveUI","DebugUI"} do local other=playerGui:FindFirstChild(name);if other then other.Panel.Visible=false end end
	end
	local function show()
		closeOthers();panel.Visible=true;panel.Status.Text="Basic always available • Special offers restock every 30 min";task.spawn(refresh)
	end
	Prompts.PromptTriggered:Connect(function(prompt,triggeringPlayer)
		if triggeringPlayer and triggeringPlayer~=player then return end
		if prompt.Name=="OpenMysteryMerchant" and prompt:IsDescendantOf(workspace:WaitForChild("MysteryMerchant")) then show() end
	end)
	for i=1,3 do
		panel["Slot"..i].Activated:Connect(function()
			local current=state;local item=current and current.Items[i]
			if busy or not item or item.Purchased or current.Busy then return end
			busy=true;render();panel.Status.Text="Buying…"
			local ok,result=pcall(function() return remote:InvokeServer("Purchase",i,current.RestockId,current.NextSequence) end)
			busy=false
			if ok and result.Ok then panel.Status.Text="Bought "..result.Name.."!" else panel.Status.Text=if ok then messages[result.Code] or "Purchase rejected." else "Reply lost. Refreshing before retry." end
			state=nil;refresh()
		end)
	end
	panel.Close.Activated:Connect(function() panel.Visible=false end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function() player:SetAttribute("MerchantPanelOpen",panel.Visible) end)
	local function resize()
		local size=gui.AbsoluteSize
		panel.UIScale.Scale=math.max(.1,math.min(1,(size.X-24)/560,(size.Y-24)/500))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize();render();task.spawn(refresh)
	task.spawn(function()
		while gui.Parent do
			local main=playerGui:FindFirstChild("FeedYourPetUI")
			if player:GetAttribute("EggPanelOpen") or player:GetAttribute("RevivePanelOpen") or player:GetAttribute("DebugPanelOpen")
				or (main and (main.Inventory.Visible or main.FeedPanel.Visible)) then panel.Visible=false end
			if panel.Visible or os.clock()-receivedAt>=5 then refresh() end
			task.wait(1)
		end
	end)
	return gui
end
return Controller
