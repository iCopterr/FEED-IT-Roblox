-- Editor-only six sculpted legendary pet concepts; no animations or gameplay binding.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local V,CF,C=Vector3.new,CFrame.new,Color3.fromRGB
local coal,slate,red,fire,gold=C(35,30,36),C(72,51,51),C(153,48,35),C(255,105,26),C(255,209,96)
local navy,blue,ice,snow,cyan=C(25,43,70),C(73,121,163),C(148,209,231),C(230,249,255),C(99,231,255)
local violet=C(99,73,143)
local function factory(name,size,pos,color)
    local m=Instance.new("Model"); m.Name=name
    local function p(n,s,cf,c,cl,glow)
        local o=Instance.new(cl or "Part")
        o.Name,o.Size,o.CFrame,o.Color=n,s,cf,c
        o.Material=glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
        o.TopSurface,o.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        o.LeftSurface,o.RightSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        o.FrontSurface,o.BackSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        o.Anchored,o.CanCollide,o.Massless=true,false,true; o.Parent=m
        return o
    end
    local function d(n,s,cf,c,l,cl,glow)
        local o=p(n,s,cf,c,cl,glow)
        local w=Instance.new("WeldConstraint"); w.Name="DetailWeld"
        w.Part0,w.Part1,w.Parent=l,o,o
        return o
    end
    local t=p("Torso",size,CF(pos),color); t.Transparency=1; t.CanCollide=true; t.Massless=false
    local r=p("HumanoidRootPart",size,t.CFrame,color); r.Transparency=1; r.Massless=false; r.RootPriority=127
    m.PrimaryPart=r
    local function joint(n,a,b,at)
        local j=Instance.new("Motor6D"); j.Name=n; j.Part0=a; j.Part1=b
        j.C0=a.CFrame:ToObjectSpace(CF(at)); j.C1=b.CFrame:ToObjectSpace(CF(at)); j.Parent=a
    end
    joint("RootJoint",r,t,pos)
    local function limb(n,at)
        local l=p(n,V(.25,.25,.25),CF(at),color); l.Transparency=1
        joint("TorsoTo"..n,t,l,at); return l
    end
    local function tri(n,a,b,c,col,l)
        local ab,ac,bc=b-a,c-a,c-b
        if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
        elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
        ab,ac,bc=b-a,c-a,c-b
        if ac:Cross(ab).Magnitude<.00001 then return end
        local right,back=ac:Cross(ab).Unit,bc.Unit
        local up=bc:Cross(right).Unit
        local h=math.abs(ab:Dot(up))
        for i,spec in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
            if spec[4]>.001 then d(n..i,V(.025,h,spec[4]),CFrame.fromMatrix(spec[1],spec[2],up,spec[3]),col,l,"WedgePart") end
        end
    end
    local function segment(n,a,b,wa,ha,wb,hb,col,l)
        local cf=CFrame.lookAt(a,b); local right,up=cf.RightVector,cf.UpVector
        -- Beveled rectangular cross-section softens the large shapes while retaining facets.
        local shape={{-.7,-1},{.7,-1},{1,-.6},{1,.6},{.7,1},{-.7,1},{-1,.6},{-1,-.6}}
        local first,last={},{}
        for i,v in shape do
            first[i]=a+right*v[1]*wa/2+up*v[2]*ha/2
            last[i]=b+right*v[1]*wb/2+up*v[2]*hb/2
        end
        for i=1,8 do
            local j=i%8+1
            local tint=(i==2 or i==7) and col:Lerp(C(255,255,255),.1) or col
            tri(n.."Panel"..i.."A",first[i],first[j],last[i],tint,l)
            tri(n.."Panel"..i.."B",last[i],first[j],last[j],tint,l)
        end
        for i=2,7 do tri(n.."CapA"..i,first[1],first[i],first[i+1],col,l); tri(n.."CapB"..i,last[1],last[i],last[i+1],col,l) end
    end
    local function spike(n,a,b,width,col,l)
        local cf=CFrame.lookAt(a,b); local x,y=cf.RightVector*width/2,cf.UpVector*width/2
        local q={a-x-y,a+x-y,a+x+y,a-x+y}
        for i=1,4 do tri(n..i,q[i],q[i%4+1],b,i%2==0 and col:Lerp(snow,.13) or col,l) end
        tri(n.."BaseA",q[1],q[2],q[3],col,l); tri(n.."BaseB",q[1],q[3],q[4],col,l)
    end
    local function beam(n,a,b,w,col,l,glow) return d(n,V(w,w,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),col,l,nil,glow) end
    local function feather(n,a,b,w,col,l)
        local dir=(b-a).Unit; local side=dir:Cross(V(0,1,0))
        if side.Magnitude<.01 then side=V(1,0,0) else side=side.Unit end
        local center=a:Lerp(b,.4)+V(0,.09,0)
        tri(n.."L",a,center-side*w/2,b,col,l)
        tri(n.."R",a,b,center+side*w/2,col:Lerp(snow,.12),l)
        beam(n.."Quill",a,b,.045,col:Lerp(navy,.25),l)
    end
    local h=Instance.new("Humanoid"); h.RigType=Enum.HumanoidRigType.R15
    h.RequiresNeck=false; h.BreakJointsOnDeath=false; h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; h.Parent=m
    Instance.new("Animator",h)
    return {m=m,t=t,d=d,l=limb,tri=tri,seg=segment,sp=spike,b=beam,f=feather}
