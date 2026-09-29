local Models = require(game.ReplicatedStorage.Shared.PetModels)
local Timing = require(game.ReplicatedStorage.Shared.Config.HatchAnimationConfig)
local Reveal = {}

function Reveal.Create(result, origin: Vector3, color: Color3)
	local template = Models.GetTemplate(result.SpeciesId)
	if not template then return nil end
	local model = template:Clone()
	model.Name = "HatchedPetReveal_" .. result.EggUid
	-- Register cleanup before any preparation that could fail.
	game:GetService("Debris"):AddItem(model, Timing.PetRevealSeconds + Timing.PetDissolveSeconds + 3)
	local parts = {}
	for _,item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("LayerCollector") or item:IsA("ProximityPrompt") or item:IsA("Sound") then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored=true;item.CanCollide=false;item.CanTouch=false;item.CanQuery=false
			table.insert(parts,{Part=item,Transparency=item.Transparency})
		end
	end
	model:ScaleTo(Models.GetScale(result.SpeciesId, 0))
	local _,size=model:GetBoundingBox()
	model:ScaleTo(model:GetScale()*math.min(1,Timing.RevealMaxSize/math.max(size.X,size.Y,size.Z)))
	local scale=model:GetScale()
	local camera=workspace.CurrentCamera
	local direction=if camera then camera.CFrame.Position-origin else Vector3.new(0,0,1)
	direction=Vector3.new(direction.X,0,direction.Z)
	if direction.Magnitude<.01 then direction=Vector3.new(0,0,1) end
	local facing=CFrame.lookAt(origin,origin+direction)
	local highlight=Instance.new("Highlight")
	highlight.Name="HatchRarityGlow";highlight.Adornee=model;highlight.FillColor=color;highlight.OutlineColor=color
	highlight.FillTransparency=1;highlight.OutlineTransparency=.35;highlight.DepthMode=Enum.HighlightDepthMode.Occluded;highlight.Parent=model
	local effect={Model=model}
	function effect.Update(elapsed,fade)
		if not model.Parent then return end
		fade=math.clamp(fade,0,1)
		model:ScaleTo(scale*(1-.92*fade))
		local bounds=model:GetBoundingBox()
		local pose=(facing+Vector3.new(0,math.sin(elapsed*2.8)*.12*(1-fade),0))*CFrame.Angles(0,math.sin(elapsed*.8)*.22,0)
		model:PivotTo(pose*bounds:ToObjectSpace(model:GetPivot()))
		for _,entry in parts do entry.Part.Transparency=entry.Transparency+(1-entry.Transparency)*fade end
		highlight.FillTransparency=1-fade*.85
		highlight.OutlineTransparency=.35+.65*fade
	end
	function effect.Destroy() model:Destroy() end
	model.Parent=workspace
	effect.Update(0,0)
	return effect
end

return Reveal
