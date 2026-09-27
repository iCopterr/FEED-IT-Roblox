param([string[]]$Names, [string]$Destination='assets/pets/consolidated-20260927', [ValidateSet('originals','optimized')][string[]]$Variants=@('originals','optimized'))
$ErrorActionPreference='Stop'
foreach($name in $Names){
 if($name -notmatch '^[A-Za-z ]+$'){throw 'Unexpected template name'}
 foreach($variant in $Variants){
  $folder=if($variant -eq 'originals'){'PetModelBackups_20260927'}else{'PetOptimizationCandidates'}
  $code="local f=game.ServerStorage:FindFirstChild('$folder');local m=(f and f:FindFirstChild('$name'))or game.ReplicatedStorage.PetsModel:FindFirstChild('$name');assert(m);local data=game:GetService('SerializationService'):SerializeInstancesAsync({m});return (buffer.tostring(data):gsub('.',function(c)return string.format('%02x',string.byte(c))end))"
  $body=@{jsonrpc='2.0';id=610;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 10
  $response=(Invoke-WebRequest 'http://localhost:58741/mcp' -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -UseBasicParsing -TimeoutSec 120).Content
  $line=$response -split "`n"|Where-Object{$_.StartsWith('data: ')}|Select-Object -First 1
  $outer=$line.Substring(6)|ConvertFrom-Json
  $inner=$outer.result.content[0].text|ConvertFrom-Json
  if(-not $inner.success){throw $inner.error}
  $bytes=[Convert]::FromHexString($inner.returnValue)
  if([Text.Encoding]::ASCII.GetString($bytes,0,8) -ne '<roblox!'){throw 'Invalid RBXM header'}
  $dir=Join-Path $Destination $variant
  [IO.Directory]::CreateDirectory((Join-Path (Get-Location) $dir))|Out-Null
  $path=Join-Path $dir ($name.Replace(' ','-')+'.rbxm')
  [IO.File]::WriteAllBytes((Join-Path (Get-Location) $path),$bytes)
  Write-Output "$variant/$name : $($bytes.Length) bytes"
 }
}
