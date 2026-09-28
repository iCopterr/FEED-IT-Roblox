--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(script.Parent.Config.PetConfig)
local PlacementConfig = require(script.Parent.Config.PlacementConfig)
local FeedConfig = require(script.Parent.Config.FeedConfig)

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

-- Species keep their relative size even at maximum growth. Large monsters use
-- a gentler growth rate instead of collapsing into one shared footprint cap.
function PetModels.GetFootprint(speciesId: string, feedLevel: number): number
	local definition = assert(PetConfig.Species[speciesId], "Unknown species")
	local growth = FeedConfig.GetScale(feedLevel) - 1
	local growthPerMultiplier = math.min(definition.BaseFootprint,
		PetConfig.MaxFootprintGrowth / (FeedConfig.MaxVisualScale - 1))
	return definition.BaseFootprint + growth * growthPerMultiplier
end

function PetModels.GetScale(speciesId: string, feedLevel: number): number
	local definition=assert(PetConfig.Species[speciesId], "Unknown species")
	local template=assert(PetModels.GetTemplate(speciesId), "Missing pet template")
	local _,size=template:GetBoundingBox()
	local footprint=Vector2.new(size.X,size.Z).Magnitude
	assert(footprint>0 and definition.BaseFootprint>0, "Invalid pet dimensions")
	return template:GetScale() * PetModels.GetFootprint(speciesId, feedLevel) / footprint
end

-- An attachment can stay within reach even when the torso is several floors up.
function PetModels.GetPickupCFrame(model: Model): CFrame
	local bounds, size = model:GetBoundingBox()
	return bounds * CFrame.new(0, -size.Y / 2 + 2, 0)
end

return table.freeze(PetModels)
