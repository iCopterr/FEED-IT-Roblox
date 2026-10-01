param([string]$Luau="$env:TEMP\FeedCriticalLuauTools\luau.exe")
$ErrorActionPreference='Stop'
$config=Get-Content src/shared/Config/PlotUpgradeConfig.luau -Raw
$view=Get-Content src/client/UI/PlotUpgradeSignView.luau -Raw
$prefix=@'
local Color3={fromRGB=function(...) return {...} end}
local Config=(function()
'@
$middle=@'
end)()
local Number=require('../src/shared/NumberFormat')
local game={ReplicatedStorage={Shared={Config={PlotUpgradeConfig=Config},NumberFormat=Number}}}
local require=function(value) return value end
local View=(function()
'@
$tests=@'
end)()
local gui={Title={},Level={},Rate={},Buy={},Status={}}
for slots=Config.StartingSlots,Config.MaxSlots-1 do
 local state={Level=slots,Slots=slots,NextSlots=slots+1,Cost=Config.UpgradeCost[slots+1],CanAfford=true}
 assert(View.Render(gui,state,true,true,false))
 local level=slots-Config.StartingSlots+1
 assert(gui.Level.Text==string.format('LEVEL %d → LEVEL %d',level,level+1))
 assert(state.Level==slots and state.Slots==slots and state.NextSlots==slots+1,'Display must not mutate purchase state')
 assert(gui.Buy.Text=='BUY • $'..Number.Money(state.Cost))
 assert(not View.Render(gui,state,false,true,false),'Owner validation unchanged')
 assert(not View.Render(gui,state,true,false,false),'Distance validation unchanged')
 assert(not View.Render(gui,state,true,true,true),'Busy validation unchanged')
end
assert(not View.Render(gui,{Level=10,Slots=10,MaxLevel=true},true,true,false))
assert(gui.Level.Text=='LEVEL 6 • MAX' and gui.Buy.Text=='MAX LEVEL')
assert(not View.Render(gui,{},true,true,false) and gui.Level.Text=='LEVEL —')
print('PASS: all five upgrades, max, loading; capacities/prices/purchase guards unchanged')
'@
$target=Join-Path (Get-Location) 'build/test-pen-level-labels.generated.luau'
[void][IO.Directory]::CreateDirectory((Split-Path $target))
[IO.File]::WriteAllText($target,$prefix+"`n"+$config+"`n"+$middle+"`n"+$view+"`n"+$tests,[Text.UTF8Encoding]::new($false))
& $Luau $target
if($LASTEXITCODE -ne 0){throw 'Pen label tests failed'}
$x=[xml](Get-Content src/world/PlotUpgradeSigns.rbxmx -Raw)
$labels=@($x.SelectNodes('//Item[Properties/string[@name="Name"]="Level"]/Properties/string[@name="Text"]'))
if($labels.Count -ne 6){throw 'Expected six authored signs'}
foreach($label in $labels){if($label.InnerText -ne 'LEVEL 1 → LEVEL 2'){throw 'Wrong initial label'}}
'PASS: six authored signs start at Level 1 -> Level 2'
