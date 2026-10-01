local View = {}
local originals = setmetatable({}, {__mode = "k"})

local DISABLED = Color3.fromRGB(110, 114, 124)
local DISABLED_GRADIENT = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 185, 185))

local descriptions = {
	Loading = "Checking purchase eligibility…",
	Restricted = "Unavailable for this account",
	Unavailable = "Eligibility unavailable • Try rejoining",
}

function View.Apply(card, robux, status)
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
	local allowed = status == "Allowed"
	buy.ButtonText.Text = if allowed then tostring(robux) .. " ROBUX"
		elseif status == "Loading" then "CHECKING…" else "UNAVAILABLE"
	buy.Active = allowed
	buy.Interactable = allowed
	buy.AutoButtonColor = allowed
	buy.BackgroundColor3 = if allowed then saved.Background else DISABLED
	buy.ImageColor3 = if allowed then saved.Image else DISABLED
	card.Description.Text = if allowed then saved.Description else descriptions[status]
	if gradient then gradient.Color = if allowed then saved.Gradient else DISABLED_GRADIENT end
	return allowed
end

return View
