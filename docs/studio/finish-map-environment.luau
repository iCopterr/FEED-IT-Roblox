local roots={}
for _,r in workspace:GetChildren() do if r.Name=='MapEnvironment' then table.insert(roots,r) end end
assert(#roots==1,'Multiple environment folders: inspect before cleanup')
local count=0
for _,p in roots[1]:GetDescendants() do if p:IsA('BasePart') then count+=1 end end
assert(count==248,'Unexpected saved geometry count')
local checked=0
for _,s in assert(_G.EnvironmentProtectedParts) do
 assert(s.part.Parent and s.part.CFrame==s.cf and s.part.Size==s.size,'Existing geometry changed')
 checked+=1
end
local camera=_G.EnvironmentReviewCamera
if camera then workspace.CurrentCamera.CFrame=camera[1];workspace.CurrentCamera.CameraType=camera[2] end
return game:GetService('HttpService'):JSONEncode({environmentFolders=#roots,parts=count,protectedPartsUnchanged=checked})
