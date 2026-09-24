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
local names={"AstralKitsune_V1","EclipseGriffin_V1","VoidLeviathan_V1","CelestialDragon_V1","SeraphBeast_V1","WorldSerpent_V1"}
for _,n in names do assert(not workspace:FindFirstChild(n),n.." exists") end
local neighbor=assert(workspace:FindFirstChild("Behemoth_V1"),"Behemoth missing")
local models={}
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
-- Astral Kitsune: slender fox with nine curved, staggered star-tipped plumes.
local q=factory(names[1],V(2.55,2.1,3.9),V(0,2.6,.3),midnight)
body(q,midnight,2.55); legs(q,midnight,false,false)
local h=q.l("Head",V(0,3.54,-1.52))
q.seg("FoxNeck",V(0,3.07,-1.33),V(0,4.43,-1.9),1.5,1.55,1.25,1.35,pearl,h)
q.seg("FoxSkull",V(0,4.54,-1.57),V(0,4.4,-2.53),1.67,1.51,1.16,.97,pearl,h)
q.seg("FoxMuzzle",V(0,4.25,-2.44),V(0,4.02,-3.38),1.04,.66,.46,.28,pearl,h)
q.d("Nose",V(.33,.23,.17),CF(0,4.07,-3.48),midnight,h)
for _,s in {-1,1} do
 q.d("EyeRim",V(.1,.26,.51),CF(s*.66,4.55,-2.41),midnight,h)
 q.d("Eye",V(.12,.13,.32),CF(s*.72,4.56,-2.45),starlight,h,nil,true)
 q.sp("Ear",V(s*.57,5.02,-1.7),V(s*.96,6.52,-1.48),.82,midnight,h)
 q.tri("InnerEar",V(s*.36,5.21,-2.02),V(s*.91,6.23,-1.69),V(s*.83,5.22,-1.99),amethyst,h)
 for i=1,4 do q.sp("FoxRuff",V(s*.62,4.1-i*.22,-1.46),V(s*(1.15+i*.07),3.78-i*.27,-.68),.58,pearl,h) end
end
star(q,"ForeheadStar",V(0,4.94,-2.3),.29,starlight,h)
for i=1,9 do
 local a=(i-5)*math.pi/11; local x=math.sin(a)*5.15; local rise=math.cos(a)
 local p={V((i-5)*.12,2.65,2),V(x*.38,3.07+rise*.62,3.1),V(x*.81,3.19+rise*2.17,4.12),V(x,3.7+rise*3.5,4.61),V(x*.88,4.28+rise*3.68,4.2)}
 local l=q.l("Tail"..i,p[1])
 tube(q,"AstralTail",{p[1],p[2],p[3],p[4]}, {.27,.55,.69,.33},i%2==0 and amethyst or midnight,l)
 tube(q,"PaleTailTip",{p[4],p[5]},{.33,.025},pearl,l)
 star(q,"TailStar",p[3]+V(0,0,-.65),.21,starlight,l)
 for _,s in {-1,1} do q.sp("TailFluff",p[3]+V(s*.33,0,0),p[3]+V(s*.84,.6,.11),.42,amethyst,l) end
end
table.insert(models,q.m)
-- Eclipse Griffin: black-gold eagle face, leonine hindquarters and solar halo.
q=factory(names[2],V(2.8,2.5,4.2),V(0,2.6,.3),midnight)
body(q,midnight,2.9); legs(q,midnight,false,false)
h=q.l("Head",V(0,3.9,-1.57))
q.seg("EagleNeck",V(0,3.15,-1.36),V(0,4.82,-1.69),1.55,1.52,1.08,1.32,pearl,h)
q.seg("EagleHead",V(0,4.96,-1.47),V(0,4.95,-2.57),1.49,1.23,1.05,.83,midnight,h)
q.sp("GoldenBeak",V(0,4.85,-2.53),V(0,4.28,-3.47),.78,sunlight,h)
for _,s in {-1,1} do
 q.d("EyeSocket",V(.12,.29,.53),CF(s*.61,5.08,-2.25),black,h)
 q.d("SolarEye",V(.14,.14,.3),CF(s*.68,5.09,-2.28),sunlight,h,nil,true)
 for i=1,3 do q.sp("Crest",V(s*.4,5.45-i*.1,-1.56+i*.15),V(s*.7,5.95-i*.08,-.39+i*.2),.47,brass,h) end
 for i=1,4 do q.sp("NeckFeather",V(s*.58,4.63-i*.24,-1.22),V(s*.88,4.23-i*.32,-.65),.62,pearl,h) end
