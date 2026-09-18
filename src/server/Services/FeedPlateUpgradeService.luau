local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.FeedPlateConfig)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local MoneyService = require(script.Parent.MoneyService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local Locks = require(script.Parent.FeedLocks)
local FeedPlateUpgradeService = {}
local saving, lastRequest = {}, {}
local changed

function FeedPlateUpgradeService.GetState(player)
	local data = DataService.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false,Code="Loading"} end
	local cost = Config.UpgradeCost[data.FeedPlateLevel+1]
	local nextBase = Config.RiskReduction[data.FeedPlateLevel+1]
	return {Ok=true,Level=math.min(data.FeedPlateLevel,#Config.RiskReduction),Reduction=Config.GetReduction(data.FeedPlateLevel),
		NextReduction=nextBase,Cost=cost,MaxLevel=data.FeedPlateLevel>=#Config.RiskReduction,
		CanAfford=cost~=nil and data.Money>=cost,Saving=saving[player]~=nil,
		Money=data.Money,MoneyAt=os.clock(),IncomePerSecond=MoneyService.GetRate(player)}
end

function FeedPlateUpgradeService.RefreshSigns()
	local folder = workspace:FindFirstChild("FeedPlateUpgradeSigns")
	if not folder then return end
	local owners = {}
	for _,player in Players:GetPlayers() do
		local plot = PlotService.GetPlot(player)
		if plot then owners[plot.Name]=player end
	end
	for _,sign in folder:GetChildren() do
		local owner = owners[sign.Name]
		local state = owner and FeedPlateUpgradeService.GetState(owner)
		local ready = state and state.Ok
		sign:SetAttribute("OwnerUserId",if owner then owner.UserId else 0)
		sign:SetAttribute("Level",if ready then state.Level else nil)
		sign:SetAttribute("Reduction",if ready then state.Reduction else nil)
		sign:SetAttribute("NextReduction",if ready then state.NextReduction else nil)
		sign:SetAttribute("Cost",if ready then state.Cost else nil)
		sign:SetAttribute("CanAfford",ready and state.CanAfford or false)
		sign:SetAttribute("Saving",ready and state.Saving or false)
		sign:SetAttribute("MaxLevel",ready and state.MaxLevel or false)
	end
end

function FeedPlateUpgradeService.HandleRequest(player, plotName, expectedLevel)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	if type(plotName)~="string" or #plotName>16 or type(expectedLevel)~="number"
		or expectedLevel~=expectedLevel or expectedLevel%1~=0 or expectedLevel<1 or expectedLevel>#Config.RiskReduction then
		return {Ok=false,Code="InvalidRequest"}
	end
	local now = os.clock()
	if now-(lastRequest[player] or -math.huge)<Config.UpgradeCooldown then return {Ok=false,Code="Cooldown"} end
	lastRequest[player]=now
	if saving[player] then return {Ok=false,Code="Saving"} end
	if Locks.IsLocked(player) then return {Ok=false,Code="Busy"} end
	local plot = PlotService.GetPlot(player)
	if not plot or plot.Name~=plotName then return {Ok=false,Code="NotOwner"} end
	local folder = workspace:FindFirstChild("FeedPlateUpgradeSigns")
	local sign = folder and folder:FindFirstChild(plot.Name)
	local board = sign and sign:FindFirstChild("Board")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not board or not board:IsA("BasePart") or not root or not humanoid or humanoid.Health<=0 then return {Ok=false,Code="Unavailable"} end
	if (root.Position-board.Position).Magnitude>Config.UpgradeDistance then return {Ok=false,Code="TooFar"} end
	local state = FeedPlateUpgradeService.GetState(player)
	if not state.Ok then return state end
	-- The displayed level is a compare-and-swap token. Retried/stale clicks cannot
	-- buy another, more expensive level, even after the purchase has saved.
	if expectedLevel~=state.Level then return {Ok=false,Code="LevelChanged"} end
	if state.MaxLevel then return {Ok=false,Code="MaxLevel"} end
	if not state.Cost or not state.NextReduction then return {Ok=false,Code="Unavailable"} end
	if not state.CanAfford then return {Ok=false,Code="NotEnoughMoney"} end
	local data = DataService.GetData(player)
	assert(Locks.Begin(player, "PlateUpgrade"))
	local oldMoney,oldLevel = data.Money,data.FeedPlateLevel
	data.Money-=state.Cost
	data.FeedPlateLevel+=1
	if not Schema.Validate(data) then
		data.Money,data.FeedPlateLevel=oldMoney,oldLevel
		Locks.Finish(player)
		return {Ok=false,Code="InvalidData"}
	end
	-- No yield before both fields change. Keep the committed state on ambiguous
	-- save failure; never refund/rebuy while income or farming may also advance.
	local token = {}
	saving[player]=token
	FeedPlateUpgradeService.RefreshSigns()
	local result=FeedPlateUpgradeService.GetState(player)
	result.Code="Upgraded"
	if changed then changed:FireClient(player,result) end
	task.spawn(function()
		while saving[player]==token and DataService.GetData(player)==data do
			local ok,saved,reason=pcall(DataService.Save,player)
			if ok and saved then
				saving[player]=nil
				Locks.Finish(player)
				FeedPlateUpgradeService.RefreshSigns()
				return
			end
			warn("[FeedPlateUpgradeService] Save pending:",reason or saved)
			task.wait(Config.SaveRetrySeconds)
		end
	end)
	return result
end

function FeedPlateUpgradeService.Start()
	local request=Instance.new("RemoteFunction")
	request.Name="FeedPlateUpgrade"
	request.OnServerInvoke=FeedPlateUpgradeService.HandleRequest
	request.Parent=game.ReplicatedStorage
	changed=Instance.new("RemoteEvent")
	changed.Name="FeedPlateUpgradeChanged"
	changed.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player)
		saving[player],lastRequest[player]=nil,nil
		task.defer(FeedPlateUpgradeService.RefreshSigns)
	end)
	task.spawn(function()
		while true do FeedPlateUpgradeService.RefreshSigns();task.wait(Config.SignRefreshSeconds) end
	end)
end

return table.freeze(FeedPlateUpgradeService)
