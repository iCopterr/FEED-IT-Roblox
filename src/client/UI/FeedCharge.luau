-- Cosmetic anticipation only: the caller supplies the server-confirmed phase.
local Critical=require(game.ReplicatedStorage.Shared.Config.FeedConfig).Presentation.Critical
local Charge={}
function Charge.Create(model)
	local body=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
	local _,size=model:GetBoundingBox()
	local radius=math.clamp(math.max(size.X,size.Z)*.55,2,8)
	local glow=Instance.new("Highlight");glow.Adornee=model;glow.DepthMode=Enum.HighlightDepthMode.Occluded
	glow.FillColor=Color3.fromRGB(255,214,95);glow.OutlineColor=Color3.fromRGB(255,245,204)
	glow.FillTransparency=1;glow.OutlineTransparency=1;glow.Parent=model
	local light=Instance.new("PointLight");light.Color=glow.FillColor;light.Range=18
	light.Shadows=false;light.Brightness=0;light.Parent=body
	local orbiters={}
	for i=1,3 do
		local point=Instance.new("Attachment");point.Parent=body
		local emitter=Instance.new("ParticleEmitter")
		emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color=ColorSequence.new(glow.FillColor,Color3.new(1,1,1));emitter.LightEmission=1
		emitter.Rate=0;emitter.Lifetime=NumberRange.new(.2,.4);emitter.Speed=NumberRange.new(0)
		emitter.Size=NumberSequence.new(.32,0);emitter.Parent=point
		table.insert(orbiters,{Point=point,Emitter=emitter})
	end
	local state={}
	function state.Update(alpha,center)
		glow.FillTransparency=1-alpha*.3
		glow.OutlineTransparency=1-alpha*.8
		light.Brightness=alpha*(1+.5*math.sin(alpha*math.pi*8))
		for i,orb in orbiters do
			local angle=i*math.pi*2/3+alpha*alpha*math.pi*8
			orb.Point.WorldPosition=center+Vector3.new(math.cos(angle)*radius,math.sin(angle*2)*.5,math.sin(angle)*radius)
			orb.Emitter.Rate=6+alpha*10
		end
	end
	function state.Finish()
		glow:Destroy();light:Destroy()
		for _,orb in orbiters do orb.Emitter.Enabled=false end
	end
	function state.Critical(alpha,center)
		-- Continue the existing orbit at full charge, adding rising gold sparks.
		state.Update(1,center)
		glow.FillTransparency=.7-.35*alpha
		glow.OutlineTransparency=.2*(1-alpha)
		light.Brightness=1.5+alpha*2
		for i,orb in orbiters do
			local angle=i*math.pi*2/3+math.pi*8+alpha*math.pi*10
			orb.Point.WorldPosition=center+Vector3.new(math.cos(angle)*radius,math.sin(angle*2)*.5,math.sin(angle)*radius)
			orb.Emitter.Rate=16+(Critical.ChargeParticleRate-16)*alpha
			orb.Emitter.Speed=NumberRange.new(.5,2)
			orb.Emitter.Acceleration=Vector3.new(0,2,0)
			orb.Emitter.Lifetime=NumberRange.new(.3,.6)
			orb.Emitter.Size=NumberSequence.new(.32+.2*alpha,0)
		end
	end
	return state
end
return Charge
