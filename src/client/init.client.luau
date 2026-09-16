local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectInfo = require(ReplicatedStorage.Shared.ProjectInfo)

print(string.format("[%s] client started (%s)", ProjectInfo.Name, ProjectInfo.Phase))
require(script.Controllers.HUDController).Start()
require(script.Controllers.CarryController).Start()
require(script.Controllers.IncomeEffectsController).Start()
