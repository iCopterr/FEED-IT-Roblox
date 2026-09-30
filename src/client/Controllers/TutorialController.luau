local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Storage=game:GetService("ReplicatedStorage")
local Config=require(Storage.Shared.Config.TutorialConfig)
local Number=require(Storage.Shared.NumberFormat).Money
local Controller={}

local function position(object)
	if not object then return nil end
	return if object:IsA("Model") then object:GetPivot().Position else object.Position
end

function Controller.Resolve(player,playerGui)
	local step=player:GetAttribute("TutorialStep")
	local main=playerGui:FindFirstChild("FeedYourPetUI")
	if not step or not main then return nil end
	local plot
	local plots=workspace:FindFirstChild("PlayerPlots")
	if plots then for _,candidate in plots:GetChildren() do
		if candidate:GetAttribute("OwnerUserId")==player.UserId then plot=candidate;break end
	end end
	local eggId=player:GetAttribute("TutorialEggUid")
	local petId=player:GetAttribute("TutorialPetId")
	local function equip(key,label)
		local slot
		for _,button in main.Hotbar:GetChildren() do
			if button:IsA("GuiButton") and button:GetAttribute("ItemKey")==key then slot=button;break end
		end
		local layout=main.Inventory.Panel.Layout
		if main.Inventory.Visible then
			if slot then return "Close your inventory, then hold your "..label.." from the hotbar.",nil,layout.Close end
			local card=layout.Pets:FindFirstChild(key)
			if not card or not card.Visible then return "Find your "..label.." in ALL.",nil,layout.All end
			if not card:GetAttribute("Selected") then return "Select your "..label..".",nil,card end
			return "Add your "..label.." to the hotbar.",nil,layout.Details.Equip
		end
		if slot then return "Select your "..label.." in the hotbar to hold it.",nil,slot end
		return "Open your inventory to hold your "..label..".",nil,main.HUD.OpenInventory
	end
	if step==Config.Completed then return "Nice! Keep collecting, earning and feeding your pets." end
	if step=="BuyEgg" then
		local conveyor=workspace:FindFirstChild("PetConveyor")
		local offers=conveyor and conveyor:FindFirstChild("Offers")
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local nearest,distance=nil,math.huge
		if offers and root then for _,offer in offers:GetChildren() do
			if offer:IsA("Model") and offer:GetAttribute("EggId")==Config.EggId then
				local d=(offer:GetPivot().Position-root.Position).Magnitude
				if d<distance then nearest,distance=offer,d end
			end
		end end
		return if nearest then "You have $5K! Follow the arrows and hold E to buy a Basic Egg."
			else "Your $5K is ready. Follow the arrows and wait for a Basic Egg.",position(nearest or (conveyor and conveyor:FindFirstChild("Start")))
	elseif step=="PlaceEgg" then
		if player:GetAttribute("CarriedEggUid")~=eggId then return equip("egg:"..tostring(eggId),"egg") end
		return "Carry your egg home, then click inside your fenced pen to place it.",plot and plot.Pen.Floor.Position
	elseif step=="HatchEgg" then
		local egg=plot and plot.Pen:FindFirstChild("Egg_"..tostring(eggId))
		return if egg and egg:GetAttribute("HatchReady") then "Your egg is ready! Go beside it and press E to hatch."
			else "Wait for your egg to finish. Then press E beside it to hatch.",position(egg)
	elseif step=="PlacePet" then
		if player:GetAttribute("CarriedPetId")~=petId then
			if player:GetAttribute("FeedPlatePetId")==petId then
				if main.FeedPanel.Visible then return "Pick up your pet so it can earn Money in the pen.",nil,main.FeedPanel.Pickup end
				return "Hold E at the feed plate, then pick up your pet.",plot and plot.FeedPlate.Dish.Position
			end
			return equip("pet:"..tostring(petId),"pet")
		end
		return "Click inside your fenced pen to place your pet. It will earn Money!",plot and plot.Pen.Floor.Position
	elseif step=="EarnMoney" then
		return "Your pet is earning! Save $100 for food: $"..Number(player:GetAttribute("TutorialMoney") or 0).." / $100"
	elseif step=="MerchantTeleport" then
		return "You have enough Money! Click MERCHANT to visit the food shop.",nil,main.HUD.Travel.Merchant
	elseif step=="BuyFood" then
		local shop=playerGui:FindFirstChild("MerchantUI")
		if shop and shop.Panel.Visible then return "Buy Basic Food once for $100.",nil,shop.Panel.Offers.Slot1.BuyMoney end
		local merchant=workspace:FindFirstChild("MysteryMerchant")
		return "Go to the merchant and hold E to open the food shop.",merchant and merchant.InteractionPoint.Position
	elseif step=="BaseTeleport" then
		local shop=playerGui:FindFirstChild("MerchantUI")
		-- Follow current visibility, not a click flag: other controls can close it too.
		if shop and shop.Enabled and shop.Panel.Visible then
			return "Food bought! Close the food shop with X.",nil,shop.Panel.Close
		end
		return "Food bought! Click BASE to return to your plot.",nil,main.HUD.Travel.Base
	elseif step=="Feed" then
		local active=plot and plot.Pen:FindFirstChild("ActivePets")
		local pet=active and active:FindFirstChild(tostring(petId))
		if pet then return "Go beside your pet and hold E to pick it up.",position(pet) end
		if player:GetAttribute("FeedPlatePetId")==petId then
			if main.FeedPanel.Visible then
				local basic=main.FeedPanel.FoodCards.List.basic
				if not basic:GetAttribute("Selected") then return "Select Basic Food.",nil,basic end
				return "Press FEED to feed your pet!",nil,main.FeedPanel.Feed
			end
			return "Hold E beside your pet on the plate to open feeding.",plot and plot.FeedPlate.Dish.Position
		end
		if player:GetAttribute("CarriedPetId")==petId then return "Carry your pet to the FEED PLATE and click the plate.",plot and plot.FeedPlate.Dish.Position end
		return equip("pet:"..tostring(petId),"pet")
	end
	return nil
