local RunService=game:GetService("RunService")
local Storage=game:GetService("ReplicatedStorage")
local Config=require(Storage.Shared.Config.PetAnimationConfig)
local Profiles=Config.Profiles
local Species=require(Storage.Shared.Config.PetConfig).Species
local FolderName=require(Storage.Shared.Config.PlacementConfig).VisualFolderName
local Pose=require(script.Parent.Parent.UI.PetPose)
local Controller={}
function Controller.Start()
	if not Config.Enabled then return end
	local plots=workspace:WaitForChild("PlayerPlots")
	local states={}
	local function track(model)
		if not model:IsA("Model") or states[model] then return end
		if not model.Parent or model.Parent.Name~=FolderName then return end
		local def=Species[model:GetAttribute("SpeciesId")]
		local profile=def and Profiles[def.TemplateName]
		if not profile then return end
		local state=Pose.Bind(model,profile)
		if state then
			state.Last=state.Root.Position;state.Walk=0;state.Time=math.random()*5
			states[model]=state
		end
	end
	for _,o in plots:GetDescendants() do track(o) end
	plots.DescendantAdded:Connect(function(o)
		if o:IsA("Model") then task.defer(track,o) end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local camera=workspace.CurrentCamera
		for model,state in states do
			if not model:IsDescendantOf(plots) or not state.Root.Parent then
				Pose.Reset(state);states[model]=nil;continue
			end
			local pos=state.Root.Position
			local delta=pos-state.Last;state.Last=pos
			local moving=Vector3.new(delta.X,0,delta.Z).Magnitude>dt*.15
			state.Walk+=( (if moving then 1 else 0)-state.Walk)*math.min(1,dt*8)
			state.Time+=math.min(dt,.1)
			if camera and (camera.CFrame.Position-pos).Magnitude<350 then
				Pose.Step(state,state.Time,state.Walk)
			end
		end
	end)
end
return Controller
