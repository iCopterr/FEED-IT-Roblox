-- Uses fresh copies of filesystem/Rojo modules to avoid edit-mode require caching.
assert(not game:GetService('RunService'):IsRunning())
local shared=game.ReplicatedStorage.Shared:Clone();shared.Name='PetSizeAuditModules';shared.Parent=game.ServerStorage
local result
local ok,failure=xpcall(function()
 local config=require(shared.Config.PetConfig)
 local models=require(shared.PetModels)
 local checks=0;local report={}
 for id,def in config.Species do
  local template=assert(models.GetTemplate(id));local sourceScale=template:GetScale()
  local clone=template:Clone();local before=0
  for _,item in clone:GetDescendants()do if item:IsA('BasePart')then before+=1 end end
  clone:ScaleTo(models.GetScale(id,0));local _,base=clone:GetBoundingBox()
  assert(math.abs(Vector2.new(base.X,base.Z).Magnitude-def.BaseFootprint)<.04,def.DisplayName..' base');checks+=1
  local previous=def.BaseFootprint
  for level=1,40 do
   clone:ScaleTo(models.GetScale(id,level));local bounds,size=clone:GetBoundingBox()
   local footprint=Vector2.new(size.X,size.Z).Magnitude
   assert(footprint>previous,def.DisplayName..' growth stalled');checks+=1
   assert(footprint<=def.BaseFootprint+config.MaxFootprintGrowth+.04,def.DisplayName..' excessive growth');checks+=1
   local pickup=models.GetPickupCFrame(clone)
   assert(math.abs(pickup.Position.Y-(bounds.Position.Y-size.Y/2+2))<.01,def.DisplayName..' unreachable pickup');checks+=1
   previous=footprint
  end
  local after=0
  for _,item in clone:GetDescendants()do
   if item:IsA('BasePart')then after+=1 end
   if item:IsA('Motor6D')then assert((item.Part0.CFrame*item.C0).Position:FuzzyEq((item.Part1.CFrame*item.C1).Position,.02),def.DisplayName..' motor');checks+=1 end
  end
  assert(after==before and template:GetScale()==sourceScale,def.DisplayName..' template mutation');checks+=1
  table.insert(report,{name=def.DisplayName,height=base.Y,footprint=def.BaseFootprint,maxFootprint=previous,parts=before})
  clone:Destroy()
 end
 table.sort(report,function(a,b)return a.footprint<b.footprint end)
 result={passed=true,checks=checks,pets=report}
end,debug.traceback)
shared:Destroy()
assert(ok,failure)
return game:GetService('HttpService'):JSONEncode(result)
