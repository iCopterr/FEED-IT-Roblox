-- Cosmetic only. Attachments/trails preserve the authored silhouette and rig.
local Config = require(game.ReplicatedStorage.Shared.Config.VFXConfig)
local Signature = {}

function Signature.Color(variant, time)
	if variant == "Rainbow" then return Color3.fromHSV(((time or os.clock())*.12)%1,.7,1) end
	return Config.Colors[variant]
end

function Signature.Create(model, parent, variant)
	if not Config.VariantAura[variant] then return nil end
	local color = Signature.Color(variant)
	local folder = Instance.new("Folder")
	folder.Name="VariantSignature";folder.Parent=parent
	local glow=Instance.new("Highlight")
	glow.Name="VariantRim";glow.Adornee=model;glow.DepthMode=Enum.HighlightDepthMode.Occluded
	glow.FillColor=color;glow.OutlineColor=color
	glow.FillTransparency=.94;glow.OutlineTransparency=.25;glow.Parent=folder
	local points={}
	local count=if variant=="Shiny" then 2 else 3
	for i=1,count do
		local a=Instance.new("Attachment");a.Name="VariantOrbit"..i;a.Parent=parent
		local b=Instance.new("Attachment");b.Parent=a;b.Position=Vector3.new(0,.1,0)
		local spark=Instance.new("ParticleEmitter")
		spark.Name="VariantStars";spark.Texture=Config.Texture;spark.LightEmission=1;spark.LightInfluence=0
		spark.Rate=if variant=="Shiny" then 3 else 2
		spark.Lifetime=NumberRange.new(.3,.6);spark.Speed=NumberRange.new(0)
		spark.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.2,.3),NumberSequenceKeypoint.new(1,0)})
		spark.Transparency=NumberSequence.new(0,1);spark.Parent=a
		local trail
		if variant~="Shiny" then
			trail=Instance.new("Trail");trail.Name="VariantRibbon";trail.Attachment0=a;trail.Attachment1=b
			trail.FaceCamera=true;trail.LightEmission=1;trail.Lifetime=if variant=="Celestial" then .8 else .45
			trail.MinLength=.04;trail.Transparency=NumberSequence.new(.15,1);trail.Parent=a
		end
		table.insert(points,{A=a,Spark=spark,Trail=trail})
	end
	local state={}
	function state.Update(time, center, extent, reduced)
		local tint=Signature.Color(variant,time)
		glow.FillColor=tint;glow.OutlineColor=tint:Lerp(Color3.new(1,1,1),.35)
		glow.FillTransparency=.94-.025*math.sin(time*2)
		local radius=math.clamp(math.max(extent.X,extent.Z)*.58,.8,9)
		for i,point in points do
			local angle=time*(if variant=="Celestial" then 1.25 else 2)+i*math.pi*2/count
			local height=if variant=="Celestial" then extent.Y*.55+math.sin(angle)*radius*.25 else math.sin(angle*2)*extent.Y*.3
			point.A.WorldPosition=center+Vector3.new(math.cos(angle)*radius,height,math.sin(angle)*radius)
			local c=if variant=="Rainbow" then Color3.fromHSV((time*.12+i/count)%1,.75,1) else tint
			point.Spark.Color=ColorSequence.new(c,Color3.new(1,1,1))
			point.Spark.Rate=if reduced then 1 else if variant=="Shiny" then 3 else 2
			if point.Trail then point.Trail.Color=ColorSequence.new(c,c:Lerp(Color3.new(1,1,1),.65)) end
		end
	end
	function state.Destroy()
		for _,point in points do point.A:Destroy() end
		folder:Destroy()
	end
	return state
end

return Signature
