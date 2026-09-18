-- Independent of services to avoid circular dependencies. Only the server writes it.
local locks = {}
local FeedLocks = {}
function FeedLocks.IsLocked(player, id)
	return locks[player] ~= nil and (id == nil or locks[player] == id)
end
function FeedLocks.Begin(player, id)
	if locks[player] then return false end
	locks[player] = id
	player:SetAttribute("FeedBusy", true)
	return true
end
function FeedLocks.Finish(player)
	locks[player] = nil
	player:SetAttribute("FeedBusy", nil)
end
return table.freeze(FeedLocks)
