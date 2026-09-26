if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("TutorialVerificationReport",60)
if not report then return end
report.OnClientEvent:Connect(function(key)
	local ok,failure=xpcall(function()
		local player=game.Players.LocalPlayer
		local gui=player.PlayerGui:WaitForChild("TutorialUI",20)
		local main=player.PlayerGui:WaitForChild("FeedYourPetUI",20)
		local merchant=player.PlayerGui:WaitForChild("MerchantUI",20)
		local controller=require(script.Parent.Controllers.TutorialController)
		if key=="BuyFood" then merchant.Panel.Visible=true end
		if key=="PickupPet" then merchant.Panel.Visible=false end
		if key=="Feed" then main.FeedPanel.Visible=true end
		local readyUntil=os.clock()+15
		repeat task.wait(.1) until (gui.Hint.Visible and workspace:FindFirstChild("LocalTutorialArrows")) or os.clock()>readyUntil
		task.wait(.2)
		local text,world,button=controller.Resolve(player,player.PlayerGui)
		assert(type(text)=="string" and #text>0,"Guide text exists")
		if key~="Done" and not gui.Hint.Visible then
			local errors={}
			for _,entry in game.LogService:GetLogHistory() do
				if entry.messageType==Enum.MessageType.MessageError or string.find(entry.message,"TutorialController",1,true) then table.insert(errors,entry.message) end
			end
			error("Tutorial hint is visible; client diagnostics: "..table.concat(errors," | "))
		end
		if key=="MerchantTeleport" then assert(button==main.HUD.Travel.Merchant,"Merchant button highlighted")
		elseif key=="BaseTeleport" then assert(button==main.HUD.Travel.Base,"Base button highlighted")
		elseif key=="BuyFood" then assert(button==merchant.Panel.Offers.Slot1,"Basic Food card highlighted")
		elseif key=="Feed" then assert(button==main.FeedPanel.Feed or button==main.FeedPanel.FoodCards.List.basic,"Feed or Basic selection highlighted")
		elseif key~="Done" then assert(typeof(world)=="Vector3" or button~=nil,"World or equip target is available") end
		if button then
			assert(gui.Focus.Visible and gui.Pointer.Visible,"UI arrow and border are visible")
			local a,b=gui.Hint.AbsolutePosition,button.AbsolutePosition
			local s,t=gui.Hint.AbsoluteSize,button.AbsoluteSize
			assert(a.X+s.X<=b.X or b.X+t.X<=a.X or a.Y+s.Y<=b.Y or b.Y+t.Y<=a.Y,"Hint does not obscure target button")
		end
		local arrows=workspace:FindFirstChild("LocalTutorialArrows")
		assert(arrows and #arrows:GetChildren()<=24,"Arrow trail has bounded instance count")
		for _,part in arrows:GetDescendants() do if part:IsA("BasePart") then
			assert(not part.CanCollide and not part.CanTouch and not part.CanQuery and part.Anchored,"Arrow cannot interfere with movement or placement rays")
		end end
		for _,arrow in arrows:GetChildren() do
			local _,size=arrow:GetBoundingBox()
			assert(size.Y<.2 and size.X>1,"Authored triangle keeps a flat shared pivot")
		end
		if key=="Done" then
			task.wait(3.2)
			assert(not gui.Hint.Visible and not gui.Focus.Visible and #arrows:GetChildren()==0,"Completed guide removes all presentation")
		end
	end,debug.traceback)
	report:FireServer(key,{Passed=ok,Failure=if ok then nil else tostring(failure)})
end)
