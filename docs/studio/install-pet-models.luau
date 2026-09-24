-- Moves the 30 reviewed loose art rigs into the gameplay template folder.
-- Safe to rerun after installation: it accepts either the original art name or
-- the final display name, validates every model, then reapplies template state.
assert(game:GetService("RunService"):IsEdit(), "Edit mode required")

local mappings = {
	{"Chicken_RigTest", "Chicken", "test_common", "prototype_egg"},
	{"Boar_RigTest", "Boar", "test_uncommon", "prototype_egg"},
	{"HornedBunny_RigTest", "Horned Bunny", "test_rare", "prototype_egg"},
	{"Fox_RigTest", "Fox", "test_epic", "prototype_egg"},
	{"BlackWolf_RigTest", "Black Wolf", "test_legendary", "prototype_egg"},
	{"BabyGriffin_RigTest", "Baby Griffin", "test_mythic", "prototype_egg"},
	{"EmberDrake_V2", "Ember Drake", "moss_buddy", "advanced_egg"},
	{"FrostWolf_V2", "Frost Wolf", "clover_cub", "advanced_egg"},
	{"StormGriffin_V2", "Storm Griffin", "river_sprite", "advanced_egg"},
	{"LavaGolem_V2", "Lava Golem", "dusk_fox", "advanced_egg"},
	{"ThunderSerpent_V2", "Thunder Serpent", "sun_guardian", "advanced_egg"},
	{"IceDragon_V2", "Ice Dragon", "moon_spirit", "advanced_egg"},
	{"Kitsune_V2", "Kitsune", "crystal_cub", "elite_egg"},
	{"Minotaur_V1", "Minotaur", "prism_buddy", "elite_egg"},
	{"Basilisk_V1", "Basilisk", "amethyst_spirit", "elite_egg"},
	{"Manticore_V1", "Manticore", "solar_phoenix", "elite_egg"},
	{"Chimera_V1", "Chimera", "lunar_guardian", "elite_egg"},
	{"Cerberus_V1", "Cerberus", "astral_dragon", "elite_egg"},
	{"Hydra_V1", "Hydra", "master_pet_1", "master_egg"},
	{"Phoenix_V1", "Phoenix", "master_pet_2", "master_egg"},
	{"Kraken_V1", "Kraken", "master_pet_3", "master_egg"},
	{"AncientWyvern_V1", "Ancient Wyvern", "master_pet_4", "master_egg"},
	{"BoneDragon_V1", "Bone Dragon", "master_pet_5", "master_egg"},
	{"Behemoth_V1", "Behemoth", "master_pet_6", "master_egg"},
	{"AstralKitsune_V1", "Astral Kitsune", "supreme_pet_1", "supreme_egg"},
	{"EclipseGriffin_V1", "Eclipse Griffin", "supreme_pet_2", "supreme_egg"},
	{"VoidLeviathan_V1", "Void Leviathan", "supreme_pet_3", "supreme_egg"},
	{"CelestialDragon_V1", "Celestial Dragon", "supreme_pet_4", "supreme_egg"},
	{"SeraphBeast_V1", "Seraph Beast", "supreme_pet_5", "supreme_egg"},
	{"WorldSerpent_V1", "World Serpent", "supreme_pet_6", "supreme_egg"},
}

local folder = workspace:FindFirstChild("PetsModel")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "PetsModel"
	folder.Parent = workspace
end
assert(folder:IsA("Folder"), "Workspace.PetsModel must be a Folder")

for _, row in mappings do
	local sourceName, templateName, speciesId, eggId = table.unpack(row)
	local loose = workspace:FindFirstChild(sourceName)
	local installed = folder:FindFirstChild(templateName)
	assert(not (loose and installed), "Duplicate pet art for " .. templateName)
	local model = loose or installed
	assert(model and model:IsA("Model"), "Missing pet art for " .. templateName)
	assert(model.PrimaryPart, "Missing PrimaryPart for " .. templateName)
	assert(model:FindFirstChildOfClass("Humanoid"), "Missing Humanoid for " .. templateName)
	for _, item in model:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Script found in " .. templateName)
		if item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
		end
	end
	model.Name = templateName
	model:SetAttribute("SpeciesId", speciesId)
	model:SetAttribute("EggId", eggId)
	model:SetAttribute("TemplateName", templateName)
	model.Parent = folder
end

folder:SetAttribute("StudioOwned", true)
folder:SetAttribute("TemplateCount", #mappings)
assert(#folder:GetChildren() == #mappings, "PetsModel contains unexpected children")
game:GetService("Selection"):Set({folder})
print("Installed", #mappings, "pet models in Workspace.PetsModel")
