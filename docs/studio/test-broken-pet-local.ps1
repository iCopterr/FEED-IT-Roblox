param([string]$Luau = "$env:TEMP\FeedCriticalLuauTools\luau.exe")
$ErrorActionPreference='Stop'
# Bundle production modules into the same detached-profile integration test.
# UI rendering still requires Studio; only engine values/services are stubbed.
$preamble=@'
local node=function(name,parent)return {Name=name,Parent=parent}end
local shared=node("Shared")
shared.Config=node("Config",shared)
local server=node("Server");server.Services=node("Services",server);server.Data=node("Data",server)
local client=node("Client");client.UI=node("UI",client);client.Controllers=node("Controllers",client)
local storage={Shared=shared}
local point={Position=setmetatable({},{__sub=function()return {Magnitude=0}end})}
local workspace={ReviveMachine={InteractionPoint=point},GetServerTimeNow=function()return 100000 end}
workspace.ReviveMachine.FindFirstChild=function(_,name)return if name=="InteractionPoint" then point else nil end
workspace.FindFirstChild=function(_,name)return workspace[name]end
local game={ReplicatedStorage=storage,ServerScriptService={Server=server},StarterPlayer={StarterPlayerScripts={Client=client}}}
local serial=0
local services={ReplicatedStorage=storage,Players={},RunService={IsRunning=function()return false end},
 HttpService={GenerateGUID=function()serial+=1;return "test-guid-"..serial end}}
game.GetService=function(_,name)return assert(services[name],"Unexpected engine service "..name)end
local Random={new=function()return {NextNumber=function()return .5 end}end}
local Color3={fromRGB=function(...)return {...}end}
local CFrame={new=function()return {}end}
local Enum={Font={FredokaOne="FredokaOne"}}
'@
$builder=[Text.StringBuilder]::new($preamble)
foreach($mapping in @(@('src/shared/Config','shared.Config'),@('src/shared','shared'),@('src/server/Services','server.Services'),@('src/server/Data','server.Data'),@('src/client/UI','client.UI'),@('src/client/Controllers','client.Controllers'))) {
 foreach($file in Get-ChildItem -LiteralPath $mapping[0] -Filter '*.luau' -File) {
  $key=$file.BaseName
  $source=[IO.File]::ReadAllText($file.FullName)
  if($source.Contains(']==========]')) {throw 'Source delimiter conflict'}
  [void]$builder.Append("`n$($mapping[1]).$key=node('$key',$($mapping[1]));$($mapping[1]).$key.Source=[==========[$source]==========]`n")
 }
}
$test=[IO.File]::ReadAllText((Resolve-Path 'docs/studio/test-broken-pet-recovery.luau'))
[void]$builder.Append("`nlocal test=assert(loadstring([==========[$test]==========]));setfenv(test,setmetatable({RECOVERY_HEADLESS=true,game=game,workspace=workspace,Random=Random,Color3=Color3,CFrame=CFrame,Enum=Enum},{__index=getfenv()}));test()`n")
$output=Join-Path (Resolve-Path build) 'broken-pet-local.luau'
[IO.File]::WriteAllText($output,$builder.ToString(),[Text.UTF8Encoding]::new($false))
& $Luau $output
if($LASTEXITCODE -ne 0) {throw 'Broken pet integration test failed'}
