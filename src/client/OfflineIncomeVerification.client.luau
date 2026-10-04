if not game:GetService("RunService"):IsStudio() then return end
local report = game.ReplicatedStorage:WaitForChild("OfflineIncomeVerificationReport", 8)
if not report then return end
local checks = {}
local activations = 0
local ok, failure = xpcall(function()
	local function check(value,name) assert(value,name);table.insert(checks,name) end
	local function waitFor(fn)
		local deadline = os.clock()+180
		repeat if fn() then return end;task.wait(.1) until os.clock()>deadline
		error("Offline UI condition timed out")
	end
	local gui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = gui:WaitForChild("FeedYourPetUI",30)
	local shop = gui:WaitForChild("ShopUI",30)
	local offline = gui:WaitForChild("OfflineIncomeUI",30)
	assert(offline,"Offline UI did not initialize")
	offline.Popup.Collect.Activated:Connect(function() activations += 1 end)
	waitFor(function()return offline.Popup.Visible end)
	check(offline.Popup.Amount.Text == "$36.00K", "Return popup shows server earnings")
	check(offline.Popup.Duration.Text:find("1h 0m",1,true), "Popup shows credited offline duration")
	check(offline.Popup.Collect:GetAttribute("SuppressClickSound"), "Collect suppresses generic click sound")
	waitFor(function()return gui:GetAttribute("GameMenuOpen")end)
	waitFor(function()return not main.HUD.Visible and not shop.Open.Visible end)
	check(not main.HUD.Visible and not shop.Open.Visible, "Offline popup hides gameplay HUD")
	local factory = require(script.Parent.UI.OfflineIncome)
	local view = factory.Create(gui)
	view.Gui.Name = "OfflineLayoutQA"
	view.Show({PendingMoney=36000,PendingSeconds=3600})
	task.wait(.3)
	for _,size in {Vector2.new(390,844),Vector2.new(568,320),Vector2.new(844,390),Vector2.new(1368,630),Vector2.new(1920,1080)} do
		view.Gui.Viewport.Size = UDim2.fromOffset(size.X,size.Y)
		waitFor(function()return view.Popup.AbsoluteSize.X <= size.X-25 and view.Popup.AbsoluteSize.Y <= size.Y-25 end)
		check(view.Popup.AbsoluteSize.X <= size.X-25 and view.Popup.AbsoluteSize.Y <= size.Y-25,
			"Popup fits "..tostring(size))
	end
	view.Menu(true,{Rate=10,PendingMoney=0,PendingSeconds=0,MinimumSeconds=600,MaxSeconds=86400})
	check(view.Gui.MenuTop.Visible and view.Gui.MenuBottom.Visible, "Both menu reminders appear")
	check(view.Gui.MenuTop.Text:find("$10.00/SEC",1,true) and view.Gui.MenuBottom.Text:find("10+ minutes",1,true)
		and view.Gui.MenuBottom.Text:find("$864.00K",1,true), "Reminders show minimum, rate and cap estimate")
	view.Menu(false)
	check(not view.Gui.MenuTop.Visible and not view.Gui.MenuBottom.Visible, "Reminders hide on menu close")
	view.Gui:Destroy()
	task.wait(.6)
	local collected
	waitFor(function()
		collected = game.ReplicatedStorage.OfflineIncome:InvokeServer("Collect")
		assert(collected.Ok or collected.Code == "Cooldown", game:GetService("HttpService"):JSONEncode(collected))
		return collected.Ok
	end)
	check(collected.Ok and collected.Money == 38000 and collected.Amount == 36000,
		"First live collect grants exact reward once: " .. game:GetService("HttpService"):JSONEncode(collected))
	offline.Popup.Visible = false
	waitFor(function()return not gui:GetAttribute("GameMenuOpen")end)
	check(main.HUD.Visible, "Closing offline popup restores HUD")
	task.wait(.6)
	local result
	waitFor(function()
		result = game.ReplicatedStorage.OfflineIncome:InvokeServer("Collect",999999999)
		return result.Ok
	end)
	check(result.Ok and result.Amount==0, "Duplicate remote / client amount cannot grant money")
end, debug.traceback)
report:FireServer({passed=ok,checks=checks,activations=activations,failure=if ok then nil else tostring(failure)})
