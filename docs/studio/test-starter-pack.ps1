param([string]$Luau="$env:TEMP\FeedCriticalLuauTools\luau.exe")
$ErrorActionPreference='Stop'
$x=[xml](Get-Content src/ui/StarterPackUI.rbxmx -Raw)
function Child($node,$name){$node.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")}
$gui=$x.roblox.Item;$panel=Child $gui 'Panel';$offers=Child $panel 'Offers';$card=Child $offers 'Welcome'
if($gui.Properties.SelectSingleNode('string[@name="Name"]').InnerText -ne 'StarterPackUI'){throw 'Wrong ScreenGui'}
if($panel.Properties.SelectSingleNode('bool[@name="Visible"]').InnerText -ne 'false'){throw 'Modal starts open'}
if((Child $gui 'Open') -or (Child $offers 'DoubleMoney') -or !$card -or !(Child $panel 'Close')){throw 'Not a standalone offer'}
if($card.SelectNodes('Item[Properties/string[@name="Name"]="Artwork"]').Count -ne 1){throw 'Duplicate artwork'}
if(!(Child $card 'ItemShine')){throw 'Missing shine'}
if((Child $card 'Buy').Properties.SelectSingleNode('bool[@name="Active"]').InnerText -ne 'true'){throw 'Buy button disabled in authored asset'}
if((Child $card 'Artwork').Properties.SelectSingleNode('Content[@name="ImageContent"]/uri').InnerText -ne 'rbxassetid://73142330309053'){throw 'Wrong pack image'}
$config=Get-Content default.project.json -Raw | ConvertFrom-Json
if($config.tree.StarterGui.StarterPackUI.'$path' -ne 'src/ui/StarterPackUI.rbxmx'){throw 'Missing Rojo mapping'}
& $Luau docs/studio/test-starter-pack.luau
if($LASTEXITCODE -ne 0){throw 'Gate tests failed'}
# Mock only Roblox interfaces; execute the actual production controller below.
$prefix=@'
local now, purchases, closed, binds = 0, 0, 0, 0
local os = {clock = function() return now end}
local function signal()
 local s = {callbacks={}}
 function s:Connect(fn)
  local c={live=true};function c:Disconnect() self.live=false end
  table.insert(self.callbacks,{fn=fn,c=c});return c
 end
 function s:Fire(...)
  for _,entry in self.callbacks do if entry.c.live then entry.fn(...) end end
 end
 return s
end
local function node(fields)
 fields=fields or {};fields.signals={};fields.attributes={};fields.Parent=true
 function fields:GetPropertyChangedSignal(key)
  self.signals[key]=self.signals[key] or signal();return self.signals[key]
 end
 function fields:GetAttributeChangedSignal(key) return self:GetPropertyChangedSignal(key) end
 function fields:GetAttribute(key) return self.attributes[key] end
 function fields:SetAttribute(key,value) self.attributes[key]=value;self:GetPropertyChangedSignal(key):Fire() end
 function fields:WaitForChild(key) return self[key] end
 function fields:FindFirstChild(key) return self[key] end
 function fields:IsA(key) return key=='GuiObject' or key=='Frame' end
 function fields:GetChildren() return self.children or {} end
 return fields
end
local buy=node({Activated=signal(),ButtonText={},Active=false,Interactable=false})
local close=node({Activated=signal()})
local panel=node({Visible=false,UIScale={},Close=close,Offers={Welcome={Artwork={},Description={},Buy=buy}}})
local gui=node({Name='StarterPackUI',Panel=panel,Enabled=true,AbsoluteSize={X=1000,Y=650},Destroying=signal()})
local shopPanel=node({Visible=false})
local shop=node({Name='ShopUI',Panel=shopPanel})
local pg=node({StarterPackUI=gui,ChildAdded=signal(),children={gui,shop}})
local player=node({PlayerGui=pg,Character={FindFirstChildOfClass=function() return {Health=100} end}})
player.attributes={TutorialStep='Feed',WelcomePackOwned=false,FeedBusy=true,PaidRandomPolicyStatus='Allowed'}
local heartbeat=signal();local input=signal()
local services={Players={LocalPlayer=player},RunService={Heartbeat=heartbeat},UserInputService={InputBegan=input}}
local Enum={KeyCode={Escape='Escape'}}
local motion={BindPopup=function() end,BindButton=function() end,Close=function(p) closed+=1;p.Visible=false end}
local config={MonetizationConfig={WelcomePack={Robux=9,ProductId=3715613361,Hearty=2,Royal=1,Revive=1}},TutorialConfig={Completed='Done'},MonetizationImages={WelcomePack='testImage'}}
local game={ReplicatedStorage={Shared={Config=config}},GetService=function(_,name) return services[name] end}
local realRequire=require
local gate=realRequire('../src/client/UI/StarterPackOffer')
local policyView={Apply=function(card,price,status,owned,ongoing,prefix)
 local enabled=status=='Allowed' and not owned
 card.Buy.Active=enabled;card.Buy.Interactable=enabled;card.Buy.AutoButtonColor=enabled
 card.Buy.ButtonText.Text=if owned then 'OWNED' elseif enabled then (prefix or '')..price..' ROBUX' else 'UNAVAILABLE'
 return enabled
end}
local script={Parent={Parent={UI={StarterPackOffer=gate,Motion=motion,
 GuiBootstrap={Wait=function(_,_,name) assert(name=='StarterPackUI');return gui end},
 DeviceLayout={Apply=function(p,size,kind) assert(kind=='StarterPack');p.UIScale.Scale=math.min(1,(size.X-24)/(if size.X<700 and size.Y>size.X then 460 else 760),(size.Y-24)/484) end},
 Purchases={Request=function(kind,id) assert(kind=='Product' and id==3715613361);purchases+=1 end},
 PolicyOfferView=policyView,ShopShine={Bind=function(g) assert(g==gui);binds+=1 end}}}}}
local require=function(value) return value end
local Controller=(function()
'@
$suffix=@'
end)()
Controller.Start();Controller.Start()
assert(binds==1 and purchases==0 and not panel.Visible)
assert(buy.Active and buy.Interactable and buy.AutoButtonColor,'Controller must enable an exported disabled Buy button')
assert(buy.ButtonText.Text=='BUY • 9 ROBUX' and buy:GetAttribute('SuppressClickSound'))
assert(panel.Offers.Welcome.Description.Text=='2 Hearty Food + 1 Royal Food\n1 Revive Charm\nOnce per player')
assert(panel.Offers.Welcome.Artwork.Image=='testImage')
player:SetAttribute('TutorialStep','Done');now=3;heartbeat:Fire(.2)
assert(not panel.Visible and purchases==0,'Must finish animation before offering')
shopPanel.Visible=true
player:SetAttribute('FeedBusy',nil);heartbeat:Fire(.2)
assert(panel.Visible and not shopPanel.Visible and purchases==0,'Offer opens, NOT Shop or native checkout')
buy.Activated:Fire();assert(purchases==1 and panel.Visible,'Only Buy opens checkout; cancel can retry')
buy.Activated:Fire();assert(purchases==2)
player:SetAttribute('WelcomePackOwned',true);assert(not panel.Visible,'Receipt closes offer')
assert(not buy.Active and not buy.Interactable,'Owned pack cannot be purchased again')
buy.Activated:Fire();assert(purchases==2,'Do not prompt owned pack')
player:SetAttribute('WelcomePackOwned',false);heartbeat:Fire(.2);assert(not panel.Visible,'Cannot reopen automatically')
assert(buy.Active and buy.Interactable)
player:SetAttribute('WelcomePackOwned',nil);assert(not buy.Active and not buy.Interactable,'Wait for ownership')
player:SetAttribute('WelcomePackOwned',false);assert(buy.Active and buy.Interactable,'Late ownership enables Buy')
panel.Visible=true;player:SetAttribute('PaidRandomPolicyStatus','Restricted')
assert(not panel.Visible and not buy.Active and not buy.Interactable,'Restricted account closes and disables Starter Pack')
player:SetAttribute('PaidRandomPolicyStatus','Allowed');assert(buy.Active and buy.Interactable,'Allowed policy restores Starter Pack button')
panel.Visible=true;close.Activated:Fire();assert(closed==1 and not panel.Visible)
panel.Visible=true;input:Fire({KeyCode='Escape'},false);assert(closed==2 and not panel.Visible)
panel.Visible=true;shopPanel.Visible=true;shopPanel:GetPropertyChangedSignal('Visible'):Fire();assert(not panel.Visible)
gui.AbsoluteSize={X=390,Y=844};gui:GetPropertyChangedSignal('AbsoluteSize'):Fire()
assert(math.abs(panel.UIScale.Scale-366/460)<.001,'Responsive portrait layout')
gui.Destroying:Fire()
for _,entry in heartbeat.callbacks do assert(not entry.c.live) end
print('PASS: controller tutorial -> final feed -> independent offer -> purchase -> owned, close, escape, other menu, resize, cleanup')
'@
# These writes only assemble a generated disposable test harness (not source edits).
$source=Get-Content src/client/Controllers/StarterPackController.luau -Raw
$target=Join-Path (Get-Location) 'build/test-starter-pack.generated.luau'
[void][IO.Directory]::CreateDirectory((Split-Path $target))
[IO.File]::WriteAllText($target,$prefix+"`n"+$source+"`n"+$suffix,[Text.UTF8Encoding]::new($false))
& $Luau $target
if($LASTEXITCODE -ne 0){throw 'Controller tests failed'}
'PASS: standalone authored UI and Rojo mapping'
