if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("HatchVerificationReport",60)
if not report then return end
local Controller=require(script.Parent.Controllers.HatchController)
Controller.Start()
local panel=game.Players.LocalPlayer.PlayerGui.HatchUI.Panel
local outcomeCount=0
local lastResult
game.ReplicatedStorage.HatchOutcome.OnClientEvent:Connect(function(r) outcomeCount+=1;lastResult=r end)
report.OnClientEvent:Connect(function(action)
	local ok,failure=xpcall(function()
		local initial=outcomeCount
		local function waitFor(fn) local deadline=os.clock()+15;repeat if fn() then return end;task.wait(.03) until os.clock()>deadline;error("Hatch animation timeout: "..tostring(panel:GetAttribute("Stage"))) end
		waitFor(function() return panel:GetAttribute("Stage")=="Egg" end)
		assert(panel.Visible and #panel.Preview.World:GetChildren()==1,"One egg preview")
		waitFor(function() return panel:GetAttribute("Stage")=="Pet" end)
		assert(#panel.Preview.World:GetChildren()==1,"One pet preview; egg freed")
		assert(lastResult and panel.PetName.Text==lastResult.PetName,"Saved result displayed")
		assert(panel.Rarity.Text:find(lastResult.Rarity),"Rarity displayed")
		assert(not Controller.Enqueue(lastResult),"Replay deduplicated")
		if action=="HatchRemote" then Controller.Skip() end
		waitFor(function() return not panel.Visible end)
		assert(#panel.Preview.World:GetChildren()==0 and panel.Preview.CurrentCamera==nil,"Geometry/camera freed")
		assert(outcomeCount==initial+1,"Exactly one saved result event")
	end,debug.traceback)
	report:FireServer({passed=ok,failure=if ok then nil else tostring(failure)})
end)
report:FireServer("Ready")