end
local ivory=C(227,216,179)
local black=C(23,24,31)
local jade=C(33,100,79)
local jadeLight=C(72,144,98)
local brass=C(177,142,71)
local plum=C(78,47,103)
local teal=C(48,133,148)
local stone=C(85,88,79)
local names={"Hydra_V1","Phoenix_V1","Kraken_V1","AncientWyvern_V1","BoneDragon_V1","Behemoth_V1"}
for _,n in names do assert(not workspace:FindFirstChild(n),n.." exists") end
local neighbor=assert(workspace:FindFirstChild("Cerberus_V1"),"Cerberus required")
local models={}
local function chain(q,n,pts,widths,col,l)
 for i=1,#pts-1 do q.seg(n..i,pts[i],pts[i+1],widths[i],widths[i],widths[i+1],widths[i+1],col,l) end
end
local function legs(q,col,big,onlyHind)
 for _,s in {-1,1} do for _,front in {true,false} do if not (onlyHind and front) then
  local z=front and -1.22 or 1.83
  local x=s*(big and 1.55 or 1.03)
  local l=q.l((s<0 and "Left" or "Right")..(front and "Foreleg" or "Hindleg"),V(x,2.65,z))
  chain(q,"Leg",{V(x,2.65,z),V(x*1.15,1.35,z+.32),V(x*1.12,.4,z-.22)},{big and 1.45 or .93,big and 1.12 or .64,big and .91 or .43},col,l)
  q.seg("Paw",V(x*1.12,.34,z+.04),V(x*1.12,.3,z-.98),big and 1.29 or .8,.57,big and 1.4 or .94,.42,col,l)
  for j=1,3 do q.sp("Claw",V(x*1.12+(j-2)*.28,.29,z-.87),V(x*1.12+(j-2)*.32,.12,z-1.3),.18,ivory,l) end
 end end end
end
local function body(q,col,wide)
 q.seg("Chest",V(0,2.84,-1.45),V(0,2.75,.45),wide or 2.9,2.6,(wide or 2.9)*.9,2.35,col,q.t)
 q.seg("Haunch",V(0,2.75,.45),V(0,2.6,2.45),(wide or 2.9)*.9,2.35,(wide or 2.9)*.72,1.9,col,q.t)
