--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(script.Parent.Config.PetConfig)
local PlacementConfig = require(script.Parent.Config.PlacementConfig)

local PetModels = {}

function PetModels.GetFolder(): Folder?
	local folder = ReplicatedStorage:FindFirstChild(PlacementConfig.TemplateFolderName)
	return if folder and folder:IsA("Folder") then folder else nil
end

function PetModels.GetTemplate(speciesId: string): Model?
	local definition = PetConfig.Species[speciesId]
	if not definition then return nil end
	local folder = PetModels.GetFolder()
	local template = folder and folder:FindFirstChild(definition.TemplateName)
	return if template and template:IsA("Model") then template else nil
end

return table.freeze(PetModels)
