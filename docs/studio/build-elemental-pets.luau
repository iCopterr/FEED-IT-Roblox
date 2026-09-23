-- Editor-only art batch. Uses existing authored griffin/drake rigs as variant bases.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local anchor=assert(workspace:FindFirstChild("EmberDrake_RigTest"),"Ember drake missing")
local griffinBase=assert(workspace:FindFirstChild("BabyGriffin_RigTest"),"Baby griffin missing")
local names={"StormGriffin_RigTest","LavaGolem_RigTest","ThunderSerpent_RigTest","IceDragon_Roster"}
for _,n in names do assert(not workspace:FindFirstChild(n),n.." already exists") end
local V,CF=Vector3.new,CFrame.new
local coal=Color3.fromRGB(38,33,37)
local rock=Color3.fromRGB(69,57,58)
local lava=Color3.fromRGB(255,99,23)
local gold=Color3.fromRGB(255,213,88)
local navy=Color3.fromRGB(29,45,77)
local blue=Color3.fromRGB(61,91,136)
local sky=Color3.fromRGB(135,209,242)
local white=Color3.fromRGB(232,249,255)
local violet=Color3.fromRGB(114,87,174)
local function part(m,n,size,cf,color,class,glow)
    local p=Instance.new(class or "Part")
    p.Name,p.Size,p.CFrame,p.Color=n,size,cf,color
    p.Material=glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Anchored,p.CanCollide,p.Massless=true,false,true
    p.Parent=m
    return p
end
local function detail(m,n,size,cf,color,limb,class,glow)
    local p=part(m,n,size,cf,color,class,glow)
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local function beam(m,n,a,b,width,color,limb,glow)
    return detail(m,n,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,limb,nil,glow)
end
local function motor(n,a,b,at)
    local j=Instance.new("Motor6D")
    j.Name,j.Part0,j.Part1=n,a,b
    j.C0,j.C1=a.CFrame:ToObjectSpace(CF(at)),b.CFrame:ToObjectSpace(CF(at))
    j.Parent=a
end
local function rig(n,size,pos,color)
    local m=Instance.new("Model")
    m.Name=n
    local t=part(m,"Torso",size,CF(pos),color)
    t.CanCollide,t.Massless=true,false
    local r=part(m,"HumanoidRootPart",size,t.CFrame,color)
    r.Transparency,r.RootPriority,r.Massless=1,127,false
    m.PrimaryPart=r
    motor("RootJoint",r,t,pos)
    local h=Instance.new("Humanoid")
    h.RigType=Enum.HumanoidRigType.R15
    h.RequiresNeck,h.BreakJointsOnDeath=false,false
    h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    h.Parent=m
    Instance.new("Animator",h)
    return m,t
end
local function limb(m,n,size,cf,color,at,class)
    local p=part(m,n,size,cf,color,class)
    motor("TorsoTo"..n,m.Torso,p,at)
    return p
end
local function cloneBase(source,n,origin)
    local m=source:Clone()
    m.Name=n
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true end end
    m:PivotTo(CF(origin))
    return m
end
-- Storm griffin: broad layered feathers, silver head, dark body, electric accents.
local storm=cloneBase(griffinBase,names[1],V(0,1.58,.27))
for _,p in storm:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
    local n=p.Name
    if n:find("Eye") and not n:find("Glint") then p.Color=gold
    elseif n:find("Beak") or n:find("Talon") then p.Color=Color3.fromRGB(187,153,77)
    elseif n:find("Feather") or n:find("WingCover") then p.Color=n:find("Cover") and blue or sky
    elseif n=="Head" or n:find("Chest") or n:find("Crest") then p.Color=white
    elseif n:find("Glint") then p.Color=white
    else p.Color=navy end
end end
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    local w=storm[side.."Wing"]
    for i=1,5 do
        detail(storm,side.."StormPrimary"..i,V(.42,.17,1.7+(6-i)*.15),CF(s*(2.0+i*.22),2.67+i*.13,.75+i*.16)*CFrame.Angles(math.rad(-14),s*math.rad(35),0),i%2==0 and blue or sky,w,"WedgePart")
    end
    local pts={V(s*1.25,2.7,.05),V(s*1.93,3.01,.44),V(s*1.8,3.04,.8),V(s*2.72,3.27,1.14)}
    for i=1,3 do beam(storm,side.."Lightning"..i,pts[i],pts[i+1],.055,gold,w,true) end
    detail(storm,side.."StormCrown",V(.22,.9,.37),CF(s*.42,3.9,-.67)*CFrame.Angles(math.rad(-28),0,-s*.14),sky,storm.Head,"WedgePart")
