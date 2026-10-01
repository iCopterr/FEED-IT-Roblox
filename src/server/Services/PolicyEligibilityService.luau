local Players = game:GetService("Players")
local RobloxPolicyService = game:GetService("PolicyService")

local Service = {}
local records = {}
local started = false

local MAX_ATTEMPTS = 4

local function publish(player, status, restricted)
	if player.Parent ~= Players then return false end
	records[player] = {
		Status = status,
		ArePaidRandomItemsRestricted = restricted,
	}
	player:SetAttribute("MoneyPacksPolicyStatus", status)
	player:SetAttribute("MoneyPacksAllowed", status == "Allowed")
	if type(restricted) == "boolean" then
		player:SetAttribute("PaidRandomItemsRestricted", restricted)
	else
		player:SetAttribute("PaidRandomItemsRestricted", nil)
	end
	return true
end

local function load(player)
	if not publish(player, "Loading", nil) then return end
	local lastError
	for attempt = 1, MAX_ATTEMPTS do
		if player.Parent ~= Players then return end
		local ok, result = pcall(
			RobloxPolicyService.GetPolicyInfoForPlayerAsync,
			RobloxPolicyService,
			player
		)
		if ok and type(result) == "table" and type(result.ArePaidRandomItemsRestricted) == "boolean" then
			local restricted = result.ArePaidRandomItemsRestricted
			publish(player, if restricted then "Restricted" else "Allowed", restricted)
			return
		end
		lastError = if ok then "missing ArePaidRandomItemsRestricted" else tostring(result)
		if attempt < MAX_ATTEMPTS then task.wait(2 ^ attempt) end
	end
	if player.Parent == Players then
		-- Fail closed. A policy outage must never accidentally expose a prohibited offer.
		publish(player, "Unavailable", nil)
		warn(string.format("[Policy] Money packs disabled for %s: %s", player.Name, lastError or "unknown error"))
	end
end

function Service.MoneyPacksAllowed(player)
	local record = records[player]
	if record and record.Status == "Allowed" then return true, nil end
	if record and record.Status == "Restricted" then return false, "PolicyRestricted" end
	if record and record.Status == "Loading" then return false, "PolicyLoading" end
	return false, "PolicyUnavailable"
end

function Service.Get(player)
	local record = records[player]
	if not record then return nil end
	return table.clone(record)
end

function Service.Start()
	if started then return end
	started = true
	local function joined(player)
		-- Publish the fail-closed state synchronously before the yielding API call.
		publish(player, "Loading", nil)
		task.spawn(load, player)
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player) records[player] = nil end)
	for _, player in Players:GetPlayers() do joined(player) end
end

return Service
