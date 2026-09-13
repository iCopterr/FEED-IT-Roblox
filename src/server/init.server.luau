local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProjectInfo = require(ReplicatedStorage.Shared.ProjectInfo)

print(string.format("[%s] server started (%s)", ProjectInfo.Name, ProjectInfo.Phase))
