local Collection = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Shared.Config.VFXConfig)
local Signature = require(script.Parent.Parent.UI.VariantSignature)
local Controller = {}
local auras, bursts = {}, {}
local started = false

function Controller.PremiumProfile(model)
	local rarity = Config.AuraProfiles[model:GetAttribute("Rarity")]
	local variant = Config.AuraProfiles[Config.VariantAura[model:GetAttribute("Variant")]]
	if variant and (not rarity or variant.Rank > rarity.Rank) then return variant end
	return rarity
end

function Controller.PremiumColor(model)
	if not Controller.PremiumProfile(model) then return nil end
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
	if kind=="Critical" then
		local flash=emitter(Config.Colors.Critical)
		flash.Name="CriticalShockwave";flash.Texture=Config.GlowTexture;flash.Speed=NumberRange.new(0)
		flash.Lifetime=NumberRange.new(.6);flash.LightEmission=1
		flash.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,9),NumberSequenceKeypoint.new(1,15)})
		flash.Transparency=NumberSequence.new(.35,1);flash.Parent=anchor;flash:Emit(2)
	end
	task.delay(1.5, function() bursts[anchor] = nil; anchor:Destroy() end)
	return true
end

local function attachment(name, parent, position)
	local anchor=Instance.new("Attachment")
	anchor.Name=name;anchor.Position=position or Vector3.zero;anchor.Parent=parent
	return anchor
end

local function makeAura(entry)
	local anchor=attachment("PremiumPetVFX",entry.Body)
	local state={Anchor=anchor, Body=entry.Body, Rank=entry.Profile.Rank, Emitters={}, Variant=entry.Model:GetAttribute("Variant")}
	state.Signature=Signature.Create(entry.Model,anchor,state.Variant)
	local function add(parent,name,rate,kind)
		local effect=emitter(entry.Color);effect.Name=name;effect.Parent=parent
		table.insert(state.Emitters,{Effect=effect,Rate=rate,Kind=kind})
	end
	local p=entry.Profile
	if p.Rank>=3 then
		state.Left=attachment("LeftMotes",anchor)
		state.Right=attachment("RightMotes",anchor)
		add(anchor,"PetSparkles",p.Rate*.5,"Sparkles")
		add(state.Left,"PetSparkles",p.Rate*.25,"Sparkles")
		add(state.Right,"PetSparkles",p.Rate*.25,"Sparkles")
	else add(anchor,"PetSparkles",p.Rate,"Sparkles") end
	if p.GlowRate>0 then add(anchor,"SoftAura",p.GlowRate,"Glow") end
	if p.CrownRate>0 then
		state.Crown=attachment("Crown",anchor)
		add(state.Crown,"CrownStars",p.CrownRate,"Crown")
	end
	return state
end

