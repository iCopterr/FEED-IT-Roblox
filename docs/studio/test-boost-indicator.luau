-- Headless regression through test-broken-pet-local.ps1 -TestPath this file.
local client=game.StarterPlayer.StarterPlayerScripts.Client
local layout=assert(loadstring(client.UI.DeviceLayout.Source))()
local imagesModule=game.ReplicatedStorage.Shared.Config.MonetizationImages
local images=assert(loadstring(imagesModule.Source))()
local function signal()
	local callbacks={}
	return {Connect=function(_,fn)
		local c={};callbacks[c]=fn
		function c:Disconnect()callbacks[self]=nil end
		return c
	end,Fire=function(...)for _,fn in table.clone(callbacks) do fn(...)end end}
end
local attributes={}
local changes={DoubleMoneyOwned=signal(),PaidRandomPolicyStatus=signal()}
local player={GetAttribute=function(_,k)return attributes[k]end,
	GetAttributeChangedSignal=function(_,k)return changes[k]end}
local touchChanged=signal()
local input={TouchEnabled=false,GetPropertyChangedSignal=function()return touchChanged end}
local sizeChanged=signal()
local badge={Icon={},UIScale={}}
local gui={MoneyBoost=badge,AbsoluteSize={X=1920,Y=1080},AbsolutePosition={X=0,Y=0},Destroying=signal(),
	GetPropertyChangedSignal=function()return sizeChanged end}
local added=signal()
local pg={DescendantAdded=added,GetDescendants=function()return {}end}
player.WaitForChild=function()return pg end
local bootstrapCalls=0
local deps={
	[imagesModule]=images,[client.UI.DeviceLayout]=layout,
	[client.UI.GuiBootstrap]={Wait=function()bootstrapCalls+=1;return gui end},
}
local fn=assert(loadstring(client.Controllers.BoostController.Source))
setfenv(fn,setmetatable({script=client.Controllers.BoostController,require=function(m)return assert(deps[m])end,
	UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}}end},
	game={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
		if name=="Players" then return {LocalPlayer=player} elseif name=="UserInputService" then return input
		elseif name=="StarterGui" then return {} end;error(name)
	end},
},{__index=getfenv()}))
local controller=fn()
assert(controller.Start()==gui);controller.Start();assert(bootstrapCalls==1)
assert(not badge.Visible and badge.Icon.Image==images.DoubleMoney)
local function set(k,v)attributes[k]=v;changes[k].Fire()end
set("DoubleMoneyOwned",true);assert(not badge.Visible,"Unknown policy showed boost")
set("PaidRandomPolicyStatus","Allowed");assert(badge.Visible,"Late ownership/eligibility failed")
for _,status in {"Restricted","Loading","Unavailable"} do set("PaidRandomPolicyStatus",status);assert(not badge.Visible)end
set("PaidRandomPolicyStatus","Allowed");set("DoubleMoneyOwned",false);assert(not badge.Visible)
set("DoubleMoneyOwned",true);assert(badge.Visible,"Purchase did not reveal boost")
assert(badge.Position.X.Scale==1 and badge.Position.Y.Scale==1 and badge.Position.X.Offset==-18)
input.TouchEnabled=true;touchChanged.Fire();assert(badge.UIScale.Scale==.8 and badge.Position.X.Offset==-144)
gui.AbsoluteSize={X=844,Y=390};sizeChanged.Fire()
local jump={Name="JumpButton",Parent=true,Visible=true,AbsolutePosition={X=748,Y=304},AbsoluteSize={X=74,Y=74},
	IsA=function()return true end,GetPropertyChangedSignal=function()return signal()end}
added.Fire(jump)
local right=-badge.Position.X.Offset
assert(gui.AbsoluteSize.X-right<=jump.AbsolutePosition.X-10,"Badge covers jump button")
for _,size in {{X=390,Y=844},{X=844,Y=390},{X=1368,Y=630},{X=2736,Y=1260}} do
	local j={X=size.X-102,Y=size.Y-90,Width=82,Height=72}
	local scale,r,b=layout.BoostBadge(size,true,j)
	assert(size.X-r-86*scale>=0 and size.Y-b-78*scale>=0,"Badge offscreen")
	assert(size.X-r<=j.X-10,"Mobile jump overlap")
end
gui.Destroying.Fire();set("DoubleMoneyOwned",false)
assert(badge.Visible,"Destroyed GUI still received attribute callbacks")
print("PASS: boost hidden until active, purchase/ownership/policy updates, idempotent startup, cleanup, bottom-right desktop and touch-jump clearance")
