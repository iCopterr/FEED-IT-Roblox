if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="VFXVerification" then return end
assert(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory-only test")
local report=Instance.new("RemoteEvent");report.Name="VFXVerificationReport";report.Parent=game.ReplicatedStorage
local finished=false
report.OnServerEvent:Connect(function(_,result) if not finished then finished=true;testing:EndTest(result) end end)
task.delay(90,function() if not finished then finished=true;testing:EndTest({passed=false,failure="Client VFX timeout"}) end end)
