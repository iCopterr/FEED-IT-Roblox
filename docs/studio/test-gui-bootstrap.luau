local Bootstrap = require("../../src/client/UI/GuiBootstrap")
local clones, waits = 0, 0
local function container()
	local object = {children = {}}
	function object:FindFirstChild(name) return self.children[name] end
	function object:WaitForChild(name, timeout)
		assert(timeout == 3, "Never wait indefinitely")
		waits += 1
		if self.onWait then self.onWait(name) end
		return self.children[name]
	end
	return object
end
local function template(name)
	local value = {Name = name, Archivable = true}
	function value:IsA(class) return class == "ScreenGui" end
	function value:Clone()
		clones += 1
		local copy = table.clone(self)
		return setmetatable(copy, {__newindex = function(t, key, parent)
			rawset(t, key, parent)
			if key == "Parent" then parent.children[t.Name] = t end
		end})
	end
	return value
end

for _,name in {"SettingsUI", "StarterPackUI"} do
	local pg, starter = container(), container()
	starter.children[name] = template(name)
	local before = clones
	local gui = Bootstrap.Wait(pg, starter, name)
	assert(gui and gui.Parent == pg and gui ~= starter.children[name])
	assert(clones == before + 1, "Clone the existing authored template")
	assert(Bootstrap.Wait(pg, starter, name) == gui and clones == before + 1, "No duplicates or overwrites")
end
local pg, starter = container(), container()
local incoming = template("SettingsUI")
starter.onWait = function() pg.children.SettingsUI = incoming end
local before = clones
assert(Bootstrap.Wait(pg, starter, "SettingsUI") == incoming and clones == before, "Handle arrival during wait")

-- Legacy Ensure callers keep their existing FeedYourPetUI behavior.
local legacy = Bootstrap.Ensure(container(), template("FeedYourPetUI"))
assert(legacy.Name == "FeedYourPetUI")
assert(not pcall(Bootstrap.Ensure, container(), template("WrongUI"), "SettingsUI"), "Reject wrong templates")
print("PASS: bounded waits, authored recovery, existing UI preserved, no duplicates, replication race, legacy compatibility")
