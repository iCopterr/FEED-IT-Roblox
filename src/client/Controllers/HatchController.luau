local Storage = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Eggs = require(Storage.Shared.Config.EggConfig)
local Timing = require(Storage.Shared.Config.HatchAnimationConfig)
local Sounds = require(script.Parent.Parent.Audio.GameSounds)
local Controller = {}
local seen = {}
local started, active = false, 0

local function play(result)
	local definition = Eggs.Definitions[result.EggId]
	local templates = workspace:FindFirstChild("EggTemplates")
	local template = templates and templates:FindFirstChild(definition and definition.TemplateName or result.EggId)
	if not template then return end
	local egg = template:Clone()
	egg.Name = "HatchReveal_" .. result.EggUid
	for _, item in egg:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("LayerCollector") or item:IsA("ProximityPrompt") then item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored = true; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false
		end
	end
	egg:PivotTo(result.HatchOrigin)
	egg.Parent = workspace
	Debris:AddItem(egg, Timing.Duration + 2)
	local hidden = {}
	local disabled = {}
	local originals = {}
	local plots = workspace:FindFirstChild("PlayerPlots")
	if plots then
		for _, plot in plots:GetChildren() do
			local pen = plot:FindFirstChild("Pen")
			local original = pen and pen:FindFirstChild("Egg_" .. result.EggUid)
			if original then
				table.insert(originals,original)
				for _, item in original:GetDescendants() do
				if item:IsA("BasePart") then hidden[item]=item.LocalTransparencyModifier;item.LocalTransparencyModifier=1 end
				if item:IsA("ParticleEmitter") or item:IsA("Light") or item:IsA("BillboardGui") or item:IsA("ProximityPrompt") then
					disabled[item]=item.Enabled;item.Enabled=false
				end
			end end
		end
	end
	local stopHatching = Sounds.Play("Hatching", Timing.Duration + 1)
	local ok, failure = xpcall(function()
		local shell = assert(egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true))
		local baseScale=egg:GetScale()
		local _,boundsSize=egg:GetBoundingBox()
		local radius=math.clamp(math.max(boundsSize.X,boundsSize.Z)*.65,1.5,5)
		local tint=shell.Color:Lerp(Color3.fromRGB(255,220,130),.55)
		local glow=Instance.new("Highlight")
		glow.Name="HatchEnergy";glow.Adornee=egg;glow.DepthMode=Enum.HighlightDepthMode.Occluded
		glow.FillColor=tint;glow.OutlineColor=Color3.new(1,1,1)
		glow.FillTransparency=1;glow.OutlineTransparency=1;glow.Parent=egg
		local light = Instance.new("PointLight")
		light.Color = tint; light.Range = Timing.MaxLightRange; light.Brightness = 0; light.Shadows = false; light.Parent = shell
		local attachment = Instance.new("Attachment"); attachment.Parent = shell
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/flare_main.dds"
		burst.Color = ColorSequence.new(Color3.new(1,1,1))
		burst.LightEmission = 1; burst.Rate = 0; burst.Speed = NumberRange.new(1,3)
		burst.SpreadAngle = Vector2.new(180,180); burst.Lifetime = NumberRange.new(.5,.8)
		burst.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,4),NumberSequenceKeypoint.new(1,6)})
		burst.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.25,.35),NumberSequenceKeypoint.new(1,1)})
		burst.Parent = attachment
		local shock=burst:Clone()
		shock.Name="HatchShockwave";shock.Speed=NumberRange.new(0)
		shock.Lifetime=NumberRange.new(.55);shock.Rotation=NumberRange.new(0,360)
		shock.Color=ColorSequence.new(Color3.new(1,1,1),tint)
		shock.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(.2,radius*3),NumberSequenceKeypoint.new(1,radius*6)})
		shock.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(.25,.5),NumberSequenceKeypoint.new(1,1)})
		shock.Parent=attachment
		local sparks=Instance.new("ParticleEmitter")
		sparks.Name="HatchSparks";sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color=ColorSequence.new(Color3.new(1,1,1),tint);sparks.LightEmission=1
		sparks.Rate=0;sparks.Speed=NumberRange.new(8,15);sparks.Drag=5
		sparks.Acceleration=Vector3.new(0,-10,0);sparks.SpreadAngle=Vector2.new(180,180)
		sparks.Lifetime=NumberRange.new(.45,.8)
		sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(.2,.55),NumberSequenceKeypoint.new(1,0)})
		sparks.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.65,.1),NumberSequenceKeypoint.new(1,1)})
		sparks.Parent=attachment
		-- Four orbiting spark points: attachments only, no extra physical shell parts.
		local orbiters={}
		for i=1,4 do
			local point=Instance.new("Attachment");point.Name="HatchOrbit";point.Parent=shell
			local trail=sparks:Clone();trail.Name="OrbitSpark";trail.Speed=NumberRange.new(0)
			trail.Acceleration=Vector3.zero;trail.Rate=8;trail.Lifetime=NumberRange.new(.15,.25)
			trail.Size=NumberSequence.new(.22);trail.Parent=point
			table.insert(orbiters,{Point=point,Emitter=trail})
		end
		local start = result.EndsAt - Timing.Duration
		local revealed = false
		local aftershock = false
		local lastPulse=-1
		egg:SetAttribute("Stage", "Float")
		repeat
			local t = math.max(0, workspace:GetServerTimeNow() - start)
			local rise = math.clamp(t / Timing.RiseSeconds,0,1)
			local charge = math.clamp((t-Timing.RiseSeconds)/(Timing.BurstAt-Timing.RiseSeconds),0,1)
			local shake=charge*charge
			local pulse=math.max(0,math.sin(charge*math.pi*6))
			local position = result.HatchOrigin * CFrame.new(0,Timing.RiseHeight*(1-(1-rise)^3)+math.sin(t*8)*.1*(1-charge),0)
			if not revealed then
				egg:ScaleTo(baseScale*(1+.045*pulse*charge-.08*math.clamp((charge-.88)/.12,0,1)))
				egg:PivotTo(position*CFrame.Angles(math.sin(t*34)*shake*.13,charge*charge*math.pi*2,math.sin(t*47)*shake*.23))
				glow.FillTransparency=1-charge*.65;glow.OutlineTransparency=1-charge*.85
				light.Brightness=charge*2+pulse*charge*2
				for i,orbit in orbiters do
					local angle=t*(3+charge*8)+i*math.pi/2
					local offset=Vector3.new(math.cos(angle),math.sin(angle*2)*.3,math.sin(angle))*radius*(1-charge*.55)
					orbit.Point.WorldPosition=position.Position+offset
				end
				local beat=math.floor(charge*3)
				if beat>lastPulse and charge>0 then lastPulse=beat;sparks:Emit(3) end
			end
			if t >= Timing.RiseSeconds and not revealed then egg:SetAttribute("Stage", "Shake") end
			if t >= Timing.BurstAt and not revealed then
				stopHatching()
				Sounds.Play("HatchFinish")
				revealed = true; egg:SetAttribute("Stage", "Light");burst:Emit(12);sparks:Emit(Timing.SparkCount);shock:Emit(2)
				glow.Enabled=false
				for _, item in egg:GetDescendants() do
					if item:IsA("BasePart") then item.Transparency = 1 end
					if item:IsA("ParticleEmitter") and item ~= burst and item ~= sparks and item ~= shock then item.Enabled = false; item:Clear() end
				end
			end
			if revealed and not aftershock and t>=Timing.BurstAt+Timing.AftershockDelay then
				aftershock=true;sparks:Emit(16);shock:Emit(1)
			end
			if revealed then light.Brightness = 5 * math.clamp(1-(t-Timing.BurstAt)/(Timing.Duration-Timing.BurstAt),0,1)^2 end
			if t >= Timing.Duration then break end
			Run.RenderStepped:Wait()
		until not egg.Parent
	end, debug.traceback)
	stopHatching()
	egg:Destroy()
	-- The reveal deadline and server removal replication can arrive on different
	-- frames. Do not flash the original shell back while its hatch is committing.
	task.spawn(function()
		local deadline=os.clock()+Timing.OriginalRestoreTimeout
		while ok and os.clock()<deadline do
			local waiting=false
			for _,original in originals do
				if original.Parent and original:GetAttribute("Hatching")==true then waiting=true;break end
			end
			if not waiting then break end
			task.wait(.05)
		end
		for part, transparency in hidden do if part.Parent then part.LocalTransparencyModifier=transparency end end
		for item, enabled in disabled do if item.Parent then item.Enabled=enabled end end
	end)
	if not ok then warn("[HatchController]", failure) end
end

function Controller.Enqueue(result)
	if type(result) ~= "table" or not result.Ok or result.Code ~= "HatchStarted" or type(result.EndsAt) ~= "number"
		or type(result.EggUid) ~= "string" or type(result.EggId) ~= "string"
		or typeof(result.HatchOrigin) ~= "CFrame" or seen[result.EggUid] then return false end
	seen[result.EggUid] = true
	task.delay(120,function() seen[result.EggUid] = nil end)
	if active >= 8 then return false end
	Sounds.Preload("HatchFinish")
	active += 1
	task.spawn(function()
		local ok, failure = xpcall(function() play(result) end, debug.traceback)
		active -= 1
		if not ok then warn("[HatchController]", failure) end
	end)
	return true
end

function Controller.Start()
	if started then return end
	started = true
	Storage:WaitForChild("HatchStarted").OnClientEvent:Connect(Controller.Enqueue)
	Storage:WaitForChild("HatchOutcome").OnClientEvent:Connect(require(script.Parent.Parent.UI.HatchCollect).Play)
end
return Controller
