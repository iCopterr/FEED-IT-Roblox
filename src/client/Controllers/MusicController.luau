-- SoundId is intentionally owner-editable on SoundService.BackgroundMusic.
local SoundService = game:GetService("SoundService")

local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	local music = SoundService:WaitForChild("BackgroundMusic", 10)
	if not music or not music:IsA("Sound") then
		warn("BackgroundMusic Sound is missing from SoundService")
		return
	end
	started = true
	local function updateTrack()
		music:Stop()
		-- No placeholder asset requests or loading errors until the owner adds audio.
		if music.SoundId:match("%S") then
			music:Play()
		end
	end
	music:GetPropertyChangedSignal("SoundId"):Connect(updateTrack)
	updateTrack()
end

return Controller
