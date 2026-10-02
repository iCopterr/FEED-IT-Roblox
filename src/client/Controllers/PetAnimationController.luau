local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Storage=game:GetService("ReplicatedStorage")
local Config=require(Storage.Shared.Config.PetAnimationConfig)
local Profiles=Config.Profiles
local Species=require(Storage.Shared.Config.PetConfig).Species
local FolderName=require(Storage.Shared.Config.PlacementConfig).VisualFolderName
local Pose=require(script.Parent.Parent.UI.PetPose)
local Controller={}
local started=false
function Controller.Start()
	if not Config.Enabled or started then return end
	started=true
	local plots=workspace:WaitForChild("PlayerPlots")
	local states={}
	local pending={}
	local function track(model)
		if not model:IsA("Model") or states[model] then return states[model]~=nil end
		if not model:IsDescendantOf(plots) or not model.Parent or model.Parent.Name~=FolderName then return false end
		local def=Species[model:GetAttribute("SpeciesId")]
		local profile=def and Profiles[def.TemplateName]
		-- Replicated/streamed models can arrive before attributes, PrimaryPart or
		-- their complete rig. Leave them pending instead of missing animation forever.
		if not profile or not model.PrimaryPart then return false end
		local state=Pose.Bind(model,profile)
		if state then
			state.Last=state.Root.Position;state.Walk=0;state.Time=math.random()*5;state.MovingUntil=0
			states[model]=state
			model:SetAttribute("ClientPetAnimationPending",false)
			model:SetAttribute("ClientPetAnimationActive",true)
		end
		return state~=nil
	end
	local function queue(model,rebind)
		if not model or not model:IsA("Model") then return end
		if rebind and states[model] then
			Pose.Reset(states[model]);states[model]=nil
			model:SetAttribute("ClientPetAnimationActive",false)
		end
		if (model.Parent and model.Parent.Name==FolderName) or CollectionService:HasTag(model,"PetVisual") then
			pending[model]=true
			model:SetAttribute("ClientPetAnimationPending",true)
		end
	end
	for _,o in plots:GetDescendants() do if o:IsA("Model") then queue(o,false) end end
	for _,model in CollectionService:GetTagged("PetVisual") do queue(model,false) end
	plots.DescendantAdded:Connect(function(o)
		local model=if o:IsA("Model") then o else o:FindFirstAncestorWhichIsA("Model")
		if model and model.Parent and model.Parent.Name==FolderName then queue(model,states[model]~=nil) end
	end)
	CollectionService:GetInstanceAddedSignal("PetVisual"):Connect(function(model) queue(model,false) end)
	RunService.RenderStepped:Connect(function(dt)
		local camera=workspace.CurrentCamera
		for model in pending do
			if not model.Parent then pending[model]=nil
			elseif track(model) then pending[model]=nil end
		end
		for model,state in states do
			if not model:IsDescendantOf(plots) or not state.Root.Parent then
				Pose.Reset(state);states[model]=nil;pending[model]=nil
				if model.Parent then model:SetAttribute("ClientPetAnimationActive",false) end
				continue
			end
			local pos=state.Root.Position
			local delta=pos-state.Last;state.Last=pos
			state.Time+=math.min(dt,.1)
			-- Replication arrives in packets, not on every render frame.
			if Vector3.new(delta.X,0,delta.Z).Magnitude>dt*.15 then state.MovingUntil=state.Time+.15 end
			local moving=state.Time<state.MovingUntil
			state.Walk+=( (if moving then 1 else 0)-state.Walk)*math.min(1,dt*8)
			if camera and (camera.CFrame.Position-pos).Magnitude<350 then
				Pose.Step(state,state.Time,state.Walk)
			end
		end
	end)
end
return Controller
