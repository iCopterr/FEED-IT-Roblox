-- Session-only presentation gate. Ownership and rewards remain server authority.
local Offer = {}
Offer.__index = Offer

function Offer.new(completed)
	return setmetatable({ Completed = completed, SawTutorial = false, Consumed = false }, Offer)
end

function Offer:Observe(step, now)
	if self.Consumed then return end
	if step and step ~= self.Completed then
		self.SawTutorial = true
	elseif step == self.Completed and self.SawTutorial and not self.CompletedAt then
		self.CompletedAt = now
	end
end

function Offer:Take(now, owned, busy, alive)
	if self.Consumed or not self.CompletedAt then return false end
	if owned == true then self.Consumed = true; return false end
	-- Wait for replicated ownership and the final feed's server presentation lock.
	-- A short settle also prevents opening between completion/lock replication.
	if owned ~= false or busy or not alive or now - self.CompletedAt < 1 then return false end
	self.Consumed = true
	return true
end

return Offer