local function updateAura(state,entry,lit)
	local p=entry.Profile
	local scale=entry.Model:GetScale()
	if state.Scale~=scale then
		-- Recompute after feeding growth; invisible roots alone miss wings/antlers.
		local bounds,size=entry.Model:GetBoundingBox()
		state.Offset=entry.Body.CFrame:PointToObjectSpace(bounds.Position)
		state.Extent=Vector3.new(math.min(size.X,16),math.min(size.Y,16),math.min(size.Z,16))
		state.Scale=scale
	end
	local extent=state.Extent
	local unit=math.clamp(extent.Y/5,.65,2)
	-- Sparse tiers emit above the silhouette so their few sparks are not
	-- swallowed by opaque torso geometry.
	state.Anchor.Position=state.Offset+(if p.Rank<=2 then Vector3.new(0,extent.Y*.5+.08,0) else Vector3.zero)
	if state.Left then
		state.Left.Position=Vector3.new(-extent.X*.28,-extent.Y*.12,0)
		state.Right.Position=Vector3.new(extent.X*.28,-extent.Y*.12,0)
	end
	if state.Crown then state.Crown.Position=Vector3.new(0,extent.Y*.47,0) end
	local color=if entry.Model:GetAttribute("Variant")=="Rainbow" then Color3.fromHSV((os.clock()*.15)%1,.65,1) else entry.Color
	local detail=if entry.Distance>Config.ReducedDetailDistance then .4 else 1
	state.Reduced=detail<1
	if state.Signature then state.Signature.Update(os.clock(),entry.Body.CFrame:PointToWorldSpace(state.Offset),extent,state.Reduced) end
	for _,layer in state.Emitters do
		local effect=layer.Effect
		effect.Color=ColorSequence.new(color,color:Lerp(Color3.new(1,1,1),.5))
		effect.Rate=layer.Rate*detail
		effect.LightEmission=.8;effect.LightInfluence=0
		effect.LockedToPart=true
		effect.Lifetime=NumberRange.new(1,1.8)
		effect.Speed=NumberRange.new(p.Speed*unit*.4,p.Speed*unit*1.6)
		effect.Acceleration=Vector3.new(0,.7*unit,0)
		effect.Drag=.6
		local size=p.Size*unit
		if layer.Kind=="Glow" then
			effect.Texture=Config.GlowTexture
			effect.Speed=NumberRange.new(.05,.15)
			effect.Acceleration=Vector3.zero
			effect.Lifetime=NumberRange.new(1.3,1.8)
			size=math.clamp(extent.Magnitude*.35,1,6)
			effect.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.35,.88),NumberSequenceKeypoint.new(1,1)})
		elseif layer.Kind=="Crown" then
			effect.Speed=NumberRange.new(.5*unit,1.8*unit)
			effect.Acceleration=Vector3.new(0,.35,0)
			size*=1.25
		end
		effect.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.2,size),NumberSequenceKeypoint.new(.7,size*.6),NumberSequenceKeypoint.new(1,0)})
	end
	local light=state.Anchor:FindFirstChild("PremiumLight")
	if lit then
		if not light then light=Instance.new("PointLight");light.Name="PremiumLight";light.Shadows=false;light.Parent=state.Anchor end
		light.Color=color;light.Brightness=p.Brightness;light.Range=math.clamp(extent.Y*1.6,4,12)
	elseif light then light:Destroy() end
end

function Controller.Refresh()
	local selected, candidates = {}, {}
	local camera=workspace.CurrentCamera
	local models=Collection:GetTagged("PetVisual")
	for _,egg in Collection:GetTagged("VariantEggVisual") do if not table.find(models,egg) then table.insert(models,egg) end end
	for _, model in models do
		local body = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true))
		local profile=Controller.PremiumProfile(model)
		local color = Controller.PremiumColor(model)
		if body and profile and color and model:IsDescendantOf(workspace) and not model:GetAttribute("Presenting")
			and not model:GetAttribute("Hatching") and not model:GetAttribute("ClientPetsHidden") and nearby(body.Position) then
			table.insert(candidates, {Model=model, Body=body, Profile=profile, Color=color, Distance=(camera.CFrame.Position-body.Position).Magnitude})
		end
	end
	table.sort(candidates, function(a,b) return a.Distance<b.Distance end)
	local lights=0
	for i=1, math.min(#candidates, Config.MaxAuras) do
		local entry=candidates[i]; local model=entry.Model
		selected[model]=true
		local state=auras[model]
		if state and (state.Rank~=entry.Profile.Rank or state.Body~=entry.Body or state.Anchor.Parent~=entry.Body or state.Variant~=model:GetAttribute("Variant")) then
			state.Anchor:Destroy();auras[model]=nil;state=nil
		end
		if not state then state=makeAura(entry);auras[model]=state end
		local lit=entry.Profile.Brightness>0 and entry.Distance<=Config.LightDistance and lights<Config.MaxLights
		if lit then lights+=1 end
		updateAura(state,entry,lit)
	end
	for model, state in auras do
		if not selected[model] then state.Anchor:Destroy(); auras[model]=nil end
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
	local elapsed=0
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		elapsed+=dt
		if elapsed<1/Config.VariantOrbitRate then return end
		elapsed=0
		for model,state in auras do
			if state.Signature and state.Extent and state.Anchor.Parent and not model:GetAttribute("ClientPetsHidden") then
				state.Signature.Update(os.clock(),state.Body.CFrame:PointToWorldSpace(state.Offset),state.Extent,state.Reduced)
			end
		end
	end)
end
return Controller
