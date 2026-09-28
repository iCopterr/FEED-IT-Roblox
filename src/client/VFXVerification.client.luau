if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("VFXVerificationReport",60)
if not report then return end
local checks={};local models={}
local camera=workspace.CurrentCamera;local old=camera.CFrame
local ok,failure=xpcall(function()
	local VFX=require(script.Parent.Controllers.VFXController)
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local model=Instance.new("Model");local part=Instance.new("Part")
	part.Anchored=true;part.CanCollide=false;part.Position=Vector3.new(0,200,0);part.Parent=model;model.PrimaryPart=part
	model.Parent=workspace;table.insert(models,model)
	camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.new(0,200,10)
	model:SetAttribute("Rarity","Common");model:SetAttribute("Variant","Normal")
	game.CollectionService:AddTag(model,"PetVisual");VFX.Refresh()
	check(not part:FindFirstChild("PremiumPetVFX"),"Normal common has no aura")
	for _,kind in {"Legendary","Mythic","Fabled","Divine","Celestial"} do model:SetAttribute("Rarity",kind);check(VFX.PremiumColor(model)~=nil,kind.." aura") end
	model:SetAttribute("Rarity","Common")
	for _,kind in {"Shiny","Rainbow","Celestial"} do model:SetAttribute("Variant",kind);check(VFX.PremiumColor(model)~=nil,kind.." aura") end
	VFX.Refresh();check(part:FindFirstChild("PremiumPetVFX")~=nil,"One emitter attached")
	VFX.Refresh();check(#part:GetChildren()==1,"Refresh does not duplicate emitter")
	model:SetAttribute("Presenting",true);VFX.Refresh();check(#part:GetChildren()==0,"Hidden feeding pet has no aura")
	model:SetAttribute("Presenting",false);part.Position=Vector3.new(1000,200,0);VFX.Refresh();check(#part:GetChildren()==0,"Distant aura culled")
	check(not VFX.Burst(part.Position,"Success"),"Distant bursts culled")
	for i=1,8 do check(VFX.Burst(Vector3.new(0,200,0),"Success"),"Bounded burst "..i) end
	check(not VFX.Burst(Vector3.new(0,200,0),"Explosion"),"Burst budget enforced")
	task.wait(1.7);check(not workspace.Terrain:FindFirstChild("PetVFXBurst"),"Burst anchors cleaned")
	model:Destroy();VFX.Refresh()
end,debug.traceback)
for _,model in models do model:Destroy() end
camera.CFrame=old;camera.CameraType=Enum.CameraType.Custom
report:FireServer({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
