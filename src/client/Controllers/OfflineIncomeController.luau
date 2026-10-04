local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local View = require(script.Parent.Parent.UI.OfflineIncome)
local Sounds = require(script.Parent.Parent.Audio.GameSounds)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local view = View.Create(player:WaitForChild("PlayerGui"))
	local remote = ReplicatedStorage:WaitForChild("OfflineIncome")
	local state, busy, menuOpen = nil, false, GuiService.MenuIsOpen
	local function request(action)
		local ok, result = pcall(function() return remote:InvokeServer(action) end)
		return if ok and type(result) == "table" then result else {Ok = false, Error = "Connection interrupted. Tap to retry."}
	end
	local function menu(open)
		menuOpen = open
		view.Menu(open, state)
		if open then
			task.spawn(function()
				local result = request("State")
				if result.Ok then state = result end
				view.Menu(menuOpen, state)
			end)
		end
	end
	GuiService.MenuOpened:Connect(function() menu(true) end)
	GuiService.MenuClosed:Connect(function() menu(false) end)
	menu(menuOpen)
	view.Collect.Activated:Connect(function()
		if busy or not view.Popup.Visible then return end
		busy = true
		view.Collect.Text = "COLLECTING…"
		local result = request("Collect")
		if result.Ok then
			view.Popup.Visible = false
			-- A lost reply may be retried after the server already credited the
			-- reward. Still acknowledge the visible reward once on confirmation.
			if (result.Amount or 0) > 0 or (state and state.PendingMoney > 0) then Sounds.Play("Buy") end
			if state then state.PendingMoney, state.PendingSeconds = 0, 0 end
		else
			view.Collect.Text = "RETRY COLLECT"
			view.Popup.Duration.Text = result.Error or "Please try again."
		end
		busy = false
	end)
	Sounds.Preload("Buy")
	-- Request after data is ready; retry transient startup/network failures without
	-- relying on an event that could arrive before this controller starts.
	task.spawn(function()
		while view.Gui.Parent do
			if player:GetAttribute("DataLoaded") then
				local result = request("State")
				if result.Ok then
					state = result
					if result.PendingMoney > 0 then view.Show(result) end
					view.Menu(menuOpen, state)
					break
				end
			end
			task.wait(1)
		end
	end)
end

return Controller