end
local function reptileHead(q,name,o,k,col,bony)
 local h=q.l(name,o)
 local function v(x,y,z) return o+V(x,y,z)*k end
 q.seg(name.."Cranium",v(0,.38,.42),v(0,.3,-.72),1.58*k,1.45*k,1.48*k,1.03*k,col,h)
 q.seg(name.."Muzzle",v(0,.14,-.69),v(0,-.06,-1.76),1.43*k,.91*k,.85*k,.45*k,col,h)
 q.seg(name.."Mouth",v(0,-.27,-.66),v(0,-.36,-1.69),1.21*k,.23*k,.76*k,.16*k,black,h)
 q.seg(name.."Jaw",v(0,-.49,-.48),v(0,-.54,-1.57),1.03*k,.24*k,.73*k,.16*k,bony and ivory or col,h)
 for _,s in {-1,1} do
  q.d(name.."EyeSocket",V(.11,.43,.65)*k,CF(v(s*.735,.38,-.52)),black,h)
  q.d(name.."Eye",V(.13,.18,.36)*k,CF(v(s*.8,.38,-.55)),bony and cyan or gold,h,nil,bony)
  q.d(name.."Slit",V(.025,.19,.065)*k,CF(v(s*.87,.38,-.57)),black,h)
  q.seg(name.."Brow",v(s*.71,.68,-.85),v(s*.76,.8,-.05),.27*k,.25*k,.38*k,.33*k,col,h)
  q.sp(name.."Horn",v(s*.55,.85,.25),v(s*.89,1.54,.99),.43*k,bony and ivory or brass,h)
  q.sp(name.."Fang",v(s*.4,-.21,-1.32),v(s*.37,-.62,-1.42),.13*k,ivory,h)
  q.sp(name.."Cheek",v(s*.65,-.08,.29),v(s*1.21,-.43,.8),.53*k,col,h)
  q.d(name.."Nostril",V(.07,.09,.17)*k,CF(v(s*.43,.02,-1.55)),black,h)
 end
 return h
end
local function batWings(q,col,membrane,bony,spread)
 for _,s in {-1,1} do
  local a=V(s*1.01,3.5,.25); local b=V(s*2.6,5.34,.5); local tip=V(s*spread,6.85,.97)
  local l=q.l((s<0 and "Left" or "Right").."Wing",a)
  chain(q,"WingArm",{a,b,tip},{.42,.29,.035},col,l)
  local ends={tip,V(s*(spread-.37),4.74,2.54),V(s*3.69,3.73,3.35),V(s*1.24,3.1,2.47)}
  for i=1,3 do
   if bony then
    local mid=b:Lerp(ends[i+1],.7)
    q.tri("TatteredSail",b,ends[i],mid,membrane,l)
   else q.tri("WingSail",b,ends[i],ends[i+1],membrane,l) end
   q.b("WingFinger",b,ends[i+1],bony and .13 or .1,col,l)
  end
  if not bony then q.tri("WingRoot",a,b,ends[4],membrane,l) end
  q.sp("WingThumb",b,b+V(s*.22,.7,-.19),.27,ivory,l)
 end
end
-- Hydra: five different neck heights, compact amphibian body and long tail.
local q=factory(names[1],V(3,2.3,4.1),V(0,2.6,.3),jade)
body(q,jade,3.2); legs(q,jade,false,false)
for i=-2,2 do
 local x=i*1.51; local height=5.28+(2-math.abs(i))*.75
 local a=V(i*.4,3.13,-1); local b=V(x*.66,4.13,-1.17); local c=V(x,height,-1.65)
 local n=q.l("Neck"..(i+3),a)
 chain(q,"HydraNeck",{a,b,c},{.89,.72,.66},jade,n)
 for j=1,4 do local p=b:Lerp(c,j/5); q.sp("NeckFin",p+V(0,0,.28),p+V(0,.14,.83),.3,jadeLight,n) end
 reptileHead(q,"Head"..(i+3),c,.79,jadeLight,false)
