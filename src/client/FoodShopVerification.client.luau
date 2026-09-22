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
	assert(main.FeedPanel:FindFirstChild("FoodType") and not main.FeedPanel:FindFirstChild("ProtectedFeed"),"Food selector replaces protection")
	assert(main.HUD.Money.Value.Text~="—" and main.HUD.Money.Value.Text~="$—","Money HUD initialized")
	assert(main.HUD:FindFirstChild("Food")==nil,"Food HUD removed")
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
