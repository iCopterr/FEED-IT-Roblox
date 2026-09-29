-- Edit-mode regression test: no persistent scene or player data changes.
local pose=require(game.StarterPlayer.StarterPlayerScripts.Client.UI.CarryPose)
local count=0
for _,r6 in {true,false} do
	local character=Instance.new("Model")
	local torso=Instance.new("Part");torso.Parent=character
	for _,side in {"Left","Right"} do
		local arm=Instance.new("Part");arm.Parent=character
		local motor=Instance.new("Motor6D")
		motor.Name=side..(if r6 then " Shoulder" else "Shoulder")
		motor.Part0=torso;motor.Part1=arm
		motor.C0=CFrame.new(if side=="Left" then -1 else 1,1,0)
			*CFrame.Angles(0,if r6 then math.rad(if side=="Left" then -90 else 90) else 0,0)
		motor.Parent=torso
	end
	local joints=pose.Create(character);assert(#joints==2);count+=1
	for _=1,3 do
		pose.Apply(joints)
		for _,entry in joints do
			local raised=(entry.Joint.C0.Rotation*entry.Joint.Transform):VectorToWorldSpace(Vector3.new(0,-1,0))
			assert(raised.Y>.9,"Arm must point overhead")
			count+=1
		end
		pose.Restore(joints)
		for _,entry in joints do assert(entry.Joint.Transform==entry.Original);count+=1 end
	end
	character:Destroy()
end
print("PASS carry shoulder pose checks",count)
