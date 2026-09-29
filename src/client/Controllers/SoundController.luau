local Sounds = require(script.Parent.Parent.Audio.GameSounds)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local gui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local bound = setmetatable({}, {__mode = "k"})
	local function bind(button)
		if not button:IsA("GuiButton") or bound[button] then return end
		bound[button] = true
		button.Activated:Connect(function()
			if button:GetAttribute("SuppressClickSound") ~= true then
				Sounds.Play("Click", 2)
			end
		end)
	end
	gui.DescendantAdded:Connect(bind)
	for _,item in gui:GetDescendants() do bind(item) end
end

return Controller
