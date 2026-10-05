if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("VFXVerificationReport",60)
if not report then return end
local checks={};local models={}
local camera=workspace.CurrentCamera;local old=camera.CFrame
local ok,failure=xpcall(function()
	local VFX=require(script.Parent.Controllers.VFXController)
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local model=Instance.new("Model");local part=Instance.new("Part")
	part.Size=Vector3.new(3,5,3);part.Anchored=true;part.CanCollide=false;part.Position=Vector3.new(0,200,0);part.Parent=model;model.PrimaryPart=part
	model.Parent=workspace;table.insert(models,model)
	camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.new(0,200,10)
	model:SetAttribute("Rarity","Common");model:SetAttribute("Variant","Normal")
	game.CollectionService:AddTag(model,"PetVisual");VFX.Refresh()
	check(not part:FindFirstChild("PremiumPetVFX"),"Normal common has no aura")
	local lastRate=0
	for _,kind in {"Epic","Legendary","Mythic","Fabled","Divine","Celestial"} do
		model:SetAttribute("Rarity",kind);VFX.Refresh()
		check(VFX.PremiumColor(model)~=nil,kind.." aura")
		local anchor=assert(part:FindFirstChild("PremiumPetVFX"));local rate=0
		for _,e in anchor:GetDescendants() do if e:IsA("ParticleEmitter") then rate+=e.Rate end end
		check(rate>lastRate,kind.." has more particles than previous tier");lastRate=rate
		check((anchor:FindFirstChild("PremiumLight")~=nil)==(kind~="Epic"),kind.." nearby light")
		check(#model:GetChildren()==1,"Aura adds no BaseParts or changes rig")
	end
	local anchor=part.PremiumPetVFX
	local before=anchor.PetSparkles.Size.Keypoints[2].Value
	model:ScaleTo(2);VFX.Refresh()
	check(anchor.PetSparkles.Size.Keypoints[2].Value>before,"Particles grow with pet")
	check(anchor:FindFirstChild("Crown") and anchor:FindFirstChild("SoftAura"),"Celestial has crown stars and soft glow")
	model:SetAttribute("Variant","Shiny");VFX.Refresh()
	check(VFX.PremiumProfile(model).Rank==6,"Variant never downgrades Celestial rarity")
	check(VFX.PremiumColor(model)==require(game.ReplicatedStorage.Shared.Config.VFXConfig).Colors.Shiny,"Variant tint retained")
	model:SetAttribute("Variant","Normal");model:SetAttribute("Rarity","Rare");VFX.Refresh()
	check(not part:FindFirstChild("PremiumPetVFX"),"Rare normal has no premium aura")
	model:SetAttribute("Rarity","Common")
	for _,kind in {"Shiny","Rainbow","Celestial"} do model:SetAttribute("Variant",kind);check(VFX.PremiumColor(model)~=nil,kind.." aura") end
	VFX.Refresh();check(part:FindFirstChild("PremiumPetVFX")~=nil,"One emitter attached")
	VFX.Refresh();check(#part:GetChildren()==1,"Refresh does not duplicate emitter")
	model:SetAttribute("Broken",true);VFX.Refresh()
	check(not VFX.PremiumProfile(model) and not part:FindFirstChild("PremiumPetVFX"),"Broken pet suppresses premium glow")
	model:SetAttribute("Broken",false);VFX.Refresh()
	check(part:FindFirstChild("PremiumPetVFX")~=nil,"Repair restores premium aura")
	model:SetAttribute("Presenting",true);VFX.Refresh();check(#part:GetChildren()==0,"Hidden feeding pet has no aura")
	model:SetAttribute("Presenting",false)
	model:SetAttribute("ClientPetsHidden",true);VFX.Refresh();check(#part:GetChildren()==0,"Settings-hidden pet has no aura")
	model:SetAttribute("ClientPetsHidden",false)
	game.CollectionService:RemoveTag(model,"PetVisual");game.CollectionService:AddTag(model,"VariantEggVisual")
	model.PrimaryPart=nil;VFX.Refresh()
	check(part:FindFirstChild("PremiumPetVFX")~=nil,"Variant eggs work without PrimaryPart")
	model:SetAttribute("Hatching",true);VFX.Refresh();check(#part:GetChildren()==0,"Original egg aura suppressed during hatch")
	model:SetAttribute("Hatching",false);model.PrimaryPart=part
	game.CollectionService:RemoveTag(model,"VariantEggVisual");game.CollectionService:AddTag(model,"PetVisual")
	model:SetAttribute("Presenting",false);part.Position=Vector3.new(1000,200,0);VFX.Refresh();check(#part:GetChildren()==0,"Distant aura culled")
	local config=require(game.ReplicatedStorage.Shared.Config.VFXConfig)
	local budgetModels={}
	for i=1,config.MaxAuras+4 do
		local m=Instance.new("Model");local b=Instance.new("Part");b.Anchored=true;b.CanCollide=false
		b.Position=Vector3.new(i*.1,200,0);b.Parent=m;m.PrimaryPart=b;m:SetAttribute("Rarity","Celestial");m.Parent=workspace
		table.insert(models,m);table.insert(budgetModels,m);game.CollectionService:AddTag(m,"PetVisual")
	end
	VFX.Refresh();local auraCount,lightCount=0,0
	for _,m in budgetModels do for _,o in m:GetDescendants() do
		if o.Name=="PremiumPetVFX" then auraCount+=1 end
		if o:IsA("PointLight") then lightCount+=1;check(not o.Shadows,"Premium light has no shadow cost") end
	end end
	check(auraCount==config.MaxAuras,"Nearest aura count capped")
	check(lightCount==config.MaxLights,"Nearby lights capped")
	local far=budgetModels[1];for _,m in budgetModels do if m~=far then m:Destroy() end end
	far.PrimaryPart.Position=Vector3.new(0,200,-60);VFX.Refresh()
	local rate=0;for _,o in far:GetDescendants()do if o:IsA("ParticleEmitter")then rate+=o.Rate end end
	check(math.abs(rate-52*.4)<.001,"Distant aura uses reduced emission")
	check(not far.PrimaryPart.PremiumPetVFX:FindFirstChild("PremiumLight"),"Distant aura has no light")
	far:Destroy();VFX.Refresh()
	check(not VFX.Burst(part.Position,"Success"),"Distant bursts culled")
	for i=1,8 do check(VFX.Burst(Vector3.new(0,200,0),"Success"),"Bounded burst "..i) end
	check(not VFX.Burst(Vector3.new(0,200,0),"Explosion"),"Burst budget enforced")
	task.wait(1.7);check(not workspace.Terrain:FindFirstChild("PetVFXBurst"),"Burst anchors cleaned")
	model:Destroy();VFX.Refresh()
end,debug.traceback)
for _,model in models do model:Destroy() end
camera.CFrame=old;camera.CameraType=Enum.CameraType.Custom
report:FireServer({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
