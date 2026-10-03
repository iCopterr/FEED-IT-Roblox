assert(not game:GetService("RunService"):IsRunning())
local ui=game.StarterPlayer.StarterPlayerScripts.Client.UI
local source=ui.HatchingEggs:Clone();local state=require(source).new();source:Destroy()
local event={Ok=true,Code="HatchStarted",EggUid="ready-egg",EndsAt=110,Reward={CollectEndsAt=115}}
assert(not state:Hidden("ready-egg",100))
assert(state:Started({Ok=false,Code="NotReady",EggUid="ready-egg"},100)==nil)
assert(not state:Hidden("ready-egg",100),"Rejected hatch must not hide egg")
assert(state:Started(event,100)=="ready-egg" and state:Hidden("ready-egg",100),"Hide at animation start")
state:Reconcile({{EggUid="ready-egg"},{EggUid="other"}},103)
assert(state:Hidden("ready-egg",103) and not state:Hidden("other",103),"Polling must not resurrect hatching row")
assert(state:Hidden("ready-egg",115),"Keep hidden through reward collection")
state:Failed("ready-egg");assert(not state:Hidden("ready-egg",115),"Failure must allow retry")
state:Started(event,100);state:Reconcile({},116);assert(not state:Hidden("ready-egg",116),"Clean up completed IDs")
state:Started(event,100);assert(not state:Hidden("ready-egg",126),"Missing reply must eventually recover")
local layoutSource=ui.DeviceLayout:Clone();local layout=require(layoutSource);layoutSource:Destroy()
for _,size in {Vector2.new(568,320),Vector2.new(844,390),Vector2.new(390,844),Vector2.new(1368,630),Vector2.new(1920,1080)} do
	local old=if size.X<900 then math.min(layout.Fit(size,510,440),(size.X-32)/510) else math.min(.82,math.max(.45,math.min(size.X*.23/510,size.Y*.34/440)),(size.X-32)/510,(size.Y-40)/440)
	local scale=layout.RemotePanelScale(size,true)
	assert(scale<=old*.8+.00001,"Remote must be at least 20% smaller")
	assert(510*scale<size.X-24 and 440*scale+2*layout.MenuLift(size,true)<=size.Y-24,"Remote exceeds mobile bounds")
end
return "PASS: start hides only selected egg, stale snapshots stay hidden, failure/timeout restore, completion cleans up; smaller remote fits five viewports"
