-- Run in Studio edit mode after Rojo sync. No player data or purchases.
assert(not game:GetService("RunService"):IsRunning(),"Use edit mode")
local config=require(game.ReplicatedStorage.Shared.Config.FeedConfig:Clone())
local resolverSource=game.ServerScriptService.Server.Services.FeedResolver.Source
local resolver=assert(loadstring(resolverSource:gsub("local Config = require%b()","local Config = ...",1)))(config)
local counts={Normal=0,Critical=0}
for ticket=0,9999 do
	local calls=0
	local result=resolver.Roll(17,function()
		calls+=1;assert(calls<=2,"Extra explosion/RNG roll")
		return if calls==1 then .999 else (ticket+.5)/10000
	end)
	counts[result.Critical]+=1
	assert(result.Gain==(if result.Critical=="Critical" then 2 else 1))
end
assert(counts.Normal==9900 and counts.Critical==100,"Exact 1% ticket distribution")
for _,case in {{.989999,"Normal",1},{.99,"Critical",2},{.999999,"Critical",2}} do
	local calls=0
	local result=resolver.Roll(0,function()calls+=1;return if calls==1 then .99 else case[1] end)
	assert(result.Critical==case[2] and result.Gain==case[3])
end
for _,level in {38,39} do
	local result=resolver.Roll(level,function()return .999 end)
	assert(result.FeedLevel==40 and result.Gain==40-level,"Cap actual gain")
end
for _,case in {{0,"MiracleSave"},{.9,"Explosion"}} do
	local calls=0
	local result=resolver.Roll(20,function()calls+=1;assert(calls<=2);return if calls==1 then 0 else case[1] end)
	assert(result.Code==case[2] and result.Gain==0 and not result.Critical)
end
assert(math.abs(config.GetSpinSeconds("Success","Critical")-4)<1e-8)
assert(math.abs(config.GetPresentationSeconds("Success","Critical")-6.45)<1e-8)
assert(math.abs(config.GetPresentationSeconds("Success","Normal")-3.9)<1e-8)
assert(not table.find(require(game.ReplicatedStorage.Shared.Config.DebugConfig:Clone()).Modes,"Mega"))
local variants=require(game.ReplicatedStorage.Shared.Config.VariantConfig:Clone())
local variantCounts={Normal=0,Shiny=0,Rainbow=0,Celestial=0}
for i=1,variants.Tickets do variantCounts[variants.Pick(i)]+=1 end
for kind,definition in variants.Types do assert(variantCounts[kind]==definition.Tickets,"Variant odds changed") end

local signature=require(game.StarterPlayer.StarterPlayerScripts.Client.UI.VariantSignature:Clone())
local model=Instance.new("Model")
local part=Instance.new("Part");part.Anchored=true;part.Parent=model;model.PrimaryPart=part
local ok,err=xpcall(function()
	local charge=require(game.StarterPlayer.StarterPlayerScripts.Client.UI.FeedCharge:Clone()).Create(model)
	charge.Update(1,Vector3.zero)
	local before=#model:GetDescendants()
	charge.Critical(1,Vector3.zero)
	assert(#model:GetDescendants()==before,"Critical charge reuses its emitters")
	local count=0
	for _,item in model:GetDescendants() do
		if item:IsA("ParticleEmitter") then
			count+=1;assert(item.Rate==config.Presentation.Critical.ChargeParticleRate and item.Acceleration.Y>0)
		end
	end
	assert(count==3,"Bounded pre-finish Critical particles")
	charge.Finish()
	for _,item in part:GetChildren() do item:Destroy() end
	for _,variant in {"Shiny","Rainbow","Celestial"} do
		local effect=assert(signature.Create(model,part,variant))
		effect.Update(1,Vector3.zero,Vector3.new(3,5,3),false)
		local physical,stars,trails=0,0,0
		for _,item in model:GetDescendants() do
			if item:IsA("BasePart") then physical+=1 end
			if item:IsA("ParticleEmitter") then stars+=1 end
			if item:IsA("Trail") then trails+=1 end
		end
		assert(physical==1,"No added physical parts")
		assert(stars==(if variant=="Shiny" then 2 else 3))
		assert(trails==(if variant=="Shiny" then 0 else 3))
		effect.Destroy();assert(#part:GetChildren()==0,"Variant cleanup")
	end
	assert(signature.Create(model,part,"Normal")==nil)
end,debug.traceback)
model:Destroy();assert(ok,err)
print("PASS: critical 99/1 distribution, boundaries/cap/order/timing; variant odds, geometry budget and cleanup")
