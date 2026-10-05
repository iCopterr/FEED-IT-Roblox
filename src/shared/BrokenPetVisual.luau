-- Shared by world pets and inventory/station previews. Never alters the rig,
-- identity or geometry; repair restores the exact original part colors.
local Config = require(script.Parent.Config.ReviveConfig).BrokenVisual
local Visual = {}

function Visual.Apply(model, broken, smoke)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local original = part:GetAttribute("RepairOriginalColor")
		if broken then
			if not original then original = part.Color; part:SetAttribute("RepairOriginalColor",original) end
			part.Color = original:Lerp(Config.SootColor,Config.SootBlend)
		elseif original then
			part.Color = original
			part:SetAttribute("RepairOriginalColor",nil)
		end
	end
	local rim = model:FindFirstChild("BrokenRim")
	local body = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
	local anchor = body and body:FindFirstChild("BrokenSmokeAnchor")
	if not broken then
		if rim then rim:Destroy() end
		if anchor then anchor:Destroy() end
		return
	end
	if not rim then
		rim = Instance.new("Highlight")
		rim.Name = "BrokenRim"; rim.Adornee = model
		rim.DepthMode = Enum.HighlightDepthMode.Occluded
		rim.FillColor = Config.SootColor; rim.FillTransparency = .82
		rim.OutlineColor = Config.WarningColor; rim.OutlineTransparency = .2
		rim.Parent = model
	end
	if not smoke or not body or anchor then return end
	anchor = Instance.new("Attachment")
	anchor.Name = "BrokenSmokeAnchor"; anchor.Parent = body
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BrokenSmoke"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Config.SootColor)
	emitter.Rate = Config.SmokeRate; emitter.Lifetime = NumberRange.new(.7,1.1)
	emitter.Speed = NumberRange.new(.8,1.4); emitter.Acceleration = Vector3.new(0,1,0)
	emitter.SpreadAngle = Vector2.new(15,15); emitter.LightInfluence = 1
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,.7)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,1)})
	emitter.Parent = anchor
end

return table.freeze(Visual)
