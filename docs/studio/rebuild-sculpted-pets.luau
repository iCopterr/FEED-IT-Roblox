-- Editor-only sculpted concept batch. Existing art stays untouched.
assert(not game:GetService("RunService"):IsRunning(),"Use Edit mode")
local reference=assert(workspace:FindFirstChild("IceDragon_V2"),"IceDragon_V2 missing")
local names={"EmberDrake_V2","FrostWolf_V2","StormGriffin_V2","LavaGolem_V2","ThunderSerpent_V2"}
for _,n in names do assert(not workspace:FindFirstChild(n),n.." already exists") end
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
local models={}
-- EMBER DRAKE: muscular chest, raised S-neck, swept bat wings, long armored tail.
do
    local q=factory(names[1],V(3.0,2.8,4.5),V(0,3.3,0),coal); local t=q.t
    q.seg("Chest",V(0,3.55,-1.8),V(0,3.22,.55),2.8,3.0,3.3,2.65,slate,t)
    q.seg("Haunch",V(0,3.22,.55),V(0,2.8,2.45),3.3,2.65,1.7,1.6,coal,t)
    local h=q.l("Head",V(0,4.4,-1.65))
    local neck={V(0,4,-1.62),V(0,5.6,-2.16),V(0,6.9,-2.7),V(0,7.1,-3.6)}
    for i=1,3 do q.seg("Neck"..i,neck[i],neck[i+1],1.75-i*.18,1.7-i*.15,1.57-i*.18,1.55-i*.15,slate,h) end
    q.seg("Skull",V(0,7.08,-3.35),V(0,6.91,-4.66),1.7,1.4,1.2,.82,coal,h)
    q.seg("Snout",V(0,6.92,-4.58),V(0,6.6,-5.72),1.2,.78,.76,.42,slate,h)
    q.seg("Jaw",V(0,6.35,-4),V(0,6.05,-5.52),1.0,.22,.71,.17,coal,h)
    for i=1,5 do q.d("ThroatScale"..i,V(1.1-i*.07,.36,.2),CF(0,4.1+i*.45,-2.52-i*.13),red,h) end
    for _,s in {-1,1} do
        local n=s<0 and "Left" or "Right"
        q.d(n.."Eye",V(.075,.22,.46),CF(s*.72,7.14,-4.39),gold,h,nil,true)
        q.b(n.."Brow",V(s*.74,7.37,-3.94),V(s*.64,7.28,-4.75),.18,slate,h)
        q.sp(n.."HornBase",V(s*.65,7.57,-3.38),V(s*1.17,8.27,-2.25),.53,coal,h)
        q.sp(n.."HornTip",V(s*1.05,8.08,-2.51),V(s*1.78,8.75,-1.33),.32,C(196,143,100),h)
        q.sp(n.."JawHorn",V(s*.7,6.65,-3.45),V(s*1.53,7.0,-2.2),.32,slate,h)
        for i=1,4 do q.sp(n.."Tooth"..i,V(s*(.46-i*.025),6.54,-4.3-i*.28),V(s*(.46-i*.025),6.23,-4.35-i*.28),.12,snow,h) end
        for _,front in {true,false} do
            local z=front and -1.35 or 1.45; local a=V(s*1.2,3.2,z)
            local b=V(s*1.69,1.72,z+(front and .3 or -.52)); local c=V(s*1.61,.45,z-.2)
            local l=q.l(n..(front and "FrontLeg" or "HindLeg"),a)
            q.seg("UpperLeg",a,b,.91,1.03,.61,.68,slate,l); q.seg("Shin",b,c,.62,.65,.4,.43,coal,l)
            q.seg("Paw",c+V(0,-.15,.2),c+V(0,-.15,-.76),.72,.38,.86,.23,slate,l)
            for j=1,3 do q.sp("Claw",c+V((j-2)*.25,-.1,-.63),c+V((j-2)*.27,-.31,-1.1),.18,C(198,149,112),l) end
        end
        local a,b,tip=V(s*1.3,4.24,-.7),V(s*3.45,6.0,.1),V(s*8.4,6.8,2.4)
        local w=q.l(n.."Wing",a)
        q.seg("WingArm",a,b,.52,.55,.33,.36,coal,w)
        q.b("LeadingEdge",b,tip,.23,slate,w)
        local ends={tip,V(s*7.3,4.1,4.2),V(s*4.8,3.1,4.7),V(s*2.4,2.95,3.6),V(s*1.31,3.4,1.6)}
        for i=1,4 do
            local mid=ends[i]:Lerp(ends[i+1],.5):Lerp(b,.22)
            q.tri("SailA",b,ends[i],mid,i%2==0 and red or C(192,65,30),w)
            q.tri("SailB",b,mid,ends[i+1],red,w)
            q.b("WingFinger",b,ends[i],.12,coal,w)
            q.b("LavaVein",b:Lerp(ends[i],.25)+V(0,.07,0),ends[i],.037,fire,w,true)
        end
        q.tri("WingRoot",a,b,ends[5],red,w); q.sp("WingThumb",b,b+V(s*.16,.85,-.2),.27,C(201,142,96),w)
        for i=1,4 do
            q.sp("FlankArmor",V(s*1.54,3.8,-.9+(i-1)*.79),V(s*1.72,2.8,-.5+(i-1)*.79),.63,slate,t)
            q.b("FlankHeat",V(s*1.57,3.51,-1.07+i*.74),V(s*1.61,3.0,-.9+i*.74),.045,fire,t,true)
        end
    end
    local tail=q.l("Tail",V(0,2.8,2.15))
    local pts={V(0,2.8,2.1),V(.3,2.26,3.8),V(.9,1.82,5.45),V(1.9,1.9,6.83),V(3.14,2.55,7.83),V(4.1,3.1,8.4)}
    for i=1,5 do q.seg("Tail"..i,pts[i],pts[i+1],1.32-(i-1)*.24,1.1-(i-1)*.18,1.32-i*.24,1.1-i*.18,coal,tail) end
    q.sp("TailBlade",pts[6],pts[6]+V(1.0,.6,.65),.8,red,tail)
    q.b("TailHeat",pts[5]+V(0,.17,0),pts[6]+V(.4,.4,.25),.075,fire,tail,true)
    for i=1,6 do local a=V(0,4.9-i*.19,-1.5+i*.68); q.sp("Dorsal",a,a+V(0,1.1-i*.09,.5),.48,red,t); q.b("DorsalHeat",a,a+V(0,.95-i*.08,.4),.055,fire,t,true) end
    table.insert(models,q.m)
