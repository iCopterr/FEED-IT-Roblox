local source=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("GrowNowController",true)
assert(source,"GrowNowController missing")
local callback,connections,calls=nil,0,{}
local remote={OnClientEvent={Connect=function(_,fn) callback=fn;connections+=1 end}}
local env=setmetatable({
 game={ReplicatedStorage={WaitForChild=function(_,name)assert(name=="GrowNowOffer");return remote end}},
 require=function()return {Request=function(kind,id)table.insert(calls,{kind,id})end}end,
 script=source,
},{__index=getfenv()})
local fn=assert(loadstring(source.Source));setfenv(fn,env)
local controller=fn()
controller.Start();controller.Start();assert(connections==1)
for _,invalid in {false,"bad",{}, {Code="Other",EggUid="egg"},{Code="GrowNowUnavailable",EggUid=""}} do callback(invalid) end
assert(#calls==0)
callback({Code="GrowNowUnavailable",EggUid="egg-one",Robux=29})
assert(#calls==1 and calls[1][1]=="Grow" and calls[1][2]=="egg-one")
local gui=game.StarterGui.PenManagerUI
assert(not gui.GrowNow.Visible)
assert(gui.Panel.GrowAll.ButtonText.Text=="GROW ALL")
assert(gui.Panel.GrowAll.ButtonTextShadow.Text=="GROW ALL")
assert(gui.Panel.GrowAll.ProductIcon.Visible and gui.Panel.GrowAll.ProductIcon.Image=="rbxassetid://112103082378017")
local pen=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("PenManagerController",true)
assert(loadstring(pen.Source))
assert(not pen.Source:find('GROW ALL •',1,true))
print("PASS: valid grow offer requests native checkout directly; malformed offers ignored; one listener; Grow All text and picture; no price label.")
