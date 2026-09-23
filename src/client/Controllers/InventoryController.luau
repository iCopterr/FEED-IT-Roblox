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
local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven,Enum.KeyCode.Eight,Enum.KeyCode.Nine,Enum.KeyCode.Zero}
local errors={Busy="An action is saving. Please wait.",
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
	local refreshing=false
	local revision=0
	local noticeUntil=0
	local refresh,render
	modal.Visible=false
	local savedNavigation,savedAutoSelect
	local function updateNavigation()
		local gamepad=string.match(Input:GetLastInputType().Name,"^Gamepad")~=nil
		if modal.Visible and not gamepad then
			if savedNavigation==nil then
				savedNavigation=GuiService.GuiNavigationEnabled
				savedAutoSelect=GuiService.AutoSelectGuiEnabled
			end
			GuiService.GuiNavigationEnabled=false
			GuiService.AutoSelectGuiEnabled=false
			GuiService.SelectedObject=nil
		else
			if savedNavigation~=nil then
				GuiService.GuiNavigationEnabled=savedNavigation
				GuiService.AutoSelectGuiEnabled=savedAutoSelect
				savedNavigation,savedAutoSelect=nil,nil
			end
			if modal.Visible and gamepad and not GuiService.SelectedObject then GuiService.SelectedObject=layout.Close end
		end
	end
	Input.LastInputTypeChanged:Connect(updateNavigation)
	task.spawn(function()
		for _=1,5 do
			if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end) then break end
			task.wait(1)
		end
	end)
	local function notice(text)
		layout.Status.Text=text;noticeUntil=os.clock()+4
	end
	local function otherModal()
		return gui.FeedPanel.Visible or player:GetAttribute("RevivePanelOpen")
			or player:GetAttribute("MerchantPanelOpen") or player:GetAttribute("DebugPanelOpen")
	end
	local function show()
		gui.FeedPanel.Visible=false
		for _,name in {"ReviveUI","MerchantUI","DebugUI"} do
			local other=player.PlayerGui:FindFirstChild(name)
			if other then other.Panel.Visible=false end
		end
		modal.Visible=true
		updateNavigation()
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
		revision+=1
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
		revision+=1
		if ok and result.Ok then
			if not locking and state~="HELD" then modal.Visible=false end
			if locking then notice("Pet lock updated.") end
		else notice(if ok then errors[result.Code] or "Action unavailable. Refreshing your collection…" else "Connection interrupted. Refreshing your collection…") end
		refresh()
	end
	local function activateSlot(index)
		if modal.Visible or otherModal() or Input:GetFocusedTextBox() then return end
		local entry=entries[slots[index]]
		if entry then selected=entry.Key;task.spawn(perform,entry,false) end
	end
	for i=1,Config.HotbarSlots do
		local button=bar["Slot"..i]
		buttons[i]=button
		button.Activated:Connect(function() activateSlot(i) end)
	end
	local function updateDetail()
		local entry=entries[selected]
		Preview.Set(detail.Preview,entry)
		detail.Equip.Visible=entry~=nil and Model.CanSlot(entry);detail.Pin.Visible=false;detail.Lock.Visible=entry~=nil and entry.Kind=="Pet"
		if not entry then detail.ItemName.Text="SELECT AN ITEM";detail.Stats.Text="";return end
		local state=stateOf(entry)
		detail.ItemName.Text=entry.Name
		detail.Stats.Text=if entry.Kind=="Pet" then string.format("%s • LEVEL %s\n%s Money / sec\n%s%s",entry.Rarity,numberText(entry.Level),numberText(entry.Income),state,if entry.Locked then " • LOCKED" else "")
			elseif entry.Kind=="Food" then string.format("%s servings\n%s%% explosion risk reduction\nSelect this food at your feed plate.",numberText(entry.Quantity),numberText(entry.Reduction*100))
			else "EGG • "..state.."\n"..(if state=="INCUBATING" then numberText(math.max(0,entry.ReadyAt-snapshot.ServerNow)).."s remaining"
				elseif state=="READY" then "Press E beside your egg to hatch."
				else "Hold, then click inside your Pen.")
		detail.Equip.ButtonText.Text=if Model.SlotOf(slots,entry.Key) then "REMOVE FROM HOTBAR" else "ADD TO HOTBAR"
		detail.Lock.ButtonText.Text=if entry.Locked then "UNLOCK" else "LOCK"
		detail.Pin.ButtonText.Text=if Model.SlotOf(slots,entry.Key) then "UNPIN" else "QUICK SLOT"
		detail.Equip.Active=not busy and not snapshot.Busy;detail.Lock.Active=not busy and not snapshot.Busy
		detail.Equip.ImageColor3=if busy or snapshot.Busy then Color3.fromRGB(100,100,110) else Color3.fromRGB(78,227,51)
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
			card.Stroke.Color=if selected==entry.Key then Color3.new(1,1,1) else tint:Lerp(Color3.new(),.65)
			card.Stroke.Thickness=5
			card:SetAttribute("Selected",selected==entry.Key)
			card.ImageColor3=tint
			card.BackgroundColor3=card.ImageColor3
			card.ItemName.Text=entry.Name;card.Stats.Text=if entry.Kind=="Pet" then "Lv. "..numberText(entry.Level).." • "..numberText(entry.Income).."/s" elseif entry.Kind=="Food" then "×"..numberText(entry.Quantity).." • -"..numberText(entry.Reduction*100).."% risk" else "EGG"
			card.State.Text=stateOf(entry)..(if entry.Locked then " • LOCKED" else "");card.LockMark.Text=""
			Preview.Set(card.Preview,entry)
		end
		for key,card in cards do
			if not entries[key] then card:Destroy();cards[key]=nil else card.Visible=shown[key]==true end
		end
		layout.EmptyState.Visible=#visible==0
		layout.EmptyState.Text=if not snapshot then "Loading…" elseif category=="Food" and layout.Search.Text=="" then "No food yet" elseif next(entries)==nil then "No pets or eggs yet" else "No matches"
		local count=0;for _,entry in entries do if (category=="Food")==(entry.Kind=="Food") then count+=1 end end
		layout.Title.Text=(if category=="Food" then "MY FOOD  •  " else "MY COLLECTION  •  ")..numberText(count)
		layout.PenSlots.Text=if snapshot then string.format("PEN %d / %d",snapshot.PlacedCount,snapshot.MaxPetSlots) else "PEN —"
		layout.Sort.ButtonText.Text="SORT: "..string.upper(sort)
		for _,name in {"All","Pet","Egg","Food"} do
			layout[name].ImageColor3=if category==name then Color3.fromRGB(78,227,51) else Color3.fromRGB(36,165,219)
			layout[name].BackgroundColor3=layout[name].ImageColor3
			layout[name].ButtonText.TextColor3=Color3.new(1,1,1)
		end
		for i,button in buttons do
			local entry=entries[slots[i]]
			button.Visible=entry~=nil
			button.Key.Text=tostring(i%10)
			local held=entry and stateOf(entry)=="HELD"
			button:SetAttribute("Held",held==true)
			button.Key.Visible=true
			button.ItemName.Visible=true
			button.Stroke.Color=if held then Color3.fromRGB(255,211,112) else Color3.fromRGB(150,150,164)
			button.Stroke.Thickness=if held then 3 else 1
			button.BackgroundTransparency=.38
			button.ItemName.Text=entry and entry.Name or "Empty"
			button.State.Text=""
			button.Active=not busy;Preview.Set(button.Preview,entry)
		end
		updateDetail()
		Responsive.Apply(gui,cards,buttons)
		if os.clock()>noticeUntil then
			layout.Status.Text=""
			bar.Hint.Text=""
		end
		bar.Visible=next(slots)~=nil and not modal.Visible and not otherModal()
	end
	refresh=function()
		if busy or refreshing then return end
		refreshing=true
		local startedRevision=revision
		local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
		refreshing=false
		-- A snapshot started before a carry/placement action must not restore stale slots.
		if startedRevision~=revision then task.defer(refresh);return end
		if ok and result.Ok then
			snapshot=result;entries=Model.Entries(result);Model.Reconcile(slots,known,entries)
			if selected and not entries[selected] then selected=nil end
			onSnapshot(result)
		elseif not ok or result.Code~="Cooldown" then notice("Unable to refresh. Reconnecting…") end
		render()
	end
	local function toggle() if modal.Visible then modal.Visible=false else show() end end
	gui.HUD.OpenInventory.ButtonText.Text="INVENTORY"
	gui.HUD.OpenInventory.Activated:Connect(toggle)
	layout.Close.Activated:Connect(function() require(script.Parent.Parent.UI.Motion).Close(modal) end)
	modal:GetPropertyChangedSignal("Visible"):Connect(function()
		updateNavigation()
		player:SetAttribute("InventoryPanelOpen",modal.Visible)
		bar.Visible=next(slots)~=nil and not modal.Visible and not otherModal()
		if not modal.Visible and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(modal) then GuiService.SelectedObject=nil end
	end)
	for _,name in {"All","Pet","Egg","Food"} do layout[name].Activated:Connect(function() category=name;selected=nil;layout.Pets.CanvasPosition=Vector2.zero;render() end) end
	layout.Search:GetPropertyChangedSignal("Text"):Connect(function() layout.Pets.CanvasPosition=Vector2.zero;render() end)
	local sorts={"Newest","Income","Level","Rarity"}
	layout.Sort.Activated:Connect(function() sort=sorts[(table.find(sorts,sort)%#sorts)+1];render() end)
	local function toggleSlot()
		local entry=entries[selected]
		if not Model.CanSlot(entry) then return end
		if stateOf(entry)=="HELD" then notice("Put it away using its hotbar slot before removing it.");return end
		if not Model.TogglePin(slots,selected) then notice("All ten slots are full. Remove another hotbar item first.") end
		render()
	end
	detail.Equip.Activated:Connect(toggleSlot)
	detail.Lock.Activated:Connect(function() local entry=entries[selected];if entry and entry.Kind=="Pet" then task.spawn(perform,entry,true) end end)
	detail.Pin.Activated:Connect(toggleSlot)
	Controller.Placed=function(kind,id)
		revision+=1
		local key=string.lower(kind)..":"..id
		local entry=entries[key]
		if entry then entry.State=if kind=="Egg" then "INCUBATING" else "IN PEN" end
		Model.Reconcile(slots,known,entries)
		render();task.defer(refresh)
	end
	Input.InputBegan:Connect(function(input,processed)
		if Input:GetFocusedTextBox() then return end
		if input.KeyCode==Enum.KeyCode.ButtonB and modal.Visible then modal.Visible=false;return end
		if processed then return end
		if input.KeyCode==Enum.KeyCode.Backquote or input.KeyCode==Enum.KeyCode.ButtonY then toggle()
		elseif input.KeyCode==Enum.KeyCode.Escape then modal.Visible=false
		else local index=table.find(keys,input.KeyCode);if index then activateSlot(index) end end
	end)
	for _,attribute in {"CarriedPetId","CarriedEggUid"} do player:GetAttributeChangedSignal(attribute):Connect(function() render();task.defer(refresh) end) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() Responsive.Apply(gui,cards,buttons) end)
	render()
	task.spawn(function()
		while gui.Parent do
			bar.Visible=next(slots)~=nil and not modal.Visible and not otherModal()
			refresh();task.wait(Config.PollSeconds)
		end
	end)
	return {Refresh=refresh,Render=render,Show=show,Slots=slots,ActivateSlot=activateSlot}
end
return Controller
