if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="PlotUpgradeVerification" then return end
local checks={}
local ok,failure=xpcall(function()
 local services=game.ServerScriptService.Server.Services
 local Data=require(services.DataService)
 local Plots=require(services.PlotService)
 local Upgrade=require(services.PlotUpgradeService)
 local Pets=require(services.PetService)
 local Placement=require(services.PlacementService)
 local Locks=require(services.FeedLocks)
 local Schema=require(services.Parent.Data.PlayerDataSchema)
 local Adapter=require(services.Parent.Data.DataStoreAdapter)
 local Config=require(game.ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
 local PlotConfig=require(game.ReplicatedStorage.Shared.Config.PlotConfig)
 local Eggs=require(services.EggService)
 local EggVisuals=require(services.EggVisuals)
 local Appearance=require(services.PlotAppearance)
 local function check(v,label) assert(v,label);table.insert(checks,label) end
 local function waitFor(f)
  local deadline=os.clock()+60
  repeat if f() then return end;task.wait(.1) until os.clock()>deadline
  error("Timed out waiting for test state")
 end
 check(Adapter.IsMemory(),"Memory-only test")
 waitFor(function() return #game.Players:GetPlayers()==2 end)
 local a,b=table.unpack(game.Players:GetPlayers())
 waitFor(function() return Data.IsLoaded(a) and Data.IsLoaded(b) and Plots.GetPlot(a) and Plots.GetPlot(b)
  and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
  and game.ReplicatedStorage:FindFirstChild("PlotUpgrade") end)
 local profile=Data.GetData(a)
 local plot=Plots.GetPlot(a)
 local root=a.Character.HumanoidRootPart
 root:SetNetworkOwner(nil);root.Anchored=true
 local board=workspace.PlotUpgradeSigns[plot.Name].Board
 local function near() root.CFrame=CFrame.new(board.Position+Vector3.new(0,0,5)) end
 local function request(name,expected)
  task.wait(.55)
  return Upgrade.HandleRequest(a,name or plot.Name,expected or profile.MaxPetSlots)
 end
 check(#workspace.PlayerPlots:GetChildren()==6 and #workspace.PlotUpgradeSigns:GetChildren()==6,"Six plots and six authored signs")
 check(workspace:FindFirstChild("Baseplate")==nil and workspace.SkyIsland.Meadow.Size==Vector3.new(368,4,420),"Expanded floating island replaces Baseplate")
 for _,p in workspace.PlayerPlots:GetChildren() do
  check(p.Ground.Size==Vector3.new(80,1,80) and #p.Pen.Slots:GetChildren()==10,"Expanded geometry "..p.Name)
 end
 check(profile.MaxPetSlots==5 and Plots.GetSlotCapacity(a)==5,"Starts with five active slots")
 local origin=assert(Plots.GetPlacementOrigin(a))
 local originalGround=plot.Ground.CFrame
 local originalFront=plot.Pen.Floor.CFrame*Vector3.new(0,0,22)
 local originalEntrance=plot.Pen.Fence.FrontLeft.CFrame
 local originalSpawn=plot.Spawn.CFrame
 local firstPet
 for i=1,5 do
  local pet=assert(Pets.CreatePet(a,"test_common"))
  assert(Placement.PlacePet(a,pet.PetId,if i==1 then origin*Vector3.new(0,.15,0) else nil))
  if i==1 then firstPet=profile.Inventory[pet.PetId];Placement.PauseWandering(a,pet.PetId,120) end
 end
 local petAnchor=Placement.GetPetCFrame(a,firstPet)
 local sixth=assert(Pets.CreatePet(a,"test_common"))
 local placed,reason=Placement.PlacePet(a,sixth.PetId)
 check(not placed and reason=="PenFull","Sixth pet blocked before purchase")
 check(Upgrade.HandleRequest(a,{},5).Code=="InvalidRequest","Malformed request rejected")
 check(Upgrade.HandleRequest(a,plot.Name,0/0).Code=="InvalidRequest","NaN rejected")
 near()
 check(request(Plots.GetPlot(b).Name).Code=="NotOwner","Foreign plot rejected")
 root.CFrame=CFrame.new(0,100,0)
 check(request().Code=="TooFar","Distant purchase rejected")
 near();profile.Money=0
 check(request().Code=="NotEnoughMoney","Insufficient Money rejected")
 profile.Money=1e9
 local eggPurchase=Eggs.BuyFromConveyor(a,"prototype_egg")
 check(eggPurchase.Ok,"Egg bought before plot upgrade")
 waitFor(function() return not Locks.IsLocked(a) end)
 local eggPoint=origin*Vector3.new(10,.15,0)
 root.CFrame=CFrame.new(eggPoint+Vector3.new(0,3,0))
 task.wait(.3)
 check(Eggs.HandleRequest(a,"Place",eggPurchase.EggUid,eggPoint).Ok,"Egg placed before plot upgrade")
 waitFor(function() return not Locks.IsLocked(a) end)
 local eggBefore=EggVisuals.GetModel(a,eggPurchase.EggUid):GetPivot()
 near()
 Locks.Begin(a,"test")
 check(request().Code=="Busy","Feed/save lock blocks purchase")
 Locks.Finish(a)
 local beforeFood=profile.Food
 for level=5,9 do
  task.wait(.55)
  local before=profile.Money
  local result=Upgrade.HandleRequest(a,plot.Name,profile.MaxPetSlots)
  check(result.Ok and profile.MaxPetSlots==level+1,"Capacity purchase "..(level+1))
  local depth=Config.RearDepthBySlots[level+1]
  check(plot.Ground.Size.Z==80+depth and plot.Pen.Floor.Size.Z==44+depth,"Milestone-only rear depth "..(level+1))
  check(plot.Ground.FloorGrid.StudsPerTileU==32 and plot.Ground.FloorGrid.StudsPerTileV==32
   and plot.Pen.Floor.FloorGrid.StudsPerTileU==32 and plot.Pen.Floor.FloorGrid.StudsPerTileV==32,
   "Floor grid persists through resize "..(level+1))
  check(plot.OwnerDisplay.Position==plot.Ground.Position+Vector3.new(0,PlotConfig.OwnerDisplayHeight,0),"Owner badge remains above expanded plot "..(level+1))
  check((plot.Pen.Floor.CFrame*Vector3.new(0,0,plot.Pen.Floor.Size.Z/2)-originalFront).Magnitude<.001
   and plot.Pen.Fence.FrontLeft.CFrame==originalEntrance and plot.Spawn.CFrame==originalSpawn,"Front and spawn unchanged "..(level+1))
  check(plot.Pen.Fence.Back.Color==Config.TierColors[level+1] and plot.PostCap0.Color==Config.TierColors[level+1],"Fence tier color "..(level+1))
  check((Placement.GetPetCFrame(a,firstPet).Position-petAnchor.Position).Magnitude<.001
   and Plots.GetPlacementOrigin(a)==origin,"Existing pet anchor stays fixed "..(level+1))
  EggVisuals.Clear(a);EggVisuals.Reconcile(a,profile)
  check((EggVisuals.GetModel(a,eggPurchase.EggUid):GetPivot().Position-eggBefore.Position).Magnitude<.001,"Egg rebuild stays fixed "..(level+1))
  check(result.Cost==Config.UpgradeCost[level+2] or level==9,"Next price advances "..level)
  check(result.Money==before-Config.UpgradeCost[level+1],"Exact Money charged "..level)
  check(not Upgrade.HandleRequest(a,plot.Name,level).Ok,"Immediate replay rejected "..level)
  waitFor(function() return not Locks.IsLocked(a) end)
  local after=profile.MaxPetSlots
  check(request(nil,level).Code=="LevelChanged" and profile.MaxPetSlots==after,"Stale purchase rejected "..level)
  local pet=if level==5 then sixth else assert(Pets.CreatePet(a,"test_common"))
  local newPoint=if depth>0 then origin*Vector3.new(-10,.15,-20-depth) else nil
  check(Placement.PlacePet(a,pet.PetId,newPoint) and profile.Inventory[pet.PetId].PlotSlot==level+1,"New slot/rear space usable "..(level+1))
 end
 check(request().Code=="MaxLevel","Maximum ten slots enforced")
 local eleventh=assert(Pets.CreatePet(a,"test_common"))
 local tooMany,full=Placement.PlacePet(a,eleventh.PetId)
 check(not tooMany and full=="PenFull","Eleventh pet blocked")
 Upgrade.RefreshSigns()
 check(plot:GetAttribute("SlotCapacity")==10 and board.UpgradeGui~=nil,"Owner sign and authored UI available")
 check(Data.GetData(b).MaxPetSlots==5 and profile.Food==beforeFood,"Other player and Food unchanged")
 assert(Data.Save(a))
 local read,record=Adapter.UpdateAsync("Player_"..a.UserId,function() return nil end)
 local loaded=assert(Schema.Migrate(record.Data))
 check(read and loaded.MaxPetSlots==10 and Schema.Validate(loaded),"Save/reload preserves purchased capacity and placements")
 local lastAnchor=Placement.GetPetCFrame(a,loaded.Inventory[eleventh.PetId])
 check(lastAnchor==nil,"Unplaced pet has no world anchor")
 -- Every orientation must fit the reserved rear space and restore exactly.
 for _,model in workspace.PlayerPlots:GetChildren() do
  Appearance.Apply(model,5)
  local baseline=model.Ground.CFrame
  local wood=model.Pen.Fence.Back.Color
  local count=#model:GetDescendants()
  Appearance.Apply(model,10)
  check(model.Ground.Size==Vector3.new(80,1,120) and model.Foundation.Size.X==122,"Both plot orientations expand backward "..model.Name)
  for _,part in model:GetDescendants() do
   if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
    local localPoint=workspace.SkyIsland.Meadow.CFrame:PointToObjectSpace(part.Position)
    assert(math.abs(localPoint.X)<184 and math.abs(localPoint.Z)<210,"Expansion exceeded island")
   end
  end
  check(#model:GetDescendants()==count,"No generated geometry "..model.Name)
  Appearance.Apply(model,5)
  check(model.Ground.CFrame==baseline and model.Pen.Fence.Back.Color==wood,"Exact base appearance restored "..model.Name)
 end
 Plots.GetPlot(a)
 check(plot.Ground.Size.Z==120 and plot.Ground.CFrame~=originalGround,"Saved capacity reapplies appearance")
 check(Schema.Validate(profile) and Schema.Validate(Data.GetData(b)),"Both profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
