assert(not game:GetService('RunService'):IsRunning())
local service=game:GetService('SoundService')
local settings={Hatching={.35,true},HatchFinish={.5,false},Click={.25,false},Buy={.4,false},BuyFail={.4,false},Eating={.4,false},Feeding={.35,true},Failed={.5,false},Complete={.5,false}}
local report={}
for name,setting in settings do
 local sound=service:FindFirstChild(name)
 if not sound then sound=Instance.new('Sound');sound.Name=name;sound.Parent=service end
 assert(sound:IsA('Sound'))
 sound.Volume=setting[1];sound.Looped=setting[2];sound.PlayOnRemove=false
 table.insert(report,{name=name,id=sound.SoundId,looped=sound.Looped,volume=sound.Volume})
end
return game:GetService('HttpService'):JSONEncode(report)
