local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.ReviveConfig)
local Controller = {}
local numberText = require(ReplicatedStorage.Shared.NumberFormat).Compact

function Controller.Start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = assert(playerGui:WaitForChild("ReviveUI",30),"ReviveUI missing; check Rojo")
	local panel = gui:WaitForChild("Panel")
	local remote = ReplicatedStorage:WaitForChild("PrototypeRevive")
	local receivedAt = 0
	local records, seen, index, busy, snapshot = {}, {}, 1, false, nil
	local messages = {Busy="Feed or recovery is still animating/saving. Please wait.",
		Cooldown="Please wait a moment.", StudioOnly="Free Revive is available in Studio only.",
		Unavailable="This recovery is no longer available. Refreshing…",
		PetChanged="This pet has a newer recovery. Refreshing…", Loading="Loading player data…"}
	local function render()
		index = math.clamp(index, 1, math.max(1, #records))
		local record = records[index]
		gui.Open.Visible = false
		gui.Open.Text = string.format("PET RECOVERY (%d)", #records)
		local remaining = record and snapshot and math.max(0, math.ceil(record.ExpiresAt-snapshot.ServerNow-(os.clock()-receivedAt))) or 0
		panel.Title.Text = string.format("RESCUE • %ds",remaining)
		panel.PetName.Text = if record then record.PetName else "No pending recovery"
		panel.Details.Text = if record then string.format("%s • LEVEL %d • %s MONEY/SEC BEFORE BREAKING\n%s Food remains spent",
			record.Rarity, record.FeedLevel, numberText(record.Income), numberText(record.FoodSpent)) else "Recovered pets are in MY PETS. Equip and place them again."
		local enabled = record ~= nil and snapshot and snapshot.CanRevive and remaining > 0 and not snapshot.Busy and not busy
		panel.Revive.Active = enabled == true
		panel.Revive.AutoButtonColor = enabled == true
		panel.Revive.BackgroundColor3 = if enabled then Color3.fromRGB(85,166,102) else Color3.fromRGB(100,100,110)
		panel.Revive.Text = if snapshot and not snapshot.CanRevive then "RESCUE: STUDIO TEST ONLY" else "RESTORE GROWTH (FREE TEST)"
		local canKeep = record ~= nil and snapshot ~= nil and not snapshot.Busy and not busy
		panel.Later.Text = if record then string.format("KEEP AT LEVEL %d",snapshot and snapshot.ResetLevel or 0) else "CLOSE"
		panel.Later.Active = canKeep or (record == nil and not busy)
		panel.Later.AutoButtonColor = panel.Later.Active
	end
	local function show()
		local debugGui = playerGui:FindFirstChild("DebugUI")
		if debugGui then debugGui.Panel.Visible = false end
		local main = playerGui:FindFirstChild("FeedYourPetUI")
		if main then main.Inventory.Visible = false; main.FeedPanel.Visible = false end
		panel.Visible = true
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		player:SetAttribute("RevivePanelOpen", panel.Visible)
	end)
	local function refresh()
		if busy then return end
		busy = true
		local ok, result = pcall(function() return remote:InvokeServer("Snapshot") end)
		busy = false
		if not ok or not result.Ok then
			snapshot = nil; render()
			if panel.Visible then panel.Status.Text = if ok then messages[result.Code] or "Unable to load recovery." else "Connection error. Retrying…" end
			return
		end
		local selected = records[index]
		records, snapshot = result.Records, result
		receivedAt = os.clock()
		if #records == 0 then panel.Visible = false end
		local unseen = false
		for i, record in records do
			if selected and selected.AttemptId == record.AttemptId then index = i end
			if not seen[record.AttemptId] then unseen = true end
		end
		-- Wait until the explosion presentation/save has ended before prompting.
		if unseen and not result.Busy then
			for _, record in records do seen[record.AttemptId] = true end
			panel.Status.Text = string.format("Restore growth now, or keep level %d. When time runs out, your pet returns at base level.",result.ResetLevel)
			show()
		end
		render()
	end
	gui.Open.Activated:Connect(function() show(); task.spawn(refresh) end)
	panel.Previous.Activated:Connect(function() if not busy then index = math.max(1,index-1); render() end end)
	panel.Next.Activated:Connect(function() if not busy then index = math.min(#records,index+1); render() end end)
	local function decide(action)
		local record = records[index]
		if busy or not record or not snapshot or snapshot.Busy then return end
		if action=="Revive" and not snapshot.CanRevive then return end
		busy = true; render(); panel.Status.Text = "Saving your choice…"
		local ok, result = pcall(function() return remote:InvokeServer(action,record.PetId,record.AttemptId) end)
		busy = false
		panel.Status.Text = if ok and result.Ok then string.format("Pet returned to MY PETS at level %d. Food was not refunded.",result.FeedLevel)
			else if ok then messages[result.Code] or "Unable to revive. Refreshing…" else "Connection interrupted. Refreshing recovery state…"
		if ok and result.Ok then
			-- Remove only the confirmed offer, even if the immediate snapshot is
			-- throttled. Never leave a consumed choice clickable in stale UI.
			for i=#records,1,-1 do
				if records[i].PetId==record.PetId and records[i].AttemptId==record.AttemptId then table.remove(records,i) end
			end
		end
		-- Always re-read state after an ambiguous response; never choose a new
		-- recovery automatically or retry against a different explosion.
		refresh()
		if ok and result.Ok and #records==0 then panel.Visible=false end
	end
	panel.Revive.Activated:Connect(function() decide("Revive") end)
	panel.Later.Activated:Connect(function()
		if not busy and #records==0 then panel.Visible=false else decide("KeepBase") end
	end)
	local function resize()
		panel.UIScale.Scale = math.max(.1,math.min(1,(gui.AbsoluteSize.X-24)/480,(gui.AbsoluteSize.Y-24)/410))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize(); render()
	task.spawn(function() while gui.Parent do refresh(); task.wait(Config.RefreshSeconds) end end)
	return gui
end

return Controller