end
local t=q.l("Tail",V(0,2.56,2.15))
chain(q,"Tail",{V(0,2.56,2.15),V(.5,2.06,3.65),V(1.56,1.1,4.84),V(2.6,.68,5.1),V(3.4,.89,4.6)},{.93,.73,.45,.24,.035},jade,t)
for i=1,5 do q.sp("DorsalFin",V(0,3.87,.15+i*.37),V(0,4.52-i*.07,.41+i*.37),.44,jadeLight,q.t) end
table.insert(models,q.m)
-- Phoenix: upturned layered wings, swept crest and five trailing flame plumes.
q=factory(names[2],V(2.1,2.8,2.1),V(0,2.9,0),fire)
q.seg("Body",V(0,2.05,.68),V(0,4.29,-.13),1.36,1.69,1.8,1.91,C(178,54,29),q.t)
q.seg("Breast",V(0,2.52,-.68),V(0,4.21,-.72),1.52,.64,1.6,.7,fire,q.t)
local h=q.l("Head",V(0,4.18,-.32))
q.seg("Neck",V(0,4,-.2),V(0,5.13,-.53),1.09,1.12,.93,1.1,fire,h)
q.seg("BirdSkull",V(0,5.27,-.2),V(0,5.24,-1.12),1.16,1.12,.81,.71,fire,h)
q.sp("HookedBeak",V(0,5.12,-1.11),V(0,4.78,-1.99),.57,gold,h)
for _,s in {-1,1} do
 q.d("EyeSocket",V(.07,.25,.4),CF(s*.51,5.37,-.85),black,h)
 q.d("GoldenEye",V(.09,.12,.21),CF(s*.55,5.38,-.87),gold,h,nil,true)
 q.sp("HeadFlame",V(s*.3,5.69,.01),V(s*.49,6.67,.77),.49,gold,h)
 local w=q.l((s<0 and "Left" or "Right").."Wing",V(s*.83,3.77,0))
 chain(q,"WingBone",{V(s*.82,3.77,0),V(s*2.63,4.8,.37),V(s*5.23,6.2,.83)},{.52,.34,.055},fire,w)
 for i=1,9 do
  local f=i/9
  local a=V(s*(1.12+f*3.86),4.04+f*1.82,.24+f*.6)
  local b=a+V(s*(.7+(1-f)*.48),-1.6-(1-f)*.9,1.51)
  q.f("PrimaryFeather",a,b,.92,i%2==0 and fire or C(213,62,26),w)
  q.f("GoldenFeatherTip",a:Lerp(b,.61),b+V(s*.11,-.19,.11),.48,gold,w)
  q.f("WingCoverts",a+V(0,.06,-.09),a:Lerp(b,.48)+V(0,.09,-.11),.67,fire:Lerp(gold,.37),w)
  local mid=a:Lerp(b,.5)
  q.tri("BroadFeatherLeft",a,mid+V(s*.49,0,-.11),b,fire,w)
  q.tri("BroadFeatherRight",a,b,mid-V(s*.49,0,.11),C(211,65,24),w)
 end
 q.tri("WingUndercoat",V(s*.89,3.78,.13),V(s*5.23,6.2,.83),V(s*2.06,2.28,1.69),C(188,51,24),w)
 for j=1,3 do q.sp("BreastFeather",V(s*.39,3.86-j*.38,-.96),V(s*.62,3.16-j*.38,-1.02),.53,gold,q.t) end
 local leg=q.l((s<0 and "Left" or "Right").."Leg",V(s*.49,2.04,.12))
 chain(q,"BirdLeg",{V(s*.49,2.04,.12),V(s*.61,.81,.24),V(s*.62,.25,-.11)},{.36,.23,.2},gold,leg)
 for j=1,3 do q.sp("Talon",V(s*.62,.24,-.11),V(s*.62+(j-2)*.34,.12,-.96+math.abs(j-2)*.15),.16,ivory,leg) end
end
t=q.l("Tail",V(0,2.38,.84))
for i=-2,2 do
 local a=V(i*.22,2.36,.86); local b=V(i*.78,.51+math.abs(i)*.15,5.96-math.abs(i)*.55)
 q.f("FlameTrain",a,b,1.0,fire,t)
 q.f("TrainGold",a:Lerp(b,.42),b+V(0,.15,.39),.63,gold,t)
end
table.insert(models,q.m)
-- Kraken: tall mantle, eight curling radial arms, contrasting suction cups.
q=factory(names[3],V(3.5,3.1,3.5),V(0,2.42,0),plum)
q.seg("MantleLower",V(0,1.72,0),V(0,3.71,.28),3.44,3.31,3.1,2.8,plum,q.t)
q.seg("MantleCrown",V(0,3.71,.28),V(0,5.58,.57),3.1,2.8,.35,.43,C(109,67,129),q.t)
for _,s in {-1,1} do
 chain(q,"MantleRidge",{V(s*.21,5.2,.05),V(s*.9,4.0,-.86),V(s*1.2,2.46,-1.04)},{.1,.16,.12},teal,q.t)
 q.seg("KrakenBrow",V(s*1.37,3.34,-1.0),V(s*1.49,3.49,-.27),.25,.23,.32,.3,C(36,75,92),q.t)
