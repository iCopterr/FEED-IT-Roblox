local Players = game:GetService("Players")
local Money = require(script.Parent.MoneyService)
local Config = require(game.ReplicatedStorage.Shared.Config.MoneyConfig)
local Service = {}
local started = false

function Service.Update(player)
	if player.Parent ~= Players then return end
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end
	local stat = folder:FindFirstChild(Config.LeaderboardStatName)
	if not stat then
		-- Numeric values retain decimal rates and Roblox's numeric ranking.
		stat = Instance.new("NumberValue")
		stat.Name = Config.LeaderboardStatName
		local primary = Instance.new("BoolValue")
		primary.Name = "IsPrimary"
		primary.Value = true
		primary.Parent = stat
		stat.Parent = folder
	end
	-- Never rank by the payout rate, which includes monetization multipliers.
	stat.Value = Money.GetBaseRate(player)
end

function Service.Start()
	if started then return end
	started = true
	Players.PlayerAdded:Connect(Service.Update)
	for _, player in Players:GetPlayers() do Service.Update(player) end
	task.spawn(function()
		while true do
			task.wait(Config.LeaderboardRefreshSeconds)
			for _, player in Players:GetPlayers() do Service.Update(player) end
		end
	end)
end

return table.freeze(Service)
