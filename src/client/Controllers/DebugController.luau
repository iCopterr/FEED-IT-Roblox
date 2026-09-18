local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config.DebugConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local Controller = {}
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local gui=playerGui:WaitForChild("DebugUI",3)
	if not RunService:IsStudio() then if gui then gui.Enabled=false end; return end
	local remote=ReplicatedStorage:WaitForChild("PrototypeDebug",5)
	if not remote then return end
	if not gui then
		gui=assert(game.StarterGui:WaitForChild("DebugUI",3),"DebugUI missing; check Rojo"):Clone()
		gui.Parent=playerGui
	end
	gui.Enabled=true
	local panel=gui.Panel
	local species={}
	for id,definition in PetConfig.Species do table.insert(species,{Id=id,Rarity=definition.Rarity,Income=definition.BaseIncome}) end
	table.sort(species,function(a,b) return a.Income<b.Income end)
	local speciesIndex,modeIndex,petIndex=1,1,1
	local state,busy,selected=nil,false,nil
	local messages={Disabled="Disabled: Studio memory data only.",Busy="Feed/Revive is animating or saving.",
		PickupFirst="Pick up this pet before setting its level.",InvalidAmount="Enter a positive whole amount (max 1000T; balance cap 4000T). K/M/B/T accepted.",
		InvalidLevel="Pet levels: 0–40. Farm levels: 1–10. Whole numbers only.",NotOwned="Select a pet you own.",
		Cooldown="Please wait a moment.",StaleRequest="State changed. Refreshing before another command.",
		InventoryLimit="Debug spawn limit: 200 inventory pets.",Loading="Loading player data…"}
	local function render()
		panel.Species.Text=species[speciesIndex].Rarity.." (click to cycle)"
		panel.Mode.Text=Config.Modes[modeIndex].." (click to cycle)"
		local pets=state and state.Pets or {}
		petIndex=math.clamp(petIndex,1,math.max(1,#pets))
		local pet=pets[petIndex]
		selected=pet and pet.PetId
		panel.Pet.Text=if pet then string.format("%d/%d • %s • Lv.%d • %s [%s]",petIndex,#pets,pet.Name,pet.FeedLevel,
			if pet.Placed then "PLACED" else "STORED/HELD/PLATE",string.sub(pet.PetId,1,8)) else "No pets — spawn one above"
		panel.Summary.Text=if state then string.format("Money %s • Food %s • Farm %d\nNext override: %s",NumberFormat.Compact(state.Money),NumberFormat.Compact(state.Food),state.FarmLevel,
			if state.Forced then state.Forced.Mode.." ["..string.sub(state.Forced.PetId,1,8).."]" else "None (normal odds)") else "Loading…"
		for _,name in {"AddMoney","AddFood","Spawn","SetPetLevel","SetFarmLevel","Force"} do
			panel[name].Active=state~=nil and not busy and not state.Busy
		end
	end
	local function refresh()
		if busy then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
		busy=false
		if ok and result.Ok then
			state=result
			for i,pet in state.Pets do if pet.PetId==selected then petIndex=i; break end end
		elseif not ok or result.Code~="Cooldown" then
			state=nil; panel.Status.Text=if ok then messages[result.Code] or "Unable to load debug state." else "Connection error. Refreshing…"
		end
		render()
	end
	local function command(action,value,id)
		if busy or not state or state.Busy then return end
		local sequence=state.NextSequence
		busy=true; render()
		local ok,result=pcall(function() return remote:InvokeServer(action,value,id,sequence) end)
		busy=false
		panel.Status.Text=if ok and result.Ok then (if action=="ForceFeed" then "Override armed/cleared. Close DEBUG and Feed the selected pet." else "Updated. Currency/inventory HUD refreshes shortly.")
			else if ok then messages[result.Code] or "Command rejected." else "Reply lost. Refreshing; command is NOT automatically retried."
		if ok and result.PetId then selected=result.PetId end
		state=nil
		refresh()
	end
	panel.Amount.Text=NumberFormat.Compact(Config.DefaultGrant)
	panel.Species.Activated:Connect(function() if not busy then speciesIndex=speciesIndex%#species+1; render() end end)
	panel.Mode.Activated:Connect(function() if not busy then modeIndex=modeIndex%#Config.Modes+1; render() end end)
	panel.Pet.Activated:Connect(function() if not busy and state and #state.Pets>0 then petIndex=petIndex%#state.Pets+1; render() end end)
	panel.AddMoney.Activated:Connect(function() command("AddMoney",NumberFormat.Parse(panel.Amount.Text)) end)
	panel.AddFood.Activated:Connect(function() command("AddFood",NumberFormat.Parse(panel.Amount.Text)) end)
	panel.Spawn.Activated:Connect(function() command("SpawnPet",species[speciesIndex].Id) end)
	panel.SetPetLevel.Activated:Connect(function() command("SetPetLevel",tonumber(panel.PetLevel.Text),selected) end)
	panel.SetFarmLevel.Activated:Connect(function() command("SetFarmLevel",tonumber(panel.FarmLevel.Text)) end)
	panel.Force.Activated:Connect(function() command("ForceFeed",Config.Modes[modeIndex],selected) end)
	gui.Open.Activated:Connect(function()
		panel.Visible=not panel.Visible
		if panel.Visible then
			local main=playerGui:FindFirstChild("FeedYourPetUI")
			if main then main.Inventory.Visible=false; main.FeedPanel.Visible=false end
			local revive=playerGui:FindFirstChild("ReviveUI")
			if revive then revive.Panel.Visible=false end
			refresh()
		end
	end)
	panel.Close.Activated:Connect(function() panel.Visible=false end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function() player:SetAttribute("DebugPanelOpen",panel.Visible) end)
	local function resize() panel.UIScale.Scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/540,(gui.AbsoluteSize.Y-24)/500)) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize(); render()
	task.spawn(function() while gui.Parent do if panel.Visible then refresh() end; task.wait(Config.RefreshSeconds) end end)
	return gui
end
return Controller
