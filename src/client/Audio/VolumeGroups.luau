-- Client-local fallback: settings must not wait for optional authored audio groups.
local Groups={}
function Groups.Ensure(parent,name)
	for _,child in parent:GetChildren() do
		if child.Name==name and child:IsA("SoundGroup") then return child end
	end
	local group=Instance.new("SoundGroup")
	group.Name=name
	group.Volume=1
	group.Parent=parent
	return group
end
return Groups
