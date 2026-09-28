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

-- A footprint-based size keeps long tails and broad wings proportional while
-- making authoring/export scale irrelevant. Large species start imposing, while
-- the world-footprint cap keeps highly fed pets inside the pen's narrow side.
function PetModels.GetScale(speciesId: string, feedLevel: number): number
	local definition=assert(PetConfig.Species[speciesId], "Unknown species")
	local template=assert(PetModels.GetTemplate(speciesId), "Missing pet template")
	local _,size=template:GetBoundingBox()
	local footprint=Vector2.new(size.X,size.Z).Magnitude
	assert(footprint>0 and definition.BaseFootprint>0, "Invalid pet dimensions")
	local baseScale = template:GetScale() * definition.BaseFootprint / footprint
	local growthScale = require(script.Parent.Config.FeedConfig).GetScale(feedLevel)
	local cappedGrowthScale = math.min(growthScale, PetConfig.MaxWorldFootprint / definition.BaseFootprint)
	return baseScale * cappedGrowthScale
end

return table.freeze(PetModels)