end
-- FROST WOLF: long-legged, deep-chested canine with an angular ice mane.
do
    local q=factory(names[2],V(2.3,2.5,4.1),V(0,3.25,0),blue); local t=q.t
    q.seg("Chest",V(0,3.5,-1.6),V(0,3.22,.35),2.45,2.95,2.1,2.3,ice,t)
    q.seg("LeanFlank",V(0,3.22,.35),V(0,3.0,2.08),2.1,2.3,1.65,1.8,blue,t)
    local h=q.l("Head",V(0,4.2,-1.3))
    q.seg("Neck",V(0,3.65,-1.48),V(0,5.4,-2.08),1.8,1.95,1.36,1.47,ice,h)
    q.seg("Skull",V(0,5.44,-1.91),V(0,5.33,-3.34),1.56,1.55,1.13,1.0,snow,h)
    q.seg("Muzzle",V(0,5.2,-3.17),V(0,4.88,-4.56),1.02,.77,.61,.39,ice,h)
    q.seg("Jaw",V(0,4.64,-3.05),V(0,4.51,-4.33),.83,.24,.53,.17,blue,h)
    q.d("Nose",V(.58,.33,.27),CF(0,4.94,-4.59),navy,h)
    for _,s in {-1,1} do
        local n=s<0 and "Left" or "Right"
        q.d(n.."Eye",V(.07,.18,.4),CF(s*.69,5.58,-2.99),cyan,h,nil,true)
        q.b(n.."Brow",V(s*.73,5.83,-2.73),V(s*.55,5.68,-3.46),.14,blue,h)
        local e=q.l(n.."Ear",V(s*.54,5.99,-2.1))
        q.sp(n.."EarShape",V(s*.58,5.88,-2.1),V(s*.91,7.19,-1.9),.67,ice,e)
        q.tri(n.."EarInside",V(s*.4,6.04,-2.43),V(s*.82,6.98,-2.12),V(s*.85,6.1,-2.37),navy,e)
        for i=1,5 do
            local a=V(s*(.79+i*.045),5.48-i*.25,-1.76+i*.11)
            q.sp("ManeCrystal",a,a+V(s*(.62+i*.065),-.48,1.1),.53,i%2==0 and snow or ice,h)
        end
        for i=1,3 do q.sp("CheekTuft",V(s*.72,5.1-i*.13,-2.12),V(s*1.31,4.79-i*.16,-1.34),.4,snow,h) end
        for _,front in {true,false} do
            local z=front and -1.16 or 1.5; local a=V(s*.82,3.25,z)
            local b=V(s*1.04,1.72,z+(front and .17 or -.65)); local c=V(s*1.02,.44,z-.13)
            local l=q.l(n..(front and "FrontLeg" or "HindLeg"),a)
            q.seg("UpperLeg",a,b,.8,.96,.48,.59,ice,l)
            q.seg("LowerLeg",b,c,.47,.55,.3,.35,blue,l)
            q.seg("Paw",c+V(0,-.11,.23),c+V(0,-.11,-.71),.55,.39,.75,.23,snow,l)
            for j=1,3 do q.sp("Claw",c+V((j-2)*.23,-.1,-.58),c+V((j-2)*.25,-.25,-.92),.12,navy,l) end
        end
        for i=1,3 do q.sp("ShoulderFur",V(s*1.09,4.28,-1.2+i*.4),V(s*1.4,3.34,-.56+i*.44),.59,snow,t) end
    end
    local l=q.l("Tail",V(0,3.13,1.95))
    local pts={V(0,3.13,1.94),V(.26,2.73,3.07),V(.6,2.12,4.19),V(.89,1.56,5.08),V(1.0,1.25,5.95)}
    for i=1,4 do q.seg("BushyTail",pts[i],pts[i+1],i==1 and .7 or 1.15,i==1 and .75 or 1.27,i==4 and .12 or 1.15,i==4 and .15 or 1.27,i>=3 and snow or ice,l) end
    for i=1,4 do q.sp("TailFur",pts[i]+V(0,.36,0),pts[i+1]+V(0,.38,.2),.52,snow,l) end
    table.insert(models,q.m)