end
for _,s in {-1,1} do
 q.d("EyeRim",V(.15,.61,1.02),CF(s*1.53,2.94,-.67),black,q.t)
 q.d("Eye",V(.18,.37,.69),CF(s*1.61,2.97,-.7),cyan,q.t,nil,true)
 q.d("Slit",V(.03,.38,.13),CF(s*1.71,2.97,-.75),black,q.t)
 q.sp("MantleFin",V(s*1.14,4.01,.22),V(s*2.26,3.2,1.13),1.05,teal,q.t)
end
q.sp("Beak",V(0,1.69,-1.51),V(0,.98,-1.98),.78,black,q.t)
for i=1,8 do
 local a=(i-1)*math.pi/4; local radial=V(math.sin(a),0,math.cos(a)); local side=V(math.cos(a),0,-math.sin(a))
 local pts={radial*1.23+V(0,1.68,0),radial*2.3+V(0,.93,0),radial*3.52+side*.38+V(0,.43,0),radial*4.58+side*.69+V(0,.59,0),radial*4.9+side*.97+V(0,1.4,0),radial*4.53+side*1.16+V(0,1.98,0)}
 local l=q.l("Tentacle"..i,pts[1]); chain(q,"Tentacle",pts,{1,.81,.57,.37,.21,.035},i%2==0 and plum or C(91,55,117),l)
 for j=1,3 do
  local p=pts[j+1]
  local cup=q.d("Sucker",V(.31,.12,.31),CF(p+V(0,.27,0)),teal,l); cup.Shape=Enum.PartType.Ball
  local inset=q.d("SuckerInset",V(.15,.035,.15),CF(p+V(0,.33,0)),C(27,70,83),l); inset.Shape=Enum.PartType.Ball
 end
end
table.insert(models,q.m)
-- Ancient Wyvern: long lean trunk, two hind legs, broad weathered wings.
local old=C(96,111,87)
q=factory(names[4],V(2.6,2.3,4.6),V(0,2.6,.3),old)
body(q,old,2.61); legs(q,old,false,true)
local neck=q.l("Neck",V(0,3.3,-1.25))
chain(q,"LongNeck",{V(0,3.3,-1.25),V(0,4.45,-1.91),V(0,5.24,-2.78)},{1.2,.99,.85},old,neck)
reptileHead(q,"Head",V(0,5.25,-2.8),1.08,old,false)
batWings(q,old,C(117,91,61),false,6.0)
t=q.l("Tail",V(0,2.54,2.2))
chain(q,"WhipTail",{V(0,2.54,2.2),V(.23,2.04,3.9),V(1.2,1.34,5.44),V(2.56,.97,6.06),V(3.5,1.23,5.65)},{.83,.64,.43,.21,.03},old,t)
for i=1,7 do q.sp("AncientSpine",V(0,3.74,.15+i*.32),V(0,4.4-i*.05,.4+i*.32),.42,brass,q.t) end
for _,s in {-1,1} do for i=1,3 do q.sp("ShoulderScale",V(s*.98,3.29,-.43+i*.54),V(s*1.61,3.42,.01+i*.54),.69,old:Lerp(ivory,.2),q.t) end end
table.insert(models,q.m)
-- Bone Dragon: exposed ribs and vertebrae, hollow skull and torn wing sails.
q=factory(names[5],V(2.8,2.2,4.5),V(0,2.6,.3),ivory)
q.seg("Spine",V(0,3.34,-1.56),V(0,3.23,2.29),.46,.49,.43,.46,ivory,q.t)
for i=1,7 do
 local z=-1.2+(i-1)*.48
 q.seg("Vertebra",V(0,3.29,z-.12),V(0,3.29,z+.12),.7,.65,.7,.65,ivory,q.t)
 q.sp("BoneSpine",V(0,3.55,z),V(0,4.05,z+.23),.23,ivory,q.t)
 for _,s in {-1,1} do
  local width=1.1-math.abs(i-4)*.075
  chain(q,"Rib",{V(s*.17,3.35,z),V(s*width,2.91,z+.06),V(s*(width+.03),2.02,z+.12),V(s*.35,1.72,z+.16)},{.19,.21,.18,.12},ivory,q.t)
 end
