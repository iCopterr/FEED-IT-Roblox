-- Suppress only gameplay chrome, never the ScreenGui containing an open menu.
-- Dedicated HUD screens retain their child state while disabled (e.g. boost
-- eligibility and tutorial updates). Hotbar rendering consumes GameMenuOpen.
local MenuHUD={}
local pages={
	FeedYourPetUI={"Inventory","FeedPanel"}, SettingsUI={"Panel"},
	ShopUI={"Panel"}, IndexUI={"Panel"}, StarterPackUI={"Panel"},
	MerchantUI={"Panel"}, ReviveUI={"Panel"}, DebugUI={"Panel"},
	PenManagerUI={"Panel","GrowNow"}, HatchUI={"Panel"},
	PurchaseThanksUI={"Popup"},
}
local chrome={FeedYourPetUI={"HUD"},ShopUI={"Open"},IndexUI={"Open"},
	SettingsUI={"Open"},DebugUI={"Open"},ReviveUI={"Open"},PenManagerUI={"Dock"}}
local hudScreens={BoostUI=true,TutorialUI=true,ConveyorUI=true}

function MenuHUD.Bind(gui)
	local connections,watched,saved={},{},{}
	local active=true
	local updating=false
	local function suppress(object,property,hidden)
		if hidden then
			if saved[object]==nil then saved[object]={property=property,value=object[property]} end
			object[property]=false
		elseif saved[object] then
			local prior=saved[object];saved[object]=nil
			object[prior.property]=prior.value
		end
	end
	local function update()
		if not active or updating then return end
		updating=true
		local open,remoteOpen=false,false
		for screenName,names in pages do
			local screen=gui:FindFirstChild(screenName)
			if screen and screen:IsA("ScreenGui") and screen.Enabled then
				for _,name in names do
					local panel=screen:FindFirstChild(name)
					if panel and panel:IsA("GuiObject") and panel.Visible then
						if screenName=="PenManagerUI" then remoteOpen=true else open=true end
					end
				end
			end
		end
		gui:SetAttribute("GameMenuOpen",open)
		for screenName,names in chrome do
			local screen=gui:FindFirstChild(screenName)
			for _,name in names do
				local object=screen and screen:FindFirstChild(name)
				if object then suppress(object,"Visible",open or (screenName=="PenManagerUI" and remoteOpen)) end
			end
		end
		for name in hudScreens do
			local screen=gui:FindFirstChild(name)
			if screen then suppress(screen,"Enabled",open) end
		end
		updating=false
	end
	local function watch(object)
		if watched[object] then return end
		local screen=if object:IsA("ScreenGui") then object else object.Parent
		if not screen or screen.Parent~=gui then return end
		local names=pages[screen.Name]
		if not names then return end
		local property=if object==screen then "Enabled" elseif table.find(names,object.Name) then "Visible" else nil
		if property then
			watched[object]=true
			table.insert(connections,object:GetPropertyChangedSignal(property):Connect(update))
		end
	end
	table.insert(connections,gui.DescendantAdded:Connect(function(object) watch(object);update() end))
	table.insert(connections,gui.DescendantRemoving:Connect(function() task.defer(update) end))
	for _,object in gui:GetDescendants() do watch(object) end
	update()
	return function()
		active=false
		for _,connection in connections do connection:Disconnect() end
		for object,prior in saved do if object.Parent then object[prior.property]=prior.value end end
		table.clear(saved)
		gui:SetAttribute("GameMenuOpen",false)
	end
end
return MenuHUD
