if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("PageFocusVerificationReport",60)
if not report then return end
local checks={}
local ok,failure=xpcall(function()
	local function check(value,name)assert(value,name);table.insert(checks,name)end
	local player=game.Players.LocalPlayer
	local character=player.Character or player.CharacterAdded:Wait()
	local root=character:WaitForChild("HumanoidRootPart")
	local gui=player:WaitForChild("PlayerGui")
	local main=gui:WaitForChild("FeedYourPetUI")
	local inventory=main:WaitForChild("Inventory")
	local index=gui:WaitForChild("IndexUI"):WaitForChild("Panel")
	local merchant=gui:WaitForChild("MerchantUI"):WaitForChild("Panel")
	require(script.Parent.Controllers.PageFocusController).Start()
	task.wait(1)
	local camera=workspace.CurrentCamera;local baseline=camera.FieldOfView
	local blur=game.Lighting:WaitForChild("PageFocusBlur")
	check(gui.SettingsUI.DisplayOrder<gui.PenManagerUI.DisplayOrder,"Settings launcher renders behind remote menu")
	local function settle(open)
		local deadline=os.clock()+20
		repeat
			local fov=if open then baseline-10 else baseline
			local amount=if open then 18 else 0
			if math.abs(camera.FieldOfView-fov)<.1 and math.abs(blur.Size-amount)<.1 then return end
			task.wait(.1)
		until os.clock()>deadline
		error("Camera/blur transition did not settle")
	end
	inventory.Visible=true;settle(true)
	check(gui:GetAttribute("GameMenuOpen") and not main.HUD.Visible and not gui.ShopUI.Open.Visible
		and not gui.IndexUI.Open.Visible and not gui.SettingsUI.Open.Visible and not gui.PenManagerUI.Dock.Visible,
		"Inventory hides all gameplay navigation and teleport HUD")
	check(not gui.BoostUI.Enabled and not gui.TutorialUI.Enabled and not main.Hotbar.Visible,"Menu hides boost, tutorial and hotbar")
	check(math.abs(camera.FieldOfView-(baseline-10))<.1 and blur.Size>17,string.format("Open page zooms and blurs (FOV %.2f baseline %.2f blur %.2f visible %s enabled %s open %s health %.1f)",camera.FieldOfView,baseline,blur.Size,tostring(inventory.Visible),tostring(main.Enabled),tostring(blur:GetAttribute("PageOpen")),character.Humanoid.Health))
	index.Visible=true;inventory.Visible=false;task.wait(.4)
	check(blur.Size>17 and math.abs(camera.FieldOfView-(baseline-10))<.1,"Switching pages retains focus")
	index.Visible=false;settle(false)
	check(not gui:GetAttribute("GameMenuOpen") and main.HUD.Visible and gui.ShopUI.Open.Visible
		and gui.IndexUI.Open.Visible and gui.SettingsUI.Open.Visible and gui.PenManagerUI.Dock.Visible,"Last close restores navigation")
	check(math.abs(camera.FieldOfView-baseline)<.1 and blur.Size<.1,"Last close restores camera and background")
	for _=1,3 do inventory.Visible=true;task.wait(.12);inventory.Visible=false;task.wait(.12)end
	settle(false)
	check(math.abs(camera.FieldOfView-baseline)<.1,"Rapid toggles do not accumulate zoom")
	inventory.Visible=true;settle(true);main.Enabled=false;settle(false)
	check(blur.Size<.1,"Disabled ScreenGui releases focus")
	inventory.Visible=false;main.Enabled=true
	local origin=root.CFrame
	local point=workspace.MysteryMerchant.InteractionPoint
	root.CFrame=point.CFrame+Vector3.new(0,3,0);merchant.Visible=true;task.wait(.4)
	check(merchant.Visible,"Merchant stays open nearby")
	root.CFrame=point.CFrame+Vector3.new(50,3,0);task.wait(.4)
	check(not merchant.Visible,"Walking away closes merchant")
	main.FeedPanel.Visible=true;task.wait(.3)
	check(not main.FeedPanel.Visible,"Distant feed plate page closes")
	local revive=gui.ReviveUI.Panel;revive.Visible=true;task.wait(.3)
	check(not revive.Visible,"Distant revive page closes")
	inventory.Visible=true;task.wait(.3)
	root.CFrame=origin;task.wait(.3)
	check(inventory.Visible,"Portable inventory stays open while moving")
	inventory.Visible=false;settle(false)
	check(blur.Size<.1 and math.abs(camera.FieldOfView-baseline)<.1,"Final focus cleanup")
	local remotePanel=gui:WaitForChild("PenManagerUI").Panel
	remotePanel.Visible=true;task.wait(.5)
	check(not gui:GetAttribute("GameMenuOpen") and main.HUD.Visible and gui.SettingsUI.Open.Visible
		and gui.ShopUI.Open.Visible and gui.IndexUI.Open.Visible
		and not gui.PenManagerUI.Dock.Visible,"Remote panel hides only its dock, not gameplay navigation")
	check(remotePanel.Visible and blur.Size<.1 and math.abs(camera.FieldOfView-baseline)<.1,"Egg/pen remote panel does not zoom or blur")
	index.Visible=true;settle(true)
	check(blur.Size>17,"A regular page still activates focus alongside a remote panel")
	index.Visible=false;settle(false)
	check(not remotePanel.Visible and blur.Size<.1,"Opening Index closes the remote panel and closing Index releases background effects")
	remotePanel.Visible=false
end,debug.traceback)
local errors={}
if not ok then for _,entry in game:GetService("LogService"):GetLogHistory() do if entry.messageType==Enum.MessageType.MessageError then table.insert(errors,entry.message) end end end
report:FireServer({passed=ok,checks=checks,failure=if ok then nil else tostring(failure),errors=errors})