end
storm:ScaleTo(1.28)
-- Lava golem: broad shoulders, floating-looking but welded armor over a hot core.
local golem,t=rig(names[2],V(2.6,2.7,1.8),V(0,3.0,0),coal)
detail(golem,"MoltenCore",V(1.38,1.42,.14),CF(0,3.25,-.97),lava,t,nil,true)
detail(golem,"CoreHeart",V(.56,.67,.15),CF(0,3.27,-1.07)*CFrame.Angles(0,0,math.rad(45)),gold,t,nil,true)
for _,s in {-1,1} do
    detail(golem,"ChestArmor"..s,V(.8,1.55,.46),CF(s*.94,3.47,-.89)*CFrame.Angles(0,0,s*.15),rock,t,"WedgePart")
    local arm=limb(golem,(s==-1 and "Left" or "Right").."Arm",V(1.04,2.04,1.1),CF(s*1.88,2.91,0),coal,V(s*1.27,3.95,0))
    detail(golem,"ShoulderBoulder"..s,V(1.7,1.28,1.66),CF(s*1.78,4.06,0)*CFrame.Angles(0,0,s*.2),rock,arm)
    detail(golem,"Fist"..s,V(1.31,1.0,1.43),CF(s*1.97,1.65,-.13),rock,arm)
    detail(golem,"ElbowHeat"..s,V(1.08,.18,1.12),CF(s*1.88,2.55,0),lava,arm,nil,true)
    for i=1,3 do detail(golem,"Knuckle"..s..i,V(.29,.33,.18),CF(s*1.97+(i-2)*.37,1.68,-.9),coal,arm) end
    detail(golem,"ShoulderSpire"..s,V(.65,1.05,.85),CF(s*2.17,4.96,.12)*CFrame.Angles(0,0,-s*.25),coal,arm,"WedgePart")
    local leg=limb(golem,(s==-1 and "Left" or "Right").."Leg",V(.91,1.6,1.09),CF(s*.75,1.2,0),coal,V(s*.75,1.95,0))
    detail(golem,"KneePlate"..s,V(1.07,.71,.39),CF(s*.75,1.35,-.57),rock,leg)
    detail(golem,"AnkleHeat"..s,V(.93,.16,1.12),CF(s*.75,.59,0),lava,leg,nil,true)
    detail(golem,"Foot"..s,V(1.21,.53,1.67),CF(s*.77,.33,-.25),rock,leg)
end
local gh=limb(golem,"Head",V(1.55,1.3,1.32),CF(0,4.89,-.08),rock,V(0,4.34,0))
detail(golem,"Brow",V(1.7,.3,.55),CF(0,5.22,-.64),coal,gh,"WedgePart")
for _,s in {-1,1} do detail(golem,"Eye"..s,V(.39,.17,.06),CF(s*.41,4.97,-.77),gold,gh,nil,true) end
detail(golem,"Mouth",V(.64,.11,.04),CF(0,4.55,-.76),lava,gh,nil,true)
for i=1,3 do detail(golem,"Abdomen"..i,V(1.67,.32,.34),CF(0,2.63-i*.3,-.94),rock,t) end
-- Thunder serpent: upright cobra-like neck, sweeping coil and lightning fins.
local serpent,st=rig(names[3],V(1.5,1.8,1.6),V(0,2.0,0),navy)
local coils={V(0,1.4,.4),V(1.6,.78,1.2),V(2.2,.68,2.8),V(.8,.63,3.8),V(-1.0,.59,3.3),V(-1.8,.55,1.8),V(-2.4,.53,.6)}
local tail=limb(serpent,"Tail",V(.8,.8,1.3),CF(0,1.15,.95),navy,V(0,1.6,.5))
for i=1,#coils-1 do
    local width=1.15-(i-1)*.13
    beam(serpent,"Coil"..i,coils[i],coils[i+1],width,i%2==0 and blue or navy,tail)
    local a,b=coils[i]+V(0,width*.51,0),coils[i+1]+V(0,width*.51,0)
    beam(serpent,"CoilSpark"..i,a,b,.065,gold,tail,true)
