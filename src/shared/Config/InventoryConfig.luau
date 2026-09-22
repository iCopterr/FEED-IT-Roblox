-- Presentation only: quick slots do not add pet capacity or grant ownership.
return table.freeze({
	HotbarSlots = 10,
	PollSeconds = 1,
	RarityOrder = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6},
	RarityColors = {
		Common=Color3.fromRGB(135,151,168), Uncommon=Color3.fromRGB(76,184,117),
		Rare=Color3.fromRGB(64,151,242), Epic=Color3.fromRGB(160,99,233),
		Legendary=Color3.fromRGB(237,167,43), Mythic=Color3.fromRGB(235,86,139),
		Egg=Color3.fromRGB(67,183,191),
	},
})
