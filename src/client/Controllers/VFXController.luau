local Collection = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config.VFXConfig)
local Controller = {}
local auras, bursts = {}, {}
local started = false

function Controller.PremiumColor(model)
	return Config.Colors[model:GetAttribute("Variant")] or Config.Colors[model:GetAttribute("Rarity")]
end

local function nearby(position)
	local camera = workspace.CurrentCamera
	return camera and (camera.CFrame.Position-position).Magnitude <= Config.Distance
end

local function emitter(color)
	local effect = Instance.new("ParticleEmitter")
	effect.Name = "PetSparkles"
	effect.Texture = Config.Texture
	effect.Color = ColorSequence.new(color)
	effect.LightEmission = .65
	effect.Lifetime = NumberRange.new(.6, 1.2)
	effect.Speed = NumberRange.new(.5, 1.5)
	effect.SpreadAngle = Vector2.new(180, 180)
	effect.Rotation = NumberRange.new(0, 360)
	effect.RotSpeed = NumberRange.new(-50, 50)
	effect.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, .12), NumberSequenceKeypoint.new(.25, .3), NumberSequenceKeypoint.new(1, 0)})
	effect.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(.65, .3), NumberSequenceKeypoint.new(1, 1)})
	effect.Rate = 0
	return effect
end

function Controller.Burst(position, kind)
	if typeof(position) ~= "Vector3" or not nearby(position) then return false end
	local count = 0
	for _ in bursts do count += 1 end
	if count >= Config.MaxBursts then return false end
	local anchor = Instance.new("Attachment")
	anchor.Name = "PetVFXBurst"; anchor.Position = position; anchor.Parent = workspace.Terrain
	local effect = emitter(Config.Colors[kind] or Config.Colors.Success)
	effect.Speed = NumberRange.new(3, 8)
	effect.Drag = 3
	effect.Parent = anchor
	bursts[anchor] = true
	effect:Emit(if kind == "Explosion" then 32 else 18)
	task.delay(1.5, function() bursts[anchor] = nil; anchor:Destroy() end)
	return true
end

function Controller.Refresh()
	local selected, candidates = {}, {}
	for _, model in Collection:GetTagged("PetVisual") do
		local body = model:IsA("Model") and model.PrimaryPart
		local color = Controller.PremiumColor(model)
		if body and color and model:IsDescendantOf(workspace) and not model:GetAttribute("Presenting") and nearby(body.Position) then
			table.insert(candidates, {Model=model, Body=body, Color=color, Distance=(workspace.CurrentCamera.CFrame.Position-body.Position).Magnitude})
		end
	end
	table.sort(candidates, function(a,b) return a.Distance<b.Distance end)
	for i=1, math.min(#candidates, Config.MaxAuras) do
		local entry=candidates[i]; local model=entry.Model
		selected[model]=true
		if not auras[model] then
			local anchor=Instance.new("Attachment"); anchor.Name="PremiumPetVFX"; anchor.Parent=entry.Body
			local bounds,size=model:GetBoundingBox()
			anchor.Position=entry.Body.CFrame:PointToObjectSpace(bounds.Position+Vector3.new(0,size.Y/2+.25,0))
			local effect=emitter(entry.Color); effect.Rate=Config.AuraRate; effect.Parent=anchor
			auras[model]=anchor
		end
		local effect=auras[model].PetSparkles
		effect.Color=if model:GetAttribute("Variant")=="Rainbow" then ColorSequence.new(Color3.fromHSV((os.clock()*.15)%1,.65,1)) else ColorSequence.new(entry.Color)
	end
	for model, anchor in auras do
		if not selected[model] then anchor:Destroy(); auras[model]=nil end
	end
end

function Controller.Start()
	if started then return end; started=true
	Collection:GetInstanceAddedSignal("PetVisual"):Connect(function(model)
		task.defer(function()
			if model:IsDescendantOf(workspace) and model.PrimaryPart then Controller.Burst(model.PrimaryPart.Position,"Placement") end
		end)
	end)
	task.spawn(function() while true do Controller.Refresh(); task.wait(.5) end end)
end
return Controller
