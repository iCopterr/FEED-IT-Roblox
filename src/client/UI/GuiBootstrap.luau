local GuiBootstrap = {}

function GuiBootstrap.Ensure(playerGui: Instance, template: Instance?, name: string?): ScreenGui
	name = name or "FeedYourPetUI"
	local existing = playerGui:FindFirstChild(name)
	if existing then
		assert(existing:IsA("ScreenGui"), name .. " must be a ScreenGui")
		return existing
	end
	assert(template and template.Name == name and template:IsA("ScreenGui") and template.Archivable,
		"Missing StarterGui." .. name .. " template; check the Rojo connection")
	-- Recover by cloning the authored asset, never by generating a second layout.
	local gui = template:Clone()
	gui.Parent = playerGui
	return gui
end

function GuiBootstrap.Wait(playerGui: Instance, starterGui: Instance, name: string): ScreenGui?
	-- Studio may sync a new StarterGui asset after the player's initial GUI copy.
	-- Recover that case using the authored asset, without replacing an existing UI.
	local existing = playerGui:WaitForChild(name, 3)
	if existing then
		if existing:IsA("ScreenGui") then return existing end
		warn("[UI] PlayerGui." .. name .. " must be a ScreenGui")
		return nil
	end
	local template = starterGui:WaitForChild(name, 3)
	-- Another bootstrap/Roblox may have supplied the GUI during the bounded wait.
	existing = playerGui:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then return existing end
	if template and template:IsA("ScreenGui") and template.Archivable and not existing then
		return GuiBootstrap.Ensure(playerGui, template, name)
	end
	warn("[UI] Missing " .. name .. "; sync StarterGui from default.project.json via Rojo localhost:34872, then restart Play")
	return nil
end

return GuiBootstrap