end
-- STORM GRIFFIN: eagle profile, tall forequarters, overlapping flight feathers.
do
    local q=factory(names[3],V(2.6,2.55,4.0),V(0,3.0,0),navy); local t=q.t
    q.seg("Breast",V(0,3.45,-1.62),V(0,3.08,.3),2.7,2.9,2.63,2.37,blue,t)
    q.seg("LionRump",V(0,3.08,.3),V(0,2.75,2.13),2.63,2.37,1.68,1.79,navy,t)
    local h=q.l("Head",V(0,4.1,-1.29))
    q.seg("EagleNeck",V(0,3.78,-1.45),V(0,5.75,-2.07),1.8,1.94,1.23,1.44,snow,h)
    q.seg("Skull",V(0,5.77,-1.95),V(0,5.58,-3.1),1.39,1.47,1.18,1.03,snow,h)
    q.seg("Beak",V(0,5.53,-3.06),V(0,5.3,-4.0),1.04,.73,.59,.42,C(205,166,83),h)
    q.sp("BeakHook",V(0,5.41,-3.86),V(0,4.64,-4.04),.59,gold,h)
    for _,s in {-1,1} do
        local n=s<0 and "Left" or "Right"
        q.d(n.."Eye",V(.07,.23,.36),CF(s*.62,5.88,-2.85),gold,h,nil,true)
        q.b("Brow",V(s*.71,6.11,-2.5),V(s*.55,6.0,-3.21),.2,blue,h)
        for i=1,4 do q.f("CrestFeather",V(s*.3,6.17,-2.11+i*.1),V(s*(.65+i*.1),6.75+i*.14,-.97+i*.13),.35,i%2==0 and ice or snow,h) end
        for i=1,5 do q.f("NeckFeather",V(s*.64,5.55-i*.28,-1.87),V(s*(1.0+i*.055),4.82-i*.3,-.96),.53,snow,h) end
        for _,front in {true,false} do
            local z=front and -1.18 or 1.47; local a=V(s*.93,3.1,z); local b=V(s*1.12,1.65,z+(front and .16 or -.49)); local c=V(s*1.05,.4,z-.16)
            local l=q.l(n..(front and "FrontLeg" or "HindLeg"),a)
            q.seg("UpperLeg",a,b,.83,1.0,.49,.58,front and snow or blue,l)
            q.seg("Shin",b,c,.48,.58,.29,.35,front and C(175,148,79) or navy,l)
            if front then
                for j=1,3 do local e=c+V((j-2)*.38,-.17,-.77); q.b("Toe",c,e,.16,C(182,153,77),l); q.sp("Talon",e,e+V((j-2)*.06,-.13,-.39),.17,navy,l) end
            else q.seg("Paw",c+V(0,-.1,.22),c+V(0,-.1,-.65),.59,.39,.75,.22,blue,l) end
        end
        local a,b,c=V(s*1.17,4.03,-.3),V(s*3.13,5.68,.28),V(s*6.82,6.32,1.6)
        local w=q.l(n.."Wing",a)
        q.seg("WingUpper",a,b,.6,.65,.38,.4,navy,w); q.seg("WingOuter",b,c,.39,.42,.1,.15,blue,w)
        for i=1,9 do
            local start=b:Lerp(c,(i-1)/9)
            local tip=start+V(s*(.48+i*.06),-1.18-(i%3)*.13,2.95-(i-1)*.12)
            q.f("Primary"..i,start,tip,.82,i%2==0 and blue or ice,w)
        end
        for i=1,6 do
            local start=a:Lerp(b,i/7)
            q.f("Secondary"..i,start,start+V(s*.31,-.65,2.2),.72,snow,w)
        end
        q.tri("WingWebOuter",b,c,c+V(s*.85,-1.3,1.95),blue,w)
        q.tri("WingWebMiddle",b,c+V(s*.85,-1.3,1.95),b+V(s*.6,-1.5,2.8),blue,w)
        q.tri("WingWebInner",a,b,b+V(s*.6,-1.5,2.8),navy,w)
        for i=1,7 do local start=b:Lerp(c,i/8); q.f("Coverts"..i,start+V(0,.12,0),start+V(s*.13,-.14,1.02),.6,snow,w) end
        local pts={a+V(0,.35,0),b+V(0,.25,0),b:Lerp(c,.45)+V(0,.2,.13),b:Lerp(c,.37)+V(0,.2,.5),c}
        for i=1,4 do q.b("LightningEdge",pts[i],pts[i+1],.06,gold,w,true) end
    end
    local l=q.l("Tail",V(0,2.78,1.93))
    local pts={V(0,2.8,1.9),V(.26,2.19,3.3),V(.85,2.05,4.42),V(1.4,2.78,5.1)}
    for i=1,3 do q.seg("Tail",pts[i],pts[i+1],.38,.38,.3,.3,navy,l) end
    for i=1,4 do q.f("TailPlume",pts[4],pts[4]+V((i-2.5)*.36,.72,1.0),.41,ice,l) end
    table.insert(models,q.m)
