if not game:GetService("RunService"):IsStudio() then return end
local signal=game.ReplicatedStorage:WaitForChild("InventoryVerificationReport",8)
if not signal then return end
local checks={}
local errors={}
local logConnection=game:GetService("LogService").MessageOut:Connect(function(message,kind)
	if kind==Enum.MessageType.MessageError or (kind==Enum.MessageType.MessageWarning and string.find(message,"startup failed",1,true)) then
		table.insert(errors,message)
	end
end)
local ok,failure=xpcall(function()
	local function check(value,name) assert(value,name);table.insert(checks,name) end
	local function waitFor(fn)
		local untilTime=os.clock()+75
		repeat if fn() then return end;task.wait(.1) until os.clock()>untilTime
		error("Client inventory test timed out: "..table.concat(errors," | "))
	end
	waitFor(function() return signal:GetAttribute("FixturesReady") end)
	local gui=game.Players.LocalPlayer.PlayerGui:WaitForChild("FeedYourPetUI",10)
	local client=script.Parent
	local model=require(client.UI.InventoryModel)
	local layout=require(client.UI.InventoryLayout)
	waitFor(function() return gui.HUD.OpenInventory.ButtonText.Text=="INVENTORY" end)
	check(not game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack),"Default Backpack suppressed")
	local remote=game.ReplicatedStorage.PrototypeUI.Request
	local snapshot
	waitFor(function() local state=remote:InvokeServer("Snapshot");if state.Ok then snapshot=state;return true end end)
	local entries=model.Entries(snapshot)
	waitFor(function()
		for key in entries do if not gui.Inventory.Panel.Layout.Pets:FindFirstChild(key) then return false end end
		return true
	end)
	check(true,"Actual controller renders owned pet/egg cards")
	local slots,known={},{}
	model.Reconcile(slots,known,entries)
	local first=slots[1]
	check(first and entries[first]~=nil,"Hotbar uses real owned IDs")
	check(model.TogglePin(slots,first) and not model.SlotOf(slots,first),"Removing quick slot leaves inventory intact")
	model.Reconcile(slots,known,entries)
	check(not model.SlotOf(slots,first),"Polling does not re-add a removed shortcut")
	check(model.TogglePin(slots,first),"Item can be pinned again")
	model.Reconcile(slots,known,{})
	check(not next(slots),"Removed or hatched IDs clear from hotbar")
	check(#model.Filter(entries,"Pet","NO SUCH PET","Income")==0,"Search handles no matches")
	local eggCount=0;for _,entry in entries do if entry.Kind=="Egg" then eggCount+=1 end end
	check(#model.Filter(entries,"Egg","","Newest")==eggCount,"Egg filter uses public eggs only")
	local cards,buttons={},{}
	for _,card in gui.Inventory.Panel.Layout.Pets:GetChildren() do if card:IsA("GuiButton") and card.Visible then cards[card.Name]=card end end
	for i=1,6 do buttons[i]=gui.Hotbar["Slot"..i];check(buttons[i]:IsA("GuiButton"),"Authored hotbar slot "..i) end
	if game.Players.LocalPlayer:GetAttribute("CarriedEggUid") then
		waitFor(function()
			for _,button in buttons do if button.State.Text=="HELD" and button.Stroke.Thickness==3 then return true end end
			return false
		end)
		check(true,"Held egg highlights actual hotbar selection")
	end
	local original=gui.Inventory.Visible;gui.Inventory.Visible=true
	for _,size in {Vector2.new(1280,720),Vector2.new(390,844),Vector2.new(844,390),Vector2.new(360,640)} do
		layout.Apply(gui,cards,buttons,size)
		local panel=gui.Inventory.Panel.Layout
		check(gui.Inventory.Size.X.Offset<=size.X and gui.Inventory.Size.Y.Offset<=size.Y,"Inventory fits "..tostring(size))
		check(gui.Hotbar.Size.X.Offset<=size.X,"Hotbar fits "..tostring(size))
		check(panel.Pets.Size.Y.Offset>0 and panel.Pets.Grid.CellSize.X.Offset>=90,"Scrollable cards fit "..tostring(size))
	end
	gui.Inventory.Visible=original;layout.Apply(gui,cards,buttons)
	for _,card in cards do
		check(card.Preview.CurrentCamera~=nil and #card.Preview.World:GetChildren()==1,"Authored preview has model and camera")
	end
end,debug.traceback)
logConnection:Disconnect()
signal:FireServer({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
