param([int]$Port=58741)
$ErrorActionPreference='Stop'
$source=Get-Content src/client/UI/InventoryLayout.luau -Raw
$code="local Layout=(function()`n"+$source+"`nend)()`n"+@'
assert(not game:GetService('RunService'):IsRunning())
local gui=game.StarterGui.FeedYourPetUI:Clone()
local ok,result=xpcall(function()
 local modal=gui.Inventory
 local cards={modal.Panel.Layout.Pets.PetCardTemplate:Clone()}
 cards[1].Parent=modal.Panel.Layout.Pets
 local before={}
 for _,obj in modal:GetDescendants() do
  if obj:IsA('GuiObject') then
   before[obj]={Size=obj.Size,Position=obj.Position,AnchorPoint=obj.AnchorPoint}
   if obj:IsA('TextLabel') or obj:IsA('TextButton') or obj:IsA('TextBox') then before[obj].TextSize=obj.TextSize end
  elseif obj:IsA('UIGridLayout') then before[obj]={CellSize=obj.CellSize,CellPadding=obj.CellPadding} end
 end
 before[modal]={Size=modal.Size,Position=modal.Position}
 local buttons={}
 for i=1,10 do buttons[i]=gui.Hotbar['Slot'..i] end
 local checks=0
 for _,viewport in {Vector2.new(1920,1080),Vector2.new(1280,720),Vector2.new(390,844),Vector2.new(844,390),Vector2.new(320,568)} do
  for _,count in {0,1,10} do
   for i,button in buttons do button.Visible=i<=count end
   Layout.Apply(gui,cards,buttons,viewport)
   Layout.Apply(gui,cards,buttons,viewport)
   for obj,properties in before do for key,value in properties do assert(obj[key]==value,obj.Name..'.'..key..' overwritten') end end
   local size=modal.Size
   local scale=modal.InventoryFitScale.Scale
   assert((size.X.Scale*viewport.X+size.X.Offset)*scale<=viewport.X,'Inventory too wide')
   assert((size.Y.Scale*viewport.Y+size.Y.Offset)*scale<=viewport.Y,'Inventory too tall')
   assert(gui.Hotbar.Size.X.Offset<=viewport.X,'Hotbar overflow')
   if count==0 then assert(gui.Hotbar.Size==UDim2.fromOffset(0,0)) end
   for i=1,count do assert(buttons[i].Size.X.Offset==buttons[i].Size.Y.Offset,'Non-square hotbar') end
   checks+=1
  end
 end
 -- Subsequent manual edits remain authoritative, not cached startup geometry.
 modal.Size=UDim2.fromOffset(900,600)
 modal.Panel.Layout.Title.Position=UDim2.fromOffset(37,21)
 cards[1].Preview.Size=UDim2.fromScale(.8,.7)
 Layout.Apply(gui,cards,buttons,Vector2.new(1920,1080))
 assert(modal.Size==UDim2.fromOffset(900,600) and modal.InventoryFitScale.Scale==1)
 assert(modal.Panel.Layout.Title.Position==UDim2.fromOffset(37,21))
 assert(cards[1].Preview.Size==UDim2.fromScale(.8,.7))
 return 'PASS '..checks..' viewport/hotbar combinations; authored positions, sizes, fonts, card grid and later edits preserved'
end,debug.traceback)
gui:Destroy()
assert(ok,result)
return result
'@
$body=@{jsonrpc='2.0';id=1025;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
