-- Editor-only recipe: execute through Studio MCP in Edit mode. Not a runtime script.
assert(not game:GetService("RunService"):IsRunning(), "Build in Edit mode")
assert(not workspace:FindFirstChild("Chicken_RigTest"), "Chicken_RigTest already exists")
local history = game:GetService("ChangeHistoryService")
local recording = history:TryBeginRecording("BuildChicken", "Build blocky chicken rig")
local model = Instance.new("Model")
model.Name = "Chicken_RigTest"
model:SetAttribute("Purpose", "Standalone rig/art test; no inventory integration")
local cream = Color3.fromRGB(255, 244, 217)
local white = Color3.fromRGB(255, 252, 238)
local feather = Color3.fromRGB(232, 214, 177)
local red = Color3.fromRGB(224, 53, 58)
local orange = Color3.fromRGB(245, 161, 40)
local dark = Color3.fromRGB(39, 31, 32)
local function part(name, size, position, color, rotation)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Anchored = true
    p.CanCollide = false
    p.Massless = true
    p.Parent = model
    return p
end
local function detail(name, size, position, color, limb, rotation)
    local p = part(name, size, position, color, rotation)
    local w = Instance.new("WeldConstraint")
    w.Name = limb.Name .. "To" .. name
    w.Part0, w.Part1 = limb, p
    w.Parent = p
    return p
end
local torso = part("Torso", Vector3.new(2.6, 2.25, 2.8), Vector3.new(0, 2.05, 0), cream)
torso.CanCollide = true
torso.Massless = false
local root = part("HumanoidRootPart", torso.Size, torso.Position, cream)
root.CFrame = torso.CFrame
root.Transparency = 1
root.RootPriority = 127
root.Massless = false
model.PrimaryPart = root
local function joint(limb, anchor)
    local world = torso.CFrame * CFrame.new(anchor)
    local motor = Instance.new("Motor6D")
    motor.Name = "TorsoTo" .. limb.Name
    motor.Part0, motor.Part1 = torso, limb
    motor.C0 = torso.CFrame:ToObjectSpace(world)
    -- Both offsets point TO the joint, preserving Part0*C0 == Part1*C1.
    motor.C1 = limb.CFrame:ToObjectSpace(world)
    motor.Parent = torso
end
local rj = Instance.new("Motor6D")
rj.Name = "RootJoint"
rj.Part0, rj.Part1 = root, torso
rj.C0, rj.C1 = CFrame.identity, CFrame.identity
rj.Parent = root
local head = part("Head", Vector3.new(1.85, 1.8, 1.65), Vector3.new(0, 3.4, -0.93), white)
joint(head, Vector3.new(0, torso.Size.Y/2, -torso.Size.Z*.3))
detail("Beak", Vector3.new(.82, .42, .62), Vector3.new(0, 3.15, -2.015), orange, head)
detail("BeakTip", Vector3.new(.56, .28, .23), Vector3.new(0, 3.11, -2.43), Color3.fromRGB(255, 187, 50), head)
detail("Wattle", Vector3.new(.48, .57, .32), Vector3.new(0, 2.76, -1.86), red, head)
for _,side in {-1, 1} do
    local label = side == -1 and "Left" or "Right"
    detail(label.."Eye", Vector3.new(.13, .34, .34), Vector3.new(side*.947, 3.58, -1.35), dark, head)
    detail(label.."EyeGlint", Vector3.new(.035, .105, .105), Vector3.new(side*1.02, 3.67, -1.43), white, head)
    local wing = part(label.."Wing", Vector3.new(.48, 1.35, 1.85), Vector3.new(side*1.43, 2.03, .1), white, CFrame.Angles(0,0,side*math.rad(8)))
    joint(wing, Vector3.new(side*torso.Size.X/2, torso.Size.Y*.3, -.35))
    for i=1,3 do
        detail(label.."WingFeather"..i, Vector3.new(.12,.65,.36), Vector3.new(side*1.72,1.82,-.57+(i-1)*.47), feather, wing, CFrame.Angles(0,0,side*math.rad(8)))
    end
    local leg = part(label.."Leg", Vector3.new(.34,.84,.35), Vector3.new(side*.7,.63,-.1), orange)
    joint(leg, Vector3.new(side*torso.Size.X*.27, -torso.Size.Y/2, -.1))
    detail(label.."Foot", Vector3.new(.72,.22,.64), Vector3.new(side*.7,.16,-.28), orange, leg)
    for i=1,3 do
        detail(label.."Toe"..i, Vector3.new(.17,.19,.55), Vector3.new(side*.7+(i-2)*.25,.145,-.75), orange, leg)
    end
end
for i=1,3 do
    detail("Comb"..i, Vector3.new(.36, ({.48,.7,.5})[i], .43), Vector3.new(0,4.35+({.48,.7,.5})[i]/2-.15,-1.55+(i-1)*.48), red, head)
end
local tail = part("Tail", Vector3.new(1.25,.48,1.25), Vector3.new(0,2.52,1.62), white, CFrame.Angles(math.rad(-32),0,0))
joint(tail, Vector3.new(0,torso.Size.Y*.2,torso.Size.Z/2))
for i=1,3 do
    detail("TailFeather"..i, Vector3.new(.42,.38,1.1), Vector3.new((i-2)*.43,2.88,2.04), i==2 and white or cream, tail, CFrame.Angles(math.rad(-40),0,0))
end
local humanoid = Instance.new("Humanoid")
humanoid.Name = "Humanoid"
humanoid.RigType = Enum.HumanoidRigType.R15
humanoid.RequiresNeck = false
humanoid.BreakJointsOnDeath = false
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
humanoid.WalkSpeed = 7
humanoid.Parent = model
Instance.new("Animator", humanoid)
local lowest = math.huge
for _,p in model:GetChildren() do
    if p:IsA("BasePart") and p ~= root then
        local half = p.Size/2
        for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
            lowest = math.min(lowest, (p.CFrame * Vector3.new(x*half.X,y*half.Y,z*half.Z)).Y)
        end end end
    end
end
humanoid.HipHeight = root.Position.Y - root.Size.Y/2 - lowest + .02
model.Parent = workspace
-- Open promenade, close to spawn; raycast avoids relying on floor height.
local hit = workspace:Raycast(Vector3.new(12,50,12),Vector3.new(0,-100,0))
local ground = hit and hit.Position.Y or .1
model:PivotTo(CFrame.new(12, ground + root.Position.Y - lowest + .02, 12))
for _,p in model:GetDescendants() do
    if p:IsA("BasePart") then p.Anchored = false end
end
game:GetService("Selection"):Set({model})
local focus = model:GetPivot().Position + Vector3.new(0,.6,0)
workspace.CurrentCamera.CFrame = CFrame.lookAt(focus+Vector3.new(8,5,-10),focus)
workspace.CurrentCamera.Focus = CFrame.new(focus)
if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end
print("Created",model:GetFullName(),"HipHeight",humanoid.HipHeight,"Parts",#model:GetChildren())
