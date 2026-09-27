if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="HatchVerification" then return end
local checks={}
local ok,failure=xpcall(function()
	local s=script.Parent.Services
	local Data=require(s.DataService);local Eggs=require(s.EggService);local Plots=require(s.PlotService)
	local Carry=require(s.CarryService);local Locks=require(s.FeedLocks)
	local function check(v,name) assert(v,name);table.insert(checks,name) end
	local function waitFor(fn) local deadline=os.clock()+60;repeat if fn() then return end;task.wait(.1) until os.clock()>deadline;error("Hatch verification timeout") end
	check(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory-only verification")
	local report=Instance.new("RemoteEvent");report.Name="HatchVerificationReport";report.Parent=game.ReplicatedStorage
	local ready,clientResult=false,nil
	local player
	report.OnServerEvent:Connect(function(actor,value) if actor~=player then return end;if value=="Ready" then ready=true else clientResult=value end end)
	waitFor(function() player=game.Players:GetPlayers()[1];return player and Data.IsLoaded(player) and Plots.GetPlot(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") end)
	waitFor(function() return ready end)
	local profile=Data.GetData(player);profile.Money=100000
	local root=player.Character.HumanoidRootPart;root.Anchored=true
	local floor=Plots.GetPlot(player).Pen.Floor
	local position=floor.Position+Vector3.new(0,floor.Size.Y/2,0)
	for _,action in {"Hatch","HatchRemote"} do
		Carry.Unequip(player)
		local bought=Eggs.BuyFromConveyor(player,"prototype_egg");check(bought.Ok,"Buy egg for "..action)
		waitFor(function() return not Locks.IsLocked(player) end)
		root.CFrame=CFrame.new(position+Vector3.new(0,4,0))
		check(Eggs.HandleRequest(player,"Place",bought.EggUid,position).Ok,"Place egg for "..action)
		waitFor(function() return not Locks.IsLocked(player) end)
		local egg=profile.IncubatingEggs[bought.EggUid]
		egg.ReadyAt=os.time()-1;egg.StartedAt=egg.ReadyAt-egg.HatchSeconds
		local id=egg.Pet.PetId
		clientResult=nil;report:FireClient(player,action)
		if action=="HatchRemote" then root.CFrame=CFrame.new(position+Vector3.new(100,4,0)) end
		local result=Eggs.HandleRequest(player,action,bought.EggUid)
		check(result.Ok and result.PetId==id,"Hatch preserves reserved identity "..action)
		check(Eggs.HandleRequest(player,action,bought.EggUid).PetId==id,"Duplicate returns same result "..action)
		waitFor(function() return clientResult~=nil end)
		check(clientResult.passed,clientResult.failure or "Client shake/reveal/cleanup "..action)
		check(profile.Inventory[id]~=nil and profile.IncubatingEggs[bought.EggUid]==nil,"Single inventory grant "..action)
		check(Carry.GetPetId(player)==id,"Hatched pet returns to hands "..action)
	end
end,debug.traceback)
testing:EndTest({passed=ok,checks=checks,failure=if ok then nil else tostring(failure)})
