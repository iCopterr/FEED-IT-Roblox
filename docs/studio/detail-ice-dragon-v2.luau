-- Editor-only detail pass; preserves the rig, pose, placement and existing surfaces.
assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
local m=assert(workspace:FindFirstChild("IceDragon_V2"), "IceDragon_V2 missing")
assert(not m:FindFirstChild("IceDetailPass"), "Detail pass already applied")
for _,name in {"Torso","Head","LeftWing","RightWing","Tail"} do
    assert(m:FindFirstChild(name), "Missing rig limb: "..name)
end
local history=game:GetService("ChangeHistoryService")
local rec=history:TryBeginRecording("IceDragonDetails", "Detail ice dragon armor and crystals")
local backup=m:Clone()
backup.Name="IceDragon_V2_BeforeDetails_"..tostring(os.time())
backup.Parent=game:GetService("ServerStorage")
local folder=Instance.new("Folder")
folder.Name="IceDetailPass"
folder.Parent=m
local V,CF=Vector3.new,CFrame.new
local scale=m:GetScale()
local origin=m.Torso.CFrame*CF(0,-3.1*scale,0)
local ice=Color3.fromRGB(193,233,247)
local snow=Color3.fromRGB(236,252,255)
local blue=Color3.fromRGB(49,115,166)
local dark=Color3.fromRGB(25,63,108)
local cyan=Color3.fromRGB(93,222,248)
local function part(n,size,cf,color,limb,class,glow)
    local p=Instance.new(class or "Part")
    p.Name,p.Size=n,size*scale
    p.CFrame=origin*CF(cf.Position*scale)*cf.Rotation
    p.Color=color
    p.Material=glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
    p.Anchored,p.CanCollide,p.Massless=false,false,true
    p.Parent=folder
    local w=Instance.new("WeldConstraint")
    w.Name,w.Part0,w.Part1,w.Parent="DetailWeld",limb,p,p
    return p
end
local function line(n,a,b,width,color,limb,glow)
    return part(n,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,limb,nil,glow)
end
local function shard(n,a,b,width,limb,color)
    local cf=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0)
    part(n.."FacetA",V(width*.55,(b-a).Magnitude,width),cf,color or ice,limb,"WedgePart")
    part(n.."FacetB",V(width*.55,(b-a).Magnitude,width),cf*CFrame.Angles(0,math.pi,0),snow,limb,"WedgePart")
end
-- Only recolor named authored anatomy. User-authored surface/material edits survive.
for _,p in m:GetChildren() do if p:IsA("BasePart") and p.Transparency<1 then
    if p.Name:find("WingFinger") or p.Name:find("WingArm") then p.Color=dark
    elseif p.Name:find("Sail") then p.Color=p.Name:find("Sail2") and ice or snow
    elseif p.Name:find("BackSpine") or p.Name:find("CrownHorn") then p.Color=ice
    elseif p.Name:find("ChestSide") or p.Name:find("HaunchSide") then
        p.Color=p.Name:find("Side1") and blue or Color3.fromRGB(116,178,209)
    end
end end
local head,torso,tail=m.Head,m.Torso,m.Tail
for _,s in {-1,1} do
    local side=s==-1 and "Left" or "Right"
    -- Brow ridge, cheek crystals and short gill marks define the face.
    line(side.."EyeRim",V(s*.74,7.87,-3.93),V(s*.64,7.71,-4.58),.13,dark,head)
    part(side.."EyeHighlight",V(.055,.075,.13),CF(s*.765,7.67,-4.23),snow,head,nil,true)
    part(side.."Nostril",V(.13,.085,.08),CF(s*.25,7.34,-5.39),dark,head)
    shard(side.."CheekCrystal",V(s*.67,7.09,-3.21),V(s*1.47,7.78,-2.18),.34,head)
    shard(side.."TempleCrystal",V(s*.62,7.71,-3.09),V(s*1.09,8.28,-2.31),.24,head)
    for i=1,3 do
        line(side.."Gill"..i,V(s*.71,7.4-i*.16,-3.41),V(s*.72,7.29-i*.16,-3.14),.045,cyan,head,true)
    end
    -- Overlapping shoulder and flank plates create a readable armor rhythm.
    for i=1,4 do
        local z=-1.05+(i-1)*.83
        part(side.."ScaleShadow"..i,V(.16,.92,.77),CF(s*1.5,3.6-i*.08,z)*CFrame.Angles(0,0,s*math.rad(-15)),dark,torso,"WedgePart")
        part(side.."ScalePlate"..i,V(.18,.78,.68),CF(s*1.61,3.7-i*.08,z-.035)*CFrame.Angles(0,0,s*math.rad(-15)),ice,torso,"WedgePart")
    end
    shard(side.."ShoulderCrystal",V(s*1.35,4.2,-1.03),V(s*2.0,5.22,-.38),.47,torso)
    local wing=m[side.."Wing"]
    local elbow=V(s*3.35,6.05,.2)
    local tip=V(s*8.7,7.25,2.2)
    line(side.."FrostLeadingEdge",elbow+V(0,.15,0),tip+V(0,.07,0),.085,cyan,wing,true)
    local ends={V(s*7.8,4.55,4.0),V(s*5.3,3.3,4.4),V(s*2.75,3.05,3.25)}
    for i,p in ends do
        line(side.."WingVein"..i,elbow:Lerp(p,.2)+V(0,.05,0),p,.045,cyan,wing)
        shard(side.."WingIceTip"..i,p,p+V(s*.27,-.46,.38),.24,wing)
    end
    for i=1,3 do
        local a=elbow:Lerp(tip,.24+i*.17)
        shard(side.."WingCrest"..i,a,a+V(s*.17,.48+(4-i)*.1,.2),.19,wing)
    end
end
-- Pale overlapping throat plates follow the existing neck curve.
local plates={V(0,4.1,-2.19),V(0,4.55,-2.52),V(0,5.05,-2.78),V(0,5.59,-2.94),V(0,6.12,-3.03),V(0,6.61,-3.27)}
for i,p in plates do
    part("ThroatPlate"..i,V(1.13-i*.065,.42,.18),CF(p)*CFrame.Angles(math.rad(-16),0,0),i%2==0 and snow or ice,head)
end
shard("BreastCrystal",V(0,3.7,-1.89),V(0,4.33,-1.99),.5,torso,cyan)
for i=1,4 do
    local a=V(0,4.8-(i-1)*.22,-1.3+(i-1)*.87)
    line("SpineFrostEdge"..i,a+V(0,.04,0),a+V(0,.93-(i-1)*.11,.51),.065,cyan,torso,true)
end
for i,p in {V(.15,2.9,3.65),V(.5,2.35,5.23),V(1.24,2.19,6.8),V(2.35,2.58,7.9)} do
    shard("TailCrown"..i,p,p+V(.09,.65-i*.07,.39),.29,tail)
end
m:SetAttribute("DetailPass","Layered armor / frosted wing ribs / facial crystals")
game:GetService("Selection"):Set({m})
local f=m:GetPivot().Position+V(0,2*scale,scale)
workspace.CurrentCamera.CFrame=CFrame.lookAt(f+V(18,8,-23)*scale,f)
workspace.CurrentCamera.Focus=CF(f)
if rec then history:FinishRecording(rec,Enum.FinishRecordingOperation.Commit) end
print("Detail pass complete",#folder:GetChildren(),"new parts; backup",backup:GetFullName())
