local c=workspace.CurrentCamera
_G.OwnerEnvironmentCamera={cf=c.CFrame,type=c.CameraType}
c.CameraType=Enum.CameraType.Scriptable
c.CFrame=CFrame.lookAt(Vector3.new(98,38,-20),Vector3.new(50,9,-72))
return 'Owner source assets preview'