end
featherWings(q,1,5.7,midnight,sunlight,3.89)
ring(q,"EclipseHalo",V(0,6.38,-1.26),.86,sunlight,h,false)
local t=q.l("Tail",V(0,2.62,2.11))
chain(q,"LionTail",{V(0,2.62,2.11),V(.52,2.89,3.46),V(.89,3.61,4.07)},{.25,.21,.13},midnight,t)
q.sp("TailPlume",V(.89,3.61,4.07),V(1.05,4.11,4.22),.58,sunlight,t)
table.insert(models,q.m)
-- Void Leviathan: long armored sea beast, sweeping fins and luminous gill cuts.
q=factory(names[3],V(3.6,2.8,6.5),V(0,2.6,.7),midnight)
tube(q,"WhaleBody",{V(0,2.65,-2.24),V(0,2.84,.18),V(0,2.61,2.64),V(0,2.21,4.38)},{1.38,1.8,1.26,.56},midnight,q.t)
h=reptileHead(q,"Head",V(0,2.94,-2.72),1.45,C(47,44,79),true)
for _,s in {-1,1} do
 local l=q.l((s<0 and "Left" or "Right").."Fin",V(s*1.33,2.57,-.2))
 q.tri("GreatFin",V(s*1.13,3.0,-.65),V(s*5.61,4.05,2.27),V(s*1.38,1.98,2.52),amethyst,l)
 q.tri("FinEdge",V(s*5.61,4.05,2.27),V(s*3.38,2.49,3.34),V(s*1.38,1.98,2.52),C(67,44,102),l)
 q.b("FinVein",V(s*1.52,2.51,.1),V(s*5.16,3.86,2.22),.065,starlight,l,true)
 for i=1,4 do q.b("VoidGill",V(s*1.62,3.25,-.93+i*.43),V(s*1.71,2.38,-.77+i*.43),.075,amethyst,q.t,true) end
end
for i=1,6 do q.sp("DorsalBlade",V(0,4.02,-.46+i*.58),V(0,5.03-i*.08,.03+i*.58),.68,amethyst,q.t) end
t=q.l("Tail",V(0,2.23,4.25))
tube(q,"LeviathanTail",{V(0,2.23,4.25),V(.48,2.33,5.73),V(1.22,2.62,6.9)},{.58,.43,.2},midnight,t)
for _,s in {-1,1} do q.tri("TailFluke",V(1.22,2.62,6.9),V(1.22+s*2.8,3.04,8.13),V(1.22+s*.47,2.6,7.88),amethyst,t) end
table.insert(models,q.m)
-- Celestial Dragon: pale long-necked dragon with branching antlers and sky sails.
q=factory(names[4],V(2.8,2.4,4.5),V(0,2.6,.3),pearl)
body(q,pearl,2.8); legs(q,pearl,false,false)
local neck=q.l("Neck",V(0,3.32,-1.31))
tube(q,"SkyNeck",{V(0,3.32,-1.31),V(0,4.38,-1.92),V(0,5.72,-2.22)},{.74,.59,.53},pearl,neck)
h=reptileHead(q,"Head",V(0,5.83,-2.35),1.0,pearl,true)
for _,s in {-1,1} do
 local p={V(s*.5,6.6,-1.97),V(s*.82,7.48,-1.48),V(s*1.42,8.13,-.81)}
 chain(q,"Antler",p,{.27,.18,.025},sunlight,h)
 q.sp("AntlerBranch",p[2],p[2]+V(s*.67,.29,-.58),.17,sunlight,h)
 q.sp("AntlerBranch",p[1]:Lerp(p[2],.5),V(s*1.34,7.61,-2.37),.14,sunlight,h)
 for i=1,3 do q.sp("CloudMane",V(s*.45,5.53-i*.29,-1.9),V(s*.91,5.32-i*.38,-1.11),.49,starlight,neck) end
