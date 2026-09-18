local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config.FarmConfig)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local FarmService = require(script.Parent.FarmService)
local MoneyService = require(script.Parent.MoneyService)
local Schema = require(script.Parent.Parent.Data.PlayerDataSchema)
local FarmUpgradeService = {}
local saving, lastRequest = {}, {}
local changed

function FarmUpgradeService.GetState(player)
	local data = DataService.GetData(player)
	if not data or not Schema.Validate(data) then return {Ok=false,Code="Loading"} end
	local cost = Config.UpgradeCost[data.FarmLevel+1]
	local nextBase = Config.FoodPerSecond[data.FarmLevel+1]
	return {Ok=true,Level=data.FarmLevel,Rate=FarmService.GetRate(player),
		NextRate=nextBase and nextBase*data.FarmPower,Cost=cost,MaxLevel=data.FarmLevel>=#Config.FoodPerSecond,
		CanAfford=cost~=nil and data.Money>=cost,Saving=saving[player]~=nil,
		Money=data.Money,MoneyAt=os.clock(),IncomePerSecond=MoneyService.GetRate(player)}
end

function FarmUpgradeService.RefreshSigns()
	local folder = workspace:FindFirstChild("FarmUpgradeSigns")
	if not folder then return end
	local owners = {}
	for _,player in Players:GetPlayers() do
		local plot = PlotService.GetPlot(player)
		if plot then owners[plot.Name]=player end
	end
	for _,sign in folder:GetChildren() do
		local owner = owners[sign.Name]
		local state = owner and FarmUpgradeService.GetState(owner)
		local ready = state and state.Ok
		sign:SetAttribute("OwnerUserId",if owner then owner.UserId else 0)
		sign:SetAttribute("Level",if ready then state.Level else nil)
		sign:SetAttribute("Rate",if ready then state.Rate else nil)
		sign:SetAttribute("NextRate",if ready then state.NextRate else nil)
		sign:SetAttribute("Cost",if ready then state.Cost else nil)
		sign:SetAttribute("CanAfford",ready and state.CanAfford or false)
		sign:SetAttribute("Saving",ready and state.Saving or false)
		sign:SetAttribute("MaxLevel",ready and state.MaxLevel or false)
	end
end

function FarmUpgradeService.HandleRequest(player, plotName, expectedLevel)
	if player.Parent~=Players then return {Ok=false,Code="Loading"} end
	if type(plotName)~="string" or #plotName>16 or type(expectedLevel)~="number"
		or expectedLevel~=expectedLevel or expectedLevel%1~=0 or expectedLevel<1 or expectedLevel>#Config.FoodPerSecond then
		return {Ok=false,Code="InvalidRequest"}
	end
	local now = os.clock()
	if now-(lastRequest[player] or -math.huge)<Config.UpgradeCooldown then return {Ok=false,Code="Cooldown"} end
	lastRequest[player]=now
	if saving[player] then return {Ok=false,Code="Saving"} end
	local plot = PlotService.GetPlot(player)
	if not plot or plot.Name~=plotName then return {Ok=false,Code="NotOwner"} end
	local folder = workspace:FindFirstChild("FarmUpgradeSigns")
	local sign = folder and folder:FindFirstChild(plot.Name)
	local board = sign and sign:FindFirstChild("Board")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not board or not board:IsA("BasePart") or not root or not humanoid or humanoid.Health<=0 then return {Ok=false,Code="Unavailable"} end
	if (root.Position-board.Position).Magnitude>Config.UpgradeDistance then return {Ok=false,Code="TooFar"} end
	local state = FarmUpgradeService.GetState(player)
	if not state.Ok then return state end
	-- The displayed level is a compare-and-swap token. Retried/stale clicks cannot
	-- buy another, more expensive level, even after the purchase has saved.
	if expectedLevel~=state.Level then return {Ok=false,Code="LevelChanged"} end
	if state.MaxLevel then return {Ok=false,Code="MaxLevel"} end
	if not state.Cost or not state.NextRate then return {Ok=false,Code="Unavailable"} end
	if not state.CanAfford then return {Ok=false,Code="NotEnoughMoney"} end
	local data = DataService.GetData(player)
	local oldMoney,oldLevel = data.Money,data.FarmLevel
	data.Money-=state.Cost
	data.FarmLevel+=1
	if not Schema.Validate(data) then
		data.Money,data.FarmLevel=oldMoney,oldLevel
		return {Ok=false,Code="InvalidData"}
	end
	-- No yield before both fields change. Keep the committed state on ambiguous
	-- save failure; never refund/rebuy while income or farming may also advance.
	local token = {}
	saving[player]=token
	FarmUpgradeService.RefreshSigns()
	local result=FarmUpgradeService.GetState(player)
	result.Code="Upgraded"
	if changed then changed:FireClient(player,result) end
	task.spawn(function()
		while saving[player]==token and DataService.GetData(player)==data do
			local ok,saved,reason=pcall(DataService.Save,player)
			if ok and saved then
				saving[player]=nil
				FarmUpgradeService.RefreshSigns()
				return
			end
			warn("[FarmUpgradeService] Save pending:",reason or saved)
			task.wait(Config.UpgradeSaveRetrySeconds)
		end
	end)
	return result
end

function FarmUpgradeService.Start()
	local request=Instance.new("RemoteFunction")
	request.Name="FarmUpgrade"
	request.OnServerInvoke=FarmUpgradeService.HandleRequest
	request.Parent=game.ReplicatedStorage
	changed=Instance.new("RemoteEvent")
	changed.Name="FarmUpgradeChanged"
	changed.Parent=game.ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player)
		saving[player],lastRequest[player]=nil,nil
		task.defer(FarmUpgradeService.RefreshSigns)
	end)
	task.spawn(function()
		while true do FarmUpgradeService.RefreshSigns();task.wait(Config.SignRefreshSeconds) end
	end)
end

return table.freeze(FarmUpgradeService)
