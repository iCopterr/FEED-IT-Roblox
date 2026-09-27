if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="PromptVerification" then return end
local checks={}
local ok,failure=xpcall(function()
 local s=script.Parent.Services
 local Data=require(s.DataService);local Pets=require(s.PetService);local Carry=require(s.CarryService)
 local Placement=require(s.PlacementService);local Plots=require(s.PlotService)
 local function check(v,name)assert(v,name);table.insert(checks,name)end
 local function waitFor(fn)local deadline=os.clock()+60;repeat if fn()then return end;task.wait(.1)until os.clock()>deadline;error("Prompt verification timeout")end
 check(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory-only test")
 local player;waitFor(function()player=game.Players:GetPlayers()[1];return player and Data.IsLoaded(player) and Plots.GetPlot(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart")end)
 local root=player.Character.HumanoidRootPart;root.Anchored=true
 local plot=Plots.GetPlot(player)
 local pet=assert(Pets.CreatePet(player,"test_common"));assert(Placement.PlacePet(player,pet.PetId))
 local model=plot.Pen.ActivePets[pet.PetId]
 root.CFrame=model:GetPivot()+Vector3.new(0,3,0)
 local pickup=model:FindFirstChildWhichIsA("ProximityPrompt",true)
 check(pickup.HoldDuration==.5,"Pickup hold reduced to 0.5 seconds")
 check(not Carry.FinishPickup(player,pickup),"No-hold pickup rejected")
 assert(Carry.BeginPickup(player,pickup))
 check(not Carry.FinishPickup(player,pickup),"Instant completion still rejected")
 assert(Carry.BeginPickup(player,pickup));task.wait(.6)
 check(Carry.FinishPickup(player,pickup),"Shortened legitimate hold succeeds")
 root.CFrame=plot.FeedPlate.Dish.CFrame+Vector3.new(0,3,0)
 check(Carry.PlaceOnPlate(player,pet.PetId),"Pet placed on feed plate")
 local feedPrompt=plot.FeedPlate.PlatePet:FindFirstChildWhichIsA("ProximityPrompt",true)
 check(feedPrompt.Name=="OpenFeedUI" and feedPrompt.HoldDuration==.5,"Feed menu uses 0.5 second hold")
 local merchant=workspace.MysteryMerchant:FindFirstChild("OpenMysteryMerchant",true)
 check(merchant and merchant.HoldDuration==.125,"Merchant uses 0.125 second hold")
 check(workspace.ReviveMachine.InteractionPoint.OpenReviveMachine.HoldDuration==.125,"Revive uses 0.125 second hold")
 local offer
 waitFor(function()local folder=workspace.PetConveyor:FindFirstChild("Offers");offer=folder and folder:GetChildren()[1];return offer~=nil end)
 check(offer:FindFirstChild("BuyConveyorEgg",true).HoldDuration==.25,"Egg purchase uses 0.25 second hold")
 local visual=require(s.EggVisuals)
 local floor=plot.Pen.Floor
 local egg=assert(visual.Prepare(player,{EggId="prototype_egg"},floor.Position+Vector3.new(0,floor.Size.Y/2,0)))
 assert(visual.Install(player,"prompt-test",egg))
 check(egg:FindFirstChild("HatchEgg",true).HoldDuration==0,"Hatching remains instant")
 visual.Clear(player)
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
