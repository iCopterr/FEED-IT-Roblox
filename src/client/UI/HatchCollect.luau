local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Debris=game:GetService("Debris")
local Timing=require(game.ReplicatedStorage.Shared.Config.HatchAnimationConfig)
local Colors=require(game.ReplicatedStorage.Shared.Config.InventoryConfig).RarityColors
local PetReveal=require(script.Parent.HatchPetReveal)
local Collect={}
local seen={}
local active=0

function Collect.Play(result)
	if type(result)~="table" or not result.Ok or result.Code~="Hatched"
		or type(result.EggUid)~="string" or typeof(result.HatchOrigin)~="CFrame"
		or type(result.CollectEndsAt)~="number" or seen[result.EggUid] then return end
	if type(result.RevealEndsAt)~="number" or type(result.CollectStartsAt)~="number"
		or type(result.SpeciesId)~="string" then return end
	seen[result.EggUid]=true;task.delay(120,function() seen[result.EggUid]=nil end)
	if active>=8 then return end
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	active+=1
	task.spawn(function()
		local orb,reveal
		local origin=result.HatchOrigin.Position+Vector3.new(0,Timing.RiseHeight,0)
		local ok,failure=xpcall(function()
			local color=Colors[result.Rarity] or Colors.Common
			orb=Instance.new("Part")
			orb.Name="HatchRewardTrail";orb.Shape=Enum.PartType.Ball
			orb.Size=Vector3.one*.6;orb.Material=Enum.Material.Neon;orb.Color=color;orb.Transparency=1
			orb.Anchored=true;orb.CanCollide=false;orb.CanTouch=false;orb.CanQuery=false;orb.CastShadow=false
			orb.Position=origin;orb.Parent=workspace
			Debris:AddItem(orb,Timing.PetRevealSeconds+Timing.PetDissolveSeconds+Timing.CollectSeconds+2)
			local light=Instance.new("PointLight");light.Color=color;light.Range=8;light.Brightness=0;light.Shadows=false;light.Parent=orb
			local a=Instance.new("Attachment");a.Position=Vector3.new(0,.16,0);a.Parent=orb
			local b=Instance.new("Attachment");b.Position=Vector3.new(0,-.16,0);b.Parent=orb
			local trail=Instance.new("Trail");trail.Attachment0=a;trail.Attachment1=b
			trail.FaceCamera=true;trail.Lifetime=.25;trail.LightEmission=1
			trail.Color=ColorSequence.new(orb.Color,Color3.new(1,1,1))
			trail.Transparency=NumberSequence.new(0,1);trail.Parent=orb
			local sparks=Instance.new("ParticleEmitter")
			sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color=trail.Color;sparks.LightEmission=1;sparks.Rate=0
			sparks.Lifetime=NumberRange.new(.2,.4);sparks.Speed=NumberRange.new(.5,1.5)
			sparks.Size=NumberSequence.new(.25,0);sparks.SpreadAngle=Vector2.new(180,180);sparks.Parent=a
			local revealStart=result.RevealEndsAt-Timing.PetRevealSeconds
			if workspace:GetServerTimeNow()<result.CollectStartsAt then reveal=PetReveal.Create(result,origin,color) end
			-- The server keeps this pet reserved in its egg until light arrival.
			while workspace:GetServerTimeNow()<result.CollectStartsAt do
				if Players.LocalPlayer.Character~=character or not root.Parent or not orb.Parent then return end
				local now=workspace:GetServerTimeNow()
				local fade=math.clamp((now-result.RevealEndsAt)/Timing.PetDissolveSeconds,0,1)
				if reveal then reveal.Update(math.max(0,now-revealStart),fade) end
				orb.Transparency=1-fade;orb.Size=Vector3.one*(.3+.3*fade);light.Brightness=fade*1.5
				Run.RenderStepped:Wait()
			end
			if reveal then reveal.Destroy();reveal=nil end
			orb.Transparency=0;light.Brightness=1.5;sparks.Rate=20;sparks:Emit(18)
			local start=result.CollectStartsAt
			repeat
				if Players.LocalPlayer.Character~=character or not root.Parent then return end
				local t=math.clamp((workspace:GetServerTimeNow()-start)/Timing.CollectSeconds,0,1)
				local eased=t*t*(3-2*t)
				local target=root.Position+Vector3.new(0,1,0)
				orb.Position=origin:Lerp(target,eased)+Vector3.new(0,math.sin(t*math.pi)*2.5,0)
				orb.Size=Vector3.one*(.6-.3*t)
				if t>=1 then break end
				Run.RenderStepped:Wait()
			until not orb.Parent
			if not orb.Parent then return end
			orb.Transparency=1;light.Enabled=false;trail.Enabled=false;sparks.Rate=0
			sparks.Speed=NumberRange.new(3,6);sparks:Emit(20)
			task.wait(.45)
		end,debug.traceback)
		if reveal then reveal.Destroy() end
		if orb then orb:Destroy() end
		active-=1
		if not ok then warn("[HatchCollect]",failure) end
	end)
end

return Collect
