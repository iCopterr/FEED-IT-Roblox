if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="LabelVerification" then return end
local checks={}
local ok,failure=xpcall(function()
 local s=script.Parent.Services
 local Data=require(s.DataService);local Pets=require(s.PetService);local Carry=require(s.CarryService)
 local Plots=require(s.PlotService);local Plate=require(s.PedestalService)
 local Income=require(game.ReplicatedStorage.Shared.PetIncome)
 local Compact=require(game.ReplicatedStorage.Shared.NumberFormat).Compact
 local function check(v,n) assert(v,n);table.insert(checks,n) end
 local function waitFor(fn) local untilTime=os.clock()+90;repeat if fn() then return end;task.wait(.1) until os.clock()>untilTime;error("Label test timed out") end
 check(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory-only test")
 local player;waitFor(function() player=game.Players:GetPlayers()[1];return player and Data.IsLoaded(player) and Plots.GetPlot(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") end)
 local root=player.Character.HumanoidRootPart;root.Anchored=true
 local plot=Plots.GetPlot(player);local pet=assert(Pets.CreatePet(player,"test_common"))
 local function inspect(model)
  local label=assert(model:FindFirstChild("PetLabel",true),"Pet label missing")
  check(label.Rarity.Text==pet.Rarity and label.NameLabel.Text~="","Pet name and rarity")
  check(label.Income.Text=="$"..Compact(Income(pet)).."/s","Correct server income")
  check(label.NameLabel.Font==Enum.Font.FredokaOne and label.NameLabel.TextOutline.Thickness==3,"Shared font and outlined text")
  local bounds,size=model:GetBoundingBox()
  check(label.Adornee.WorldPosition.Y>=bounds.Position.Y+size.Y/2+.7,"Label sits above scaled model")
 end
 check(Carry.Equip(player,pet.PetId),"Hold pet")
 inspect(player.Character.HeldPet)
 local floor=plot.Pen.Floor;local point=floor.Position+Vector3.new(0,floor.Size.Y/2,0)
 root.CFrame=CFrame.new(point+Vector3.new(0,4,0))
 check(Carry.PlaceAt(player,pet.PetId,point),"Place pet")
 inspect(plot.Pen.ActivePets[pet.PetId])
 assert(require(s.PlacementService).PickupPet(player,pet.PetId))
 root.CFrame=CFrame.new(plot.FeedPlate.Dish.Position+Vector3.new(0,3,4))
 check(Plate.Place(player,pet.PetId),"Place on plate")
 inspect(plot.FeedPlate.PlatePet)
 Plate.BeginPresentation(player)
 check(not plot.FeedPlate.PlatePet:FindFirstChild("PetLabel",true).Enabled,"Feeding hides label")
 Data.GetData(player).Inventory[pet.PetId].FeedLevel=20;pet.FeedLevel=20
 Plate.EndPresentation(player,pet.PetId,false)
 inspect(plot.FeedPlate.PlatePet)
 check(plot.FeedPlate.PlatePet:FindFirstChild("PetLabel",true).Enabled,"Growth restores label")
 local offer
 waitFor(function() local f=workspace.PetConveyor:FindFirstChild("Offers");offer=f and f:GetChildren()[1];return offer~=nil end)
 local label=offer:FindFirstChild("ConveyorPetLabel",true)
 check(label and label.NameLabel.Text~="" and label.Price.Text:sub(1,1)=="$" and not label.Rarity.Visible,"Conveyor shows egg name and price only")
 check(label.NameLabel.Font==Enum.Font.FredokaOne and label.Price:FindFirstChild("TextOutline"),"Egg label shares font and stroke")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
