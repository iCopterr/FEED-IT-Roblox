local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config.EggConfig)
local Pets=require(ReplicatedStorage.Shared.Config.PetConfig)
local numberText=require(ReplicatedStorage.Shared.NumberFormat).Compact
local Controller={}

local function timeText(seconds)
	seconds=math.max(0,math.ceil(seconds))
	return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end

function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local gui=playerGui:WaitForChild("EggUI",3)
	if not gui then gui=game.StarterGui:WaitForChild("EggUI"):Clone();gui.Parent=playerGui end
	local panel=gui.Panel
	local remote=ReplicatedStorage:WaitForChild("PrototypeEgg")
	local state,receivedAt,busy=nil,0,false
	local messages={NotReady="This egg is still incubating.",Busy="Another action is saving. Please wait.",
		NotPlaced="Hold your egg and click inside your fenced Pen first.",Farming="Jump out of the farm first.",
		AlreadyPlaced="Your egg is already incubating in your Pen.",CharacterUnavailable="Wait for your character to respawn.",
		Unavailable="Egg already hatched or unavailable. Refreshing…",Cooldown="Please wait a moment.",
		Loading="Loading your eggs…",InvalidRequest="Invalid egg request."}
	local function render()
		local egg=state and state.Eggs[1]
		local definition=Config.Definitions[egg and egg.EggId or "prototype_egg"]
		local remaining=egg and math.max(0,egg.ReadyAt-(state.ServerNow+os.clock()-receivedAt)) or 0
		gui.Open.Text=if egg then "MY EGGS • "..(if not egg.Placed then "PLACE" elseif remaining<=0 then "READY!" else timeText(remaining)) else "MY EGGS"
		panel.Title.Text="EGG INCUBATOR"
		panel.PetName.Text=if egg then egg.Name else "No egg incubating"
		local odds={}
		if definition then
			local total=0
			for _,entry in definition.Results do total+=entry.Weight end
			for _,entry in definition.Results do
				table.insert(odds,Pets.Species[entry.SpeciesId].Rarity.." "..numberText(entry.Weight/total*100).."%")
			end
		end
		panel.Details.Text=(if egg then (if not egg.Placed then "Hold egg • Click inside your fenced Pen" elseif remaining<=0 then "READY TO HATCH" else "HATCH IN "..timeText(remaining))
			else "Conveyor: "..(definition and numberText(definition.Price) or "—").." Money • "..(definition and timeText(definition.HatchSeconds) or "—"))
		panel.Notice.Text=table.concat(odds," • ")
		panel.Hatch.Text=if not egg then "BUY AN EGG ON THE CONVEYOR" elseif not egg.Placed then
			(if player:GetAttribute("CarriedEggUid")==egg.EggUid then "PUT AWAY EGG" else "HOLD EGG") elseif remaining>0 then "INCUBATING…" else "PRESS E BESIDE YOUR EGG"
		local enabled=egg~=nil and not egg.Placed and not busy and not state.Busy
		panel.Hatch.Active=enabled;panel.Hatch.AutoButtonColor=enabled
		panel.Hatch.BackgroundColor3=if enabled then Color3.fromRGB(85,166,102) else Color3.fromRGB(100,100,110)
	end
	local function refresh()
		if busy then return end
		busy=true
		local ok,result=pcall(function() return remote:InvokeServer("Snapshot") end)
		busy=false
		if ok and result.Ok then state=result;receivedAt=os.clock()
		elseif not ok or result.Code~="Cooldown" then
			state=nil;panel.Status.Text=if ok then messages[result.Code] or "Unable to load eggs." else "Connection interrupted. Retrying…"
		end
		render()
	end
	gui.Open.Activated:Connect(function()
		panel.Visible=not panel.Visible
		if panel.Visible then
			for _,name in {"ReviveUI","DebugUI"} do local other=playerGui:FindFirstChild(name);if other then other.Panel.Visible=false end end
			local main=playerGui:FindFirstChild("FeedYourPetUI")
			if main then main.Inventory.Visible=false;main.FeedPanel.Visible=false end
			panel.Status.Text="Place to start timer • Hatched pets return to you"
			task.spawn(refresh)
		end
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function() player:SetAttribute("EggPanelOpen",panel.Visible) end)
	panel.Later.Activated:Connect(function() panel.Visible=false end)
	panel.Hatch.Activated:Connect(function()
		local egg=state and state.Eggs[1]
		if busy or not egg or not panel.Hatch.Active then return end
		local action=if egg.Placed then "Hatch" elseif player:GetAttribute("CarriedEggUid")==egg.EggUid then "Unequip" else "Equip"
		busy=true;render();panel.Status.Text="Please wait…"
		local ok,result=pcall(function() return remote:InvokeServer(action,egg.EggUid) end)
		busy=false
		if ok and result.Ok then
			state=nil
			panel.Status.Text=if action=="Hatch" then "Hatched "..result.PetName.." ("..result.Rarity..")! Returned to you / MY PETS."
				elseif action=="Equip" then "Click inside your fenced Pen to place your egg." else "Egg safely stored in MY EGGS."
			if action=="Equip" then panel.Visible=false end
		else panel.Status.Text=if ok then messages[result.Code] or "Unable to hatch." else "Connection interrupted. Check MY PETS; refreshing eggs…" end
		refresh()
	end)
	local function resize() panel.UIScale.Scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/480,(gui.AbsoluteSize.Y-24)/410)) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize();render()
	task.spawn(function()
		while gui.Parent do
			local main=playerGui:FindFirstChild("FeedYourPetUI")
			if player:GetAttribute("RevivePanelOpen") or player:GetAttribute("DebugPanelOpen") or player:GetAttribute("MerchantPanelOpen")
				or (main and (main.Inventory.Visible or main.FeedPanel.Visible)) then panel.Visible=false end
			refresh();task.wait(1)
		end
	end)
	return gui
end

return Controller