end
legs(q,ivory,false,false)
neck=q.l("Neck",V(0,3.27,-1.42))
chain(q,"BoneNeck",{V(0,3.3,-1.45),V(0,4.45,-1.97),V(0,5.35,-2.22)},{.52,.43,.52},ivory,neck)
for j=1,4 do q.seg("CervicalBone",V(0,3.59+j*.32,-1.66-j*.1),V(0,3.74+j*.32,-1.66-j*.1),.71,.57,.66,.53,ivory,neck) end
reptileHead(q,"Skull",V(0,5.4,-2.3),1.07,ivory,true)
batWings(q,ivory,C(54,64,70),true,5.73)
t=q.l("Tail",V(0,3.23,2.19))
local pts={V(0,3.23,2.19),V(.15,2.71,3.31),V(.71,1.9,4.22),V(1.66,1.17,4.85),V(2.66,.88,4.6)}
chain(q,"BoneTail",pts,{.47,.39,.29,.19,.025},ivory,t)
for i=1,4 do q.sp("TailSpike",pts[i],pts[i]+V(.05,.61,.26),.3,ivory,t) end
table.insert(models,q.m)
-- Behemoth: massive quadruped, slate armor, tusks and heavy brow.
q=factory(names[6],V(4,3,4.7),V(0,2.6,.3),stone)
body(q,stone,4.3); legs(q,stone,true,false)
local head=reptileHead(q,"Head",V(0,3.24,-2.17),1.48,C(106,105,87),false)
for _,s in {-1,1} do
 chain(q,"Tusks",{V(s*.81,2.62,-3.63),V(s*1.49,3.12,-4.14),V(s*1.65,4.04,-4.01),V(s*1.4,4.77,-3.67)},{.58,.45,.27,.025},ivory,head)
 for j=1,4 do
  local z=-1.25+j*.84
  q.seg("Carapace",V(s*1.1,3.79,z-.3),V(s*1.1,3.87,z+.31),1.65,.76,1.47,.76,C(54,64,66),q.t)
  q.sp("ArmorSpike",V(s*1.5,4.13,z),V(s*2.16,4.78,z+.27),.58,brass,q.t)
 end
end
for i=1,5 do q.sp("CenterArmor",V(0,3.94,-.8+i*.61),V(0,4.85,-.49+i*.61),.81,C(68,77,76),q.t) end
t=q.l("Tail",V(0,2.65,2.21))
chain(q,"ClubTail",{V(0,2.65,2.21),V(0,1.88,3.45),V(.6,1.14,4.49)},{.76,.63,.73},stone,t)
for _,s in {-1,1} do q.sp("TailClubSpike",V(.6,1.16,4.49),V(.6+s*.93,1.33,4.54),.55,ivory,t) end
table.insert(models,q.m)
local np=neighbor:GetPivot()
local floor=neighbor.PrimaryPart.Position.Y-neighbor.PrimaryPart.Size.Y/2-neighbor.Humanoid.HipHeight
for i,m in models do
 local low=math.huge
 for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y) end end end
 end end
 local root=m.PrimaryPart
 m.Humanoid.HipHeight=root.Position.Y-root.Size.Y/2-low+.025
 local pos=np.Position+np.RightVector*(i*18)
 m:PivotTo(CF(pos.X,floor+root.Position.Y-low+.025,pos.Z)*np.Rotation)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
 m:SetAttribute("Purpose","Sculpted art prototype; no gameplay integration")
 m.Parent=workspace
 print("Created",m.Name,#m:GetDescendants())
end
game:GetService("Selection"):Set({})
local cf=models[1]:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(11,6,-23),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)

