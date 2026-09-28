local Eggs=require(game.ReplicatedStorage.Shared.Config.EggConfig)
local PetModels=require(game.ReplicatedStorage.Shared.PetModels)
local Preview={}
local Foods=require(game.ReplicatedStorage.Shared.Config.FoodConfig)
local Images=require(script.Parent.IconImages)
local Art=require(script.Parent.ImageArt)
function Preview.Set(view,entry)
	local art=view:FindFirstChild("FoodArt")
	if art then
		art.Visible=entry~=nil and entry.Kind=="Food"
		if art.Visible then
			art.Emoji.Text=entry.Icon or (Foods.Types[entry.Id] and Foods.Types[entry.Id].Icon) or "🍗"
			Art.Set(art,art.Emoji,Images[entry.Id] or Images.empty)
		end
	end
	if entry and entry.Kind=="Food" then
		entry=nil
	end
	if not entry then
		view.World:ClearAllChildren();view:SetAttribute("PreviewKey",nil)
		view.CurrentCamera=nil
		local camera=view:FindFirstChild("PreviewCamera")
		if camera then camera:Destroy() end
		return
	end
	-- Cameras are client-local render helpers, not UI layout. StarterGui cameras
	-- are not replicated reliably; bind a local camera to the authored viewport.
	local camera=view:FindFirstChild("PreviewCamera")
	if not camera then camera=Instance.new("Camera");camera.Name="PreviewCamera";camera.Parent=view end
	view.CurrentCamera=camera
	local signature=entry.Kind..":"..(entry.SpeciesId or entry.EggId)
	if view:GetAttribute("PreviewKey")==signature then return end
	view:SetAttribute("PreviewKey",signature)
	local world=view.World
	world:ClearAllChildren()
	local definition=entry.EggId and Eggs.Definitions[entry.EggId]
	local name=entry.SpeciesId or (definition and definition.TemplateName) or entry.EggId
	local folder=if entry.Kind=="Egg" then workspace:FindFirstChild("EggTemplates") else nil
	local template=if entry.Kind=="Pet" then PetModels.GetTemplate(entry.SpeciesId) else folder and folder:FindFirstChild(name)
	if not template or not template:IsA("Model") then view:SetAttribute("PreviewKey",nil);return end
	local model=template:Clone()
	for _,child in model:GetDescendants() do
		-- Static UI copies need geometry, not thousands of rig joints or gameplay
		-- helpers. Preserve all visible parts, mesh bones, textures and transforms.
		if child:IsA("LuaSourceContainer") or child:IsA("LayerCollector") or child:IsA("ProximityPrompt")
			or child:IsA("JointInstance") or child:IsA("WeldConstraint") or child:IsA("Constraint")
			or child:IsA("Humanoid") or child:IsA("AnimationController") then child:Destroy()
		elseif child:IsA("BasePart") then
			child.Anchored=true;child.CanCollide=false;child.CanTouch=false;child.CanQuery=false
		end
	end
	model.Parent=world
	model:PivotTo(CFrame.new())
	local bounds,size=model:GetBoundingBox()
	local radius=math.max(size.X,size.Y,size.Z)
	camera.FieldOfView=35
	local inventory=view:FindFirstAncestor("Inventory")~=nil
	local distance=if inventory then .72 else 1
	camera.CFrame=CFrame.lookAt(bounds.Position+Vector3.new(radius*1.4,radius*.8,-radius*2.1)*distance,bounds.Position)
end
return Preview
