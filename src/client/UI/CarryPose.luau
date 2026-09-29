local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Shared.Config.CarryConfig)
local Pose={}
local started=false
local states={}

function Pose.Create(character)
	local joints={}
	for _,joint in character:GetDescendants() do
		if joint:IsA("Motor6D") and (joint.Name=="RightShoulder" or joint.Name=="LeftShoulder"
			or joint.Name=="Right Shoulder" or joint.Name=="Left Shoulder") then
			local rotation=joint.C0.Rotation
			table.insert(joints,{Joint=joint,Original=joint.Transform,
				Raised=rotation:Inverse()*CFrame.Angles(math.rad(Config.ArmRaiseDegrees),0,0)*rotation})
		end
	end
	return joints
end

function Pose.Apply(joints)
	for _,entry in joints do if entry.Joint.Parent then entry.Joint.Transform=entry.Raised end end
end

function Pose.Restore(joints)
	for _,entry in joints do if entry.Joint.Parent then entry.Joint.Transform=entry.Original end end
end

function Pose.Start()
	if started then return end
	started=true
	-- Run after Animator evaluation. Only shoulders are overridden; walking,
	-- jumping and character physics stay unchanged. Each client poses all carriers.
	RunService.PreSimulation:Connect(function()
		for player,state in states do
			local character=player.Character
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if player.Parent~=Players or character~=state.Character or not humanoid or humanoid.Health<=0
				or not (player:GetAttribute("CarriedPetId") or player:GetAttribute("CarriedEggUid")) then
				Pose.Restore(state.Joints);states[player]=nil
			end
		end
		for _,player in Players:GetPlayers() do
			local character=player.Character
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health>0 and (player:GetAttribute("CarriedPetId") or player:GetAttribute("CarriedEggUid")) then
				local state=states[player]
				if not state then
					state={Character=character,Joints=Pose.Create(character)}
					-- Streaming may deliver the character before both shoulders.
					if #state.Joints~=2 then continue end
					states[player]=state
				end
				Pose.Apply(state.Joints)
			end
		end
	end)
end

return Pose
