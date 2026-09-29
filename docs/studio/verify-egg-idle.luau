local Motion = require(game.ReplicatedStorage.Shared.EggIdleMotion)
local count = 0
for _, template in workspace.EggTemplates:GetChildren() do
	if not template:IsA("Model") then continue end
	local phase = Motion.Phase(template.Name)
	assert(phase >= 0 and phase < math.pi * 2)
	local clone = template:Clone()
	local origin = clone:GetPivot()
	for _, ready in {false, true} do
		for i = 0, 120 do
			local offset = Motion.Offset(i / 10, phase, ready)
			assert(offset.Y >= 0.14 - 1e-5 and offset.Y <= 0.341)
			clone:PivotTo(origin * offset)
			assert((clone:GetPivot().Position - origin.Position).Magnitude <= 0.342)
		end
	end
	clone:Destroy()
	count += 1
end
assert(count == 6)
return "PASS: six egg models, waiting/ready motion bounds and no accumulated drift"
