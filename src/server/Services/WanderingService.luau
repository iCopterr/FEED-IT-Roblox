local Config = require(game.ReplicatedStorage.Shared.Config.WanderingConfig)
local RunService = game:GetService("RunService")
local states = {}
local random = Random.new()
local started = false
local Service = {}

function Service.Track(model, floor)
	if states[model] then return end
	local bounds, size = model:GetBoundingBox()
	local state = {
		Floor = floor, Parent = model.Parent,
		Offset = bounds:ToObjectSpace(model:GetPivot()),
		-- A rotation-safe footprint also handles large Feed-grown pets.
		Radius = Vector2.new(size.X, size.Z).Magnitude / 2 + Config.FenceClearance,
		Wait = random:NextNumber(Config.MinPauseSeconds, Config.MaxPauseSeconds),
		PausedUntil = 0,
	}
	states[model] = state
	model.Destroying:Once(function() states[model] = nil end)
end

function Service.Pause(model, seconds)
	local state = states[model]
	if state then state.PausedUntil = os.clock() + seconds end
end

function Service.IsTracked(model)
	return states[model] ~= nil
end

function Service.Step(dt)
	-- Never leap across the Pen after a server stall.
	dt = math.clamp(dt, 0, Config.MaxStepSeconds)
	for model, state in states do
		local floor = state.Floor
		if model.Parent ~= state.Parent or not floor:IsDescendantOf(workspace) then
			states[model] = nil
			continue
		end
		if os.clock() < state.PausedUntil then continue end
		if state.Wait > 0 then state.Wait -= dt; continue end
		local bounds = model:GetPivot() * state.Offset:Inverse()
		local point = floor.CFrame:PointToObjectSpace(bounds.Position)
		local limitX = math.max(0, floor.Size.X / 2 - state.Radius)
		local limitZ = math.max(0, floor.Size.Z / 2 - state.Radius)
		if not state.Target then
			local angle = random:NextNumber(0, math.pi * 2)
			local distance = random:NextNumber(Config.MinWalkDistance, Config.MaxWalkDistance)
			state.Target = Vector3.new(
				math.clamp(point.X + math.cos(angle) * distance, -limitX, limitX), point.Y,
				math.clamp(point.Z + math.sin(angle) * distance, -limitZ, limitZ))
		end
		local delta = state.Target - point
		local distance = delta.Magnitude
		if distance < 0.01 then
			state.Target = nil
			state.Wait = random:NextNumber(Config.MinPauseSeconds, Config.MaxPauseSeconds)
			continue
		end
		local nextPoint = point + delta.Unit * math.min(distance, Config.Speed * dt)
		local world = floor.CFrame:PointToWorldSpace(nextPoint)
		local rotation = bounds.Rotation
		-- Preserve the exact clicked position initially. If placed close to a
		-- fence, walk inward before rotating, avoiding a corner swinging outside.
		if math.abs(nextPoint.X) <= limitX and math.abs(nextPoint.Z) <= limitZ then
			rotation = CFrame.lookAt(world, world + floor.CFrame:VectorToWorldSpace(delta.Unit), floor.CFrame.UpVector).Rotation
		end
		model:PivotTo(CFrame.new(world) * rotation * state.Offset)
	end
end

function Service.Start()
	assert(not started, "WanderingService already started")
	started = true
	RunService.Heartbeat:Connect(Service.Step)
end

return table.freeze(Service)
