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
		Unavailable="Egg already hatched or unavailable. Refreshing…",Cooldown="Please wait a moment.",
		Loading="Loading your eggs…",InvalidRequest="Invalid egg request."}
	local function render()
		local egg=state and state.Eggs[1]
		local definition=Config.Definitions[egg and egg.EggId or "prototype_egg"]
		local remaining=egg and math.max(0,egg.ReadyAt-(state.ServerNow+os.clock()-receivedAt)) or 0
		gui.Open.Text=if egg then "MY EGGS • "..(if remaining<=0 then "READY!" else timeText(remaining)) else "MY EGGS"
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
		panel.Details.Text=(if egg then (if remaining<=0 then "READY TO HATCH" else "HATCH IN "..timeText(remaining))
			else "Conveyor: "..(definition and numberText(definition.Price) or "—").." Money • "..(definition and timeText(definition.HatchSeconds) or "—"))
		panel.Notice.Text=table.concat(odds," • ")
		panel.Hatch.Text=if not egg then "BUY AN EGG ON THE CONVEYOR" else if remaining>0 then "INCUBATING…" else "HATCH"
		local enabled=egg~=nil and remaining<=0 and not busy and not state.Busy
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
			panel.Status.Text="One incubation slot • Timers continue while away"
			task.spawn(refresh)
		end
	end)
	panel:GetPropertyChangedSignal("Visible"):Connect(function() player:SetAttribute("EggPanelOpen",panel.Visible) end)
	panel.Later.Activated:Connect(function() panel.Visible=false end)
	panel.Hatch.Activated:Connect(function()
		local egg=state and state.Eggs[1]
		if busy or not egg or not panel.Hatch.Active then return end
		busy=true;render();panel.Status.Text="Hatching…"
		local ok,result=pcall(function() return remote:InvokeServer("Hatch",egg.EggUid) end)
		busy=false
		if ok and result.Ok then
			state=nil
			panel.Status.Text="Hatched "..result.PetName.." ("..result.Rarity..")! Find it in MY PETS."
		else panel.Status.Text=if ok then messages[result.Code] or "Unable to hatch." else "Connection interrupted. Check MY PETS; refreshing eggs…" end
		refresh()
	end)
	local function resize() panel.UIScale.Scale=math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/480,(gui.AbsoluteSize.Y-24)/410)) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize();render()
	task.spawn(function()
		while gui.Parent do
			local main=playerGui:FindFirstChild("FeedYourPetUI")
			if player:GetAttribute("RevivePanelOpen") or player:GetAttribute("DebugPanelOpen")
				or (main and (main.Inventory.Visible or main.FeedPanel.Visible)) then panel.Visible=false end
			refresh();task.wait(1)
		end
	end)
	return gui
end

return Controller
