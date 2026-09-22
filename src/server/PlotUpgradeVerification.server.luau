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
 check(workspace:FindFirstChild("Baseplate")==nil and workspace.SkyIsland.Meadow.Size.X==236,"Compact floating island replaces Baseplate")
 for _,p in workspace.PlayerPlots:GetChildren() do
  check(p.Ground.Size==Vector3.new(80,1,80) and #p.Pen.Slots:GetChildren()==10,"Expanded geometry "..p.Name)
 end
 check(profile.MaxPetSlots==5 and Plots.GetSlotCapacity(a)==5,"Starts with five active slots")
 for i=1,5 do local pet=assert(Pets.CreatePet(a,"test_common"));assert(Placement.PlacePet(a,pet.PetId)) end
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
 Locks.Begin(a,"test")
 check(request().Code=="Busy","Feed/save lock blocks purchase")
 Locks.Finish(a)
 local beforeFood=profile.Food
 for level=5,9 do
  task.wait(.55)
  local before=profile.Money
  local result=Upgrade.HandleRequest(a,plot.Name,profile.MaxPetSlots)
  check(result.Ok and profile.MaxPetSlots==level+1,"Capacity purchase "..(level+1))
  check(result.Cost==Config.UpgradeCost[level+2] or level==9,"Next price advances "..level)
  check(result.Money==before-Config.UpgradeCost[level+1],"Exact Money charged "..level)
  check(not Upgrade.HandleRequest(a,plot.Name,level).Ok,"Immediate replay rejected "..level)
  waitFor(function() return not Locks.IsLocked(a) end)
  local after=profile.MaxPetSlots
  check(request(nil,level).Code=="LevelChanged" and profile.MaxPetSlots==after,"Stale purchase rejected "..level)
  local pet=if level==5 then sixth else assert(Pets.CreatePet(a,"test_common"))
  check(Placement.PlacePet(a,pet.PetId) and profile.Inventory[pet.PetId].PlotSlot==level+1,"New slot usable "..(level+1))
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
 check(Schema.Validate(profile) and Schema.Validate(Data.GetData(b)),"Both profiles valid")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
