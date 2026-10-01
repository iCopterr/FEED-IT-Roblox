-- Presentation budgets only; these values never affect economy or hatch odds.
return table.freeze({
	Distance = 100, MaxAuras = 18, MaxBursts = 8,
	LightDistance = 45, MaxLights = 6, ReducedDetailDistance = 55,
	VariantOrbitRate = 30,
	GlowTexture = "rbxasset://textures/particles/flare_main.dds",
	-- Total continuous particle rates rise by rarity: 3, 7, 12, 20, 34, 52.
	AuraProfiles = {
		Epic = {Rank=1, Rate=3, Size=.22, Speed=.6, GlowRate=0, CrownRate=0, Brightness=0},
		Legendary = {Rank=2, Rate=7, Size=.23, Speed=.8, GlowRate=0, CrownRate=0, Brightness=.25},
		Mythic = {Rank=3, Rate=12, Size=.28, Speed=1, GlowRate=0, CrownRate=0, Brightness=.45},
		Fabled = {Rank=4, Rate=18, Size=.34, Speed=1.15, GlowRate=2, CrownRate=0, Brightness=.7},
		Divine = {Rank=5, Rate=27, Size=.4, Speed=1.3, GlowRate=3, CrownRate=4, Brightness=1},
		Celestial = {Rank=6, Rate=40, Size=.48, Speed=1.5, GlowRate=4, CrownRate=8, Brightness=1.5},
	},
	-- Variants set a minimum effect tier; they never downgrade a rare pet's aura.
	VariantAura = {Shiny="Legendary", Rainbow="Mythic", Celestial="Divine"},
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Colors = {
		Epic = Color3.fromRGB(190, 100, 255),
		Legendary = Color3.fromRGB(255, 195, 55), Mythic = Color3.fromRGB(232, 100, 255),
		Fabled = Color3.fromRGB(255,112,55), Divine = Color3.fromRGB(100,235,220),
		Shiny = Color3.fromRGB(255, 243, 145), Rainbow = Color3.fromRGB(120, 255, 240),
		Celestial = Color3.fromRGB(165, 185, 255),
		Success = Color3.fromRGB(135, 255, 100), Explosion = Color3.fromRGB(255, 110, 45),
		Critical = Color3.fromRGB(255, 215, 65),
		MiracleSave = Color3.fromRGB(110, 240, 255), Placement = Color3.fromRGB(255, 240, 165),
	},
})