end
local sh=limb(serpent,"Head",V(1.5,1.1,1.55),CF(0,4.78,-.95),blue,V(0,2.78,-.15))
beam(serpent,"Neck",V(0,2.35,-.15),V(0,4.53,-.75),1.07,navy,sh)
detail(serpent,"Muzzle",V(1.19,.48,.97),CF(0,4.55,-2.03),navy,sh)
detail(serpent,"LowerJaw",V(1.05,.19,.82),CF(0,4.16,-1.98),violet,sh)
for i=1,5 do detail(serpent,"NeckBelly"..i,V(.67,.26,.17),CF(0,2.65+i*.35,-.75-i*.075),gold,sh) end
for _,s in {-1,1} do
    detail(serpent,"Eye"..s,V(.09,.23,.41),CF(s*.77,4.97,-1.24),gold,sh,nil,true)
    detail(serpent,"Fang"..s,V(.15,.47,.23),CF(s*.42,4.22,-2.28),white,sh,"WedgePart")
    local hood=limb(serpent,(s==-1 and "Left" or "Right").."Hood",V(.38,2.08,1.02),CF(s*.91,3.85,-.09)*CFrame.Angles(0,0,-s*.32),violet,V(s*.46,3.0,-.1),"WedgePart")
    local pts={V(s*.59,3.05,-.53),V(s*1.29,3.71,-.58),V(s*.98,4.0,-.59),V(s*1.25,4.67,-.55)}
    for i=1,3 do beam(serpent,"HoodBolt"..s..i,pts[i],pts[i+1],.07,gold,hood,true) end
    detail(serpent,"CrownFin"..s,V(.24,1.16,.59),CF(s*.56,5.7,-.48)*CFrame.Angles(math.rad(-20),0,-s*.2),sky,sh,"WedgePart")
end
-- Ice dragon: compact drake skeleton with broad frosted wings and a crystal crown.
local ice=cloneBase(anchor,names[4],V(0,1.97,.15))
for _,p in ice:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
    local n=p.Name
    if p.Material==Enum.Material.Neon then p.Color=Color3.fromRGB(104,235,255)
    elseif n:find("Sail") then p.Color=sky
    elseif n:find("Horn") or n:find("Claw") or n:find("Fang") then p.Color=white
    elseif n:find("Pupil") or n:find("Socket") or n:find("Nostril") then p.Color=navy
    elseif n:find("Spine") or n:find("Scale") or n:find("ChestPlate") then p.Color=white
    else p.Color=Color3.fromRGB(91,156,188) end
end end
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    for i=1,3 do
        detail(ice,side.."IceCrown"..i,V(.25,.75+i*.15,.45),CF(s*(.25+i*.23),3.75+i*.1,-1.28+i*.19)*CFrame.Angles(math.rad(20),0,-s*.2),white,ice.Head,"WedgePart")
        detail(ice,side.."WingIcicle"..i,V(.22,.77,.34),CF(s*(2.1+i*.5),3.22+i*.24,1.85)*CFrame.Angles(0,0,s*.18),white,ice[side.."Wing"],"WedgePart")
    end
    detail(ice,side.."ShoulderCrystal",V(.45,1.0,.61),CF(s*1.14,3.24,-.8)*CFrame.Angles(0,0,-s*.25),sky,ice.Torso,"WedgePart")
end
ice:ScaleTo(1.15)
local models={storm,golem,serpent,ice}
local ap=anchor:GetPivot()
local prev=griffinBase:GetPivot().Position
local direction=ap:PointToObjectSpace(prev).X>0 and -1 or 1
local ground=anchor.PrimaryPart.Position.Y-anchor.PrimaryPart.Size.Y/2-anchor.Humanoid.HipHeight
local offsets={11,21,31,43}
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("ElementalPets","Create four elemental pet concepts")
for i,m in models do
    local low=math.huge
    for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y)
        end end end
    end end
    local r=m.PrimaryPart
    m.Humanoid.HipHeight=math.max(0,r.Position.Y-r.Size.Y/2-low+.025)
    local pos=ap.Position+ap.RightVector*offsets[i]*direction
    m:PivotTo(CF(pos.X,ground+r.Position.Y-low+.025,pos.Z)*ap.Rotation)
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
    m:SetAttribute("Purpose","Standalone elemental art trial; no gameplay integration")
    m.Parent=workspace
    print("Created",m.Name,m:GetPivot().Position)
end
game:GetService("Selection"):Set(models)
local f=(models[1]:GetPivot().Position+models[4]:GetPivot().Position)/2+V(0,1,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(f+V(4,15,-34),f)
workspace.CurrentCamera.Focus=CF(f)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
