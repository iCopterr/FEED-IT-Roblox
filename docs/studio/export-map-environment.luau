assert(not game:GetService('RunService'):IsRunning())
local root=assert(workspace:FindFirstChild('MapEnvironment'))
local data=game:GetService('SerializationService'):SerializeInstancesAsync({root})
return (buffer.tostring(data):gsub('.',function(c) return string.format('%02x',string.byte(c)) end))
