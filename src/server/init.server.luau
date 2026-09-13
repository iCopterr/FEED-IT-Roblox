local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectInfo = require(ReplicatedStorage.Shared.ProjectInfo)
local DataService = require(script.Services.DataService)

print(string.format("[%s] server started (%s)", ProjectInfo.Name, ProjectInfo.Phase))
DataService.Start()
