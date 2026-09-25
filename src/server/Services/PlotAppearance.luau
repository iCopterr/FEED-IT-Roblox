-- Resizes/recolors authored parts only; never generates replacement geometry.
local Config=require(game.ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local PlotConfig=require(game.ReplicatedStorage.Shared.Config.PlotConfig)
local Appearance={}
local states={}

function Appearance.Capture(model)
 assert(not states[model],"Plot appearance already captured")
 local state={Base=model.Ground.CFrame,Origin=model.Pen.Floor.CFrame,Parts={}}
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") then
   local name=part.Name
   local lower=part.Parent==model.Pen.Fence
   local upper=name:match("^UpperRail")~=nil
   local post=tonumber(name:match("^FencePost(%d+)$") or name:match("^PostCap(%d+)$"))
   local stretch=name=="Ground" or name=="Foundation" or part==model.Pen.Floor
    or (lower and (name=="Left" or name=="Right"))
    or name=="UpperRailLeft" or name=="UpperRailRight"
   local shift=if stretch then .5 else 0
   if (lower and name=="Back") or name=="UpperRailBack" or name=="Shrub0" or name=="Shrub2" then shift=1 end
   if post then shift=if post<=2 then 1 else if post<=4 then .5 else 0 end
   local depth=part.CFrame:VectorToObjectSpace(state.Base.ZVector)
   table.insert(state.Parts,{Part=part,CFrame=part.CFrame,Size=part.Size,Color=part.Color,
    Shift=shift,Stretch=stretch,Axis=if math.abs(depth.X)>.5 then Vector3.xAxis else Vector3.zAxis,
    Accent=lower or upper or name:match("^PostCap")~=nil,
    Grass=name=="Ground" or part==model.Pen.Floor})
  end
 end
 states[model]=state
end

function Appearance.GetOrigin(model)
 return states[model].Origin
end

function Appearance.Apply(model,capacity)
 local state=assert(states[model],"Missing authored plot baseline")
 local tier=math.clamp(capacity,Config.StartingSlots,Config.MaxSlots)
 if state.Tier==tier then return end
 local extra=Config.RearDepthBySlots[tier]
 local accent=Config.TierColors[tier]
 for _,entry in state.Parts do
  local part=entry.Part
  part.Size=entry.Size+(if entry.Stretch then entry.Axis*extra else Vector3.zero)
  part.CFrame=entry.CFrame-state.Base.ZVector*(entry.Shift*extra)
  part.Color=if accent and entry.Accent then accent
   else if accent and entry.Grass then entry.Color:Lerp(accent,.22) else entry.Color
 end
 local ownerDisplay=model:FindFirstChild("OwnerDisplay")
 if ownerDisplay and ownerDisplay:IsA("BasePart") then
  ownerDisplay.CFrame=CFrame.new(model.Ground.Position+Vector3.new(0,PlotConfig.OwnerDisplayHeight,0))
 end
 state.Tier=tier
 model:SetAttribute("ExpansionDepth",extra)
 model:SetAttribute("VisualSlotTier",tier)
end

return table.freeze(Appearance)
