local GuiBootstrap = {}

function GuiBootstrap.Ensure(playerGui: Instance, template: Instance?): ScreenGui
	local existing = playerGui:FindFirstChild("FeedYourPetUI")
	if existing then
		assert(existing:IsA("ScreenGui"), "FeedYourPetUI must be a ScreenGui")
		return existing
	end
	assert(template and template:IsA("ScreenGui") and template.Archivable,
		"Missing StarterGui.FeedYourPetUI template; check the Rojo connection")
	-- Recover by cloning the authored asset, never by generating a second layout.
	local gui = template:Clone()
	gui.Parent = playerGui
	return gui
end

return GuiBootstrap
