-- Edit-only, detached clones. Checks reversible damage without touching assets.
assert(not game:GetService("RunService"):IsRunning())
local shared=game.ReplicatedStorage.Shared
local config=assert(loadstring(shared.Config.ReviveConfig.Source))()
local fn=assert(loadstring(shared.BrokenPetVisual.Source))
setfenv(fn,setmetatable({script=shared.BrokenPetVisual,require=function(module)
	if module==shared.Config.ReviveConfig then return config end
	return require(module)
end},{__index=getfenv()}))
local visual=fn()
local models=require(shared.PetModels)
local checks=0
for _,species in {"test_common","test_rare","test_legendary"} do
	local model=assert(models.GetTemplate(species)):Clone()
	local ok,failure=xpcall(function()
		local parts,joints={},{}
		for _,o in model:GetDescendants() do
			if o:IsA("BasePart") then parts[o]={Color=o.Color,Material=o.Material,Transparency=o.Transparency} end
			if o:IsA("JointInstance") then joints[o]={o.Part0,o.Part1,o.C0,o.C1} end
		end
		local function check(v) assert(v,species.." damage visual invariant");checks+=1 end
		visual.Apply(model,true,true)
		check(model:FindFirstChild("BrokenRim")~=nil)
		check(model.PrimaryPart:FindFirstChild("BrokenSmokeAnchor")~=nil)
		visual.Apply(model,true,true)
		local count=0
		for _,o in model:GetDescendants() do if o:IsA("BasePart") then count+=1;check(parts[o]~=nil) end end
		local before=0
		for part,p in parts do
			before+=1
			local expected=p.Color:Lerp(config.BrokenVisual.SootColor,config.BrokenVisual.SootBlend)
			-- BasePart Color is quantized by the engine; attributes/Lerp retain floats.
			check(math.max(math.abs(part.Color.R-expected.R),math.abs(part.Color.G-expected.G),math.abs(part.Color.B-expected.B))<=1/255+.00001)
		end
		check(count==before)
		for joint,j in joints do check(joint.Part0==j[1] and joint.Part1==j[2] and joint.C0==j[3] and joint.C1==j[4]) end
		visual.Apply(model,false,true)
		check(not model:FindFirstChild("BrokenRim") and not model.PrimaryPart:FindFirstChild("BrokenSmokeAnchor"))
		for part,p in parts do check(part.Color==p.Color and part.Material==p.Material
			and part.Transparency==p.Transparency and part:GetAttribute("RepairOriginalColor")==nil) end
		visual.Apply(model,true,false)
		check(model:FindFirstChild("BrokenRim") and not model.PrimaryPart:FindFirstChild("BrokenSmokeAnchor"))
	end,debug.traceback)
	model:Destroy();assert(ok,failure)
end
print("PASS: "..checks.." broken appearance/repair restoration checks on three authored pets; no geometry or rig changes")
