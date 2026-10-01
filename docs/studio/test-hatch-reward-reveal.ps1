param([int]$Port=58741)
$timing=[IO.File]::ReadAllText((Resolve-Path 'src/shared/Config/HatchAnimationConfig.luau'))
$reveal=[IO.File]::ReadAllText((Resolve-Path 'src/client/UI/HatchPetReveal.luau'))
$collect=[IO.File]::ReadAllText((Resolve-Path 'src/client/UI/HatchCollect.luau')).Replace('workspace:GetServerTimeNow()','testNow()')
$controller=[IO.File]::ReadAllText((Resolve-Path 'src/client/Controllers/HatchController.luau')).Replace('workspace:GetServerTimeNow()','testNow()')
$prefix=@'
assert(not game:GetService('RunService'):IsRunning())
local realGame,realRequire=game,require
local uiModules=realGame.StarterPlayer.StarterPlayerScripts.Client.UI
local now=0
local function testNow() return now end
local player={}
local character=Instance.new('Model')
local body=Instance.new('Part');body.Name='HumanoidRootPart';body.CFrame=CFrame.new(12,4,0);body.Parent=character
player.Character=character
local playerService={LocalPlayer=player}
local observations={}
local testId,interrupt
local render={Wait=function()
 local orb=workspace:FindFirstChild('HatchRewardTrail')
 local pet=workspace:FindFirstChild('HatchedPetReveal_'..testId)
 if orb then table.insert(observations,{at=now,pet=pet~=nil,alpha=orb.Transparency,color=orb.Color,position=orb.Position}) end
 now+=.05
 if interrupt and now>.5 then player.Character=nil end
 return .05
end}
local fakeGame={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
 if name=='Players' then return playerService end
 if name=='RunService' then return {RenderStepped=render} end
 if name=='Debris' then return {AddItem=function()end} end
 return realGame:GetService(name)
end}
local fakeTask={delay=function()end,spawn=function(fn)fn()end,wait=function(seconds)now+=seconds;return seconds end}
'@
$code=$prefix+"`nlocal Timing=(function()`n"+$timing+"`nend)()`n"+@'
local function configRequire(module)
 if module==realGame.ReplicatedStorage.Shared.Config.HatchAnimationConfig then return Timing end
 return realRequire(module)
end
local PetReveal=(function(game,require,script)
'@+"`n"+$reveal+"`nend)(fakeGame,configRequire,{Parent=uiModules})`n"+@'
local function collectRequire(module)
 if module=='PetReveal' then return PetReveal end
 return configRequire(module)
end
local Collect=(function(game,require,task,script)
'@+"`n"+$collect+"`nend)(fakeGame,collectRequire,fakeTask,{Parent={HatchPetReveal='PetReveal',VariantSignature=uiModules.VariantSignature,CriticalPopup=uiModules.CriticalPopup}})`n"+@'
local colors=realRequire(realGame.ReplicatedStorage.Shared.Config.InventoryConfig).RarityColors
local tested=0
for _,rarity in {'Common','Uncommon','Rare','Epic','Legendary','Mythic','Fabled','Divine','Celestial'} do
 now=0;observations={};testId='reveal_test_'..rarity;player.Character=character;interrupt=false
 local result={Ok=true,Code='Hatched',EggUid=testId,SpeciesId='test_common',Rarity=rarity,HatchOrigin=CFrame.new(0,3,0),
 RevealEndsAt=Timing.PetRevealSeconds,CollectStartsAt=Timing.PetRevealSeconds+Timing.PetDissolveSeconds,
 CollectEndsAt=Timing.PetRevealSeconds+Timing.PetDissolveSeconds+Timing.CollectSeconds}
 Collect.Play(result)
 local held,faded,flew=false,false,false
 for _,sample in observations do
  assert(sample.color==colors[rarity],'Rarity color mismatch')
  if sample.at>.5 and sample.at<1.8 then assert(sample.pet and sample.alpha==1);held=true end
  if sample.at>2.05 and sample.at<2.25 then assert(sample.pet and sample.alpha>0 and sample.alpha<1);faded=true end
  if sample.at>2.4 then assert(not sample.pet and sample.alpha==0);flew=true end
 end
 assert(held and faded and flew,'Missing reveal/dissolve/flight phase')
 assert(not workspace:FindFirstChild('HatchRewardTrail') and not workspace:FindFirstChild('HatchedPetReveal_'..testId),'Cleanup failed')
 observations={};Collect.Play(result);assert(#observations==0,'Duplicate replay')
 tested+=1
end
now=0;observations={};testId='reveal_test_respawn';interrupt=true;player.Character=character
Collect.Play({Ok=true,Code='Hatched',EggUid=testId,SpeciesId='test_common',Rarity='Rare',HatchOrigin=CFrame.new(0,3,0),RevealEndsAt=2,CollectStartsAt=2.3,CollectEndsAt=3.1})
assert(not workspace:FindFirstChild('HatchRewardTrail') and not workspace:FindFirstChild('HatchedPetReveal_'..testId),'Respawn cleanup failed')
character:Destroy()
'@+"`n"+@'
local popAt,calls=nil,0
local function controllerRequire(module)
 if module=='Sounds' then return {Play=function()return function()end end,Preload=function()end} end
 if module=='Collect' then return {Play=function(reward)
  calls+=1;popAt=now
  assert(reward.PetId=='pop-test-pet','Result lost at pop')
  local shell=workspace:FindFirstChild('HatchReveal_pop_timing_test')
  assert(shell and shell:GetAttribute('Stage')=='Light','Reveal not in pop block')
  for _,part in shell:GetDescendants() do
   if part:IsA('BasePart') then assert(part.Transparency==1,'Pet appears before shell disappears') end
  end
 end} end
 return configRequire(module)
end
local Controller=(function(game,require,task,script)
'@+"`n"+$controller+"`nend)(fakeGame,controllerRequire,fakeTask,{Parent={Parent={Audio={GameSounds='Sounds'},UI={HatchCollect='Collect',VariantSignature=uiModules.VariantSignature}}}})`n"+@'
now=0;interrupt=false
local started={Ok=true,Code='HatchStarted',EggUid='pop_timing_test',EggId='prototype_egg',HatchOrigin=CFrame.new(0,3,0),EndsAt=Timing.Duration,Reward={PetId='pop-test-pet'}}
assert(Controller.Enqueue(started),'Hatch rejected')
assert(calls==1 and popAt>=Timing.BurstAt and popAt<Timing.BurstAt+.06,'Reveal not at pop frame')
assert(not Controller.Enqueue(started) and calls==1,'Duplicate pop')
assert(not workspace:FindFirstChild('HatchReveal_pop_timing_test'),'Shell leaked')
return 'PASS '..tested..' rarity colors; 2s reveal, dissolve, flight, dedupe, respawn cleanup; actual HatchController reveals once on shell-pop frame'
'@
$body=@{jsonrpc='2.0';id=1011;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
