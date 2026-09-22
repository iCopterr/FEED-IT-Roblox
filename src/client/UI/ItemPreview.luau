local Eggs=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local Preview={}
function Preview.Set(view,entry)
	-- Cameras are client-local render helpers, not UI layout. StarterGui cameras
	-- are not replicated reliably; bind a local camera to the authored viewport.
	local camera=view:FindFirstChild("PreviewCamera")
	if not camera then camera=Instance.new("Camera");camera.Name="PreviewCamera";camera.Parent=view end
	view.CurrentCamera=camera
	local signature=entry and (entry.Kind..":"..(entry.SpeciesId or entry.EggId)) or ""
	if view:GetAttribute("PreviewKey")==signature then return end
	view:SetAttribute("PreviewKey",signature)
	local world=view.World
	world:ClearAllChildren()
	if not entry then return end
	local folder=workspace:FindFirstChild(if entry.Kind=="Pet" then "PetTemplates" else "EggTemplates")
	local definition=entry.EggId and Eggs.Definitions[entry.EggId]
	local name=entry.SpeciesId or (definition and definition.TemplateName) or entry.EggId
	local template=folder and folder:FindFirstChild(name)
	if not template or not template:IsA("Model") then view:SetAttribute("PreviewKey",nil);return end
	local model=template:Clone()
	for _,child in model:GetDescendants() do
		if child:IsA("LuaSourceContainer") or child:IsA("LayerCollector") or child:IsA("ProximityPrompt") then child:Destroy()
		elseif child:IsA("BasePart") then child.Anchored=true;child.CanCollide=false end
	end
	model.Parent=world
	model:PivotTo(CFrame.new())
	local bounds,size=model:GetBoundingBox()
	local radius=math.max(size.X,size.Y,size.Z)
	camera.FieldOfView=35
	camera.CFrame=CFrame.lookAt(bounds.Position+Vector3.new(radius*1.4,radius*.8,-radius*2.1),bounds.Position)
end
return Preview
