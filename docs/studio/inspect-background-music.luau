local service=game:GetService('SoundService')
local result={}
for _,child in service:GetDescendants() do
 table.insert(result,{name=child:GetFullName(),class=child.ClassName,id=child:IsA('Sound') and child.SoundId or nil})
end
return game:GetService('HttpService'):JSONEncode(result)
