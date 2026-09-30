-- Reference-inspired Kitsune; execute in Studio Edit mode.
assert(not game:GetService("RunService"):IsRunning(),"Edit mode required")
local previous=assert(workspace:FindFirstChild("Kitsune_V2"),"Previous Kitsune required")
assert(not workspace:FindFirstChild("Kitsune_V3"),"Already built")
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
local cream,white,red,dark,amber=C(243,226,199),C(255,247,227),C(220,42,36),C(39,23,25),C(255,138,28)
local q=factory("Kitsune_V3",V(2.25,2.1,3.4),V(0,2.5,.3),cream)
local m,t=q.m,q.t
local function oval(n,pos,size,col,limb,rotation)
    local p=q.d(n,size,CF(pos)*(rotation or CF()),col,limb)
    p.Shape=Enum.PartType.Ball
    return p
end
local function tuft(n,a,b,w,col,l)
    local mid=a:Lerp(b,.42)
    q.seg(n.."Root",a,mid,w*.7,w*.5,w,w*.65,col,l)
    q.seg(n.."Tip",mid,b,w,w*.65,.025,.025,col,l)
end
oval("Body",V(0,2.65,.45),V(2.45,2.35,3.8),cream,t)
oval("Chest",V(0,2.9,-.95),V(2.55,2.7,1.9),white,t)
local h=q.l("Head",V(0,3.65,-1.25))
oval("HeadShape",V(0,4.28,-1.84),V(3.12,2.55,2.3),white,h)
oval("MuzzleLeft",V(-.38,3.91,-2.9),V(1.13,.8,.86),white,h)
oval("MuzzleRight",V(.38,3.91,-2.9),V(1.13,.8,.86),white,h)
oval("Chin",V(0,3.66,-2.69),V(1.38,.47,.85),cream,h)
oval("Nose",V(0,4.02,-3.34),V(.34,.23,.18),dark,h)
q.b("MouthCenter",V(0,3.99,-3.38),V(0,3.84,-3.36),.027,dark,h)
for _,s in {-1,1} do
 local side=s<0 and "Left" or "Right"
 q.b("Smile",V(0,3.84,-3.36),V(s*.29,3.77,-3.27),.025,dark,h)
 local rot=CFrame.Angles(0,math.rad(-s*19),math.rad(-s*11))
 oval(side.."EyeOutline",V(s*.88,4.48,-2.75),V(.92,.97,.18),dark,h,rot)
 oval(side.."Iris",V(s*.88,4.45,-2.86),V(.69,.78,.14),amber,h,rot)
 oval(side.."Pupil",V(s*.84,4.48,-2.95),V(.24,.64,.08),dark,h,rot)
 oval(side.."EyeSpark",V(s*.8-.09,4.7,-3.0),V(.19,.22,.06),white,h)
 q.b(side.."UpperLiner",V(s*.47,4.82,-2.81),V(s*1.29,4.92,-2.51),.085,dark,h)
 for i=1,3 do tuft(side.."CheekFur"..i,V(s*1.05,4.19-i*.15,-1.94),V(s*(1.88-i*.08),4.07-i*.29,-1.92),.69,white,h) end
 for i=1,2 do
 q.tri(side.."CheekRed"..i,V(s*1.15,4.05-i*.18,-2.61),V(s*.85,4.11-i*.18,-2.88),V(s*1.44,4.19-i*.18,-2.4),red,h)
 end
 local e=q.l(side.."Ear",V(s*.95,5.12,-1.53))
 tuft(side.."Ear",V(s*.9,5.0,-1.55),V(s*1.37,6.89,-1.49),1.22,red,e)
 q.tri(side.."EarInner",V(s*.53,5.24,-1.98),V(s*1.33,6.61,-1.68),V(s*1.46,5.4,-1.94),C(135,34,31),e)
 for i=1,3 do tuft(side.."EarFluff",V(s*(.65+i*.17),5.15,-1.98),V(s*(.53+i*.2),5.67+i*.08,-2.03),.4,white,e) end
 for i=1,4 do tuft(side.."Ruff"..i,V(s*(.25+i*.22),3.37,-1.68),V(s*(.22+i*.3),2.14+(i%2)*.2,-1.95),.83,white,t) end
 for _,front in {true,false} do
 local z=front and -1.0 or 1.6
 local a=V(s*.91,2.48,z)
 local l=q.l(side..(front and "FrontLeg" or "HindLeg"),a)
 oval("Haunch",a,V(.97,1.35,1.05),cream,l)
 q.seg("LowerLeg",a-V(0,.2,0),V(s*1.04,.44,z-.19),.65,.74,.46,.5,white,l)
 oval("Paw",V(s*1.04,.32,z-.42),V(.84,.55,1.05),white,l)
 for j=1,3 do oval("RedToe",V(s*1.04+(j-2)*.22,.24,z-.87),V(.2,.24,.24),red,l) end
 tuft("LegMark",V(s*1.04,1.18,z-.4),V(s*1.04,1.57,z-.43),.27,red,l)
 end
