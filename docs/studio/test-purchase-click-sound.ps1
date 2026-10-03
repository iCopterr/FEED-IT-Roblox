param([int]$Port=58741)
$source=[IO.File]::ReadAllText((Resolve-Path 'src/client/Controllers/SoundController.luau'))
$prefix=@'
local clicks=0
local function signal()
 local list={}
 return {Connect=function(_,fn) table.insert(list,fn) end,Fire=function(...) for _,fn in list do fn(...) end end}
end
local function button(suppress)
 return {Name='TestButton',Suppress=suppress,Activated=signal(),IsA=function(_,c)return c=='GuiButton'end,GetAttribute=function(self,n)assert(n=='SuppressClickSound');return self.Suppress end,
 FindFirstAncestor=function(self,n)assert(n=='TouchGui');return self.TouchGui end}
end
local normal,buy=button(false),button(true)
local gui={DescendantAdded=signal(),GetDescendants=function()return {normal,buy}end}
local fakeGame={Players={LocalPlayer={WaitForChild=function(_,n)assert(n=='PlayerGui');return gui end}}}
local fakeRequire=function()return {Play=function(name)assert(name=='Click');clicks+=1 end}end
local fakeScript={Parent={Parent={Audio={GameSounds={}}}}}
local controller=(function(game,require,script)
'@
$suffix=@'
end)(fakeGame,fakeRequire,fakeScript)
controller.Start();controller.Start()
normal.Activated.Fire();assert(clicks==1,'Normal click / no duplicate binding')
buy.Activated.Fire();assert(clicks==1,'Purchase click suppressed')
local added=button(false);gui.DescendantAdded.Fire(added);gui.DescendantAdded.Fire(added)
added.Suppress=true;added.Activated.Fire();assert(clicks==1,'Late tagging respected')
added.Suppress=false;added.Activated.Fire();assert(clicks==2,'Other dynamic buttons retain click')
local jump=button(false);jump.Name='JumpButton';gui.DescendantAdded.Fire(jump);jump.Activated.Fire();assert(clicks==2,'Jump button stays silent')
local touch=button(false);touch.TouchGui={};gui.DescendantAdded.Fire(touch);touch.Activated.Fire();assert(clicks==2,'Other Roblox touch controls stay silent')
added.TouchGui={};added.Activated.Fire();assert(clicks==2,'Reparented touch control stays silent')
return 'PASS: purchase and jump/touch clicks suppressed, dynamic/late tagging, normal clicks and idempotent binding'
'@
$code=$prefix+"`n"+$source+"`n"+$suffix
$body=@{jsonrpc='2.0';id=1002;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 20).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
