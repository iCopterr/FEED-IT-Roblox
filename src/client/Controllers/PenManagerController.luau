local Players=game:GetService("Players")
local Shared=game.ReplicatedStorage.Shared
local Pets=require(Shared.Config.PetConfig)
local Variants=require(Shared.Config.VariantConfig)
local Income=require(Shared.PetIncome)
local Number=require(Shared.NumberFormat).Money
local Monetization=require(Shared.Config.MonetizationConfig)
local Motion=require(script.Parent.Parent.UI.Motion)
local Purchases=require(script.Parent.Parent.UI.Purchases)
local Preview=require(script.Parent.Parent.UI.ItemPreview)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local gui=player:WaitForChild("PlayerGui"):WaitForChild("PenManagerUI",30)
	assert(gui,"PenManagerUI missing")
	local panel=gui.Panel
	local request=game.ReplicatedStorage:WaitForChild("PrototypeUI").Request
	local eggs=game.ReplicatedStorage:WaitForChild("PrototypeEgg")
	local mode="Pets"
	local rows={}
	local busy=false
	local refreshing=false
	local revision=0
	local refresh
	local messages={Busy="",Cooldown="",GrowNowUnavailable="",NotReady="Egg is still growing.",
		Unavailable="Already collected or unavailable.",CharacterUnavailable="Wait for your character.",
		Loading="Your pen is still loading.",PlacementFailed="Could not update your pen.",
		TemplateUnavailable="A pet model is unavailable."}
	Motion.BindPopup(panel,{FromRight=true})
	Motion.BindButton(panel.Close,panel)
	Motion.BindButton(panel.EquipBest,panel)
	for _,button in {gui.Dock.Eggs,gui.Dock.Pets} do Motion.BindButton(button,gui.Dock) end
	local function render(snapshot)
		local list={}
		if mode=="Eggs" then
			for _,egg in snapshot.Eggs do
				if egg.Placed then
					local remaining=math.max(0,egg.ReadyAt-snapshot.ServerNow)
					table.insert(list,{Id=egg.EggUid,Name=egg.Name,Kind="Egg",EggId=egg.EggId,
						Details=if remaining==0 then "READY" else string.format("%d:%02d",math.floor(remaining/60),remaining%60),Ready=remaining==0})
				end
			end
		else
			for id,pet in snapshot.Inventory do
				if pet.Placed then local species=Pets.Species[pet.SpeciesId]
					table.insert(list,{Id=id,Name=Variants.Name(species and species.DisplayName or pet.SpeciesId,pet.Variant),
						Kind="Pet",SpeciesId=pet.SpeciesId,Details="$"..Number(Income(pet)).."/s",Ready=true})
				end
			end
		end
		table.sort(list,function(a,b) if a.Name==b.Name then return a.Id<b.Id end;return a.Name<b.Name end)
		panel.Title.Text=if mode=="Eggs" then "GROWING EGGS • "..#list else string.format("PETS • %d / %d",snapshot.PlacedCount,snapshot.MaxPetSlots)
		panel.EquipBest.Visible=mode=="Pets"
		panel.GrowAll.Visible=mode=="Eggs"
		local _,count=Monetization.GrowAllQuote(snapshot.Eggs or {},snapshot.ServerNow)
		panel.GrowAll.Active=count>0 and not snapshot.Busy
		panel.GrowAll.ButtonText.Text="GROW ALL"
		panel.EquipBest.Active=mode=="Pets" and not busy and not snapshot.Busy
		panel.EquipBest.BackgroundColor3=if panel.EquipBest.Active then Color3.fromRGB(78,227,51) else Color3.fromRGB(90,94,108)
		local shown={}
		for index,entry in list do
			local key=mode..":"..entry.Id;shown[key]=true
			local row=rows[key]
			if not row then
				row=panel.List.RowTemplate:Clone();row.Name=key;row.Visible=true;row.Parent=panel.List;rows[key]=row
				Motion.BindButton(row.Action,panel)
				local actionMode=mode
				row.Action.Activated:Connect(function()
					if busy or not row.Action.Active then return end
					busy=true;revision+=1;panel.Status.Text=""
					for _,r in rows do r.Action.Active=false end
					local ok,result=pcall(function()
						if actionMode=="Eggs" then return eggs:InvokeServer("HatchRemote",entry.Id) end
						return request:InvokeServer("PickupRemote",entry.Id)
					end)
					busy=false
					panel.Status.Text=if ok and result.Ok then (if actionMode=="Eggs" then result.PetName.." hatched!" else "Returned to inventory") else (if ok then messages[result.Code] or "Unable to collect." else "Connection interrupted.")
					if ok and result.Ok and rows[key] then rows[key]:Destroy();rows[key]=nil end
					task.delay(.3,refresh)
				end)
			end
			row.LayoutOrder=index;row.ItemName.Text=entry.Name;row.Details.Text=entry.Details
			row.Action.Label.Text=if mode=="Pets" then "PICK UP" else "HATCH"
			row.Action.Active=not busy and not snapshot.Busy
			row.Action.BackgroundColor3=if row.Action.Active then Color3.fromRGB(78,227,51) else Color3.fromRGB(90,94,108)
			Preview.Set(row.Preview,entry)
		end
		for key,row in rows do if not shown[key] then row:Destroy();rows[key]=nil end end
		if #list==0 then panel.Status.Text=if mode=="Pets" then "No pets in your pen" else "No placed eggs" end
	end
	refresh=function()
		if not panel.Visible or refreshing or busy then return end
		refreshing=true;local version=revision
		local ok,result=pcall(function() return request:InvokeServer("Snapshot") end)
		refreshing=false
		if version~=revision or not panel.Visible then return end
		if ok and result.Ok then render(result)
		elseif not ok then panel.Status.Text="Connection interrupted."
		elseif result.Code~="Cooldown" then panel.Status.Text=messages[result.Code] or "Loading…" end
	end
	local function open(nextMode)
		if panel.Visible and mode==nextMode then Motion.Close(panel);return end
		revision+=1;mode=nextMode
		for key,row in rows do row:Destroy();rows[key]=nil end
		for _,name in {"FeedYourPetUI","MerchantUI","ReviveUI","DebugUI","IndexUI"} do
			local other=gui.Parent:FindFirstChild(name)
			if other then
				if name=="FeedYourPetUI" then other.Inventory.Visible=false;other.FeedPanel.Visible=false
				else other.Panel.Visible=false end
			end
		end
		panel.Title.Text=if mode=="Pets" then "PLACED PETS" else "GROWING EGGS"
		panel.EquipBest.Visible=mode=="Pets"
		panel.GrowAll.Visible=mode=="Eggs"
		panel.GrowAll.Active=false
		panel.GrowAll.ButtonText.Text="GROW ALL"
		panel.Status.Text="Loading…";panel.Visible=true;task.spawn(refresh)
	end
	gui.Dock.Eggs.Activated:Connect(function() open("Eggs") end)
	panel.GrowAll:SetAttribute("SuppressClickSound",true)
	panel.GrowAll.Activated:Connect(function()
		if panel.GrowAll.Active then Purchases.Request("GrowAll") end
	end)
	gui.Dock.Pets.Activated:Connect(function() open("Pets") end)
	panel.EquipBest.Activated:Connect(function()
		if busy or mode~="Pets" or not panel.EquipBest.Active then return end
		busy=true;revision+=1;panel.Status.Text="Finding your best pets…"
		panel.EquipBest.Active=false
		for _,row in rows do row.Action.Active=false end
		local ok,result=pcall(function() return request:InvokeServer("EquipBest") end)
		busy=false
		if ok and result.Ok then
			panel.Status.Text=if result.Code=="NoChange" then "Your best pets are already active"
				elseif result.Code=="NoAvailablePets" then "No available pets to equip"
				else "Best pets equipped"
		else
			panel.Status.Text=if ok then messages[result.Code] or "Unable to equip pets." else "Connection interrupted."
		end
		task.delay(.3,refresh)
	end)
	panel.Close.Activated:Connect(function() Motion.Close(panel) end)
	for _,name in {"FeedYourPetUI","MerchantUI","ReviveUI","DebugUI","IndexUI"} do
		task.spawn(function()
			local other=gui.Parent:WaitForChild(name,30)
			if not other then return end
			local panels=if name=="FeedYourPetUI" then {other.Inventory,other.FeedPanel} else {other.Panel}
			for _,p in panels do p:GetPropertyChangedSignal("Visible"):Connect(function()
				if p.Visible then panel.Visible=false;revision+=1 end
			end) end
		end)
	end
	local function resize()
		local size=gui.AbsoluteSize
		-- Compact side card: approximately 22% wide / 34% tall on desktop.
		local scale=math.min(.82,math.max(.45,math.min(size.X*.23/510,size.Y*.34/440)),(size.X-32)/510,(size.Y-40)/440)
		panel.UIScale.Scale=scale
		panel.Position=UDim2.new(1,-16,.5,-220*scale)
		local dockScale=math.clamp(size.Y/1080,.65,1)
		gui.Dock.UIScale.Scale=dockScale
		gui.Dock.Position=UDim2.new(1,-18,.5,-86*dockScale)
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function() gui.Dock.Visible=not panel.Visible end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
	task.spawn(function() while gui.Parent do refresh();task.wait(1) end end)
end
return Controller
