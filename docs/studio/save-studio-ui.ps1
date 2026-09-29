param([int]$Port=58741)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$snapshot=Join-Path ([IO.Path]::GetTempPath()) ('FeedUIBackup_'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($snapshot)|Out-Null
function Invoke-Studio($code) {
 $body=@{jsonrpc='2.0';id=995;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 10
 $response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
 $line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
 $inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
 if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 10)}
 return $inner.returnValue
}
$inventory=Invoke-Studio @'
assert(not game:GetService('RunService'):IsRunning(),'Cannot capture runtime UI')
local entries={}
for _,ui in game.StarterGui:GetChildren() do
 assert(ui:IsA('ScreenGui'),'Unexpected StarterGui child: '..ui.Name)
 for _,p in ui:GetDescendants() do assert(not p:IsA('LuaSourceContainer'),'Review embedded scripts before export') end
 table.insert(entries,{name=ui.Name,count=#ui:GetDescendants()+1})
end
return game:GetService('HttpService'):JSONEncode(entries)
'@ | ConvertFrom-Json
$tree=@{'$className'='DataModel';StarterGui=@{'$className'='StarterGui'}}
foreach($entry in $inventory) {
 if($entry.name -notmatch '^[A-Za-z][A-Za-z0-9_]*$') {throw 'Unexpected UI name; manual review required'}
 $name=$entry.name
 $hex=Invoke-Studio "assert(not game:GetService('RunService'):IsRunning());local ui=assert(game.StarterGui:FindFirstChild('$name'));local b=game:GetService('SerializationService'):SerializeInstancesAsync({ui});return (buffer.tostring(b):gsub('.',function(c)return string.format('%02x',string.byte(c))end))"
 $bytes=New-Object byte[] ($hex.Length/2)
 for($i=0;$i -lt $bytes.Length;$i++) {$bytes[$i]=[Convert]::ToByte($hex.Substring($i*2,2),16)}
 $path=Join-Path $snapshot ($name+'.rbxm')
 [IO.File]::WriteAllBytes($path,$bytes)
 $tree.StarterGui[$name]=@{'$path'=$path}
 Write-Output "Captured $name ($($entry.count) instances)"
}
# Convert with Rojo's native reader/writer instead of a lossy custom serializer.
$project=Join-Path $snapshot 'snapshot.project.json'
[IO.File]::WriteAllText($project,(@{name='UISnapshot';tree=$tree}|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
$place=Join-Path $snapshot 'snapshot.rbxlx'
& rojo build $project -o $place
if($LASTEXITCODE -ne 0) {throw 'Snapshot conversion failed; original assets untouched'}
$doc=[xml][IO.File]::ReadAllText($place)
$starter=$doc.SelectSingleNode('/roblox/Item[@class="StarterGui"]')
if(!$starter) {throw 'StarterGui missing from converted snapshot'}
$exports=@()
foreach($entry in $inventory) {
 $name=$entry.name
 $node=$starter.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")
 if(!$node -or (1+$node.SelectNodes('.//Item').Count) -ne $entry.count) {throw "Hierarchy mismatch: $name"}
 $asset=[xml]'<roblox version="4"></roblox>'
 [void]$asset.DocumentElement.AppendChild($asset.ImportNode($node,$true))
 $shared=$doc.SelectSingleNode('/roblox/SharedStrings')
 if($shared) {[void]$asset.DocumentElement.AppendChild($asset.ImportNode($shared,$true))}
 $exports+=@{name=$name;xml=$asset.OuterXml;path=(Join-Path $repo "src/ui/$name.rbxmx")}
}
# All live copies and hierarchy validations complete before any tracked asset write.
foreach($entry in $exports) {
 [IO.File]::WriteAllText($entry.path,$entry.xml,[Text.UTF8Encoding]::new($false))
 Write-Output "Saved $($entry.name)"
}
Write-Output "Original Studio binary snapshots retained at $snapshot"
