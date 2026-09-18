local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectInfo = require(ReplicatedStorage.Shared.ProjectInfo)

print(string.format("[%s] client started (%s)", ProjectInfo.Name, ProjectInfo.Phase))
-- A missing UI asset must not stall unrelated gameplay controllers.
for _, name in { "HUDController", "CarryController", "IncomeEffectsController", "FarmController", "FeedController" } do
	task.spawn(function()
		local ok, failure = xpcall(function()
			require(script.Controllers[name]).Start()
		end, debug.traceback)
		if not ok then warn(string.format("[%s] startup failed: %s", name, failure)) end
	end)
end
