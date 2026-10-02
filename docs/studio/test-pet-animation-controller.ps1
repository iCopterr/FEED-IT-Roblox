param([int]$Port=58741)
$ErrorActionPreference='Stop'
$pose=Get-Content src/client/UI/PetPose.luau -Raw
$config=Get-Content src/shared/Config/PetAnimationConfig.luau -Raw
$controller=Get-Content src/client/Controllers/PetAnimationController.luau -Raw
$code="local Pose=(function()`n$pose`nend)()`nlocal Config=(function()`n$config`nend)()`n"+@'
local realGame,realWorkspace=game,workspace
assert(not realGame:GetService('RunService'):IsRunning())
local storage=realGame.ReplicatedStorage
local species=require(storage.Shared.Config.PetConfig).Species
local placement=require(storage.Shared.Config.PlacementConfig)
local plots=Instance.new('Folder')
local folder=Instance.new('Folder');folder.Name=placement.VisualFolderName;folder.Parent=plots
local models={}
for id,def in species do
 local source=storage.PetsModel:FindFirstChild(def.TemplateName)
 assert(source,def.TemplateName..' missing')
 local m=source:Clone();m:SetAttribute('SpeciesId',id);m:PivotTo(CFrame.identity);m.Parent=folder;table.insert(models,m)
end
local delayedSource=storage.PetsModel.Chicken
local delayed=delayedSource:Clone();delayed.Name='Delayed Chicken';local delayedRoot=delayed.PrimaryPart
delayed.PrimaryPart=nil;delayed.Parent=folder
local steps={};local callbacks={};local connections={}
local originalStep=Pose.Step
Pose.Step=function(state,t,walk) steps[state.Model]={Walk=walk};originalStep(state,t,walk) end
local service={RenderStepped={Connect=function(_,fn)table.insert(callbacks,fn) end}}
local taggedAdded={}
local collection={
 GetTagged=function()return {} end,
 HasTag=function(_,model)return model:GetAttribute('TestPetVisual')==true end,
 GetInstanceAddedSignal=function()return {Connect=function(_,fn)table.insert(taggedAdded,fn) end} end,
}
local workspace={CurrentCamera={CFrame=CFrame.identity},WaitForChild=function()return plots end}
local game={GetService=function(_,name)
 if name=='RunService' then return service elseif name=='ReplicatedStorage' then return storage end
 if name=='CollectionService' then return collection end
 return realGame:GetService(name)
end}
local token={};local script={Parent={Parent={UI={PetPose=token}}}}
local realRequire=require
local function require(module)
 if module==token then return Pose end
 if module==storage.Shared.Config.PetAnimationConfig then return {Enabled=true,Profiles=Config.Profiles} end
 return realRequire(module)
end
'@
$code+="`nlocal Controller=(function()`n$controller`nend)()`n"+@'
Controller.Start();Controller.Start();assert(#callbacks==1,'duplicate render loop')
-- Simulate a streamed pet whose parent arrives before its replicated identity
-- and PrimaryPart. The production controller must retry rather than miss it.
for _,callback in callbacks do callback(1/60) end
assert(not steps[delayed],'incomplete streamed pet bound too early')
assert(delayed:GetAttribute('ClientPetAnimationPending')==true,'delayed pet was not queued')
delayed:SetAttribute('SpeciesId','test_common');delayed.PrimaryPart=delayedRoot
table.insert(models,delayed)
-- Also verify a complete pet streamed after startup is caught through its
-- replicated PetVisual tag, independent of descendant event ordering.
local late=delayedSource:Clone();late.Name='Late Chicken';late:SetAttribute('SpeciesId','test_common')
late:SetAttribute('TestPetVisual',true);late.Parent=folder;table.insert(models,late)
for _,added in taggedAdded do added(late) end
for frame=1,120 do
 -- Simulated lower-frequency server replication between client render frames.
 if frame%3==0 then for _,m in models do m:PivotTo(m:GetPivot()+Vector3.new(.15,0,0)) end end
 for _,callback in callbacks do callback(1/60) end
end
for _,m in models do
 assert(steps[m] and steps[m].Walk>.95,'packet walk blend failed: '..m.Name..' '..tostring(steps[m] and steps[m].Walk))
 assert(m:GetAttribute('ClientPetAnimationActive')==true,'animation activation marker missing')
end
for frame=1,120 do for _,callback in callbacks do callback(1/60) end end
for _,m in models do assert(steps[m].Walk<.001,'idle blend failed') end
steps={};workspace.CurrentCamera.CFrame=CFrame.new(10000,0,0)
for _,callback in callbacks do callback(1/60) end
assert(next(steps)==nil,'distance culling failed')
workspace.CurrentCamera.CFrame=CFrame.identity
for _,callback in callbacks do callback(1/60) end
for _,m in models do assert(steps[m],'resume failed') end
for _,m in models do m.Parent=nil end
for _,callback in callbacks do callback(1/60) end
for _,m in models do m:Destroy() end
plots:Destroy()
return 'PASS 36 pets + delayed/late replicas: retry/tag binding, duplicate-start guard, packet movement, smooth idle, culling, resuming and removal'
'@
$body=@{jsonrpc='2.0';id=1201;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 35).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
