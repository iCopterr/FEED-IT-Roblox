if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("FoodShopVerificationReport",10)
if not report then return end
local ok,failure=xpcall(function()
	local gui=game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local main=assert(gui:WaitForChild("FeedYourPetUI",10),"Main UI missing")
	local merchant=assert(gui:WaitForChild("MerchantUI",10),"Merchant UI missing")
	local rescue=assert(gui:WaitForChild("ReviveUI",10),"Rescue UI missing")
	local deadline=os.clock()+20
	repeat
		if merchant.Panel.Slot1.Text:find("Basic Food",1,true) then break end
		task.wait(.25)
	until os.clock()>deadline
	for _,entry in game.LogService:GetLogHistory() do
		assert(not entry.message:find("startup failed:",1,true),entry.message)
		if entry.messageType==Enum.MessageType.MessageError and not entry.message:find("plugin",1,true) then
			error(entry.message)
		end
	end
	assert(merchant:FindFirstChild("TokenHUD")==nil and merchant:FindFirstChild("TokenPopup")==nil,"Old Token UI visible")
	assert(merchant.Panel.Money.Text:find("YOUR MONEY",1,true),"Merchant binds Money label")
	assert(merchant.Panel.Slot1.Text:find("Basic Food",1,true),"Basic Food rendered in shop: "..merchant.Panel.Status.Text.." / "..merchant.Panel.Slot1.Text)
	assert(merchant.Panel.Slot1.Text:find("/5 LEFT",1,true) or merchant.Panel.Slot1.Text:find("SOLD OUT",1,true),"Basic stock limit is visible")
	assert(main.FeedPanel:FindFirstChild("FoodCards") and not main.FeedPanel:FindFirstChild("FoodType"),"Food cards replace cycling selector")
	local feedLayout=main.FeedPanel
	for _,panel in {main.Inventory.Panel,feedLayout,feedLayout.FoodCards,merchant.Panel,rescue.Panel} do
		assert(panel.PageHeader:IsA("ImageLabel") and panel.PageTexture:IsA("ImageLabel"),"Authored page theme present")
	end
	assert(feedLayout.FoodCards.Title.ZIndex>feedLayout.FoodCards.PageHeader.ZIndex,"Food title stays above header")
	assert(main.Inventory.Panel.Layout.Title.ZIndex>main.Inventory.Panel.PageHeader.ZIndex,"Inventory title stays above header")
	assert(rescue.Panel:FindFirstChild("Close"),"Rescue close button authored")
	assert(gui:FindFirstChild("EggUI")==nil,"Obsolete MY EGGS screen removed")
	assert(feedLayout.FoodCards.Position.X.Offset>=feedLayout.Size.X.Offset+12,"Food sidebar sits beside main panel")
	assert(feedLayout.PetPreview.Position.X.Offset+feedLayout.PetPreview.Size.X.Offset/2==feedLayout.Size.X.Offset/2,"Pet preview centered")
	assert(not feedLayout.ClipsDescendants,"External sidebar is not clipped")
	local previousOrder=0
	assert(feedLayout.FoodCards.List:IsA("ScrollingFrame") and feedLayout.FoodCards.List.AutomaticCanvasSize==Enum.AutomaticSize.Y,"Food list grows automatically")
	local foods=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
	assert(#foods.Order==7,"Expanded food config reaches client")
	for _,id in foods.Order do
		local card=feedLayout.FoodCards.List[id]
		assert(card and card:IsA("GuiButton"),"Authored food card "..id)
		assert(card.LayoutOrder>previousOrder,"Food cards form a vertical bar")
		previousOrder=card.LayoutOrder
	end
	assert(main.Inventory.Panel.Layout:FindFirstChild("Food"),"Food inventory tab")
	local model=require(script.Parent.UI.InventoryModel)
	local entries=model.Entries({Inventory={},Foods={basic=5,fresh=5,enchanted=2,royal=2}})
	assert(#model.Filter(entries,"Food","","Newest")==4,"Owned expanded foods appear in food tab")
	assert(#model.Filter(entries,"All","","Newest")==0,"Food excluded from pets/eggs All tab")
	assert(not model.CanSlot(entries["food:basic"]),"Food cannot enter hotbar")
	local view=main.Inventory.Panel.Layout.Pets.PetCardTemplate.Preview
	require(script.Parent.UI.ItemPreview).Set(view,entries["food:basic"])
	assert(view.FoodArt.Visible and view.FoodArt.Emoji.Visible,"Food placeholder supports future image")
	local deadline=os.clock()+15
	repeat
		if game.Players.LocalPlayer:GetAttribute("FeedPlatePetId") then break end
		task.wait(.1)
	until os.clock()>deadline
	if game.Players.LocalPlayer:GetAttribute("FeedPlatePetId") then
		local panel=main.FeedPanel
		local deadline=os.clock()+10
		repeat task.wait(.1) until panel.PetPreview.World:FindFirstChildOfClass("Model") or os.clock()>deadline
		local pet=assert(panel.PetPreview.World:FindFirstChildOfClass("Model"),"Pet preview loaded")
		local before=pet:GetPivot();task.wait(.3)
		assert(before~=pet:GetPivot(),"Pet preview spins while feeding UI open")
		local feed=require(script.Parent.Controllers.FeedController)
		feed.SelectFood("royal")
		assert(panel.FoodCards.List.royal:GetAttribute("Selected"),"Clicked food selected")
		assert(not panel.Feed.Active,"Unowned food cannot be fed")
		feed.SelectFood("basic")
		assert(panel.FoodCards.List.basic:GetAttribute("Selected"),"Can switch selected food")
	end
	assert(main.HUD.Money.Value.Text~="—" and main.HUD.Money.Value.Text~="$—","Money HUD initialized")
	assert(main.HUD:FindFirstChild("Food")==nil,"Food HUD removed")
	local signCount=0
	for _,sign in workspace.PlotUpgradeSigns:GetChildren() do
		local upgradeGui=assert(gui:WaitForChild("PlotUpgrade_"..sign.Name,5),"Plot upgrade controller did not bind")
		assert(upgradeGui.Adornee==sign.Board and upgradeGui.Enabled,"Upgrade UI adorns authored world sign")
		assert(upgradeGui.Title.Text=="PET CAPACITY","Correct upgrade title")
		assert(not upgradeGui.Buy.Selectable,"World upgrade button must not capture keyboard navigation")
		signCount+=1
	end
	assert(signCount==6,"All six plot signs have client bindings")
	assert(main.FeedPanel:FindFirstChild("Food")~=nil,"Feed quantity display retained")
	assert(not rescue.Open.Visible,"No anytime recovery button")
	local debugGui=gui:FindFirstChild("DebugUI")
	if debugGui then assert(not debugGui.Panel:FindFirstChild("AddTokens"),"No debug Token grant") end
	for _,entry in game.LogService:GetLogHistory() do
		assert(not entry.message:find("startup failed:",1,true),entry.message)
	end
end,debug.traceback)
if not ok then
	local diagnostics={}
	for _,entry in game.LogService:GetLogHistory() do table.insert(diagnostics,entry.message) end
	local gui=game.Players.LocalPlayer.PlayerGui.MerchantUI
	table.insert(diagnostics,"Shop timer: "..gui.Panel.Restock.Text.."; Money: "..gui.Panel.Money.Text)
	task.spawn(function()
		local reply=game.ReplicatedStorage.PrototypeMerchant:InvokeServer("Snapshot")
		report:FireServer({Passed=false,Failure=table.concat(diagnostics,"\n").."\nDirect snapshot OK: "..tostring(reply.Ok).."\n"..tostring(failure)})
	end)
else report:FireServer({Passed=true}) end
