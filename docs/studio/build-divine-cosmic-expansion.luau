-- Editor-only six sculpted celestial pet concepts; no animations or gameplay binding.
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
local pearl=C(224,232,235)
local midnight=C(32,37,65)
local amethyst=C(115,81,167)
local starlight=C(131,216,243)
local sunlight=C(235,183,74)
local function ring(q,n,center,r,color,l,vertical)
 for i=0,23 do
  local a,b=i*math.pi/12,(i+1)*math.pi/12
  local function v(t) return center+(vertical and V(math.cos(t)*r,math.sin(t)*r,0) or V(math.cos(t)*r,0,math.sin(t)*r)) end
  q.b(n,v(a),v(b),.075,color,l,true)
 end
end
local function star(q,n,p,r,color,l)
 for _,d in {V(1,0,0),V(-1,0,0),V(0,1,0),V(0,-1,0)} do q.sp(n,p,p+d*r,.16,color,l) end
end
-- Continuous tube rings give tails and serpentine bodies clean joined bends.
local function tube(q,n,pts,radii,col,l)
 local rings={}
 for i,p in pts do
  local dir=(pts[math.min(i+1,#pts)]-pts[math.max(i-1,1)]).Unit
  local side=dir:Cross(V(0,1,0)); if side.Magnitude<.04 then side=V(1,0,0) else side=side.Unit end
  local up=side:Cross(dir).Unit; rings[i]={}
  for k=1,8 do local a=(k-1)*math.pi/4; rings[i][k]=p+(side*math.cos(a)+up*math.sin(a))*radii[i] end
 end
 for i=1,#pts-1 do for k=1,8 do local j=k%8+1
  local c=k<5 and col or col:Lerp(black,.16)
  q.tri(n.."A",rings[i][k],rings[i+1][k],rings[i][j],c,l)
  q.tri(n.."B",rings[i][j],rings[i+1][k],rings[i+1][j],c,l)
 end end
 for k=1,8 do q.tri(n.."Cap",pts[1],rings[1][k],rings[1][k%8+1],col,l); q.tri(n.."End",pts[#pts],rings[#pts][k%8+1],rings[#pts][k],col,l) end
end
local function plumage(q,n,a,tip,width,col,l)
 local middle=a:Lerp(tip,.47)
 local side=(tip-a):Cross(V(0,0,1)); if side.Magnitude<.1 then side=V(1,0,0) else side=side.Unit end
 q.tri(n.."L",a,middle-side*width/2,tip,col,l)
 q.tri(n.."R",a,tip,middle+side*width/2,col:Lerp(pearl,.12),l)
 q.b(n.."Quill",a,tip,.055,col:Lerp(black,.19),l)
end
local function featherWings(q,level,spread,col,tipcol,rootY)
 for _,s in {-1,1} do
  local a=V(s*.99,rootY,level*.39)
  local b=V(s*spread,rootY+2.2-level*.25,.8+level*.6)
  local l=q.l((s<0 and "Left" or "Right").."Wing"..level,a)
  q.seg("WingShoulder",a,a:Lerp(b,.42),.44,.55,.3,.32,col,l)
  q.b("LeadingEdge",a,b,.14,tipcol,l)
  q.tri("WingUndercoat",a,b,V(s*1.75,rootY-1.0,2.05+level*.7),col,l)
  for i=1,9 do
   local f=i/9; local p=a:Lerp(b,f)
   local tip=p+V(s*(.28+(1-f)*.5),-1.52+(level-1)*.16,1.45)
   plumage(q,"PrimaryFeather",p,tip,.94,col,l)
   plumage(q,"FeatherTip",p:Lerp(tip,.66),tip+V(0,-.06,.06),.39,tipcol,l)
   plumage(q,"Covert",p+V(0,.02,-.1),p:Lerp(tip,.47)+V(0,.05,-.14),.65,col:Lerp(pearl,.17),l)
  end
 end
end

-- Run one requested model; source shapes are archived before consolidation.
local name="__PET_NAME__"
local storage=game:GetService("ServerStorage")
local archive=storage:FindFirstChild("DivineCosmicSources_20260927") or Instance.new("Folder")
archive.Name="DivineCosmicSources_20260927";archive.Parent=storage
if archive:FindFirstChild(name) then return "EXISTS "..name end
local q=factory(name,V(3,2.8,4.5),V(0,2.8,.3),pearl)
q.m.Parent=archive;q.m:SetAttribute("BuildState","Building")
local ok,err=xpcall(function()
if name=="Divine Phoenix" then
 q.seg("Body",V(0,2.7,1.6),V(0,3.9,-.8),1.8,1.7,1.55,2.1,pearl,q.t)
 local h=q.l("Head",V(0,4.2,-.7))
 chain(q,"Neck",{V(0,3.8,-.7),V(0,5,-1.1),V(0,5.8,-1.5)},{1.25,.95,.8},pearl,h)
 q.seg("Skull",V(0,5.85,-1.2),V(0,5.7,-2.1),1.05,1.15,.8,.65,pearl,h)
 q.sp("Beak",V(0,5.6,-2),V(0,5.25,-2.95),.7,sunlight,h)
 for _,s in {-1,1} do
  q.d("Eye",V(.08,.16,.38),CF(s*.49,5.86,-1.84),cyan,h,nil,true)
  q.b("Brow",V(s*.49,6.05,-2.07),V(s*.48,6.12,-1.56),.15,sunlight,h)
  for i=1,3 do plumage(q,"Crown",V(s*.24,6,-1.2),V(s*(.28+i*.24),6.7+i*.3,-.5+i*.15),.46,sunlight,h) end
  local leg=q.l(s<0 and "LeftLeg" or "RightLeg",V(s*.57,2.6,.5))
  chain(q,"Shin",{V(s*.57,2.6,.5),V(s*.72,1.2,.95),V(s*.73,.32,.2)},{.48,.29,.2},sunlight,leg)
  for j=1,3 do q.sp("Talon",V(s*.73,.3,.2),V(s*.73+(j-2)*.35,.08,-.75),.22,brass,leg) end
 end
 for row=1,3 do for i=-1,1 do
  plumage(q,"BreastFeather",V(i*.38,4.15-row*.3,-1.34),V(i*.48,3.4-row*.32,-1.48),.65,row==1 and sunlight or pearl,q.t)
 end end
 for _,side in {-1,1} do for i=1,3 do
  plumage(q,"Collar",V(side*.28,5.1-i*.24,-1.15),V(side*(.9-i*.1),4.75-i*.3,-.9),.53,sunlight,h)
 end end
 featherWings(q,1,5.8,pearl,sunlight,4)
 local tail=q.l("Tail",V(0,2.9,1.4))
 for i=-2,2 do
  local a=V(i*.14,2.9,1.2);local b=V(i*.9,1.2,6.2-math.abs(i)*.55)
  plumage(q,"SacredTail",a,b,1.15,pearl,tail)
  plumage(q,"GoldenTail",a:Lerp(b,.47),b+V(0,.05,.1),.68,sunlight,tail)
 end
 ring(q,"Halo",V(0,7,-.8),1.05,sunlight,h,true)
elseif name=="Heavenly Kirin" then
 body(q,jadeLight,2.1)
 for _,s in {-1,1} do for _,z in {-1.25,1.65} do
  local l=q.l("Leg"..s..z,V(s*.78,2.8,z))
  chain(q,"LongLeg",{V(s*.78,2.8,z),V(s*.9,1.4,z+.15),V(s*.88,.4,z-.2)},{.62,.4,.27},pearl,l)
  q.seg("GoldenHoof",V(s*.88,.35,z),V(s*.88,.29,z-.6),.5,.5,.58,.43,sunlight,l)
 end end
 local h=q.l("Head",V(0,3.5,-1.4))
 chain(q,"ProudNeck",{V(0,3.1,-1.3),V(0,4.4,-1.8),V(0,5.4,-1.8)},{1.35,.95,.75},pearl,h)
 q.seg("DeerSkull",V(0,5.55,-1.55),V(0,5.4,-2.4),.94,1.12,.7,.75,pearl,h)
 q.seg("Muzzle",V(0,5.4,-2.3),V(0,5.02,-3.05),.7,.67,.46,.4,pearl,h)
 for _,s in {-1,1} do
  q.d("Eye",V(.065,.17,.36),CF(s*.45,5.61,-2.22),cyan,h,nil,true)
  q.b("Brow",V(s*.45,5.76,-2.4),V(s*.46,5.84,-2.04),.12,sunlight,h)
  q.sp("Ear",V(s*.43,5.76,-1.4),V(s*1.04,6.15,-1.08),.42,jade,h)
  local pts={V(s*.32,5.98,-1.57),V(s*.48,6.8,-1.25),V(s*.84,7.3,-.7),V(s*1.06,7.8,-.5)}
  tube(q,"Antler",pts,{.15,.12,.07,.015},sunlight,h)
  q.sp("AntlerFork",pts[2],V(s*1.13,7.03,-1.4),.19,sunlight,h)
  q.sp("AntlerFork",pts[3],V(s*.47,7.64,-.8),.13,sunlight,h)
  for i=1,5 do plumage(q,"Mane",V(s*.27,5.6-i*.37,-1),V(s*.7,5.5-i*.45,.3),.7,jadeLight,h) end
 end
 for _,side in {-1,1} do for row=1,2 do for i=1,4 do
  local a=V(side*(1.02-row*.03),3.5-row*.33,-.85+i*.59)
  plumage(q,"JadeScale",a,a+V(side*.12,-.52,.28),.5,row==1 and sunlight or pearl,q.t)
 end end end
 for i=1,5 do q.sp("DorsalJade",V(0,4.05-i*.09,-.7+i*.55),V(0,4.55-i*.1,i*.55),.5,sunlight,q.t) end
 local tail=q.l("Tail",V(0,2.8,2.3))
 tube(q,"FlowingTail",{V(0,2.8,2.3),V(.2,3,3.3),V(.65,2.2,4.2),V(.9,1.2,4.8)},{.32,.28,.34,.03},pearl,tail)
 for i=-1,1 do plumage(q,"TailSilk",V(.4,2.8,3.5),V(.9+i*.4,.65,5.1),.55,jadeLight,tail) end
elseif name=="Godly Behemoth" then
 body(q,ivory,4.2);legs(q,ivory,true,false)
 local h=reptileHead(q,"Head",V(0,3.3,-2),1.5,pearl,false)
 for _,s in {-1,1} do
  tube(q,"GreatTusk",{V(s*.95,2.7,-3.5),V(s*1.6,3,-4.1),V(s*1.65,4,-3.95),V(s*1.25,4.7,-3.4)},{.36,.29,.18,.018},sunlight,h)
  q.seg("ShoulderArmor",V(s*1.55,3.9,-1.3),V(s*1.7,3.5,.1),1.3,1.15,1.1,.7,sunlight,q.t)
  for i=1,3 do q.sp("ArmorCrest",V(s*1.65,4.25,-1+i*.4),V(s*2.2,5.1,-.55+i*.4),.48,pearl,q.t) end
 end
 for i=-1,1 do q.sp("SunCrown",V(i*.46,4.6,-2),V(i*.68,5.9-math.abs(i)*.4,-1.65),.42,sunlight,h) end
 ring(q,"SolarSeal",V(0,3.75,-1.98),.57,sunlight,q.t,true)
 star(q,"SunCore",V(0,3.75,-2.02),.4,cyan,q.t)
 local tail=q.l("Tail",V(0,2.6,2.3))
 tube(q,"Tail",{V(0,2.6,2.3),V(0,2.1,3.5),V(.7,1.6,4.4)},{.62,.4,.05},ivory,tail)
elseif name=="Galaxy Dragon" then
 body(q,midnight,2.65);legs(q,midnight,false,false)
 local h=reptileHead(q,"Head",V(0,5,-2.2),1.1,amethyst,true)
 tube(q,"LongNeck",{V(0,3.2,-1.3),V(0,4.3,-1.5),V(0,5,-2.1)},{.9,.66,.62},midnight,h)
 for i=1,5 do
  local y=4.55-i*.34;local z=-2.04+i*.07
  q.seg("ThroatPlate",V(0,y,z),V(0,y-.29,z+.1),.64,.13,.75,.14,starlight,h)
 end
 batWings(q,amethyst,midnight,false,6.5)
 for _,s in {-1,1} do
  local wing=q.m:FindFirstChild(s<0 and "LeftWing" or "RightWing")
  local pts={V(s*2.8,5.35,.42),V(s*4.2,5.5,1.55),V(s*5.7,6.3,1.24)}
  for i,p in pts do star(q,"WingStar",p,.18,cyan,wing);if i>1 then q.b("Constellation",pts[i-1],p,.035,cyan,wing,true) end end
  q.sp("SweptHorn",V(s*.6,5.9,-1.85),V(s*1.3,7.1,-.7),.46,amethyst,h)
 end
 local tail=q.l("Tail",V(0,2.5,2.3))
 tube(q,"Tail",{V(0,2.5,2.2),V(.2,2.3,3.8),V(1,2.9,5),V(1.8,3.7,5.7)},{.65,.42,.25,.025},amethyst,tail)
 star(q,"TailStar",V(1.8,3.7,5.7),.65,cyan,tail)
 for i=1,5 do q.sp("CrystalSpine",V(0,4.1-i*.12,i*.55),V(0,4.9-i*.18,.25+i*.55),.38,cyan,q.t) end
elseif name=="Cosmic Hydra" then
 body(q,midnight,3.4);legs(q,amethyst,true,false)
 for i=-2,2 do
  local o=V(i*1.6,5.8-math.abs(i)*.58,-2.25+math.abs(i)*.25)
  local h=reptileHead(q,"Head"..(i+3),o,.85,amethyst,true)
  tube(q,"Neck",{V(i*.42,3.2,-.6),V(i*1.03,4.3,-1),o},{.64,.51,.48},midnight,h)
  tube(q,"Throat",{V(i*.42,3.2,-1.12),V(i*1.03,4.3,-1.48),o+V(0,-.25,-.43)},{.14,.13,.12},starlight,h)
  star(q,"BrowStar",o+V(0,.7,-.52),.22,cyan,h)
 end
 local tail=q.l("Tail",V(0,2.5,2.3))
 tube(q,"Tail",{V(0,2.5,2.3),V(.6,2,3.8),V(1.8,2.4,4.8),V(2.7,3.3,4.6)},{.68,.45,.28,.02},amethyst,tail)
 ring(q,"AstralOrbit",V(0,4.1,.9),2.4,starlight,q.t,false)
 for _,s in {-1,1} do for i=1,3 do q.sp("BackCrystal",V(s*.8,3.9,.1+i*.58),V(s*1.5,4.8,.6+i*.58),.45,amethyst,q.t) end end
elseif name=="World Eater" then
 local h=q.l("Head",V(0,4.1,-2))
 tube(q,"VoidBody",{V(0,4,-2),V(0,3.8,0),V(0,2.6,2.7),V(2.2,1.4,4.7),V(4.8,1.3,3.3),V(4.4,2.1,1),V(3.1,3.2,.6)},{1.4,1.7,1.35,.9,.6,.3,.015},midnight,q.t)
 q.seg("Skull",V(0,4.6,-1.9),V(0,4.5,-3.8),2.7,1.6,2.05,.85,midnight,h)
 q.seg("OpenJaw",V(0,3.6,-1.9),V(0,2.6,-4),2.4,.5,1.85,.3,amethyst,h)
 q.seg("MouthVoid",V(0,3.9,-1.9),V(0,3.6,-2.5),2.1,1.8,1.9,1.45,black,h)
 star(q,"DevouringCore",V(0,3.7,-2.84),.55,cyan,h)
 for _,s in {-1,1} do
  q.d("Eye",V(.1,.19,.73),CF(s*1.2,4.72,-3.14)*CFrame.Angles(0,0,s*.15),cyan,h,nil,true)
  q.seg("Brow",V(s*1.2,4.9,-3.65),V(s*1.34,5.23,-2.67),.26,.3,.4,.4,amethyst,h)
  for i=1,5 do
   q.sp("UpperFang",V(s*(.87+i*.055),4.1,-4+i*.37),V(s*(.8+i*.05),3.45,-4+i*.37),.19,pearl,h)
   q.sp("LowerFang",V(s*(.82+i*.06),2.65+i*.14,-4+i*.37),V(s*(.77+i*.055),3.15+i*.14,-4+i*.37),.19,pearl,h)
  end
  tube(q,"GreatHorn",{V(s*.85,5.1,-2),V(s*1.8,6,-1.1),V(s*2.1,6.4,.1),V(s*1.4,6.6,.9)},{.4,.28,.14,.015},amethyst,h)
  local fin=q.l(s<0 and "LeftFin" or "RightFin",V(s*1.2,3.8,.3))
  for i=1,3 do plumage(q,"RiftFin",V(s*1.25,4-i*.25,.1+i*.4),V(s*(4.2-i*.35),4.5-i*.8,2.9+i*.3),1.05,amethyst,fin) end
 end
 for i=1,5 do q.sp("VoidSpine",V(0,5.05-i*.31,-.9+i*.65),V(0,6.1-i*.35,-.1+i*.65),.6,amethyst,q.t) end
else error("Unknown model "..name) end
local n=0;for _,p in q.m:GetDescendants() do if p:IsA("BasePart") then n+=1 end end
q.m:SetAttribute("OriginalPartCount",n);q.m:SetAttribute("BuildState","Complete")
q.m:SetAttribute("Style","Faceted sculpted / native CSG");q.m:SetAttribute("PartBudget",100)
end,debug.traceback)
if not ok then q.m:SetAttribute("BuildError",err);error(err) end
return name.." source complete"
