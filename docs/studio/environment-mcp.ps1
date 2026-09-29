param([string]$Recipe, [string]$Export, [string]$Screenshot)
$ErrorActionPreference = 'Stop'
if ($Screenshot) { $name='capture_screenshot'; $arguments=@{} }
else { $name='execute_luau'; $arguments=@{code=[IO.File]::ReadAllText((Resolve-Path $Recipe));target='edit'} }
$body=@{jsonrpc='2.0';id=801;method='tools/call';params=@{name=$name;arguments=$arguments}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing 'http://localhost:58742/mcp' -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 45).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$result=($line.Substring(6)|ConvertFrom-Json).result
if ($Screenshot) {
 $im=$result.content|Where-Object type -eq 'image'|Select-Object -First 1
 if (!$im) {throw ($result|ConvertTo-Json -Depth 8)}
 [IO.File]::WriteAllBytes($Screenshot,[Convert]::FromBase64String($im.data))
} else {
 $inner=$result.content[0].text|ConvertFrom-Json
 if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
 if ($Export) {
  $hex=$inner.returnValue
  $bytes=New-Object byte[] ($hex.Length/2)
  for($i=0;$i -lt $bytes.Length;$i++){ $bytes[$i]=[Convert]::ToByte($hex.Substring($i*2,2),16) }
  [IO.File]::WriteAllBytes($Export,$bytes)
 } else { $inner|ConvertTo-Json -Depth 10 }
}
