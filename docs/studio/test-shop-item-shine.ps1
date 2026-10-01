param([string]$Luau="$env:TEMP\FeedCriticalLuauTools\luau.exe")
$ErrorActionPreference='Stop'
$xml=[xml](Get-Content src/ui/ShopUI.rbxmx -Raw)
$offers=$xml.SelectSingleNode('//Item[Properties/string[@name="Name"]="Offers"]')
foreach($name in @('Welcome','DoubleMoney','Money1','Money2','Money3','Money4','Money5','Money6')){
 $card=$offers.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")
 $layers=$card.SelectNodes('Item[Properties/string[@name="Name"]="ItemShine"]')
 if($layers.Count -ne 1){throw "Expected one shine for $name"}
 $layer=$layers[0];$rays=$layer.SelectSingleNode('Item[Properties/string[@name="Name"]="Rays"]')
 if($layer.GetAttribute('class') -ne 'CanvasGroup' -or $layer.Properties.SelectSingleNode('*[@name="ClipsDescendants"]').InnerText -ne 'true'){throw 'Missing clipping'}
 if($rays.Properties.SelectSingleNode('Content/uri').InnerText -ne 'rbxassetid://119106720608654'){throw 'Wrong asset'}
 $z=[int]$layer.Properties.SelectSingleNode('*[@name="ZIndex"]').InnerText
 foreach($child in $card.SelectNodes('Item[Properties/string[@name="Name"]="Artwork" or Properties/string[@name="Name"]="Title" or Properties/string[@name="Name"]="Buy"]')){
  if([int]$child.Properties.SelectSingleNode('*[@name="ZIndex"]').InnerText -le $z){throw "Foreground covered: $name"}
 }
}
$source=Get-Content src/client/UI/ShopShine.luau -Raw
$prefix=@'
local tweens={}
local function signal()
 local s={callbacks={}}
 function s:Connect(fn)
  local c={active=true};function c:Disconnect()self.active=false end
  table.insert(self.callbacks,{fn=fn,c=c});return c
 end
 function s:Fire() for _,e in self.callbacks do if e.c.active then e.fn() end end end
 return s
end
local function object(fields)
 fields=fields or {};fields.signals={}
 function fields:GetPropertyChangedSignal(key)self.signals[key]=self.signals[key] or signal();return self.signals[key]end
 function fields:FindFirstChild(key)return self[key]end
 return fields
end
local TweenService={Create=function(_,target,info,goal)
 assert(info.seconds==24 and info.repeats==-1 and goal.Rotation==360)
 local t={target=target};function t:Play()self.state='playing'end;function t:Pause()self.state='paused'end;function t:Cancel()self.state='cancelled'end
 table.insert(tweens,t);return t
end}
local game={GetService=function()return TweenService end,ReplicatedStorage={Shared={Config={MonetizationImages={}}}}}
local function require()return {ShopShine='rbxassetid://119106720608654'}end
local Enum={EasingStyle={Linear=1},EasingDirection={InOut=1}}
local TweenInfo={new=function(seconds,_,_,repeats)return {seconds=seconds,repeats=repeats}end}
local UDim2={fromScale=function(x,y)return {X=x,Y=y}end}
'@
$tests=@'
local cards={}
for i=1,8 do
 cards[i]=object({Visible=true,AbsoluteSize={X=0,Y=0},Artwork=object(),ItemShine=object({Rays={Rotation=0}})})
end
local panel=object({Visible=false,Offers={GetChildren=function()return cards end}})
local gui=object({Enabled=true,Panel=panel,Destroying=signal()})
Shine.Bind(gui);Shine.Bind(gui);assert(#tweens==8,'Duplicate bindings')
for _,t in tweens do assert(t.state=='paused' and t.target.Image=='rbxassetid://119106720608654')end
panel.Visible=true;panel.signals.Visible:Fire();for _,t in tweens do assert(t.state=='playing')end
gui.Enabled=false;gui.signals.Enabled:Fire();for _,t in tweens do assert(t.state=='paused')end
gui.Enabled=true;gui.signals.Enabled:Fire()
cards[1].Visible=false;cards[1].signals.Visible:Fire();assert(tweens[1].state=='paused' and tweens[2].state=='playing')
gui.Destroying:Fire();for _,t in tweens do assert(t.state=='cancelled')end
print('PASS: eight layered/clipped assets; repeat rotation, duplicate guard, show/hide pause/resume and cleanup (mocked)')
'@
$bundle="$prefix`nlocal Shine=(function()`n$source`nend)()`n$tests"
[IO.File]::WriteAllText((Join-Path (Resolve-Path build) 'test-shop-shine.luau'),$bundle,[Text.UTF8Encoding]::new($false))
& $Luau build/test-shop-shine.luau
if($LASTEXITCODE -ne 0){throw 'Shine lifecycle test failed'}
