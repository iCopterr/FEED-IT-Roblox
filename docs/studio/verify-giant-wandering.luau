assert(not game:GetService('RunService'):IsRunning())
local shared=game.ReplicatedStorage.Shared:Clone();shared.Parent=game.ServerStorage
local module=game.ServerScriptService.Server.Services.WanderingService:Clone();module.Parent=game.ServerStorage
local models=require(shared.PetModels);local wander=require(module)
local folder=Instance.new('Folder');folder.Name='GiantMovementAudit';folder.Parent=workspace
local checks=0
local ok,failure=xpcall(function()
 for _,plot in workspace.PlayerPlots:GetChildren()do
  if not plot:IsA('Model')then continue end
  for _,id in {'test_common','master_pet_3','supreme_pet_6','world_eater'}do
   local m=assert(models.GetTemplate(id)):Clone();m:ScaleTo(models.GetScale(id,40))
   local bounds,size=m:GetBoundingBox();local floor=plot.Pen.Floor
   local giant=Vector2.new(size.X,size.Z).Magnitude+1>math.min(floor.Size.X,floor.Size.Z)
   m:PivotTo(floor.CFrame*CFrame.new(if giant then 8 else 0,floor.Size.Y/2+size.Y/2+.05,0)*bounds:ToObjectSpace(m:GetPivot()))
   for _,p in m:GetDescendants()do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false end end
   m.Parent=folder;wander.Track(m,floor)
   for step=1,300 do
    wander.Step(.1)
    local cf,dimensions=m:GetBoundingBox();local center=floor.CFrame:PointToObjectSpace(cf.Position)
    assert(center.X==center.X and center.Z==center.Z,'Non-finite movement');checks+=1
    assert(math.abs(center.Y-dimensions.Y/2-floor.Size.Y/2-.05)<.05,'Lost grounding');checks+=1
    if not giant then
     for _,x in {-1,1}do for _,z in {-1,1}do
      local corner=floor.CFrame:PointToObjectSpace(cf:PointToWorldSpace(Vector3.new(x*dimensions.X/2,0,z*dimensions.Z/2)))
      assert(math.abs(corner.X)<floor.Size.X/2 and math.abs(corner.Z)<floor.Size.Z/2,'Ordinary pet escaped')
     end end
    end
   end
   if giant then
    local center=floor.CFrame:PointToObjectSpace((m:GetBoundingBox()).Position)
    assert(math.abs(center.X)<.05 and math.abs(center.Z)<.05,'Giant failed to settle at center');checks+=1
   end
   m:Destroy()
  end
 end
end,debug.traceback)
folder:Destroy();shared:Destroy();module:Destroy()
assert(ok,failure)
return ('PASS: %d production wandering checks across six rotated pens'):format(checks)