end

function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local gui=assert(playerGui:WaitForChild("TutorialUI",30),"TutorialUI asset missing")
	local template=assert(Storage:WaitForChild("TutorialArrow",30),"TutorialArrow asset missing")
	local pool={}
	local folder=Instance.new("Folder");folder.Name="LocalTutorialArrows";folder.Parent=workspace
	local function clear()
		for _,arrow in pool do arrow:Destroy() end
		table.clear(pool)
	end
	local function visible(button)
		local object=button
		while object and object~=playerGui do
			if object:IsA("GuiObject") and not object.Visible then return false end
			if object:IsA("ScreenGui") and not object.Enabled then return false end
			object=object.Parent
		end
		return object==playerGui
	end
	local doneAt,lastStep,elapsed=nil,nil,0
	local observedActive=false
	local connection
	connection=RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
		if not gui.Parent then clear();folder:Destroy();connection:Disconnect();return end
		local step=player:GetAttribute("TutorialStep")
		if step and step~=Config.Completed then observedActive=true end
		if step~=lastStep then
			if step==Config.Completed then doneAt=if observedActive then os.clock() else -math.huge;clear() end
			lastStep=step
		end
		local text,target,button=Controller.Resolve(player,playerGui)
		if step==Config.Completed and doneAt and os.clock()-doneAt>3 then text=nil end
		gui.Hint.Visible=text~=nil;gui.Hint.Message.Text=text or ""
		local main=playerGui:FindFirstChild("FeedYourPetUI")
		local shop=playerGui:FindFirstChild("MerchantUI")
		local modal=(main and main.FeedPanel.Visible) or (shop and shop.Panel.Visible)
		local width=math.min(560,gui.AbsoluteSize.X-24)
		gui.Hint.AnchorPoint=Vector2.new(.5,1)
		gui.Hint.Size=UDim2.fromOffset(width,if width<450 then 82 else 66)
		gui.Hint.Position=UDim2.new(.5,0,1,-110)
		if modal then
			if gui.AbsoluteSize.X>=1200 then
				gui.Hint.AnchorPoint=Vector2.new(0,.5)
				gui.Hint.Position=UDim2.new(0,12,.65,0)
				gui.Hint.Size=UDim2.fromOffset(270,100)
			else
				-- Keep the instruction away from the current clickable target.
				local bottomTarget=button and button.AbsolutePosition.Y>gui.AbsoluteSize.Y*.5
				gui.Hint.AnchorPoint=Vector2.new(.5,if bottomTarget then 0 else 1)
				gui.Hint.Position=if bottomTarget then UDim2.new(.5,0,0,112) else UDim2.new(.5,0,1,-8)
			end
		end
		local showButton=button~=nil and visible(button)
		gui.Focus.Visible=showButton;gui.Pointer.Visible=showButton
		if showButton then
			local p=button.AbsolutePosition-gui.AbsolutePosition
			local size=button.AbsoluteSize
			gui.Focus.Position=UDim2.fromOffset(p.X-5,p.Y-5)
			gui.Focus.Size=UDim2.fromOffset(size.X+10,size.Y+10)
			gui.Focus.Outline.Transparency=.15+.25*(1+math.sin(os.clock()*6))/2
			local above=p.Y>=55
			gui.Pointer.Rotation=if above then 0 else 180
			gui.Pointer.Position=UDim2.fromOffset(p.X+size.X/2,p.Y+(if above then -26 else size.Y+26)+math.sin(os.clock()*5)*5)
		end
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if target and root and text then
			local from=root.Position+Vector3.new(0,Config.ArrowHeight,0)
			local offset=target+Vector3.new(0,1,0)-from
			local distance=offset.Magnitude
			if distance>2 then
				local direction=offset.Unit
				for index=1,Config.ArrowCount do
					local arrow=pool[index]
					if not arrow then
						arrow=template:Clone();arrow.Name="Arrow"..index
						-- The authored wedges are rotated; use their shared origin,
						-- not Roblox's inferred first-part orientation, as the pivot.
						arrow.WorldPivot=CFrame.new();pool[index]=arrow
					end
					local along=index*Config.ArrowSpacing+(os.clock()*Config.ArrowSpeed)%Config.ArrowSpacing
					if along<distance then
						local point=from+direction*along
						local up=if math.abs(direction.Y)>.98 then Vector3.xAxis else Vector3.yAxis
						arrow:PivotTo(CFrame.lookAt(point,point+direction,up));arrow.Parent=folder
						local color=Color3.fromRGB(235,67,239):Lerp(Color3.fromRGB(255,207,38),math.clamp(along/distance,0,1))
						for _,part in arrow:GetChildren() do if part:IsA("BasePart") then part.Color=color end end
					else arrow.Parent=nil end
				end
				return
			end
		end
		for _,arrow in pool do arrow.Parent=nil end
	end)
	return gui
end
return Controller
