local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local GuiService=game:GetService("GuiService")
local Config=require(ReplicatedStorage.Shared.Config.InventoryConfig)
local Model=require(script.Parent.Parent.UI.InventoryModel)
local Preview=require(script.Parent.Parent.UI.ItemPreview)
local Responsive=require(script.Parent.Parent.UI.InventoryLayout)
local numberText=require(ReplicatedStorage.Shared.NumberFormat).Compact
local Controller={}
local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six}
local errors={Busy="An action is saving. Please wait.",Farming="Jump out of the farm first.",
	HoldToPickup="Hold E beside your pet to pick it up.",CharacterUnavailable="Wait for your character to respawn.",
	AlreadyPlaced="Visit your egg in the Pen. Press E when it is ready.",Loading="Your collection is loading…",
	Cooldown="Please try again in a moment."}

function Controller.Start(gui,onSnapshot)
	local player=Players.LocalPlayer
	local modal=gui.Inventory
	local layout=modal.Panel.Layout
	local detail=layout.Details
	local bar=gui.Hotbar
	local remote=ReplicatedStorage:WaitForChild("PrototypeUI"):WaitForChild("Request")
	local eggRemote=ReplicatedStorage:WaitForChild("PrototypeEgg")
	local entries,slots,known,cards,buttons={},{},{},{},{}
	local selected,category,sort=nil,"All","Newest"
	local snapshot,busy=nil,false
	local noticeUntil=0
	local refresh,render
	modal.Visible=false
	task.spawn(function()
		for _=1,5 do
			if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end) then break end
			task.wait(1)
		end
	end)
	local function notice(text)
		layout.Status.Text=text;bar.Hint.Text=text;noticeUntil=os.clock()+4
	end
	local function otherModal()
		return gui.FeedPanel.Visible or player:GetAttribute("EggPanelOpen") or player:GetAttribute("RevivePanelOpen")
			or player:GetAttribute("MerchantPanelOpen") or player:GetAttribute("DebugPanelOpen")
	end
	local function show()
		gui.FeedPanel.Visible=false
		for _,name in {"EggUI","ReviveUI","MerchantUI","DebugUI"} do
			local other=player.PlayerGui:FindFirstChild(name)
			if other then other.Panel.Visible=false end
		end
		modal.Visible=true
		if Input.GamepadEnabled then GuiService.SelectedObject=layout.Close end
		task.spawn(refresh)
	end
	local function stateOf(entry)
		if player:GetAttribute(if entry.Kind=="Egg" then "CarriedEggUid" else "CarriedPetId")==entry.Id then return "HELD" end
		return if entry.State=="HELD" then "STORED" else entry.State
	end
	local function perform(entry,locking)
		if busy or not snapshot or snapshot.Busy or player:GetAttribute("FeedBusy") then notice(errors.Busy);return end
		if not entry then return end
		local state=stateOf(entry)
		if not locking and state~="STORED" and state~="HELD" then
			notice(if state=="FEED PLATE" then "Hold E at the plate; use Pick Up Pet in the Feed UI."
				elseif entry.Kind=="Egg" then "Visit your egg in the Pen. Press E when it is ready."
				else "Hold E beside your pet to pick it up.");return
		end
		busy=true;render()
		local target=if entry.Kind=="Egg" then eggRemote else remote
		local action=if locking then "SetLocked" elseif entry.Kind=="Egg" then (if state=="HELD" then "Unequip" else "Equip")
			else (if state=="HELD" then "UnequipPet" else "EquipPet")
		local ok,result=pcall(function() return target:InvokeServer(action,entry.Id,if locking then not entry.Locked else nil) end)
		if ok and result.Code=="Cooldown" then
			task.wait(.3)
			ok,result=pcall(function() return target:InvokeServer(action,entry.Id,if locking then not entry.Locked else nil) end)
		end
		busy=false
		if ok and result.Ok then
			if not locking and state~="HELD" then modal.Visible=false end
			notice(if locking then "Pet lock updated." elseif state=="HELD" then "Returned to your inventory." else "Click inside your Pen to place. Pets can also go on the feed plate.")
		else notice(if ok then errors[result.Code] or "Action unavailable. Refreshing your collection…" else "Connection interrupted. Refreshing your collection…") end
		refresh()
	end
	local function activateSlot(index)
		if modal.Visible or otherModal() or Input:GetFocusedTextBox() then return end
		local entry=entries[slots[index]]
		if entry then selected=entry.Key;task.spawn(perform,entry,false) else show();notice("Select an item, then choose ADD QUICK SLOT.") end
	end
	for i=1,Config.HotbarSlots do
		local button=bar["Slot"..i]
		buttons[i]=button
		button.Activated:Connect(function() activateSlot(i) end)
	end
	local function updateDetail()
		local entry=entries[selected]
		Preview.Set(detail.Preview,entry)
		detail.Equip.Visible=entry~=nil;detail.Pin.Visible=entry~=nil;detail.Lock.Visible=entry~=nil and entry.Kind=="Pet"
		if not entry then detail.ItemName.Text="SELECT A PET";detail.Stats.Text="Tap a card to see its stats.";return end
		local state=stateOf(entry)
		detail.ItemName.Text=entry.Name
		detail.Stats.Text=if entry.Kind=="Pet" then string.format("%s • LEVEL %s\n%s Money / sec\n%s%s",entry.Rarity,numberText(entry.Level),numberText(entry.Income),state,if entry.Locked then " • LOCKED" else "")
			else "EGG • "..state.."\n"..(if state=="INCUBATING" then numberText(math.max(0,entry.ReadyAt-snapshot.ServerNow)).."s remaining"
				elseif state=="READY" then "Press E beside your egg to hatch."
				else "Hold, then click inside your Pen.")
		detail.Equip.ButtonText.Text=if state=="HELD" then "PUT AWAY" elseif state=="STORED" then "HOLD "..string.upper(entry.Kind)
			elseif entry.Kind=="Egg" then "HATCH AT YOUR PEN" elseif state=="FEED PLATE" then "PICK UP AT PLATE" else "PICK UP IN PEN"
		detail.Lock.ButtonText.Text=if entry.Locked then "UNLOCK" else "LOCK"
		detail.Pin.ButtonText.Text=if Model.SlotOf(slots,entry.Key) then "UNPIN" else "QUICK SLOT"
		detail.Equip.Active=not busy and not snapshot.Busy;detail.Lock.Active=not busy and not snapshot.Busy
		detail.Equip.ImageColor3=if busy or snapshot.Busy then Color3.fromRGB(147,136,164) else Color3.fromRGB(112,219,89)
		detail.Equip.BackgroundColor3=detail.Equip.ImageColor3
	end
	render=function()
		local visible=Model.Filter(entries,category,layout.Search.Text,sort)
		local shown={}
		for index,entry in visible do
			local card=cards[entry.Key]
			if not card then
				card=layout.Pets.PetCardTemplate:Clone();card.Name=entry.Key;card.Parent=layout.Pets;cards[entry.Key]=card
				card.Activated:Connect(function() selected=entry.Key;render() end)
			end
			shown[entry.Key]=true;card.Visible=true;card.LayoutOrder=index
			local tint=Config.RarityColors[entry.Rarity] or Config.RarityColors.Common
			card.RarityStripe.BackgroundColor3=tint
			card.Stroke.Color=if selected==entry.Key then Color3.fromRGB(255,210,96) else tint:Lerp(Color3.new(),.6)
			card.Stroke.Thickness=if selected==entry.Key then 4 else 3
			card.ImageColor3=if selected==entry.Key then Color3.fromRGB(255,210,96) else tint
			card.BackgroundColor3=card.ImageColor3
			card.ItemName.Text=entry.Name;card.Stats.Text=if entry.Kind=="Pet" then "Lv. "..numberText(entry.Level).." • "..numberText(entry.Income).."/s" else "EGG"
			card.State.Text=stateOf(entry)..(if entry.Locked then " • LOCKED" else "");card.LockMark.Text=""
			Preview.Set(card.Preview,entry)
		end
		for key,card in cards do
			if not entries[key] then card:Destroy();cards[key]=nil else card.Visible=shown[key]==true end
		end
		layout.EmptyState.Visible=#visible==0
		layout.EmptyState.Text=if not snapshot then "Loading your collection…" elseif next(entries)==nil then "Your collection starts with an egg.\nVisit the conveyor to get one." else "No matches. Try another name or category."
		local count=0;for _ in entries do count+=1 end
		layout.Title.Text="MY PETS  •  "..numberText(count)
		layout.PenSlots.Text=if snapshot then string.format("PEN %d / %d",snapshot.PlacedCount,snapshot.MaxPetSlots) else "PEN —"
		layout.Sort.ButtonText.Text="SORT: "..string.upper(sort)
		for _,name in {"All","Pet","Egg"} do
			layout[name].ImageColor3=if category==name then Color3.fromRGB(255,195,55) else Color3.fromRGB(111,172,241)
			layout[name].BackgroundColor3=layout[name].ImageColor3
			layout[name].ButtonText.TextColor3=Color3.new(1,1,1)
		end
		for i,button in buttons do
			local entry=entries[slots[i]]
			local held=entry and stateOf(entry)=="HELD"
			button.Stroke.Color=if held then Color3.fromRGB(255,211,112) else Color3.fromRGB(150,150,164)
			button.Stroke.Thickness=if held then 3 else 1
			button.BackgroundTransparency=if held then .12 else .38
			button.ItemName.Text=entry and entry.Name or "Empty"
			button.State.Text=if held then "HELD" elseif entry and entry.State~="STORED" then "PLACED" else ""
			button.Active=not busy;Preview.Set(button.Preview,entry)
		end
		updateDetail()
		Responsive.Apply(gui,cards,buttons)
		if os.clock()>noticeUntil then
			layout.Status.Text="Select a pet • Hold to carry • Pin to your hotbar"
			bar.Hint.Text=if Input.TouchEnabled then "Tap a slot to hold • BAG opens inventory" else "1–6 to hold • B for inventory"
		end
	end
	refresh=function()
		if busy then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
		busy=false
		if ok and result.Ok then
			snapshot=result;entries=Model.Entries(result);Model.Reconcile(slots,known,entries)
			if selected and not entries[selected] then selected=nil end
			onSnapshot(result)
		elseif not ok or result.Code~="Cooldown" then notice("Unable to refresh. Reconnecting…") end
		render()
	end
	local function toggle() if modal.Visible then modal.Visible=false else show() end end
	gui.HUD.OpenInventory.ButtonText.Text="INVENTORY"
	gui.HUD.OpenInventory.Activated:Connect(toggle);bar.Bag.Activated:Connect(toggle)
	layout.Close.Activated:Connect(function() modal.Visible=false end)
	modal:GetPropertyChangedSignal("Visible"):Connect(function()
		player:SetAttribute("InventoryPanelOpen",modal.Visible)
		bar.Visible=not modal.Visible and not otherModal()
		if not modal.Visible and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(modal) then GuiService.SelectedObject=nil end
	end)
	for _,name in {"All","Pet","Egg"} do layout[name].Activated:Connect(function() category=name;layout.Pets.CanvasPosition=Vector2.zero;render() end) end
	layout.Search:GetPropertyChangedSignal("Text"):Connect(function() layout.Pets.CanvasPosition=Vector2.zero;render() end)
	local sorts={"Newest","Income","Level","Rarity"}
	layout.Sort.Activated:Connect(function() sort=sorts[(table.find(sorts,sort)%#sorts)+1];render() end)
	detail.Equip.Activated:Connect(function() task.spawn(perform,entries[selected],false) end)
	detail.Lock.Activated:Connect(function() local entry=entries[selected];if entry and entry.Kind=="Pet" then task.spawn(perform,entry,true) end end)
	detail.Pin.Activated:Connect(function()
		if not entries[selected] then return end
		if not Model.TogglePin(slots,selected) then notice("All six slots are full. Remove another quick slot first.") end
		render()
	end)
	Input.InputBegan:Connect(function(input,processed)
		if Input:GetFocusedTextBox() then return end
		if input.KeyCode==Enum.KeyCode.ButtonB and modal.Visible then modal.Visible=false;return end
		if processed then return end
		if input.KeyCode==Enum.KeyCode.B or input.KeyCode==Enum.KeyCode.Backquote or input.KeyCode==Enum.KeyCode.ButtonY then toggle()
		elseif input.KeyCode==Enum.KeyCode.Escape then modal.Visible=false
		else local index=table.find(keys,input.KeyCode);if index then activateSlot(index) end end
	end)
	for _,attribute in {"CarriedPetId","CarriedEggUid"} do player:GetAttributeChangedSignal(attribute):Connect(function() render();task.defer(refresh) end) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() Responsive.Apply(gui,cards,buttons) end)
	render()
	task.spawn(function()
		while gui.Parent do
			bar.Visible=not modal.Visible and not otherModal()
			refresh();task.wait(Config.PollSeconds)
		end
	end)
	return {Refresh=refresh,Render=render,Show=show,Slots=slots,ActivateSlot=activateSlot}
end
return Controller
