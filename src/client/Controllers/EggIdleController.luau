local RunService = game:GetService("RunService")
local Motion = require(game.ReplicatedStorage.Shared.EggIdleMotion)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local plots = workspace:WaitForChild("PlayerPlots")
	local eggs = {}
	local function track(model)
		if not model:IsA("Model") then return end
		local origin = model:GetAttribute("EggIdleOrigin")
		local id = model:GetAttribute("EggUid")
		if typeof(origin) == "CFrame" and type(id) == "string" then
			eggs[model] = {Origin = origin, Phase = Motion.Phase(id)}
		end
	end
	-- Deferred registration lets replicated attributes arrive with the model.
	plots.DescendantAdded:Connect(function(item) task.defer(track, item) end)
	plots.DescendantRemoving:Connect(function(item) eggs[item] = nil end)
	for _, item in plots:GetDescendants() do track(item) end
	local scanAt = 0
	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		if now >= scanAt then
			scanAt = now + 2
			-- Retry streamed models whose attributes arrived after DescendantAdded.
			for _, plot in plots:GetChildren() do
				local pen = plot:FindFirstChild("Pen")
				if pen then for _, model in pen:GetChildren() do
					if not eggs[model] then track(model) end
				end end
			end
		end
		local camera = workspace.CurrentCamera
		for model, state in eggs do
			if not model:IsDescendantOf(plots) then eggs[model] = nil; continue end
			if camera and (camera.CFrame.Position - state.Origin.Position).Magnitude <= 160 then
				model:PivotTo(state.Origin * Motion.Offset(now, state.Phase, model:GetAttribute("HatchReady") == true))
			end
		end
	end)
end

return Controller
