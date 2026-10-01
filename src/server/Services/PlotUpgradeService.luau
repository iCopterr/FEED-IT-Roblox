local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local MoneyService = require(script.Parent.MoneyService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks = require(script.Parent.FeedLocks)
local PlotUpgradeService = {}
local saving, lastRequest = {}, {}
local changed

function PlotUpgradeService.GetState(player)
	local data = DataService.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false,Code="Loading"} end
	local cost = Config.UpgradeCost[data.MaxPetSlots+1]
	local nextBase = if data.MaxPetSlots<Config.MaxSlots then data.MaxPetSlots+1 else nil
	return {Ok=true,Level=math.min(data.MaxPetSlots,Config.MaxSlots),Slots=data.MaxPetSlots,
		NextSlots=nextBase,Cost=cost,MaxLevel=data.MaxPetSlots>=Config.MaxSlots,
		CanAfford=cost~=nil and data.Money>=cost,Saving=saving[player]~=nil,
		Money=data.Money,MoneyAt=os.clock(),IncomePerSecond=MoneyService.GetRate(player)}
end

function PlotUpgradeService.RefreshSigns()
	local folder = workspace:FindFirstChild("PlotUpgradeSigns")
	if not folder then return end
	local owners = {}
	for _,player in Players:GetPlayers() do
		local plot = PlotService.GetPlot(player)
		if plot then owners[plot.Name]=player end
	end
	for _,sign in folder:GetChildren() do
		local owner = owners[sign.Name]
		local state = owner and PlotUpgradeService.GetState(owner)
		if owner then PlotService.RefreshSign(owner) end
		local ready = state and state.Ok
		sign:SetAttribute("OwnerUserId",if owner then owner.UserId else 0)
		sign:SetAttribute("Level",if ready then state.Level else nil)
		sign:SetAttribute("Slots",if ready then state.Slots else nil)
		sign:SetAttribute("NextSlots",if ready then state.NextSlots else nil)
		sign:SetAttribute("Cost",if ready then state.Cost else nil)
		sign:SetAttribute("CanAfford",ready and state.CanAfford or false)
		sign:SetAttribute("Saving",ready and state.Saving or false)
		sign:SetAttribute("MaxLevel",ready and state.MaxLevel or false)
	end
end

function PlotUpgradeService.HandleRequest(player, plotName, expectedLevel)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	if type(plotName)~="string" or #plotName>16 or type(expectedLevel)~="number"
		or expectedLevel~=expectedLevel or expectedLevel%1~=0 or expectedLevel<Config.StartingSlots or expectedLevel>Config.MaxSlots then
		return {Ok=false,Code="InvalidRequest"}
	end
	local now = os.clock()
	if now-(lastRequest[player] or -math.huge)<Config.UpgradeCooldown then return {Ok=false,Code="Cooldown"} end
	lastRequest[player]=now
	if saving[player] then return {Ok=false,Code="Saving"} end
	if Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	local plot = PlotService.GetPlot(player)
	if not plot or plot.Name~=plotName then return {Ok=false,Code="NotOwner"} end
	local folder = workspace:FindFirstChild("PlotUpgradeSigns")
	local sign = folder and folder:FindFirstChild(plot.Name)
	local board = sign and sign:FindFirstChild("Board")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not board or not board:IsA("BasePart") or not root or not humanoid or humanoid.Health<=0 then return {Ok=false,Code="Unavailable"} end
	if (root.Position-board.Position).Magnitude>Config.UpgradeDistance then return {Ok=false,Code="TooFar"} end
	local state = PlotUpgradeService.GetState(player)
	if not state.Ok then return state end
	-- Level carries capacity as a compare-and-swap token (not the display tier). Retried/stale clicks cannot
	-- buy another, more expensive level, even after the purchase has saved.
	if expectedLevel~=state.Level then return {Ok=false,Code="LevelChanged"} end
	if state.MaxLevel then return {Ok=false,Code="MaxLevel"} end
	if not state.Cost or not state.NextSlots then return {Ok=false,Code="Unavailable"} end
	if not state.CanAfford then return {Ok=false,Code="NotEnoughMoney"} end
	local data = DataService.GetData(player)
	assert(Locks.Begin(player, "PlotUpgrade"))
	local oldMoney,oldLevel = data.Money,data.MaxPetSlots
	data.Money-=state.Cost
	data.MaxPetSlots+=1
	if not Schema.Validate(data) then
		data.Money,data.MaxPetSlots=oldMoney,oldLevel
		Locks.Finish(player)
		return {Ok=false,Code="InvalidData"}
	end
	-- No yield before both fields change. Keep the committed state on ambiguous
	-- save failure; never refund/rebuy while income may also advance.
	local token = {}
	saving[player]=token
	PlotUpgradeService.RefreshSigns()
	local result=PlotUpgradeService.GetState(player)
	result.Code="Upgraded"
	if changed then changed:FireClient(player,result) end
	task.spawn(function()
		while saving[player]==token and DataService.GetData(player)==data do
			local ok,saved,reason=pcall(DataService.Save,player)
			if ok and saved then
				saving[player]=nil
				Locks.Finish(player)
				PlotUpgradeService.RefreshSigns()
				return
			end
			warn("[PlotUpgradeService] Save pending:",reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
	return result
end

function PlotUpgradeService.Start()
	local request=Instance.new("RemoteFunction")
	request.Name="PlotUpgrade"
	request.OnServerInvoke=PlotUpgradeService.HandleRequest
	request.Parent=game.ReplicatedStorage
	changed=Instance.new("RemoteEvent")
	changed.Name="PlotUpgradeChanged"
	changed.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player)
		saving[player],lastRequest[player]=nil,nil
		task.defer(PlotUpgradeService.RefreshSigns)
	end)
	task.spawn(function()
		while true do PlotUpgradeService.RefreshSigns();task.wait(Config.SignRefreshSeconds) end
	end)
end

return table.freeze(PlotUpgradeService)
