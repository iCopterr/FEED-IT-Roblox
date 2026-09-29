local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Debris=game:GetService("Debris")
local Timing=require(game.ReplicatedStorage.Shared.Config.HatchAnimationConfig)
local Collect={}
local seen={}
local active=0

function Collect.Play(result)
	if type(result)~="table" or not result.Ok or result.Code~="Hatched"
		or type(result.EggUid)~="string" or typeof(result.HatchOrigin)~="CFrame"
		or type(result.CollectEndsAt)~="number" or seen[result.EggUid] then return end
	seen[result.EggUid]=true;task.delay(120,function() seen[result.EggUid]=nil end)
	if active>=8 then return end
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	active+=1
	task.spawn(function()
		local orb=Instance.new("Part")
		orb.Name="HatchRewardTrail";orb.Shape=Enum.PartType.Ball
		orb.Size=Vector3.one*.6;orb.Material=Enum.Material.Neon
		orb.Color=Color3.fromRGB(255,224,130)
		orb.Anchored=true;orb.CanCollide=false;orb.CanTouch=false;orb.CanQuery=false;orb.CastShadow=false
		local origin=result.HatchOrigin.Position+Vector3.new(0,Timing.RiseHeight,0)
		orb.Position=origin;orb.Parent=workspace;Debris:AddItem(orb,Timing.CollectSeconds+2)
		local ok,failure=xpcall(function()
			local a=Instance.new("Attachment");a.Position=Vector3.new(0,.16,0);a.Parent=orb
			local b=Instance.new("Attachment");b.Position=Vector3.new(0,-.16,0);b.Parent=orb
			local trail=Instance.new("Trail");trail.Attachment0=a;trail.Attachment1=b
			trail.FaceCamera=true;trail.Lifetime=.25;trail.LightEmission=1
			trail.Color=ColorSequence.new(orb.Color,Color3.new(1,1,1))
			trail.Transparency=NumberSequence.new(0,1);trail.Parent=orb
			local sparks=Instance.new("ParticleEmitter")
			sparks.Texture="rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color=trail.Color;sparks.LightEmission=1;sparks.Rate=20
			sparks.Lifetime=NumberRange.new(.2,.4);sparks.Speed=NumberRange.new(.5,1.5)
			sparks.Size=NumberSequence.new(.25,0);sparks.SpreadAngle=Vector2.new(180,180);sparks.Parent=a
			local start=result.CollectEndsAt-Timing.CollectSeconds
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
			orb.Transparency=1;trail.Enabled=false;sparks.Rate=0
			sparks.Speed=NumberRange.new(3,6);sparks:Emit(20)
			task.wait(.45)
		end,debug.traceback)
		orb:Destroy();active-=1
		if not ok then warn("[HatchCollect]",failure) end
	end)
end

return Collect
