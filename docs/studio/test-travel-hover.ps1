param([int]$Port=58741)
$ErrorActionPreference='Stop'
$source=Get-Content src/client/UI/Motion.luau -Raw
$code="local Motion=(function()`n"+$source+"`nend)()`n"+@'
assert(not game:GetService('RunService'):IsRunning())
local function signal()
 local callbacks={}
 return {Connect=function(_,fn)table.insert(callbacks,fn);return {Disconnect=function()end} end,
 Fire=function(...)for _,fn in callbacks do fn(...) end end,Count=function()return #callbacks end}
end
for _,name in {'Base','Merchant'} do
 local template=game.StarterGui.FeedYourPetUI.HUD.Travel[name]
 assert(template.MotionScale:IsA('UIScale') and template.MotionScale.Scale==1)
 assert(template.AnchorPoint==Vector2.new(.5,.5))
 local scale=template.MotionScale:Clone()
 local changed,selected,visibility=signal(),signal(),signal()
 local button={Active=true,MouseEnter=signal(),MouseLeave=signal(),InputBegan=signal(),InputEnded=signal(),Activated=signal(),Destroying=signal()}
 function button:FindFirstChild(key)return if key=='MotionScale' then scale else nil end
 function button:GetAttributeChangedSignal()return selected end
 function button:GetPropertyChangedSignal()return changed end
 function button:GetAttribute()return false end
 local panel={Visible=true,GetPropertyChangedSignal=function()return visibility end}
 local function check(target)
  task.wait(.15);assert(math.abs(scale.Scale-target)<.001,name..' wrong tween scale '..scale.Scale)
 end
 Motion.BindButton(button,panel);Motion.BindButton(button,panel)
 assert(button.MouseEnter.Count()==1,'Duplicate hover binding')
 button.MouseEnter.Fire();check(1.025)
 button.InputBegan.Fire({UserInputType=Enum.UserInputType.MouseButton1});check(.96)
 button.InputEnded.Fire({UserInputType=Enum.UserInputType.MouseButton1});check(1.025)
 button.MouseLeave.Fire();check(1)
 button.MouseEnter.Fire();button.MouseLeave.Fire();button.MouseEnter.Fire();check(1.025)
 button.Active=false;changed.Fire();check(1)
 button.Active=true;changed.Fire();panel.Visible=false;visibility.Fire();check(1)
 button.Destroying.Fire();scale:Destroy()
end
return 'PASS Base/Merchant: real TweenService hover, press, release, leave, rapid reversal, disabled/hidden reset and binding dedupe'
'@
$body=@{jsonrpc='2.0';id=1028;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
