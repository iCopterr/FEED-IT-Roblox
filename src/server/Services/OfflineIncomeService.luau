local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.OfflineIncomeConfig)
local DataService = require(script.Parent.DataService)
local Earnings = require(script.Parent.Parent.Data.OfflineEarnings)
local Locks = require(script.Parent.FeedLocks)
local Service = {}
local busy, lastRequest, awaitingSave = {}, {}, {}

function Service.State(player)
	local data = DataService.GetData(player)
	if not data then return {Ok = false, Error = "Loading your earnings…"} end
	return {Ok = true, PendingMoney = data.OfflineEarnings.PendingMoney,
		PendingSeconds = data.OfflineEarnings.PendingSeconds, Rate = Earnings.Rate(data),
		MinimumSeconds = Config.MinimumSeconds, MaxSeconds = Config.MaxSeconds}
end

function Service.Collect(player)
	if busy[player] then return {Ok = false, Error = "Saving your earnings…"} end
	local data = DataService.GetData(player)
	if not data then return {Ok = false, Error = "Please wait for your data to load."} end
	if not Locks.Begin(player, "OfflineCollect") then
		return {Ok = false, Code = "Busy", Error = "Finish your current action, then collect."}
	end
	busy[player] = true
	local amount = awaitingSave[player] or Earnings.Collect(data)
	if amount <= 0 then
		busy[player] = nil
		Locks.Finish(player)
		if data.OfflineEarnings.PendingMoney > 0 then return {Ok = false, Error = "Balance limit reached."} end
		return {Ok = true, Amount = 0, Money = data.Money}
	end
	awaitingSave[player] = amount
	-- Never roll back an ambiguous DataStore failure: a retry saves the same
	-- already-applied claim, rather than awarding it again. Rejoin sees either
	-- the pending reward or the credited balance, never both.
	local called, saved = pcall(DataService.Save, player)
	busy[player] = nil
	Locks.Finish(player)
	if not called or not saved then return {Ok = false, Error = "Couldn't confirm save. Tap to retry."} end
	awaitingSave[player] = nil
	return {Ok = true, Amount = amount, Money = data.Money}
end

function Service.Start()
	local remote = Instance.new("RemoteFunction")
	remote.Name = "OfflineIncome"
	remote.OnServerInvoke = function(player, action)
		if action ~= "State" and action ~= "Collect" then return {Ok = false} end
		local now = os.clock()
		local requests = lastRequest[player] or {}
		lastRequest[player] = requests
		if now - (requests[action] or -math.huge) < Config.RequestCooldown then
			return {Ok = false, Code = "Cooldown", Error = "Please wait a moment.", RetryAfter = Config.RequestCooldown - (now - requests[action])}
		end
		requests[action] = now
		return if action == "Collect" then Service.Collect(player) else Service.State(player)
	end
	remote.Parent = ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player], awaitingSave[player] = nil, nil
	end)
end

return Service
