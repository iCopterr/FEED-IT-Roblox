-- Presentation only: never changes incubation time or hatch readiness.
local Motion = {}

function Motion.Offset(time: number, phase: number, ready: boolean): CFrame
	local cycle = time * (if ready then 2.8 else 1.8) + phase
	local lift = (1 - math.cos(cycle)) * (if ready then 0.10 else 0.065)
	local rock = math.sin(cycle) * math.rad(if ready then 4 else 2.5)
	local sway = math.sin(cycle * 0.5) * math.rad(1.2)
	-- A small lift keeps the rocking shell clear of the ground.
	return CFrame.new(0, 0.14 + lift, 0) * CFrame.Angles(sway, 0, rock)
end

function Motion.Phase(id: string): number
	local hash = 0
	for i = 1, #id do hash = (hash * 31 + string.byte(id, i)) % 10007 end
	return hash / 10007 * math.pi * 2
end

return Motion