end
batWings(q,sunlight,C(122,188,213),false,5.9)
t=q.l("Tail",V(0,2.57,2.25))
tube(q,"CloudTail",{V(0,2.57,2.25),V(.31,2.08,3.99),V(1.51,1.42,5.41),V(3.13,1.63,5.84),V(3.73,2.1,5.08)},{.63,.49,.33,.18,.025},pearl,t)
for i=1,6 do q.sp("SkyCrest",V(0,3.7,-.33+i*.48),V(0,4.32,.02+i*.48),.35,sunlight,q.t) end
table.insert(models,q.m)
-- Seraph Beast: ivory lion with three stacked wing pairs and a radiant halo.
q=factory(names[5],V(2.8,2.5,4.3),V(0,2.6,.3),pearl)
body(q,pearl,2.9); legs(q,pearl,false,false)
h=reptileHead(q,"Head",V(0,3.78,-1.87),1.05,pearl,false)
for i=0,13 do
 local a=i*math.pi/7
 q.sp("RadiantMane",V(math.cos(a)*.97,3.9+math.sin(a)*.98,-1.34),V(math.cos(a)*1.58,3.9+math.sin(a)*1.61,-.89),.76,sunlight,h)
end
featherWings(q,1,5.96,pearl,sunlight,4.56)
featherWings(q,2,4.98,pearl,sunlight,3.37)
featherWings(q,3,3.83,pearl,sunlight,2.45)
ring(q,"SeraphHalo",V(0,6.06,-1.63),1.0,sunlight,h,false)
star(q,"ChestStar",V(0,3.26,-2.0),.49,sunlight,q.t)
t=q.l("Tail",V(0,2.6,2.18))
chain(q,"SeraphTail",{V(0,2.6,2.18),V(.73,2.48,3.4),V(1.54,3.07,3.86)},{.29,.23,.1},pearl,t)
q.sp("TailSun",V(1.54,3.07,3.86),V(1.74,3.67,3.83),.56,sunlight,t)
table.insert(models,q.m)
-- World Serpent: broad encircling coil, rising S-neck and ancient crown.
q=factory(names[6],V(5.1,2.5,5.1),V(0,1.8,.7),jade)
local pts,radii={},{}
for i=0,27 do
 local f=i/27; local a=math.rad(-90+f*343); local r=3.65-f*.45
 pts[i+1]=V(math.cos(a)*r,1.01-f*.3,1.18+math.sin(a)*r)
 radii[i+1]=1.0-f*.72
end
pts[#pts+1]=V(-1.21,.76,-2.85); radii[#radii+1]=.025
t=q.l("CoiledTail",pts[1]); tube(q,"WorldCoil",pts,radii,jade,t)
for i=2,26 do
 local p=pts[i]+V(0,radii[i]*.88,0)
 q.sp("CoilScale",p,p+V(0,.32,.4),.7,brass,t)
 if i%4==0 then q.sp("WorldSpine",p,p+V(0,.84,.25),.28,sunlight,t) end
end
neck=q.l("Neck",V(0,1.42,-2.47))
pts={V(0,1.12,-2.47),V(0,2.47,-2.64),V(0,3.89,-2.02),V(0,5.23,-1.38),V(0,6.21,-1.85)}
tube(q,"SerpentNeck",pts,{1.0,.94,.81,.68,.65},jade,neck)
for j=0,11 do
 local a=j/11*4; local ix=math.min(math.floor(a)+1,4); local p=pts[ix]:Lerp(pts[ix+1],a-(ix-1)); local r=1-j/11*.35
 q.seg("GoldenBelly",p+V(0,-.23,-r*.85),p+V(0,.23,-r*.85),r*1.35,.2,r*1.31,.2,ivory,neck)
end
h=reptileHead(q,"Head",V(0,6.3,-2.0),1.26,jade,false)
for _,s in {-1,1} do
 q.sp("CrownProng",V(s*.55,7.17,-1.64),V(s*1.12,8.33,-.93),.45,sunlight,h)
 for i=1,4 do q.sp("CrownFrill",V(s*.54,6.8-i*.23,-1.19),V(s*(1.25+i*.14),6.75-i*.22,-.51),.57,brass,h) end
end
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
 local at=np.Position+np.RightVector*(i*20)
 m:PivotTo(CF(at.X,floor+root.Position.Y-low+.025,at.Z)*np.Rotation)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
 m:SetAttribute("Purpose","Sculpted celestial art prototype; no gameplay integration")
 m.Parent=workspace; print("Created",m.Name,#m:GetDescendants())
end
game:GetService("Selection"):Set({})
local cf=models[1]:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(11,6,-23),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)
