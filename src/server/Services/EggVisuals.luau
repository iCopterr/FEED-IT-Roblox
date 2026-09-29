-- Runtime clones of the authored egg and label; no generated geometry or UI.
local Config=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local EggLabelAnchor=require(game.ReplicatedStorage.Shared.EggLabelAnchor)
local Placement=require(script.Parent.PlacementService)
local Plots=require(script.Parent.PlotService)
local Visuals={}
local states={}

function Visuals.GetModel(player,id)
	local model=states[player] and states[player][id]
	local plot=Plots.GetPlot(player)
	return if model and plot and model.Parent==plot.Pen then model else nil
end

function Visuals.Clear(player)
	local state=states[player]
	if state then for _,model in state do model:Destroy() end end
	states[player]=nil
end

function Visuals.Prepare(player,egg,position)
	local target=Placement.ResolvePosition(player,position)
	local definition=Config.Definitions[egg.EggId]
	local templates=workspace:FindFirstChild("EggTemplates")
	local template=templates and templates:FindFirstChild(definition and definition.TemplateName or egg.EggId)
	if not target or not template or not template:IsA("Model") or not template.Archivable then return nil end
	for _,child in template:GetDescendants() do if child:IsA("LuaSourceContainer") then return nil end end
	local model=template:Clone()
	local ok=pcall(function()
		local body=assert(model:FindFirstChildWhichIsA("BasePart",true))
		local bounds,size=model:GetBoundingBox()
		model:PivotTo(target*CFrame.new(0,size.Y/2,0)*bounds:ToObjectSpace(model:GetPivot()))
		for _,part in model:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end
		end
		local label=game.ReplicatedStorage.ConveyorPetLabel:Clone()
		label.NameLabel.Text=definition and definition.DisplayName or egg.EggId
		label.Price.Text=""
		label.Price.Visible=false
		label.Size=UDim2.fromOffset(240,56)
		EggLabelAnchor.Bind(model,label)
		model:SetAttribute("OwnerUserId",player.UserId)
	end)
	if not ok then model:Destroy();return nil end
	return model
end

function Visuals.Install(player,id,model)
	local plot=Plots.GetPlot(player)
	if not plot then model:Destroy();return false end
	local state=states[player] or {};states[player]=state
	if state[id] then state[id]:Destroy() end
	model.Name="Egg_"..id;model:SetAttribute("EggUid",id)
	model:SetAttribute("EggIdleOrigin",model:GetPivot())
	model.Parent=plot.Pen;state[id]=model
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name=Config.HatchPromptName
	prompt.ActionText="Hatch"
	prompt.ObjectText="Ready Egg"
	prompt.KeyboardKeyCode=Enum.KeyCode.E
	prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	prompt.HoldDuration=0
	prompt.MaxActivationDistance=Config.HatchDistance
	prompt.RequiresLineOfSight=false
	prompt.Enabled=false
	prompt.Parent=model:FindFirstChildWhichIsA("BasePart",true)
	prompt.Triggered:Connect(function(actor)
		if actor==player and Visuals.GetModel(player,id)==model and Visuals.OnHatch then
			Visuals.OnHatch(player,id)
		end
	end)
	return true
end

function Visuals.Reconcile(player,profile)
	local plot=Plots.GetPlot(player)
	if not profile or not plot then Visuals.Clear(player);return end
	local state=states[player] or {};states[player]=state
	for id,model in state do
		local egg=profile.IncubatingEggs[id]
		if not egg or not egg.PenPosition or model.Parent~=plot.Pen then model:Destroy();state[id]=nil end
	end
	for id,egg in profile.IncubatingEggs do
		if egg.PenPosition then
			if not state[id] then
				local floor=plot.Pen.Floor
				local position=assert(Plots.GetPlacementOrigin(player)):PointToWorldSpace(Vector3.new(egg.PenPosition.X,floor.Size.Y/2,egg.PenPosition.Z))
				local model=Visuals.Prepare(player,egg,position)
				if model then Visuals.Install(player,id,model) end
			end
			local label=state[id] and state[id]:FindFirstChild("ConveyorPetLabel",true)
			local prompt=state[id] and state[id]:FindFirstChild(Config.HatchPromptName,true)
			if prompt then
				local ready=os.time()>=egg.ReadyAt
				state[id]:SetAttribute("HatchReady",ready)
				prompt.Enabled=ready and not state[id]:GetAttribute("Hatching")
			end
			if label then
				local seconds=math.max(0,egg.ReadyAt-os.time())
				label.Rarity.Text=if seconds==0 then "READY TO HATCH" else string.format("%ds TO HATCH",seconds)
			end
		end
	end
end

return Visuals
