-- Presentation budgets only; these values never affect economy or hatch odds.
return table.freeze({
	Distance = 100, MaxAuras = 18, MaxBursts = 8, AuraRate = 5,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Colors = {
		Legendary = Color3.fromRGB(255, 195, 55), Mythic = Color3.fromRGB(232, 100, 255),
		Fabled = Color3.fromRGB(255,112,55), Divine = Color3.fromRGB(100,235,220),
		Shiny = Color3.fromRGB(255, 243, 145), Rainbow = Color3.fromRGB(120, 255, 240),
		Celestial = Color3.fromRGB(165, 185, 255),
		Success = Color3.fromRGB(135, 255, 100), Explosion = Color3.fromRGB(255, 110, 45),
		MiracleSave = Color3.fromRGB(110, 240, 255), Placement = Color3.fromRGB(255, 240, 165),
	},
})
