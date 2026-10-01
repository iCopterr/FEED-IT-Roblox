local View = {}
local originals = setmetatable({}, {__mode = "k"})

local DISABLED = Color3.fromRGB(110, 114, 124)
local DISABLED_GRADIENT = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 185, 185))

local descriptions = {
	Loading = "Checking purchase eligibility…",
	Restricted = "Unavailable for this account",
	Unavailable = "Eligibility unavailable • Try rejoining",
}

function View.Apply(card, robux, status, owned, ongoingBenefit, buttonPrefix)
	local buy = card.Buy
	local gradient = buy:FindFirstChildOfClass("UIGradient")
	local saved = originals[card]
	if not saved then
		saved = {
			Description = card.Description.Text,
			Background = buy.BackgroundColor3,
			Image = buy.ImageColor3,
			Gradient = gradient and gradient.Color,
		}
		originals[card] = saved
	end
	status = if status == "Allowed" then "Allowed"
		elseif status == "Restricted" then "Restricted"
		elseif status == "Unavailable" then "Unavailable"
		else "Loading"
	local policyAllowed = status == "Allowed"
	local enabled = policyAllowed and not owned
	local paused = owned and ongoingBenefit and not policyAllowed
	buy.ButtonText.Text = if paused then "POLICY PAUSED"
		elseif owned then "OWNED"
		elseif enabled then (buttonPrefix or "") .. tostring(robux) .. " ROBUX"
		elseif status == "Loading" then "CHECKING…" else "UNAVAILABLE"
	buy.Active = enabled
	buy.Interactable = enabled
	buy.AutoButtonColor = enabled
	buy.BackgroundColor3 = if enabled then saved.Background else DISABLED
	buy.ImageColor3 = if enabled then saved.Image else DISABLED
	card.Description.Text = if paused then "Owned • Benefit paused for this session"
		elseif owned then saved.Description
		elseif policyAllowed then saved.Description else descriptions[status]
	if gradient then gradient.Color = if enabled then saved.Gradient else DISABLED_GRADIENT end
	return enabled
end

return View
