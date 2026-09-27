if not game:GetService("RunService"):IsStudio() then return end
local testing=game:GetService("StudioTestService")
if testing:GetTestArgs()~="PageFocusVerification" then return end
assert(require(script.Parent.Data.DataStoreAdapter).IsMemory(),"Memory-only verification")
local report=Instance.new("RemoteEvent");report.Name="PageFocusVerificationReport";report.Parent=game.ReplicatedStorage
local finished=false
report.OnServerEvent:Connect(function(_,result)if not finished then finished=true;testing:EndTest(result)end end)
task.delay(90,function()if not finished then finished=true;testing:EndTest({passed=false,failure="Page focus timeout"})end end)
