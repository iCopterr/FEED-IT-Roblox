-- Run via MCP in edit mode. No player data or persistent world changes.
local check=require(game.StarterPlayer.StarterPlayerScripts.Client.UI.FeedPrompt)
local model=Instance.new("Model")
local root=Instance.new("Part")
local ok,failure=xpcall(function()
	model:SetAttribute("OwnerUserId",123);model:SetAttribute("PetId","pet-a")
	local body=Instance.new("Part");body.Position=Vector3.new(0,100,0);body.Parent=model
	local anchor=Instance.new("Attachment");anchor.Position=Vector3.new(0,-98,0);anchor.Parent=body
	local prompt=Instance.new("ProximityPrompt");prompt.Name="OpenFeedUI"
	prompt.MaxActivationDistance=12;prompt.Parent=anchor
	root.Position=Vector3.new(0,2,2)
	for _=1,3 do assert(check.CanOpen(prompt,123,"pet-a",root)) end
	assert(not check.CanOpen(prompt,456,"pet-a",root))
	assert(not check.CanOpen(prompt,123,"wrong",root))
	assert(not check.CanOpen(prompt,123,nil,root))
	assert(not check.CanOpen(prompt,123,"pet-a",nil))
	root.Position=Vector3.new(50,2,0);assert(not check.CanOpen(prompt,123,"pet-a",root))
	prompt.Parent=body;root.Position=Vector3.new(0,100,2)
	assert(check.CanOpen(prompt,123,"pet-a",root))
	prompt.Name="PickupPet";assert(not check.CanOpen(prompt,123,"pet-a",root))
end,debug.traceback)
model:Destroy();root:Destroy()
assert(ok,failure)
print("PASS FeedPrompt regression checks: 10")
