local service=game:GetService('SoundService')
local sound=service:FindFirstChild('BuyFail')
if not sound then
 sound=Instance.new('Sound');sound.Name='BuyFail';sound.Volume=.4;sound.Parent=service
end
assert(sound:IsA('Sound'))
sound.Looped=false;sound.PlayOnRemove=false
return game:GetService('HttpService'):JSONEncode({name=sound:GetFullName(),id=sound.SoundId,looped=sound.Looped})
