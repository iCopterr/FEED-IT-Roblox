-- Run via MCP execute_luau in idle Edit mode. Executes the actual service source
-- with isolated profile/clock/saver dependencies; never touches live saves.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local services=game.ServerScriptService.Server.Services
local Schema=require(services.Parent.Data.PlayerDataSchema)
local Config=require(game.ReplicatedStorage.Shared.Config.MerchantConfig)
local checks={}
local function check(ok,label) assert(ok,label);table.insert(checks,label) end
for _,wanted in {"revive","blessed"} do
	local restock,slot
	for n=1,100000 do
		local found=table.find(Config.GetStock(n),wanted)
		if found then restock,slot=n,found;break end
	end
	assert(restock,"Rare stock not found")
	local profile=Schema.CreateDefault();profile.Settings={};profile.Money=20000000
	local players={};local point=workspace.MysteryMerchant.InteractionPoint
	local character={FindFirstChildOfClass=function() return {Health=100} end,
		FindFirstChild=function() return {Position=point.Position} end}
	local player={Parent=players,Character=character}
	local locked=false;local saves=0;local rejectMutation=false
	local pending={}
	local fakeData={GetData=function() return profile end,Save=function() saves+=1;return true end}
	local fakeLocks={IsLocked=function() return locked end,
		Begin=function() if locked then return false end;locked=true;return true end,
		Finish=function() locked=false end}
	local fakeSchema={Validate=function(data)
		if rejectMutation and data.Money<20000000 then return false end
		return Schema.Validate(data)
	end}
	local clock=100
	local fakeOs=table.clone(os);fakeOs.time=function() return restock*Config.RestockSeconds end
	fakeOs.clock=function() clock+=1;return clock end
	local env=setmetatable({script=services.MerchantService,os=fakeOs,
		game={ReplicatedStorage=game.ReplicatedStorage,GetService=function(_,name)
			assert(name=="Players");return players
		end},
		task={spawn=function(fn) table.insert(pending,fn) end,wait=function() error("Unexpected save retry") end},
		require=function(module)
			if module==services.DataService then return fakeData end
			if module==services.FeedLocks then return fakeLocks end
			if module==services.Parent.Data.PlayerDataSchema then return fakeSchema end
			return require(module)
		end}, {__index=getfenv()})
	local source=assert(loadstring(services.MerchantService.Source))
	setfenv(source,env)
	local service=source()
	local function quantity() return if wanted=="revive" then profile.ReviveCharges else profile.Foods.blessed or 0 end
	profile.Money=0
	check(service.HandleRequest(player,"Purchase",slot,restock,1).Code=="NotEnoughMoney" and quantity()==0,wanted..": affordability enforced")
	profile.Money=20000000;rejectMutation=true
	check(service.HandleRequest(player,"Purchase",slot,restock,1).Code=="InvalidData"
		and quantity()==0 and profile.Money==20000000 and not locked,wanted..": validation rollback restores item, Money and lock")
	rejectMutation=false
	local result=service.HandleRequest(player,"Purchase",slot,restock,1)
	check(result.Ok and result.Amount==1 and quantity()==1 and profile.Money==20000000-Config.Items[wanted].Price,wanted..": correct one-item grant and charge")
	check(locked and #pending==1,wanted..": purchase remains locked until saved")
	check(service.HandleRequest(player,"Purchase",slot,restock,1).Ok and quantity()==1 and #pending==1,wanted..": retry cannot double grant/save")
	pending[1]()
	check(not locked and saves==1,wanted..": confirmed save releases lock")
	check(service.HandleRequest(player,"Purchase",slot,restock,2).Code=="Sold" and quantity()==1,wanted..": one purchase per stock")
	local snapshot=service.HandleRequest(player,"Snapshot")
	check(snapshot.Items[slot].Owned==1 and snapshot.Items[slot].Purchased,wanted..": snapshot owns one and shows sold out")
	check(Schema.Validate(Schema.Migrate(profile)),wanted..": saved profile round-trip validates")
end
print(game:GetService("HttpService"):JSONEncode({passed=true,checks=checks}))
