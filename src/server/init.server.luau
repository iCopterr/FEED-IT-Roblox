local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectInfo = require(ReplicatedStorage.Shared.ProjectInfo)
local DataService = require(script.Services.DataService)
local PetService = require(script.Services.PetService)

print(string.format("[%s] server started (%s)", ProjectInfo.Name, ProjectInfo.Phase))
DataService.Start()
PetService.Start()
require(script.Services.PlotService).Start()
require(script.Services.UIService).Start()
