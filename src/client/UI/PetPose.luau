-- Solve anchored visual rigs locally. Never move the authoritative primary root.
local Pose={}
function Pose.Bind(model,profile)
	local root=model.PrimaryPart
	if not root then return nil end
	local links,rest,parts={},{},{}
	for _,o in model:GetDescendants() do
		if o:IsA("BasePart") then parts[o]=true;rest[o]=root.CFrame:ToObjectSpace(o.CFrame) end
	end
	local function link(a,b,c0,c1,name)
		if parts[a] and parts[b] and b~=root then
			links[#links+1]={A=a,B=b,C0=c0,C1=c1,Name=name}
		end
	end
	for _,o in model:GetDescendants() do
		if o:IsA("Motor6D") then link(o.Part0,o.Part1,o.C0,o.C1,o.Name)
		elseif o:IsA("WeldConstraint") and o.Part0 and o.Part1 then
			link(o.Part0,o.Part1,o.Part0.CFrame:ToObjectSpace(o.Part1.CFrame),CFrame.identity,"")
		end
	end
	-- Topological ordering keeps decorative welded pieces attached to posed limbs.
	local ordered,known={}, {[root]=true}
	for _=1,#links do
		local progress=false
		for i=#links,1,-1 do
			local l=links[i]
			if known[l.A] then ordered[#ordered+1]=l;known[l.B]=true;table.remove(links,i);progress=true end
		end
		if not progress then break end
	end
	return {Model=model,Root=root,Links=ordered,Rest=rest,Profile=profile}
end
function Pose.Offset(name,t,walk,p)
	local n=string.lower(name)
	local phase=t*p.Pace*math.pi*2
	local slow=math.sin(t*1.6)
	local side=if n:find("right") then -1 else 1
	local index=tonumber(n:match("(%d+)$")) or 0
	if n:find("leg") or n:find("arm") then
		local sign=side*(if n:find("hind") then -1 else 1)
		-- Heavenly Kirin's authored rig encodes side/fore-hind in numeric names.
		if n:find("leg%-") then sign=-1 end
		if n:find("leg") and n:find("1.65",1,true) then sign=-sign end
		if p.Kind=="Hop" then sign=if n:find("hind") then -1 else 1 end
		return CFrame.Angles(math.sin(phase)*p.Stride*walk*sign,0,0)
	elseif n:find("wing") or n:find("fin") then
		return CFrame.Angles(0,0,side*(slow*.025+math.sin(phase+index*.7)*walk*.13))
	elseif n:find("tentacle") then
		return CFrame.Angles(math.sin(phase+index*.8)*(.025+walk*.12),0,math.cos(phase+index)*(.025+walk*.08))
	elseif n:find("tail") then
		return CFrame.Angles(0,math.sin(t*2.1+index*.5)*(.05+walk*.10),0)
	elseif n:find("head") or n:find("skull") or n:find("neck") then
		return CFrame.Angles(slow*.025+math.sin(phase)*walk*.035,math.sin(t*.9+index)*.025,0)
	elseif n:find("ear") then
		return CFrame.Angles(math.sin(t*2.3)*.035,0,0)
	elseif name=="RootJoint" then
		return CFrame.Angles(0,if p.Kind=="Serpent" or p.Kind=="Swimmer" then math.sin(phase)*walk*.06 else 0,math.sin(phase)*walk*.018)
	end
	return CFrame.identity
end
function Pose.Step(state,t,walk)
	local root=state.Root
	if not root.Parent then return end
	for _,l in state.Links do
		if l.A.Parent and l.B.Parent then
			l.B.CFrame=l.A.CFrame*l.C0*Pose.Offset(l.Name,t,walk,state.Profile)*l.C1:Inverse()
		end
	end
end
function Pose.Reset(state)
	if not state.Root.Parent then return end
	for part,offset in state.Rest do if part.Parent then part.CFrame=state.Root.CFrame*offset end end
end
return Pose
