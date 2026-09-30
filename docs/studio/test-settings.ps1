param([int]$Port=58741)
$ErrorActionPreference='Stop'
$config=Get-Content src/shared/Config/SettingsConfig.luau -Raw
$server=Get-Content src/server/Services/UIService.luau -Raw
$client=Get-Content src/client/Controllers/SettingsController.luau -Raw
$code="local Settings=(function()`n$config`nend)()`nassert(loadstring([====[$client]====]))`n"+@'
assert(Settings.Valid('MusicVolume',0) and Settings.Valid('SFXVolume',1))
for _,v in {-1,2,math.huge,0/0,'1',true} do assert(not Settings.Valid('MusicVolume',v)) end
assert(not Settings.Valid('TutorialStep','Done'))
assert(Settings.Valid('ShowOwnPets',false) and not Settings.Valid('ShowOwnPets',0))
local saved={TutorialStep='BuyEgg',MusicVolume=.25,ShowOwnPets=false}
local values=Settings.Read(saved)
assert(values.MusicVolume==.25 and values.ShowOwnPets==false and values.SFXVolume==1)
assert(values.TutorialStep==nil and saved.TutorialStep=='BuyEgg')
local storage=game.ReplicatedStorage
local data={Settings=saved}
local ticks=0
local os={clock=function() ticks+=1;return ticks end}
local script={Parent={}}
for _,name in {'DataService','PetService','CarryService','PlacementService','MoneyService','PedestalService','FeedLocks'} do script.Parent[name]=name end
local function require(module)
 if module=='DataService' then return {GetData=function(player)return if player=='owner' then data else nil end} end
 if module==storage.Shared.Config.SettingsConfig then return Settings end
 if module==storage.Shared.Config.UIConfig then return {RequestCooldown=.1} end
 return {}
end
'@
$code+="`nlocal UI=(function()`n$server`nend)()`n"+@'
assert(UI.HandleRequest('owner','GetSettings').Settings.MusicVolume==.25)
assert(UI.HandleRequest('owner','SetSetting','MusicVolume',.6).Ok)
assert(data.Settings.MusicVolume==.6 and data.Settings.TutorialStep=='BuyEgg')
assert(not UI.HandleRequest('owner','SetSetting','TutorialStep','Done').Ok)
assert(not UI.HandleRequest('owner','SetSetting','SFXVolume',2).Ok)
assert(not UI.HandleRequest('missing','SetSetting','MusicVolume',0).Ok)
assert(UI.HandleRequest('owner','SetSetting','ShowOwnPets',false).Ok)
local gui=game.StarterGui.SettingsUI
assert(not gui.Panel.Visible)
for _,key in {'MusicVolume','SFXVolume'} do
 assert(gui.Panel[key].Slider.Fill and gui.Panel[key].Slider.Knob)
end
for _,key in {'ShowOwnPets','ShowOtherPets'} do assert(gui.Panel[key].Toggle.Active) end
for _,o in gui:GetDescendants() do assert(not o:IsA('LuaSourceContainer')) end
return 'PASS: actual settings server handlers, validation, profile isolation, preserved tutorial fields, defaults, authored controls and client syntax'
'@
$body=@{jsonrpc='2.0';id=1300;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
