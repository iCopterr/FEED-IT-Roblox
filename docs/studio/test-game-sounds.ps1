param([int]$Port=58741)
$source=[IO.File]::ReadAllText((Resolve-Path 'src/client/Audio/GameSounds.luau'))
$prefix=@'
local callbacks,clones={},{}
local now,loads=0,0
local function signal()
 local handlers={}
 return {Connect=function(_,fn)
  local conn={};handlers[conn]=fn
  function conn:Disconnect() handlers[self]=nil end
  return conn
 end,Fire=function() for _,fn in table.clone(handlers) do fn() end end}
end
local function sound(id)
 local s={SoundId=id,Ended=signal(),Destroying=signal(),plays=0,stops=0}
 function s:IsA(class) return class=='Sound' end
 function s:Clone() local c=sound(self.SoundId);table.insert(clones,c);return c end
 function s:Play() self.plays+=1 end
 function s:Stop() self.stops+=1 end
 function s:Destroy() if self.dead then return end;self.dead=true;self.Destroying.Fire() end
 return s
end
local templates={}
for _,name in {'Hatching','HatchFinish','Click','Buy','Eating','Feeding','Failed','Complete'} do templates[name]=sound('') end
local service={FindFirstChild=function(_,name) return templates[name] end}
local fakeGame={GetService=function(_,name)
 if name=='ContentProvider' then return {PreloadAsync=function(_,assets) assert(#assets==1);loads+=1 end} end
 assert(name=='SoundService');return service
end}
local fakeTask={delay=function(seconds,fn) assert(seconds>=.05 and seconds<=30);table.insert(callbacks,fn) end}
fakeTask.spawn=function(fn) fn() end
local fakeOs={clock=function() return now end}
local audio=(function(game,task,os)
'@
$suffix=@'
end)(fakeGame,fakeTask,fakeOs)
audio.Play('Buy')();audio.Play('Unknown')();assert(#clones==0,'Empty IDs must not clone/play')
audio.Preload('HatchFinish');assert(loads==0)
for _,s in templates do s.SoundId='test-only-mock' end
audio.Preload('HatchFinish');audio.Preload('HatchFinish');assert(loads==1,'Preload deduplicated')
templates.HatchFinish.SoundId='changed-mock';audio.Preload('HatchFinish');assert(loads==2,'Changed asset preloaded')
local stop=audio.Play('Feeding',3);assert(#clones==1 and clones[1].Looped and clones[1].plays==1)
stop();stop();assert(clones[1].dead and clones[1].stops==1,'Stop must be idempotent')
local a,b,c=audio.Play('Hatching'),audio.Play('Hatching'),audio.Play('Hatching')
local n=#clones;audio.Play('Hatching')();assert(#clones==n,'Concurrency cap')
a();audio.Play('Hatching')();assert(#clones==n+1,'Released slot can play')
b();c()
audio.Play('Click');local before=#clones;audio.Play('Click');assert(#clones==before,'Click throttle')
now=.1;audio.Play('Click');assert(#clones==before+1)
for _,name in {'HatchFinish','Buy','Eating','Failed','Complete'} do
 audio.Play(name);local s=clones[#clones];assert(not s.Looped);s.Ended.Fire();assert(s.dead)
end
audio.Play('Feeding');local s=clones[#clones];s:Destroy()
for _,callback in callbacks do callback() end
for _,s in clones do assert(s.dead,'Timeout must remove sound') end
return 'PASS: blank IDs, preload deduplication/ID changes, playback, phase loops, idempotent stop, overlap cap, click throttle, Ended/external destruction and timeout cleanup'
'@
$code=$prefix+"`n"+$source+"`n"+$suffix
$body=@{jsonrpc='2.0';id=979;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 20).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
