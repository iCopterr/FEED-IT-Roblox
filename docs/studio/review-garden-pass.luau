local out={}
for _,p in workspace.SkyIsland:GetChildren() do if p:IsA('BasePart') then table.insert(out,{p.Name,tostring(p.Position),tostring(p.Size),tostring(p.Color),p.Transparency}) end end
local camera=workspace.CurrentCamera
camera.CFrame=CFrame.lookAt(Vector3.new(198,77,196),Vector3.new(104,0,113))
return game:GetService('HttpService'):JSONEncode(out)