end
-- LAVA GOLEM: asymmetric jagged armor, lava gaps and massive hanging fists.
do
    local q=factory(names[4],V(3.5,3.7,2.5),V(0,4.0,0),coal); local t=q.t
    q.seg("Core",V(0,2.44,0),V(0,5.49,0),2.44,1.8,3.62,2.52,coal,t)
    q.d("MoltenHeart",V(1.45,1.6,.14),CF(0,4.35,-1.88),fire,t,nil,true)
    q.d("HeartCenter",V(.7,.91,.16),CF(0,4.4,-1.99)*CFrame.Angles(0,0,math.rad(45)),gold,t,nil,true)
    for _,s in {-1,1} do
        local n=s<0 and "Left" or "Right"
        q.seg("ChestPlate",V(s*.97,3.54,-1.01),V(s*1.35,5.5,-.9),.88,.8,1.18,.85,slate,t)
        local a,b,c=V(s*1.69,5.2,0),V(s*2.94,3.6,.02),V(s*3.16,1.77,-.27)
        local arm=q.l(n.."Arm",a)
        q.seg("UpperArm",a,b,1.37,1.49,1.01,1.15,coal,arm)
        q.seg("Forearm",b+V(0,-.13,0),c,1.13,1.18,1.66,1.45,slate,arm)
        q.seg("ShoulderBoulder",a+V(-s*.3,.12,0),a+V(s*.84,.27,0),1.77,1.6,1.4,1.4,slate,arm)
        q.seg("Fist",c+V(0,.33,0),c+V(0,-.65,-.14),1.83,1.73,1.56,1.59,coal,arm)
        q.b("ElbowHeat",b+V(-.5,0,-.49),b+V(.5,0,-.49),.13,fire,arm,true)
        for i=1,3 do q.seg("Finger",c+V((i-2)*.48,-.08,-.9),c+V((i-2)*.48,-.62,-1.0),.35,.42,.32,.34,slate,arm) end
        for i=1,3 do q.sp("ShoulderShard",a+V(s*(i*.25),.55,.1),a+V(s*(.6+i*.29),1.35+i*.2,.25),.66,coal,arm) end
        local la=V(s*.93,2.69,0); local lb=V(s*1.19,1.51,-.05); local lc=V(s*1.28,.39,-.26)
        local leg=q.l(n.."Leg",la)
        q.seg("Thigh",la,lb,1.05,1.25,1.2,1.15,slate,leg)
        q.seg("Shin",lb+V(0,-.13,0),lc,1.05,1.1,.89,.91,coal,leg)
        q.seg("Foot",lc+V(0,-.09,.37),lc+V(0,-.09,-1.02),1.4,.6,1.54,.46,slate,leg)
        q.b("KneeGlow",lb+V(-.45,0,-.58),lb+V(.45,0,-.58),.1,fire,leg,true)
    end
    local h=q.l("Head",V(0,5.63,-.02))
    q.seg("Skull",V(0,5.67,0),V(0,7.16,.1),1.68,1.45,1.44,1.35,slate,h)
    q.b("HeavyBrow",V(-.93,6.81,-.73),V(.93,6.81,-.73),.25,coal,h)
    for _,s in {-1,1} do q.d("Eye",V(.43,.16,.05),CF(s*.44,6.58,-.77),gold,h,nil,true); q.sp("HeadCrag",V(s*.56,7.0,.1),V(s*.86,7.8,.39),.59,coal,h) end
    q.b("Mouth",V(-.46,6.09,-.79),V(.46,6.09,-.79),.09,fire,h,true)
    for i=1,3 do q.d("AbdominalPlate",V(2.07-i*.14,.38,.42),CF(0,3.48-i*.42,-1.1),slate,t,"WedgePart") end
    for i=1,4 do q.sp("BackCrag",V((i-2.5)*.73,5.1,1.03),V((i-2.5)*.84,6.1+(i%2)*.4,1.63),.72,coal,t) end
    table.insert(models,q.m)
