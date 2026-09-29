-- Local-only playback from owner-editable SoundService templates.
local SoundService = game:GetService("SoundService")
local Sounds = {}
local allowed = {Hatching=true, HatchFinish=true, Click=true, Buy=true, Eating=true, Feeding=true, Failed=true, Complete=true}
local active, lastClick = {}, -math.huge
local preloaded = setmetatable({}, {__mode = "k"})
local function silent() end

function Sounds.Preload(name: string)
	if not allowed[name] then return end
	local template = SoundService:FindFirstChild(name)
	if not template or not template:IsA("Sound") or not template.SoundId:match("%S") then return end
	local id = template.SoundId
	if preloaded[template] == id then return end
	preloaded[template] = id
	-- Never hold up the animation while the sound is downloading.
	task.spawn(function()
		local ok = pcall(function() game:GetService("ContentProvider"):PreloadAsync({template}) end)
		if not ok and preloaded[template] == id then preloaded[template] = nil end
	end)
end

function Sounds.Play(name: string, maxSeconds: number?): () -> ()
	if not allowed[name] then return silent end
	local template = SoundService:FindFirstChild(name)
	if not template or not template:IsA("Sound") or not template.SoundId:match("%S") then return silent end
	if name == "Click" and os.clock() - lastClick < .04 then return silent end
	if (active[name] or 0) >= 3 then return silent end
	if name == "Click" then lastClick = os.clock() end
	local sound = template:Clone()
	sound.Name = "Playing_" .. name
	sound.PlayOnRemove = false
	-- The authored looping setting is reserved for animation-phase sounds.
	sound.Looped = name == "Hatching" or name == "Feeding"
	active[name] = (active[name] or 0) + 1
	local stopped = false
	local ended, destroying
	local function stop()
		if stopped then return end
		stopped = true
		active[name] -= 1
		if ended then ended:Disconnect() end
		if destroying then destroying:Disconnect() end
		sound:Stop()
		sound:Destroy()
	end
	ended = sound.Ended:Connect(stop)
	destroying = sound.Destroying:Connect(function()
		if stopped then return end
		stopped = true; active[name] -= 1
		ended:Disconnect(); destroying:Disconnect()
	end)
	sound.Parent = SoundService
	-- Bound even unloaded/invalid assets and interrupted animation tasks.
	task.delay(math.clamp(maxSeconds or 10, .05, 30), stop)
	sound:Play()
	return stop
end

return table.freeze(Sounds)
