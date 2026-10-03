-- Opt-in, memory-only client startup smoke test. Never changes entitlements.
if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="HUDSmokeVerification" then return end
assert(require(script.Parent.Data.DataStoreAdapter).IsMemory())
local report=Instance.new("RemoteEvent")
report.Name="HUDSmokeVerificationReport"
local replies,finished={},false
report.OnServerEvent:Connect(function(player,result)
	if finished or type(result)~="table" then return end
	replies[player]=result
	local count=0
	for _ in replies do count+=1 end
	if count<2 then return end
	finished=true
	local checks,failures={},{}
	for p,r in replies do
		for _,c in r.checks or {} do table.insert(checks,p.Name..": "..c) end
		if not r.passed then table.insert(failures,p.Name..": "..tostring(r.failure)) end
	end
	testing:EndTest({passed=#failures==0,checks=checks,failure=if #failures>0 then table.concat(failures,"\n") else nil})
end)
report.Parent=game.ReplicatedStorage
task.delay(75,function()
	if not finished then finished=true;testing:EndTest({passed=false,failure="HUD smoke client timeout"}) end
end)
