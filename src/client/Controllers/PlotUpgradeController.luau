local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local View=require(script.Parent.Parent.UI.PlotUpgradeSignView)
local Controller={}
function Controller.Start()
	local player=Players.LocalPlayer
	local playerGui=player:WaitForChild("PlayerGui")
	local remote=game.ReplicatedStorage:WaitForChild("PlotUpgrade")
	local folder=workspace:WaitForChild("PlotUpgradeSigns")
	local bindings={}
	local messages={NotOwner="This is not your plot.",TooFar="Move closer to the sign.",
		NotEnoughMoney="Not enough Money — let your pets earn!",LevelChanged="Pet capacity updated. Check the new price.",
		Cooldown="",Busy="",Saving="",MaxLevel="Maximum plot level reached!",
		Loading="Loading plot data…",Unavailable="Upgrade unavailable right now."}
	local function bind(sign)
		if bindings[sign] then return end
		local board=sign:FindFirstChild("Board")
		local template=board and board:FindFirstChild("UpgradeGui")
		if not template then return end
		-- Interactive SurfaceGuis must live in PlayerGui and adorn a world part.
		-- This clones the authored sign UI, not a generated screen/layout.
		local gui=template:Clone()
		gui.Name="PlotUpgrade_"..sign.Name
		gui.Adornee=board;gui.Enabled=true;gui.ResetOnSpawn=false
		gui.Parent=playerGui
		template.Enabled=false
		local binding={Gui=gui,Template=template}
		bindings[sign]=binding
		local function render()
			local state={}
			for _,key in {"Level","Slots","NextSlots","Cost","CanAfford","Saving","MaxLevel"} do state[key]=sign:GetAttribute(key) end
			local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local near=root~=nil and (root.Position-board.Position).Magnitude<=Config.UpgradeDistance
			local owner=sign:GetAttribute("OwnerUserId")==player.UserId
			local modal=playerGui:FindFirstChild("FeedYourPetUI")
			local blocked=player:GetAttribute("IndexPanelOpen") or player:GetAttribute("DebugPanelOpen") or player:GetAttribute("RevivePanelOpen") or player:GetAttribute("MerchantPanelOpen")
				or player:GetAttribute("FeedBusy") or (modal and (modal.Inventory.Visible or modal.FeedPanel.Visible))
			local message=if binding.MessageUntil and os.clock()<binding.MessageUntil then binding.Message else nil
			binding.CanBuy=View.Render(gui,state,owner,near,binding.Busy or blocked,message)
			binding.Level=state.Level
		end
		binding.Render=render
		binding.Connection=gui.Buy.Activated:Connect(function()
			render()
			if not binding.CanBuy then return end
			local expected=binding.Level
			binding.Busy=true;render()
			local ok,result=pcall(function() return remote:InvokeServer(sign.Name,expected) end)
			if ok and result.Ok then require(script.Parent.Parent.Audio.GameSounds).Play("Buy") end
			binding.Busy=false
			if not gui.Parent then return end
			binding.Message=if ok and result.Ok then "UPGRADED! "..View.Number(result.Level).." active pet slots"
				else if ok then messages[result.Code] or "Upgrade rejected." else "Connection interrupted. Check the displayed level before retrying."
			binding.MessageUntil=os.clock()+3
			render()
		end)
		render()
	end
	task.spawn(function()
		while folder.Parent do
			for _,sign in folder:GetChildren() do bind(sign) end
			for sign,binding in bindings do
				if sign.Parent~=folder then
					binding.Connection:Disconnect();binding.Gui:Destroy();bindings[sign]=nil
				else binding.Render() end
			end
			task.wait(.2)
		end
		for _,binding in bindings do binding.Connection:Disconnect();binding.Gui:Destroy() end
	end)
end
return Controller
