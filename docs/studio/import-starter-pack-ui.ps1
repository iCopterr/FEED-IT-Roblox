# Transfer the saved authored UI into a connected EDIT session only when missing.
# No managed Script edits, no replacement of an existing UI, no world changes.
param([int]$Port=58741)
$ErrorActionPreference='Stop'
$xml=[xml](Get-Content 'src/ui/StarterPackUI.rbxmx' -Raw)
function Convert-Node($node){
 $properties=@()
 foreach($p in $node.Properties.ChildNodes){
  $name=$p.GetAttribute('name');$kind=$p.LocalName
  # Export-only/internal metadata is not writable through the plugin API.
  if($kind -in @('BinaryString','Ref','SecurityCapabilities') -or $name -in @('SourceAssetId','DefinesCapabilities','Sink','LocalizationMatchIdentifier','LocalizationMatchedSourceText')){continue}
  $value=switch($kind){
   'UDim2' {@([double]$p.XS,[double]$p.XO,[double]$p.YS,[double]$p.YO);break}
   'UDim' {@([double]$p.S,[double]$p.O);break}
   'Color3' {@([double]$p.R,[double]$p.G,[double]$p.B);break}
   'Vector2' {@([double]$p.X,[double]$p.Y);break}
   'Rect2D' {@([double]$p.min.X,[double]$p.min.Y,[double]$p.max.X,[double]$p.max.Y);break}
   'Font' {@([string]$p.Family.url,[int]$p.Weight,[string]$p.Style);break}
   'Content' {[string]$p.uri;break}
   default {$p.InnerText}
  }
  $properties+=,@($name,$kind,$value)
 }
 $children=@();foreach($child in $node.SelectNodes('Item')){$children+=Convert-Node $child}
 return @{class=$node.GetAttribute('class');properties=$properties;children=$children}
}
$payload=Convert-Node $xml.roblox.Item | ConvertTo-Json -Depth 80 -Compress
$code=@'
assert(not game:GetService("RunService"):IsRunning(),"Stop Play before importing")
assert(not game.StarterGui:FindFirstChild("StarterPackUI"),"StarterPackUI exists; preserve it")
local data=game:GetService("HttpService"):JSONDecode([====[PAYLOAD]====])
local function enumValue(enum,value)
 for _,item in enum:GetEnumItems() do if item.Value==value then return item end end
 error("Unknown enum "..tostring(value))
end
local function decode(instance,name,kind,v)
 if kind=="string" then return v end
 if kind=="bool" then return v=="true" end
 if kind=="float" or kind=="int" or kind=="int64" then return tonumber(v) end
 if kind=="token" then
  local current=instance[name]
  return if typeof(current)=="EnumItem" then enumValue(current.EnumType,tonumber(v)) else tonumber(v)
 end
 if kind=="Color3" then return Color3.new(unpack(v)) end
 if kind=="UDim2" then return UDim2.new(unpack(v)) end
 if kind=="UDim" then return UDim.new(unpack(v)) end
 if kind=="Vector2" then return Vector2.new(unpack(v)) end
 if kind=="Rect2D" then return Rect.new(unpack(v)) end
 if kind=="Font" then return Font.new(v[1],enumValue(Enum.FontWeight,v[2]),Enum.FontStyle[v[3]]) end
 if kind=="Content" then return Content.fromUri(v) end
 if kind=="ColorSequence" or kind=="NumberSequence" then
  local numbers={};for n in v:gmatch("%S+") do table.insert(numbers,tonumber(n)) end
  local keys={};local stride=if kind=="ColorSequence" then 5 else 3
  for i=1,#numbers,stride do
   table.insert(keys,if stride==5 then ColorSequenceKeypoint.new(numbers[i],Color3.new(numbers[i+1],numbers[i+2],numbers[i+3])) else NumberSequenceKeypoint.new(numbers[i],numbers[i+1],numbers[i+2]))
  end
  return if stride==5 then ColorSequence.new(keys) else NumberSequence.new(keys)
 end
 error("Unhandled property type "..kind)
end
local errors={}
local function build(node)
 local instance=Instance.new(node.class)
 for _,p in node.properties do
  local ok,err=pcall(function() instance[p[1]]=decode(instance,p[1],p[2],p[3]) end)
  if not ok then table.insert(errors,node.class.."."..p[1]..": "..tostring(err)) end
 end
 for _,child in node.children do build(child).Parent=instance end
 return instance
end
local gui=build(data)
if #errors>0 then gui:Destroy();error(table.concat(errors,"\n")) end
assert(gui:IsA("ScreenGui") and gui.Name=="StarterPackUI" and gui.Panel.Offers.Welcome.Buy)
gui.Parent=game.StarterGui
game:GetService("ChangeHistoryService"):SetWaypoint("Import saved StarterPackUI")
print("IMPORTED",gui:GetFullName(),#gui:GetDescendants(),gui.Panel.Visible)
'@
$code=$code.Replace('PAYLOAD',$payload)
$body=@{jsonrpc='2.0';id=810;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n" | Where-Object { $_.StartsWith('data: ') } | Select-Object -First 1
$rpc=$line.Substring(6)|ConvertFrom-Json
if($rpc.error){throw ($rpc.error|ConvertTo-Json -Compress)}
$result=$rpc.result.content[0].text|ConvertFrom-Json
if(!$result.success){throw ($result|ConvertTo-Json -Depth 8)}
$result|ConvertTo-Json -Depth 8