end
-- Forehead flame motif floats just above the forehead surface.
q.tri("ForeheadFlameLeft",V(0,4.89,-2.99),V(-.28,5.17,-2.7),V(0,5.62,-2.23),red,h)
q.tri("ForeheadFlameRight",V(0,4.89,-2.99),V(0,5.62,-2.23),V(.28,5.17,-2.7),red,h)
q.tri("FlameCenter",V(0,5.1,-2.87),V(-.1,5.26,-2.65),V(.04,5.42,-2.48),white,h)
-- Nine rounded, swept plumes distributed in depth, with hooked red tips.
for i=1,9 do
 local angle=math.rad((i-5)*20)
 local x=math.sin(angle)*4.05
 local rise=math.cos(angle)
 local a=V((i-5)*.1,2.6,1.85)
 local b=V(x*.56,2.55+rise*1.5,3.1)
 local c=V(x,2.55+rise*3.32,3.78+(i%2)*.28)
 local d=V(x*.92,2.8+rise*4.3,3.6)
 local tip=d+V(-.48, .25,-.38)
 local tail=q.l("Tail"..i,a)
 q.seg("TailStem"..i,a,b,.48,.57,.9,1.0,cream,tail)
 local axis=CFrame.lookAt((b+c)/2,c)*CFrame.Angles(math.pi/2,0,0)
 oval("TailPlume"..i,(b+c)/2,V(1.36,(c-b).Magnitude+1.1,1.29),white,tail,axis.Rotation)
 q.seg("TailUpper"..i,b:Lerp(c,.65),c,1.25,1.2,1.05,1.03,white,tail)
 q.seg("RedTail"..i,c,d,1.08,1.06,.69,.69,red,tail)
 tuft("HookTip"..i,d,tip,.72,red,tail)
 for _,s in {-1,1} do
 tuft("TailFluff"..i,b:Lerp(c,.65)+V(s*.35,0,-.25),c+V(s*.66,-.2,-.1),.55,white,tail)
 tuft("RedEdge"..i,c+V(s*.3,.08,-.36),c+V(s*.49,-.43,-.39),.4,red,tail)
 end
end
local low=math.huge
for _,p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency<1 then
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do low=math.min(low,(p.CFrame*V(x*p.Size.X/2,y*p.Size.Y/2,z*p.Size.Z/2)).Y) end end end
end end
m.Humanoid.HipHeight=m.PrimaryPart.Position.Y-m.PrimaryPart.Size.Y/2-low+.025
local old=previous:GetPivot()
local floor=previous.PrimaryPart.Position.Y-previous.PrimaryPart.Size.Y/2-previous.Humanoid.HipHeight
m:PivotTo(CF(old.Position.X,floor+2.5-low+.025,old.Position.Z)*old.Rotation)
for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Anchored=false end end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("ReferenceKitsune","Rebuild Kitsune from reference")
local archive=game:GetService("ServerStorage"):FindFirstChild("PetArtArchive") or Instance.new("Folder",game:GetService("ServerStorage"))
archive.Name="PetArtArchive"; previous.Parent=archive
m:SetAttribute("Purpose","Reference-inspired Kitsune art prototype")
m.Parent=workspace
local cf=m:GetBoundingBox()
workspace.CurrentCamera.FieldOfView=40
workspace.CurrentCamera.CFrame=CFrame.lookAt(cf.Position+V(10,4,-20),cf.Position)
workspace.CurrentCamera.Focus=CF(cf.Position)
game:GetService("Selection"):Set({})
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Created",m.Name,#m:GetDescendants())

