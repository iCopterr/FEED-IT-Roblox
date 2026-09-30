param([int]$Port=58741,[int]$PreviewPage=0,[double]$SampleTime=.3,[double]$Walk=1)
$ErrorActionPreference='Stop'
$pose=Get-Content src/client/UI/PetPose.luau -Raw
$profiles=Get-Content src/shared/Config/PetAnimationConfig.luau -Raw
$code="local Pose=(function()`n$pose`nend)()`nlocal Profiles=(function()`n$profiles`nend)()`nlocal page=$PreviewPage`nlocal sampleTime=$SampleTime`nlocal walk=$Walk`n"+@'
assert(not game:GetService('RunService'):IsRunning())
Profiles=Profiles.Profiles
local templates=game.ReplicatedStorage.PetsModel
local names={};for name in Profiles do table.insert(names,name) end;table.sort(names)
local report={};local available={}
for _,name in names do
 local source=templates:FindFirstChild(name)
 if not source then table.insert(report,name..': MISSING TEMPLATE');continue end
 local model=source:Clone()
 local state=assert(Pose.Bind(model,Profiles[name]),name..' missing root')
 local base=state.Root.CFrame
 local parts=0;for _ in state.Rest do parts+=1 end
 assert(#state.Links==parts-1,name..' rig coverage')
 for _,walk in {0,1} do
  local moving=false
  for _,t in {0,.125,.3,.6,1.2,2.4} do
   Pose.Step(state,t,walk)
   assert(state.Root.CFrame==base,name..' moved authoritative root')
   for part,rest in state.Rest do
    assert(part.Position.X==part.Position.X,name..' invalid position')
    if (part.Position-(base*rest).Position).Magnitude>.0001 then moving=true end
   end
  end
  assert(moving,name..' no motion in state '..walk)
 end
 Pose.Reset(state)
 for part,rest in state.Rest do assert((part.Position-(base*rest).Position).Magnitude<.01,name..' bad reset') end
 table.insert(report,name..': idle/walk/reset PASS ('..#state.Links..' rig links)')
 table.insert(available,name);model:Destroy()
end
local old=game.StarterGui:FindFirstChild('PetAnimationPreview')
if old then old:Destroy() end
local stage=workspace:FindFirstChild('PetAnimationPreviewStage')
if stage then stage:Destroy() end
local cam=workspace.CurrentCamera
if page==0 and cam:GetAttribute('PetPreviewOriginal') then
 cam.CFrame=cam:GetAttribute('PetPreviewOriginal');cam:SetAttribute('PetPreviewOriginal',nil)
 if cam:GetAttribute('PetPreviewFocus') then cam.Focus=cam:GetAttribute('PetPreviewFocus');cam:SetAttribute('PetPreviewFocus',nil) end
 if cam:GetAttribute('PetPreviewFov') then cam.FieldOfView=cam:GetAttribute('PetPreviewFov');cam:SetAttribute('PetPreviewFov',nil) end
end
if page>0 then
 if not cam:GetAttribute('PetPreviewOriginal') then cam:SetAttribute('PetPreviewOriginal',cam.CFrame) end
 if not cam:GetAttribute('PetPreviewFocus') then cam:SetAttribute('PetPreviewFocus',cam.Focus) end
 if not cam:GetAttribute('PetPreviewFov') then cam:SetAttribute('PetPreviewFov',cam.FieldOfView) end
 cam.FieldOfView=38
 stage=Instance.new('Folder');stage.Name='PetAnimationPreviewStage';stage.Parent=workspace
 local origin=Vector3.new(10000,1000,10000)
 cam.CFrame=CFrame.lookAt(origin+Vector3.new(0,26,-43),origin+Vector3.new(0,0,7))
 cam.Focus=CFrame.new(origin+Vector3.new(0,0,7))
 local gui=Instance.new('ScreenGui');gui.Name='PetAnimationPreview';gui.DisplayOrder=999;gui.IgnoreGuiInset=true
 for i=(page-1)*6+1,math.min(page*6,#available) do
  local name=available[i];local cell=(i-1)%6
  local view=Instance.new('ViewportFrame');view.Size=UDim2.fromScale(1/3,.5)
  view.Position=UDim2.fromScale((cell%3)/3,math.floor(cell/3)/2)
  view.BackgroundColor3=Color3.fromRGB(46,53,64);view.BorderSizePixel=2
  view.Ambient=Color3.fromRGB(200,200,200);view.LightColor=Color3.new(1,1,1);view.Parent=gui
  local model=templates[name]:Clone();model.Parent=stage
  local _,originalSize=model:GetBoundingBox();model:ScaleTo(model:GetScale()*9/originalSize.Magnitude)
  model:PivotTo(CFrame.new(origin+Vector3.new((cell%3-1)*14,0,math.floor(cell/3)*15)))
  local state=Pose.Bind(model,Profiles[name]);Pose.Step(state,sampleTime,walk)
  local cf,size=model:GetBoundingBox()
  local camera=Instance.new('Camera');camera.FieldOfView=35
  camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(1,.65,-1.5).Unit*size.Magnitude*1.3,cf.Position)
  camera.Parent=view;view.CurrentCamera=camera
  local label=Instance.new('TextLabel');label.Size=UDim2.new(1,0,0,30);label.BackgroundTransparency=1
  label.Text=name..' | WALK';label.Font=Enum.Font.GothamBold;label.TextSize=19;label.TextColor3=Color3.new(1,1,1);label.Parent=view
 end
 gui:Destroy()
end
return table.concat(report,'\n')
'@
$body=@{jsonrpc='2.0';id=1200;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 35).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
