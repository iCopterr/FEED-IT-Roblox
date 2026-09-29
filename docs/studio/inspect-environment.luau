local out={}
for _,plot in workspace.PlayerPlots:GetChildren() do
 local parts={}
 for _,p in plot:GetDescendants() do
  if p:IsA('BasePart') and (p.Name=='Ground' or p.Name=='Floor' or p.Name=='Spawn' or p.Name=='Entrance') then table.insert(parts,{p.Name,tostring(p.Position),tostring(p.Size)}) end
 end
 table.insert(out,{plot.Name,parts})
end
local camera=workspace.CurrentCamera
_G.EnvironmentReviewCamera={camera.CFrame,camera.CameraType}
camera.CameraType=Enum.CameraType.Scriptable
camera.CFrame=CFrame.lookAt(Vector3.new(320,320,330),Vector3.new(0,0,4))
return game:GetService('HttpService'):JSONEncode(out)
