-- Presentation-only filter. Never removes a saved egg or grants a pet.
local HatchingEggs={}
function HatchingEggs.new()
	local pending={}
	return {
		Started=function(_,payload,now)
			if type(payload)~="table" or payload.Code~="HatchStarted" or payload.Ok~=true
				or type(payload.EggUid)~="string" or type(payload.EndsAt)~="number" then return nil end
			local reward=payload.Reward
			local untilAt=if type(reward)=="table" and type(reward.CollectEndsAt)=="number" then reward.CollectEndsAt else payload.EndsAt
			pending[payload.EggUid]=math.max(now,untilAt)+10
			return payload.EggUid
		end,
		Hidden=function(_,id,now)
			if pending[id] and pending[id]<=now then pending[id]=nil end
			return pending[id]~=nil
		end,
		Failed=function(_,id) pending[id]=nil end,
		Reconcile=function(_,eggs,now)
			local present={}
			for _,egg in eggs do present[egg.EggUid]=true end
			for id,expires in pending do
				if not present[id] or expires<=now then pending[id]=nil end
			end
		end,
	}
end
return HatchingEggs
