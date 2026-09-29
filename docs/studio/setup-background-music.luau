assert(not game:GetService('RunService'):IsRunning(), 'Stop Play first')
local service=game:GetService('SoundService')
local sound=service:FindFirstChild('BackgroundMusic')
if not sound then sound=Instance.new('Sound');sound.Name='BackgroundMusic';sound.Parent=service end
assert(sound:IsA('Sound'))
sound.Looped=true;sound.Volume=.2
-- Preserve an ID the owner may already have entered; do not set SoundId here.
return game:GetService('HttpService'):JSONEncode({name=sound:GetFullName(),looped=sound.Looped,volume=sound.Volume,id=sound.SoundId})
