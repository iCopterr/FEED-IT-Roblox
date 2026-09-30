local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectInfo = require(ReplicatedStorage.Shared.ProjectInfo)
task.spawn(function() require(script.Controllers.GrowNowController).Start() end)
task.spawn(function() require(script.Controllers.NotificationController).Start() end)
task.spawn(function() require(script.Controllers.PageFocusController).Start() end)
task.spawn(function() require(script.Controllers.HatchController).Start() end)
task.spawn(function() require(script.Controllers.EggIdleController).Start() end)
task.spawn(function() require(script.Controllers.PenManagerController).Start() end)
task.spawn(function() require(script.Controllers.UIMotionController).Start() end)

print(string.format("[%s] client started (%s)", ProjectInfo.Name, ProjectInfo.Phase))
-- A missing UI asset must not stall unrelated gameplay controllers.
for _, name in { "MusicController", "SoundController", "VFXController", "HUDController", "TutorialController", "IndexController", "PlotUpgradeController", "CarryController", "IncomeEffectsController", "MerchantController", "FeedController", "ConveyorController", "ReviveController", "DebugController" } do
	task.spawn(function()
		local ok, failure = xpcall(function()
			require(script.Controllers[name]).Start()
		end, debug.traceback)
		if not ok then warn(string.format("[%s] startup failed: %s", name, failure)) end
	end)
end
