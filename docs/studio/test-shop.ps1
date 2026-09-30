param([int]$Port=58741)
$ErrorActionPreference='Stop'
$config=Get-Content src/shared/Config/MonetizationConfig.luau -Raw
$controller=Get-Content src/client/Controllers/ShopController.luau -Raw
$code="local Config=(function()`n"+$config+"`nend)()`nassert(loadstring("+('[====['+$controller+']====]')+"))`n"+@'
local gui=game.StarterGui.ShopUI
assert(not gui.Panel.Visible)
assert(gui.Open.Label.Text=='SHOP')
assert(gui.Open.Size==game.StarterGui.IndexUI.Open.Size)
assert(gui.Open.Label.FontFace==game.StarterGui.IndexUI.Open.Label.FontFace)
assert(gui.Open.Position.Y.Offset<game.StarterGui.IndexUI.Open.Position.Y.Offset)
assert(#Config.MoneyPacks==6)
local lastMoney,lastPrice=0,0
for i,p in Config.MoneyPacks do
 assert(p.ProductId==0 and p.Money>lastMoney and p.Robux>lastPrice)
 lastMoney,lastPrice=p.Money,p.Robux
 assert(not gui.Panel.Offers['Money'..i].Buy.Active)
end
assert(lastMoney==10000000)
assert(Config.WelcomePack.Robux==9 and Config.WelcomePack.OncePerPlayer)
assert(Config.WelcomePack.Hearty==2 and Config.WelcomePack.Royal==1 and Config.WelcomePack.Revive==1)
assert(Config.DoubleMoney.Robux==249 and Config.DoubleMoney.GamePassId==0)
local count=0
for _,card in gui.Panel.Offers:GetChildren() do
 if card:IsA('Frame') then
  count+=1;assert(not card.Buy.Active)
  assert(card.Position.X.Offset>=8 and card.Position.Y.Offset>=8)
  assert(card.Position.Y.Offset+card.Size.Y.Offset<gui.Panel.Offers.CanvasSize.Y.Offset)
 end
end
assert(count==8)
assert(gui.Panel.Offers.ScrollingEnabled and gui.Panel.Offers.Active)
assert(gui.Panel.Offers.CanvasSize.Y.Offset>gui.Panel.Offers.AbsoluteSize.Y)
for _,name in {'Welcome','DoubleMoney','Money1','Money2','Money3','Money4','Money5','Money6'} do
 local card=gui.Panel.Offers[name]
 assert(card.Artwork:IsA('ImageLabel') and card.Artwork.Image=='')
end
assert(gui.Panel.Offers.Money3.Position.Y==gui.Panel.Offers.Money1.Position.Y)
assert(gui.Panel.Offers.Money4.Position.Y.Offset>gui.Panel.Offers.Money1.Position.Y.Offset)
for _,o in gui:GetDescendants() do assert(not o:IsA('LuaSourceContainer')) end
return 'PASS: six ascending capped money packs, starter rewards, pass quote, disabled eight controls, authored layout and client syntax'
'@
$body=@{jsonrpc='2.0';id=1070;method='tools/call';params=@{name='execute_luau';arguments=@{code=$code;target='edit'}}}|ConvertTo-Json -Depth 8
$response=(Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/mcp" -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body $body -TimeoutSec 30).Content
$line=$response -split "`n"|Where-Object {$_.StartsWith('data: ')}|Select-Object -First 1
$inner=(($line.Substring(6)|ConvertFrom-Json).result.content[0].text)|ConvertFrom-Json
if (!$inner.success) {throw ($inner|ConvertTo-Json -Depth 8)}
$inner.returnValue