end
-- THUNDER SERPENT: long S-neck and low sweeping coil, no arms or legs.
do
    local q=factory(names[5],V(1.6,2.1,1.7),V(0,2.0,0),navy); local t=q.t
    local tail=q.l("Tail",V(0,1.64,.48))
    local pts={V(0,1.64,.4),V(1.57,.95,1.47),V(2.7,.77,3.21),V(1.65,.71,4.68),V(-.36,.68,4.77),V(-2.18,.61,3.57),V(-2.53,.55,1.76),V(-3.45,.49,.37),V(-4.95,.43,.15)}
    for i=1,#pts-1 do
        local w=1.47-(i-1)*.15
        q.seg("Coil"..i,pts[i],pts[i+1],w,w*.82,w-.15,(w-.15)*.82,i%2==0 and blue or navy,tail)
        q.b("DorsalCurrent",pts[i]+V(0,w*.43,0),pts[i+1]+V(0,(w-.15)*.43,0),.055,gold,tail,true)
    end
    q.sp("LightningTail",pts[#pts],pts[#pts]+V(-1.07,.25,-.15),.43,gold,tail)
    local h=q.l("Head",V(0,2.72,-.08))
    local neck={V(0,1.7,.3),V(-.37,3.18,-.35),V(-.22,4.81,-.42),V(.34,6.22,-.92),V(.53,7.22,-1.83)}
    for i=1,4 do
        q.seg("Neck"..i,neck[i],neck[i+1],1.45-i*.13,1.35-i*.09,1.32-i*.13,1.26-i*.09,navy,h)
        for j=1,3 do
            local a=neck[i]:Lerp(neck[i+1],j/4)+V(0,0,-.58)
            q.d("BellyScute",V(1.0-i*.1,.17,.16),CF(a),C(190,163,91),h)
        end
    end
    q.seg("Cranium",V(.53,7.25,-1.72),V(.53,7.11,-3.17),1.45,1.16,1.08,.73,blue,h)
    q.seg("Snout",V(.53,7.1,-3.1),V(.53,6.81,-4.06),1.08,.61,.68,.37,navy,h)
    q.seg("Jaw",V(.53,6.57,-2.9),V(.53,6.37,-3.92),.89,.18,.6,.14,violet,h)
    for _,s in {-1,1} do
        local n=s<0 and "Left" or "Right"
        q.d(n.."Eye",V(.07,.18,.42),CF(.53+s*.63,7.36,-2.9),gold,h,nil,true)
        q.sp("Fang",V(.53+s*.36,6.8,-3.45),V(.53+s*.33,6.13,-3.74),.18,snow,h)
        q.sp("CrownHorn",V(.53+s*.48,7.65,-1.99),V(.53+s*1.24,8.72,-.77),.4,ice,h)
        -- Three fins form a continuous flared hood around the neck.
        local hood=q.l(n.."Hood",V(s*.45,3.7,-.18))
        local a,b,c,d=V(s*.33,3.02,-.21),V(s*.44,6.82,-1.21),V(s*2.23,6.12,.18),V(s*1.57,3.86,.36)
        q.tri("HoodUpper",a,b,c,violet,hood); q.tri("HoodLower",a,c,d,blue,hood)
        q.b("HoodEdge",b,c,.12,ice,hood); q.b("HoodLowerEdge",c,d,.11,ice,hood)
        local bolt={b:Lerp(c,.2),b:Lerp(c,.72)+V(0,-.25,-.06),a:Lerp(c,.6)+V(0,.03,-.09),a:Lerp(d,.57)}
        for i=1,3 do q.b("HoodLightning",bolt[i],bolt[i+1],.065,gold,hood,true) end
        for i=1,3 do q.sp("FinSpike",b:Lerp(c,i/4),b:Lerp(c,i/4)+V(s*.43,.51,.11),.23,ice,hood) end
    end
    table.insert(models,q.m)
end
-- Stage the new designs in a parallel display row; retain all originals.
local origin=reference:GetPivot()
local ground=reference.PrimaryPart.Position.Y-reference.PrimaryPart.Size.Y/2-reference.Humanoid.HipHeight
local offsets={0,23,45,68,88}
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("SculptedPetRebuild","Build five sculpted elemental pet concepts")
for i,m in models do
    local low=math.huge
    for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y)
        end end end
    end end
    local root=m.PrimaryPart
    m.Humanoid.HipHeight=math.max(0,root.Position.Y-root.Size.Y/2-low+.025)
    local pos=origin.Position+origin.RightVector*offsets[i]-origin.LookVector*25
    m:PivotTo(CF(pos.X,ground+root.Position.Y-low+.025,pos.Z)*origin.Rotation)
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
    m:SetAttribute("Purpose","Sculpted art prototype; no gameplay integration")
    m.Parent=workspace
    print("Created",m.Name,m:GetPivot().Position)
end
game:GetService("Selection"):Set(models)
local focus=models[1]:GetPivot().Position+V(0,2,1)
workspace.CurrentCamera.CFrame=CFrame.lookAt(focus+V(16,8,-22),focus)
workspace.CurrentCamera.Focus=CF(focus)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
