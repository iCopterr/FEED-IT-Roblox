local Storage = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Eggs = require(Storage.Shared.Config.EggConfig)
local Timing = require(Storage.Shared.Config.HatchAnimationConfig)
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
	Debris:AddItem(egg, 5)
	local hidden = {}
	local disabled = {}
	local plots = workspace:FindFirstChild("PlayerPlots")
	if plots then
		for _, plot in plots:GetChildren() do
			local pen = plot:FindFirstChild("Pen")
			local original = pen and pen:FindFirstChild("Egg_" .. result.EggUid)
			if original then for _, item in original:GetDescendants() do
				if item:IsA("BasePart") then hidden[item]=item.LocalTransparencyModifier;item.LocalTransparencyModifier=1 end
				if item:IsA("ParticleEmitter") or item:IsA("Light") or item:IsA("BillboardGui") or item:IsA("ProximityPrompt") then
					disabled[item]=item.Enabled;item.Enabled=false
				end
			end end
		end
	end
	local ok, failure = xpcall(function()
		local shell = assert(egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true))
		local light = Instance.new("PointLight")
		light.Color = Color3.new(1,1,1); light.Range = 16; light.Brightness = 0; light.Shadows = false; light.Parent = shell
		local attachment = Instance.new("Attachment"); attachment.Parent = shell
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/flare_main.dds"
		burst.Color = ColorSequence.new(Color3.new(1,1,1))
		burst.LightEmission = 1; burst.Rate = 0; burst.Speed = NumberRange.new(1,3)
		burst.SpreadAngle = Vector2.new(180,180); burst.Lifetime = NumberRange.new(.5,.8)
		burst.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,4),NumberSequenceKeypoint.new(1,6)})
		burst.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.25,.35),NumberSequenceKeypoint.new(1,1)})
		burst.Parent = attachment
		local start = result.EndsAt - Timing.Duration
		local revealed = false
		egg:SetAttribute("Stage", "Float")
		repeat
			local t = math.max(0, workspace:GetServerTimeNow() - start)
			local rise = math.clamp(t / .8,0,1)
			local shake = math.clamp((t-.8)/1.2,0,1)
			local position = result.HatchOrigin * CFrame.new(0,2*(1-(1-rise)^3),0)
			egg:PivotTo(position * CFrame.Angles(math.sin(t*32)*shake*.06,0,math.sin(t*45)*shake*.18))
			light.Brightness = shake * 3
			if t >= .8 and not revealed then egg:SetAttribute("Stage", "Shake") end
			if t >= 2 and not revealed then
				revealed = true; egg:SetAttribute("Stage", "Light"); burst:Emit(12)
				for _, item in egg:GetDescendants() do
					if item:IsA("BasePart") then item.Transparency = 1 end
					if item:IsA("ParticleEmitter") and item ~= burst then item.Enabled = false; item:Clear() end
				end
			end
			if revealed then light.Brightness = 4 * math.clamp(1-(t-2)/.8,0,1) end
			if t >= Timing.Duration then break end
			Run.RenderStepped:Wait()
		until not egg.Parent
	end, debug.traceback)
	egg:Destroy()
	for part, transparency in hidden do if part.Parent then part.LocalTransparencyModifier=transparency end end
	for item, enabled in disabled do if item.Parent then item.Enabled=enabled end end
	if not ok then warn("[HatchController]", failure) end
end

function Controller.Enqueue(result)
	if type(result) ~= "table" or not result.Ok or result.Code ~= "HatchStarted" or type(result.EndsAt) ~= "number"
		or type(result.EggUid) ~= "string" or type(result.EggId) ~= "string"
		or typeof(result.HatchOrigin) ~= "CFrame" or seen[result.EggUid] then return false end
	seen[result.EggUid] = true
	task.delay(120,function() seen[result.EggUid] = nil end)
	if active >= 8 then return false end
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
end
return Controller
