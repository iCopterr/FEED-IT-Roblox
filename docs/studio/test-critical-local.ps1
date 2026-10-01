param([string]$Luau = "$env:TEMP\FeedCriticalLuauTools\luau.exe")
$ErrorActionPreference='Stop'
# Bundle unchanged production configuration/resolver with a substituted import.
# Generated output lives under ignored build/, never edits production sources.
$config=Get-Content -Raw src/shared/Config/FeedConfig.luau
$resolver=(Get-Content -Raw src/server/Services/FeedResolver.luau).Replace('local Config = require(game.ReplicatedStorage.Shared.Config.FeedConfig)','local Config = FeedConfig')
$variants=Get-Content -Raw src/shared/Config/VariantConfig.luau
$debug=Get-Content -Raw src/shared/Config/DebugConfig.luau
$tests=@'
assert(#FeedConfig.CriticalResults==2)
assert(not table.find(Debug.Modes,"Mega") and not table.find(Debug.Modes,"Insane"))
local counts={Normal=0,Critical=0}
for ticket=0,9999 do
 local calls=0
 local result=Resolver.Roll(17,function()
  calls+=1;assert(calls<=2,"Extra RNG roll")
  return if calls==1 then .999 else (ticket+.5)/10000
 end)
 counts[result.Critical]+=1
 assert(result.Gain==(if result.Critical=="Critical" then 2 else 1))
end
assert(counts.Normal==9900 and counts.Critical==100)
for _,case in {{.989999,"Normal",1},{.99,"Critical",2},{.999999,"Critical",2}} do
 local calls=0
 local result=Resolver.Roll(0,function()calls+=1;return if calls==1 then .999 else case[1] end)
 assert(result.Critical==case[2] and result.Gain==case[3])
end
for _,level in {38,39} do
 local result=Resolver.Roll(level,function()return .999 end)
 assert(result.FeedLevel==40 and result.Gain==40-level)
end
assert(not pcall(Resolver.Roll,40,function()error("Must not roll")end))
for _,case in {{0,"MiracleSave"},{.9,"Explosion"}} do
 local calls=0
 local result=Resolver.Roll(20,function()calls+=1;assert(calls<=2);return if calls==1 then 0 else case[1] end)
 assert(result.Code==case[2] and result.Gain==0 and not result.Critical)
end
-- Guaranteed food still permits Critical, but never Explosion.
local calls=0
local guaranteed=Resolver.Roll(20,function()calls+=1;return if calls==1 then 0 else .999 end,0)
assert(guaranteed.Code=="Success" and guaranteed.Critical=="Critical" and guaranteed.Gain==2)
assert(math.abs(FeedConfig.GetPresentationSeconds("Success","Critical")-4.85)<1e-8)
assert(math.abs(FeedConfig.GetPresentationSeconds("Success","Normal")-3.9)<1e-8)
assert(math.abs(FeedConfig.GetPresentationSeconds("Explosion")-3.9)<1e-8)
assert(math.abs(FeedConfig.GetPresentationSeconds("MiracleSave")-3.9)<1e-8)
local tally={Normal=0,Shiny=0,Rainbow=0,Celestial=0}
for i=1,Variants.Tickets do tally[Variants.Pick(i)]+=1 end
for kind,definition in Variants.Types do assert(tally[kind]==definition.Tickets) end
assert(Variants.Multiplier("Shiny")==2 and Variants.Multiplier("Rainbow")==5 and Variants.Multiplier("Celestial")==10)
print("PASS: 10,000 Critical tickets (9,900 Normal / 100 Critical), boundaries, cap, explosion order, guarantee, presentation timing; 100,000 unchanged variant tickets")
'@
$bundle="local FeedConfig=(function()`n$config`nend)()`nlocal Resolver=(function()`n$resolver`nend)()`nlocal Variants=(function()`n$variants`nend)()`nlocal Debug=(function()`n$debug`nend)()`n$tests"
$output=Join-Path (Resolve-Path build) 'critical-variant-local.luau'
[IO.File]::WriteAllText($output,$bundle,[Text.UTF8Encoding]::new($false))
& $Luau $output
if ($LASTEXITCODE -ne 0) { throw 'Critical/variant regression failed' }
