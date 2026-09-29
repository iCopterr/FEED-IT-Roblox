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
 local report=Instance.new("RemoteEvent");report.Name="FixedLabelReport";report.Parent=game.ReplicatedStorage
 local clientResult
 report.OnServerEvent:Connect(function(actor,result) if actor==player then clientResult=result end end)
 local plot=Plots.GetPlot(player);local pet=assert(Pets.CreatePet(player,"test_common"))
 local function inspect(model)
  local label=assert(model:FindFirstChild("PetLabel",true),"Pet label missing")
  check(label.Rarity.Text==pet.Rarity and label.NameLabel.Text~="","Pet name and rarity")
  check(label.Income.Text=="$"..Compact(Income(pet)).."/s","Correct server income")
  check(label.NameLabel.Font==Enum.Font.FredokaOne and label.NameLabel.TextOutline.Thickness==3,"Shared font and outlined text")
  check(label.Size==UDim2.fromOffset(240,84),"Fixed pixel pet label before/after growth")
  check(not label.NameLabel.TextScaled and label.NameLabel.TextSize==24,"Pet text never auto-resizes")
  local bounds,size=model:GetBoundingBox()
  check(label.Adornee.WorldPosition.Y>=bounds.Position.Y+size.Y/2+2.2,"Raised label sits above scaled model")
 end
 check(Carry.Equip(player,pet.PetId),"Hold pet")
 inspect(player.Character.HeldPet)
 local floor=plot.Pen.Floor;local point=floor.Position+Vector3.new(0,floor.Size.Y/2,0)
 local egg=assert(require(s.EggVisuals).Prepare(player,{EggId="prototype_egg"},point))
 local eggLabel=assert(egg:FindFirstChild("ConveyorPetLabel",true))
 check(not eggLabel.Price.Visible and eggLabel.Price.Text=="" and eggLabel.Size==UDim2.fromOffset(240,56),"Placed egg has no E instruction row")
 local eggBounds,eggSize=egg:GetBoundingBox()
 check(eggLabel.Adornee:IsA("Attachment") and eggLabel.Adornee.WorldPosition.Y>=eggBounds.Position.Y+eggSize.Y/2+2.4,"Placed egg label raised")
 egg:Destroy()
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
 check(label.Size==UDim2.fromOffset(240,56) and not label.NameLabel.TextScaled and label.NameLabel.TextSize==24,"Conveyor label and text use fixed pixels")
 local offerBounds,offerSize=offer:GetBoundingBox()
 check(label.Adornee:IsA("Attachment") and label.Adornee.WorldPosition.Y>=offerBounds.Position.Y+offerSize.Y/2+2.4,"Conveyor egg label raised")
 local eggTemplate=game.ReplicatedStorage.ConveyorPetLabel
 check(eggTemplate.Size==UDim2.fromOffset(240,84) and not eggTemplate.Rarity.TextScaled,"Incubating egg template uses fixed pixels")
 waitFor(function() return clientResult~=nil end)
 check(clientResult.Passed,clientResult.Failure or "Client confirms identical near/far pixel dimensions for pets and eggs")
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
