$ErrorActionPreference='Stop'
$repo=Resolve-Path (Join-Path $PSScriptRoot '../..')
function Studio($code) {
    $body=@{jsonrpc='2.0';id=621;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
    $response=(Invoke-WebRequest 'http://localhost:58741/mcp' -UseBasicParsing -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 20).Content
    $line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
    $outer=$line.Substring(6)|ConvertFrom-Json
    $inner=$outer.result.content[0].text|ConvertFrom-Json
    if (!$inner.success) { throw $inner.error }
    return $inner
}
$result=Studio @'
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before editing map')
local changes={}
for _,plot in workspace.PlayerPlots:GetChildren() do
 local plate=plot:FindFirstChild('FeedPlate')
 if not plate then continue end
 local dish,rim,base=plate.Dish,plate.Rim,plate.Base
 base.Color=Color3.fromRGB(35,43,67);base.Material=Enum.Material.SmoothPlastic
 rim.Color=Color3.fromRGB(239,185,66);rim.Material=Enum.Material.Metal
 rim.Size=Vector3.new(.22,8.5,8.5)
 rim.CFrame=CFrame.new(dish.Position-Vector3.new(0,.06,0))*dish.CFrame.Rotation
 dish.Color=Color3.fromRGB(236,244,250);dish.Material=Enum.Material.SmoothPlastic
 local trim=plate:FindFirstChild('GoldFoot')
 if not trim then trim=base:Clone();trim:ClearAllChildren();trim.Name='GoldFoot';trim.Parent=plate end
 trim.Size=Vector3.new(.12,9.15,9.15)
 trim.CFrame=CFrame.new(base.Position-Vector3.new(0,.22,0))*base.CFrame.Rotation
 trim.Color=Color3.fromRGB(213,155,49);trim.Material=Enum.Material.Metal
 for i=1,8 do
  local name='RimAccent'..i;local accent=plate:FindFirstChild(name)
  if not accent then accent=Instance.new('Part');accent.Name=name;accent.Shape=Enum.PartType.Ball;accent.Parent=plate end
  local angle=i*math.pi/4
  accent.Size=Vector3.new(.22,.12,.22)
  accent.CFrame=CFrame.new(dish.Position+Vector3.new(math.cos(angle)*3.9,.08,math.sin(angle)*3.9))
  accent.Color=Color3.fromRGB(165,225,244);accent.Material=Enum.Material.Neon
  accent.Anchored=true;accent.CanCollide=false;accent.CanTouch=false;accent.CanQuery=true
 end
 local parts={}
 for _,part in plate:GetChildren() do if part:IsA('BasePart') then
  table.insert(parts,{Name=part.Name,Size={part.Size.X,part.Size.Y,part.Size.Z},CFrame={part.CFrame:GetComponents()},Color={part.Color.R,part.Color.G,part.Color.B},Material=part.Material.Value,Shape=part.Shape.Value})
 end end
 assert(#parts==12,'Unexpected plate part count')
 table.insert(changes,{Plot=plot.Name,Parts=parts})
end
assert(#changes==6,'Expected six feed plates')
return game:GetService('HttpService'):JSONEncode(changes)
'@
$changes=$result.returnValue|ConvertFrom-Json
$path=Join-Path $repo 'src/world/PlayerPlots.rbxmx'
$doc=[xml](Get-Content $path -Raw -Encoding UTF8)
function Property($item,$tag,$name,$xml) {
    $node=$item.SelectSingleNode("Properties/*[@name='$name']")
    if (!$node) { $node=$doc.CreateElement($tag);$node.SetAttribute('name',$name);[void]$item.SelectSingleNode('Properties').AppendChild($node) }
    $node.InnerXml=$xml
}
foreach ($change in $changes) {
    $plot=$doc.SelectSingleNode("//Item[Properties/string[@name='Name']='$($change.Plot)']")
    $plate=$plot.SelectSingleNode("Item[Properties/string[@name='Name']='FeedPlate']")
    foreach ($part in $change.Parts) {
        $item=$plate.SelectSingleNode("Item[Properties/string[@name='Name']='$($part.Name)']")
        if (!$item) {
            $item=$doc.CreateElement('Item');$item.SetAttribute('class','Part');$item.InnerXml='<Properties />';[void]$plate.AppendChild($item)
            Property $item 'string' 'Name' $part.Name
            Property $item 'bool' 'Anchored' 'true'
            Property $item 'bool' 'CanCollide' 'false'
            Property $item 'bool' 'CanTouch' 'false'
            Property $item 'bool' 'CanQuery' 'true'
            Property $item 'token' 'TopSurface' '0'
            Property $item 'token' 'BottomSurface' '0'
        }
        Property $item 'Vector3' 'size' "<X>$($part.Size[0])</X><Y>$($part.Size[1])</Y><Z>$($part.Size[2])</Z>"
        Property $item 'Color3' 'Color' "<R>$($part.Color[0])</R><G>$($part.Color[1])</G><B>$($part.Color[2])</B>"
        Property $item 'token' 'Material' "$($part.Material)"
        Property $item 'token' 'shape' "$($part.Shape)"
        $keys=@('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22')
        $xml='';for ($i=0;$i -lt 12;$i++) { $xml+="<$($keys[$i])>$($part.CFrame[$i])</$($keys[$i])>" }
        Property $item 'CoordinateFrame' 'CFrame' $xml
    }
}
[IO.File]::WriteAllText($path,$doc.OuterXml,[Text.UTF8Encoding]::new($false))
Write-Output 'Updated and persisted six feed plates, 12 parts each; original Dish transforms preserved.'
