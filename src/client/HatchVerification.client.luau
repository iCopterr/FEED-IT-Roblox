if not game:GetService("RunService"):IsStudio() then return end
local report=game.ReplicatedStorage:WaitForChild("HatchVerificationReport",60)
if not report then return end
local Controller=require(script.Parent.Controllers.HatchController)
Controller.Start()
local lastResult
game.ReplicatedStorage:WaitForChild("HatchStarted").OnClientEvent:Connect(function(r) lastResult=r end)
report.OnClientEvent:Connect(function()
	local ok,failure=xpcall(function()
		local function waitFor(fn)
			local deadline=os.clock()+15
			repeat local value=fn();if value then return value end;task.wait(.02) until os.clock()>deadline
			error("World hatch effect timeout")
		end
		local effect=waitFor(function()
			for _,model in workspace:GetChildren() do
				if model.Name:sub(1,12)=="HatchReveal_" then return model end
			end
		end)
		assert(not game.Players.LocalPlayer.PlayerGui:FindFirstChild("HatchUI"),"No popup UI")
		waitFor(function() return effect:GetAttribute("Stage")=="Shake" end)
		assert(lastResult and not Controller.Enqueue(lastResult),"Replay deduplicated")
		waitFor(function() return effect:GetAttribute("Stage")=="Light" end)
		assert(effect.PrimaryPart.Transparency==1,"Shell disappears into white light")
		waitFor(function() return not effect.Parent end)
	end,debug.traceback)
	report:FireServer({passed=ok,failure=if ok then nil else tostring(failure)})
end)
report:FireServer("Ready")
