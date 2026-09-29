local c=_G.GardenCamera
if c then workspace.CurrentCamera.CFrame=c.cf;workspace.CurrentCamera.CameraType=c.type end
if _G.GardenSelection then game:GetService('Selection'):Set(_G.GardenSelection) end
local n=0;for _,p in workspace:GetChildren() do if p.Name=='MapEnvironment' then n+=1 end end
assert(n==1)
return 'Editor camera/selection restored; single MapEnvironment verified'
